import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'storage_service.dart';

/// Service intelligent de gestion des mises à jour Shorebird
///
/// Stratégie:
/// 1. Vérifie les mises à jour au lancement (silencieux)
/// 2. Télécharge en arrière-plan sans bloquer l'utilisateur
/// 3. Applique la mise à jour au prochain lancement naturel
/// 4. Notifie l'utilisateur de manière non intrusive
class ShorebirdUpdateService extends GetxService {
  final _updater = ShorebirdUpdater();
  final _storage = StorageService();

  // Observable pour suivre l'état de la mise à jour
  final isUpdateAvailable = false.obs;
  final isDownloading = false.obs;
  final downloadProgress = 0.0.obs;
  final updateStatus = ''.obs;
  final currentPatchNumber = Rx<int?>(null);

  // Clés de stockage
  static const String _keyLastCheckTime = 'shorebird_last_check';
  static const String _keyUpdateAvailable = 'shorebird_update_available';
  static const String _keyPatchNumber = 'shorebird_patch_number';

  // Configuration
  static const Duration _checkInterval = Duration(hours: 6);

  @override
  Future<ShorebirdUpdateService> onInit() async {
    super.onInit();
    debugPrint('🚀 [SHOREBIRD] Initialisation du service de mise à jour');

    // Vérifier automatiquement au lancement (silencieux)
    await checkForUpdatesInBackground();

    return this;
  }

  /// Vérifie les mises à jour en arrière-plan (non bloquant)
  Future<void> checkForUpdatesInBackground() async {
    try {
      debugPrint('🔍 [SHOREBIRD] Vérification des mises à jour en arrière-plan...');

      // Vérifier si on doit checker (rate limiting)
      if (!_shouldCheckForUpdates()) {
        debugPrint('⏭️ [SHOREBIRD] Vérification trop récente, skip');
        _checkStoredUpdateStatus();
        return;
      }

      // Lire le patch actuel
      final currentPatch = await _updater.readCurrentPatch();
      currentPatchNumber.value = currentPatch?.number;
      debugPrint('📦 [SHOREBIRD] Patch actuel: ${currentPatch?.number ?? 'aucun'}');

      // Vérifier si une mise à jour est disponible
      final status = await _updater.checkForUpdate();

      if (status == UpdateStatus.outdated) {
        debugPrint('✅ [SHOREBIRD] Mise à jour disponible !');
        isUpdateAvailable.value = true;
        updateStatus.value = 'Mise à jour disponible';

        // Sauvegarder l'information
        await _storage.write(_keyUpdateAvailable, true);
        await _storage.write(_keyLastCheckTime, DateTime.now().millisecondsSinceEpoch);

        // Télécharger automatiquement en arrière-plan
        await _downloadUpdateInBackground();
      } else if (status == UpdateStatus.upToDate) {
        debugPrint('ℹ️ [SHOREBIRD] Application à jour');
        isUpdateAvailable.value = false;
        updateStatus.value = 'Application à jour';
        await _storage.write(_keyUpdateAvailable, false);
        await _storage.write(_keyLastCheckTime, DateTime.now().millisecondsSinceEpoch);
      } else {
        debugPrint('⚠️ [SHOREBIRD] Statut inconnu: $status');
        updateStatus.value = 'Statut inconnu';
      }

    } catch (e, stackTrace) {
      debugPrint('❌ [SHOREBIRD] Erreur lors de la vérification: $e');
      debugPrint('❌ [SHOREBIRD] StackTrace: $stackTrace');
      updateStatus.value = 'Erreur de vérification';
    }
  }

  /// Télécharge la mise à jour en arrière-plan (non bloquant)
  Future<void> _downloadUpdateInBackground() async {
    if (isDownloading.value) {
      debugPrint('⚠️ [SHOREBIRD] Téléchargement déjà en cours');
      return;
    }

    try {
      isDownloading.value = true;
      updateStatus.value = 'Téléchargement...';
      debugPrint('⬇️ [SHOREBIRD] Début du téléchargement silencieux...');

      // Télécharger la mise à jour
      await _updater.update();

      debugPrint('✅ [SHOREBIRD] Téléchargement terminé !');
      debugPrint('🔄 [SHOREBIRD] La mise à jour sera appliquée au prochain lancement');

      isDownloading.value = false;
      downloadProgress.value = 1.0;
      updateStatus.value = 'Prêt à redémarrer';

      // Lire et sauvegarder le nouveau patch
      final newPatch = await _updater.readCurrentPatch();
      if (newPatch != null) {
        await _storage.write(_keyPatchNumber, newPatch.number);
        currentPatchNumber.value = newPatch.number;
      }

    } catch (e, stackTrace) {
      debugPrint('❌ [SHOREBIRD] Erreur lors du téléchargement: $e');
      debugPrint('❌ [SHOREBIRD] StackTrace: $stackTrace');
      isDownloading.value = false;
      updateStatus.value = 'Erreur de téléchargement';
    }
  }

  /// Vérifie si on doit checker les mises à jour (rate limiting)
  bool _shouldCheckForUpdates() {
    final lastCheck = _storage.read(_keyLastCheckTime);
    if (lastCheck == null) return true;

    final lastCheckTime = DateTime.fromMillisecondsSinceEpoch(lastCheck as int);
    final now = DateTime.now();

    return now.difference(lastCheckTime) > _checkInterval;
  }

  /// Vérifie le statut stocké d'une mise à jour
  void _checkStoredUpdateStatus() {
    final updateAvailable = _storage.read(_keyUpdateAvailable) ?? false;
    isUpdateAvailable.value = updateAvailable as bool;

    if (updateAvailable) {
      updateStatus.value = 'Mise à jour disponible';
      debugPrint('ℹ️ [SHOREBIRD] Mise à jour déjà téléchargée, en attente de redémarrage');
    }
  }

  /// Force une vérification immédiate (pour usage manuel)
  Future<void> forceCheckForUpdates() async {
    debugPrint('🔄 [SHOREBIRD] Vérification forcée des mises à jour...');
    await _storage.remove(_keyLastCheckTime);
    await checkForUpdatesInBackground();
  }

  /// Obtient le numéro de patch actuel
  Future<int?> getCurrentPatchNumber() async {
    try {
      final patch = await _updater.readCurrentPatch();
      return patch?.number;
    } catch (e) {
      debugPrint('❌ [SHOREBIRD] Erreur lors de la récupération du patch: $e');
      return null;
    }
  }

  /// Obtient les informations de l'application
  Future<Map<String, dynamic>> getAppInfo() async {
    try {
      final currentPatch = await _updater.readCurrentPatch();
      final status = await _updater.checkForUpdate();

      return {
        'currentPatch': currentPatch?.number,
        'updateAvailable': status == UpdateStatus.outdated,
        'status': updateStatus.value,
        'downloadProgress': downloadProgress.value,
      };
    } catch (e) {
      debugPrint('❌ [SHOREBIRD] Erreur lors de la récupération des infos: $e');
      return {};
    }
  }

  /// Nettoie les données du service
  void clearUpdateData() {
    _storage.remove(_keyLastCheckTime);
    _storage.remove(_keyUpdateAvailable);
    _storage.remove(_keyPatchNumber);
    isUpdateAvailable.value = false;
    isDownloading.value = false;
    downloadProgress.value = 0.0;
    updateStatus.value = '';
    currentPatchNumber.value = null;
    debugPrint('🧹 [SHOREBIRD] Données de mise à jour nettoyées');
  }
}
