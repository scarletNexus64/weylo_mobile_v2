import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../data/services/shorebird_update_service.dart';

/// Widget non intrusif pour notifier l'utilisateur qu'une mise à jour est disponible
///
/// Affiche un banner discret en haut de l'écran qui peut être fermé
/// Propose à l'utilisateur de redémarrer l'app pour appliquer la MAJ
class UpdateNotificationWidget extends StatelessWidget {
  const UpdateNotificationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final updateService = Get.find<ShorebirdUpdateService>();

    return Obx(() {
      // Ne rien afficher si pas de MAJ disponible ou si en téléchargement
      if (!updateService.isUpdateAvailable.value ||
          updateService.isDownloading.value ||
          updateService.updateStatus.value != 'Prêt à redémarrer') {
        return const SizedBox.shrink();
      }

      return _UpdateBanner(
        onRestart: () => _restartApp(),
        onDismiss: () => updateService.isUpdateAvailable.value = false,
      );
    });
  }

  /// Redémarre l'application
  void _restartApp() {
    if (Platform.isAndroid || Platform.isIOS) {
      // Sur mobile, on peut simplement quitter l'app
      // L'utilisateur la relancera manuellement
      SystemNavigator.pop();
    }
  }
}

class _UpdateBanner extends StatelessWidget {
  final VoidCallback onRestart;
  final VoidCallback onDismiss;

  const _UpdateBanner({
    required this.onRestart,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade600,
              Colors.blue.shade700,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Icône
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.system_update,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Texte
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Mise à jour disponible',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Redémarrez pour appliquer',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bouton Redémarrer
                TextButton(
                  onPressed: onRestart,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Redémarrer',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Bouton Fermer
                InkWell(
                  onTap: onDismiss,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      color: Colors.white.withOpacity(0.9),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Version simplifiée en SnackBar (alternative)
class UpdateSnackbar {
  static void show() {
    Get.snackbar(
      'Mise à jour disponible',
      'Une nouvelle version est prête. Redémarrez l\'app pour l\'appliquer.',
      icon: const Icon(Icons.system_update, color: Colors.white),
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue.shade700,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      mainButton: TextButton(
        onPressed: () {
          Get.back(); // Fermer le snackbar
          if (Platform.isAndroid || Platform.isIOS) {
            SystemNavigator.pop();
          }
        },
        child: const Text(
          'Redémarrer',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
