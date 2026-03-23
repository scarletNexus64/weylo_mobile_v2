import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../data/services/premium_service.dart';
import '../../../data/services/wallet_service.dart';

class CertificationController extends GetxController {
  final PremiumService _premiumService = PremiumService();
  final WalletService _walletService = WalletService();

  // Loading states
  final isLoadingInfo = false.obs;
  final isLoadingStatus = false.obs;
  final isPurchasing = false.obs;
  final isRenewing = false.obs;
  final isTogglingAutoRenew = false.obs;

  // Premium info
  final premiumPrice = 0.obs;
  final formattedPrice = ''.obs;
  final premiumDuration = '1 mois'.obs;
  final premiumFeatures = <String>[].obs;

  // User premium status
  final isPremium = false.obs;
  final hasActivePremium = false.obs;
  final premiumExpiresAt = Rxn<DateTime>();
  final daysRemaining = 0.obs;
  final autoRenewEnabled = false.obs;

  // Wallet
  final walletBalance = 0.0.obs;
  final formattedBalance = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadPremiumInfo();
    loadPremiumStatus();
    loadWalletBalance();
  }

  /// Charger les informations sur le passe premium
  Future<void> loadPremiumInfo() async {
    try {
      isLoadingInfo.value = true;

      final info = await _premiumService.getPremiumInfo();

      premiumPrice.value = info['price'] ?? 0;
      formattedPrice.value = info['formatted_price'] ?? '0 FCFA';
      premiumDuration.value = info['duration'] ?? '1 mois';

      if (info['features'] != null) {
        premiumFeatures.value = List<String>.from(info['features']);
      }
    } catch (e) {
      print('❌ Error loading premium info: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger les informations du passe premium',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoadingInfo.value = false;
    }
  }

  /// Charger le statut premium de l'utilisateur
  Future<void> loadPremiumStatus() async {
    try {
      isLoadingStatus.value = true;

      final status = await _premiumService.getPremiumStatus();

      isPremium.value = status['is_premium'] ?? false;
      hasActivePremium.value = status['has_active_premium'] ?? false;
      autoRenewEnabled.value = status['auto_renew'] ?? false;
      daysRemaining.value = status['days_remaining'] ?? 0;

      if (status['expires_at'] != null) {
        premiumExpiresAt.value = DateTime.parse(status['expires_at']);
      }
    } catch (e) {
      print('❌ Error loading premium status: $e');
      // Silently fail for status, it's not critical
    } finally {
      isLoadingStatus.value = false;
    }
  }

  /// Charger le solde du wallet
  Future<void> loadWalletBalance() async {
    try {
      final wallet = await _walletService.getWallet();
      if (wallet != null) {
        walletBalance.value = wallet.balance;
        formattedBalance.value = wallet.formattedBalance;
      }
    } catch (e) {
      print('❌ Error loading wallet balance: $e');
    }
  }

  /// Acheter le passe premium
  Future<void> purchasePremium({bool autoRenew = false}) async {
    try {
      // Vérifier le solde
      if (walletBalance.value < premiumPrice.value) {
        Get.snackbar(
          'Solde insuffisant',
          'Votre solde est insuffisant pour acheter le passe premium. Veuillez recharger votre wallet.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // Confirmation
      final confirm = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Confirmer l\'achat'),
          content: Text(
            'Voulez-vous acheter le passe premium pour $formattedPrice ?\n\n'
            'Votre nouveau solde sera de ${(walletBalance.value - premiumPrice.value).toStringAsFixed(0)} FCFA.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFf35453),
              ),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      isPurchasing.value = true;

      await _premiumService.purchasePremium(autoRenew: autoRenew);

      // Recharger les données
      await Future.wait([
        loadPremiumStatus(),
        loadWalletBalance(),
      ]);

      // Note: Le statut premium sera mis à jour automatiquement lors de la prochaine
      // récupération des données utilisateur depuis l'API (ex: au prochain rafraîchissement)

      Get.back(); // Fermer la page

      Get.snackbar(
        'Félicitations ! 🎉',
        'Votre compte est maintenant certifié premium !',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      print('❌ Error purchasing premium: $e');
      Get.snackbar(
        'Erreur',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isPurchasing.value = false;
    }
  }

  /// Renouveler le passe premium manuellement
  Future<void> renewPremium() async {
    try {
      // Vérifier le solde
      if (walletBalance.value < premiumPrice.value) {
        Get.snackbar(
          'Solde insuffisant',
          'Votre solde est insuffisant pour renouveler le passe premium. Veuillez recharger votre wallet.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // Confirmation
      final confirm = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Confirmer le renouvellement'),
          content: Text(
            'Voulez-vous renouveler votre passe premium pour $formattedPrice ?\n\n'
            'Votre certification sera prolongée d\'un mois supplémentaire.\n\n'
            'Votre nouveau solde sera de ${(walletBalance.value - premiumPrice.value).toStringAsFixed(0)} FCFA.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFf35453),
              ),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      isRenewing.value = true;

      await _premiumService.renewPremium();

      // Recharger les données
      await Future.wait([
        loadPremiumStatus(),
        loadWalletBalance(),
      ]);

      Get.snackbar(
        'Succès ! 🎉',
        'Votre certification premium a été renouvelée avec succès !',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      print('❌ Error renewing premium: $e');
      Get.snackbar(
        'Erreur',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isRenewing.value = false;
    }
  }

  /// Activer/Désactiver le renouvellement automatique
  Future<void> toggleAutoRenew(bool enable) async {
    try {
      isTogglingAutoRenew.value = true;

      if (enable) {
        await _premiumService.enableAutoRenew();
      } else {
        await _premiumService.disableAutoRenew();
      }

      autoRenewEnabled.value = enable;

      Get.snackbar(
        'Succès',
        enable
            ? 'Renouvellement automatique activé'
            : 'Renouvellement automatique désactivé',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('❌ Error toggling auto-renew: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de modifier le renouvellement automatique',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isTogglingAutoRenew.value = false;
    }
  }

  /// Rafraîchir toutes les données
  Future<void> refreshAll() async {
    await Future.wait([
      loadPremiumInfo(),
      loadPremiumStatus(),
      loadWalletBalance(),
    ]);
  }
}
