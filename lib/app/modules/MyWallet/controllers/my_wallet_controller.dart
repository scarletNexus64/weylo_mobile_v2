import 'package:get/get.dart';
import 'dart:async';
import '../../../data/models/wallet_model.dart';
import '../../../data/models/wallet_transaction_model.dart';
import '../../../data/models/withdrawal_model.dart';
import '../../../data/services/wallet_service.dart';
import '../../../data/core/api_service.dart';
import '../../../data/models/sponsorship_checkout_args.dart';
import '../../../data/services/sponsorship_service.dart';
import '../../../routes/app_pages.dart';

class MyWalletController extends GetxController {
  final WalletService _walletService = WalletService();
  final SponsorshipService _sponsorshipService = SponsorshipService();

  // Observable states
  final isLoading = true.obs;
  final isLoadingTransactions = false.obs;
  final isProcessingPayment = false.obs;
  final isLoadingMore = false.obs;

  // Wallet data
  final wallet = Rxn<WalletModel>();
  final walletStats = Rxn<WalletDetailedStats>();

  // Transactions
  final transactions = <WalletTransactionModel>[].obs;
  final currentPage = 1.obs;
  final lastPage = 1.obs;
  final totalTransactions = 0.obs;
  final perPage = 20.obs;

  // Filters
  final selectedType = Rxn<String>(); // credit, debit, deposit, withdrawal

  // Withdrawals
  final withdrawals = <WithdrawalModel>[].obs;
  final withdrawalMethods = Rxn<WithdrawalMethodsResponse>();
  Timer? _pendingRefreshTimer;

  // Payment intents (ex: Sponsoring checkout)
  final pendingSponsorship = Rxn<SponsorshipCheckoutArgs>();
  Object? _lastArgs;

  @override
  void onInit() {
    super.onInit();
    loadWalletData();
  }

  @override
  void onClose() {
    _pendingRefreshTimer?.cancel();
    _pendingRefreshTimer = null;
    super.onClose();
  }

  void initFromArgs(dynamic args) {
    if (args is SponsorshipCheckoutArgs) {
      if (identical(args, _lastArgs)) return;
      _lastArgs = args;
      pendingSponsorship.value = args;
    }
  }

  void clearPendingSponsorship() {
    pendingSponsorship.value = null;
  }

  Future<void> payPendingSponsorship() async {
    final args = pendingSponsorship.value;
    if (args == null) return;

    // Ensure wallet loaded
    if (wallet.value == null) {
      await loadWallet();
    }

    final balance = wallet.value?.balance ?? 0;
    if (balance < args.price) {
      Get.defaultDialog(
        title: 'Solde insuffisant',
        middleText:
            'Vous avez ${wallet.value?.formattedBalance ?? '0 FCFA'}. Il vous faut ${args.price} FCFA pour payer ce sponsoring.',
        textCancel: 'Fermer',
        textConfirm: 'Recharger',
        onConfirm: () {
          Get.back();
          Get.toNamed(Routes.WALLET_DEPOSIT);
        },
      );
      return;
    }

    isProcessingPayment.value = true;
    try {
      final result = await _sponsorshipService.purchase(args);
      if (result['success'] == true) {
        Get.snackbar(
          'Succès',
          result['message'] ?? 'Sponsoring acheté',
          snackPosition: SnackPosition.BOTTOM,
        );

        // Refresh wallet + transactions to show the debit
        await Future.wait([
          loadWallet(),
          loadTransactions(),
        ]);

        pendingSponsorship.value = null;
        Get.back(); // retour à l'écran Sponsoring
      } else {
        Get.snackbar(
          'Erreur',
          result['message'] ?? 'Paiement échoué',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isProcessingPayment.value = false;
    }
  }

  /// Charger toutes les données du wallet
  Future<void> loadWalletData() async {
    isLoading.value = true;
    await Future.wait([
      loadWallet(),
      loadTransactions(),
      loadWithdrawalMethods(),
      // Keep pending withdrawals in sync on the wallet screen.
      loadWithdrawals(status: 'pending'),
    ]);
    isLoading.value = false;
  }

  /// Charger le solde et les stats
  Future<void> loadWallet() async {
    try {
      final walletData = await _walletService.getWallet();
      if (walletData != null) {
        wallet.value = walletData;
      }
    } on ApiException catch (e) {
      Get.snackbar(
        'Erreur',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Charger les statistiques détaillées
  Future<void> loadWalletStats() async {
    try {
      final stats = await _walletService.getWalletStats();
      if (stats != null) {
        walletStats.value = stats;
      }
    } on ApiException catch (e) {
      Get.snackbar(
        'Erreur',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Charger l'historique des transactions
  Future<void> loadTransactions({bool loadMore = false}) async {
    if (loadMore) {
      if (currentPage.value >= lastPage.value) return;
      isLoadingMore.value = true;
      currentPage.value++;
    } else {
      currentPage.value = 1;
      isLoadingTransactions.value = true;
    }

    try {
      final response = await _walletService.getTransactions(
        page: currentPage.value,
        perPage: perPage.value,
        type: selectedType.value,
      );

      if (loadMore) {
        transactions.addAll(response.transactions);
      } else {
        transactions.value = response.transactions;
      }

      lastPage.value = response.meta.lastPage;
      totalTransactions.value = response.meta.total;
    } on ApiException catch (e) {
      Get.snackbar(
        'Erreur',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingTransactions.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Filtrer les transactions par type
  void filterByType(String? type) {
    selectedType.value = type;
    loadTransactions();
  }

  /// Rafraîchir toutes les données
  Future<void> refresh() async {
    await loadWalletData();
  }

  /// Initier un dépôt
  Future<Map<String, dynamic>> initiateDeposit({
    required double amount,
    String? phoneNumber,
  }) async {
    isProcessingPayment.value = true;

    try {
      final result = await _walletService.initiateDeposit(
        amount: amount,
        phoneNumber: phoneNumber,
      );

      if (result['success'] == true) {
        Get.snackbar(
          'Succès',
          result['message'] ?? 'Dépôt initié avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );

        // Rafraîchir le wallet après un certain délai
        Future.delayed(const Duration(seconds: 2), () {
          loadWallet();
          loadTransactions();
        });
      }

      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'Une erreur est survenue',
      };
    } finally {
      isProcessingPayment.value = false;
    }
  }

  /// Demander un retrait
  Future<Map<String, dynamic>> requestWithdrawal({
    required double amount,
    required String phoneNumber,
    required String provider,
  }) async {
    isProcessingPayment.value = true;

    try {
      final result = await _walletService.requestWithdrawal(
        amount: amount,
        phoneNumber: phoneNumber,
        provider: provider,
      );

      if (result['success'] == true) {
        Get.snackbar(
          'Succès',
          result['message'] ?? 'Demande de retrait créée',
          snackPosition: SnackPosition.BOTTOM,
        );

        // Rafraîchir les données
        await Future.wait([
          loadWallet(),
          loadWithdrawals(status: 'pending'),
        ]);

        // Redirect to wallet: if we came from the wallet screen, pop back.
        // Otherwise, replace current route with wallet.
        if (Get.previousRoute == Routes.MY_WALLET) {
          Get.back();
        } else {
          Get.offNamed(Routes.MY_WALLET);
        }
      } else {
        Get.snackbar(
          'Erreur',
          result['message'] ?? 'Erreur lors de la demande de retrait',
          snackPosition: SnackPosition.BOTTOM,
        );
      }

      return result;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Une erreur est survenue',
        snackPosition: SnackPosition.BOTTOM,
      );
      return {
        'success': false,
        'message': 'Une erreur est survenue',
      };
    } finally {
      isProcessingPayment.value = false;
    }
  }

  /// Charger la liste des retraits
  Future<void> loadWithdrawals({String? status}) async {
    try {
      final response = await _walletService.getWithdrawals(status: status);
      withdrawals.value = response.withdrawals;
      _syncPendingRefreshTimer();
    } on ApiException catch (e) {
      Get.snackbar(
        'Erreur',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Annuler un retrait
  Future<void> cancelWithdrawal(int withdrawalId) async {
    try {
      final success = await _walletService.cancelWithdrawal(withdrawalId);

      if (success) {
        Get.snackbar(
          'Succès',
          'Retrait annulé',
          snackPosition: SnackPosition.BOTTOM,
        );

        // Rafraîchir les données
        await loadWithdrawals(status: 'pending');
        await loadWallet();
      } else {
        Get.snackbar(
          'Erreur',
          'Impossible d\'annuler ce retrait',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } on ApiException catch (e) {
      Get.snackbar(
        'Erreur',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Charger les méthodes de retrait disponibles
  Future<void> loadWithdrawalMethods() async {
    try {
      final methods = await _walletService.getWithdrawalMethods();
      if (methods != null) {
        withdrawalMethods.value = methods;
      }
    } on ApiException catch (e) {
      print('❌ Error loading withdrawal methods: $e');
    }
  }

  /// Vérifier si l'utilisateur a assez de solde
  bool hasEnoughBalance(double amount) {
    return (wallet.value?.balance ?? 0) >= amount;
  }

  bool get hasPendingWithdrawals =>
      withdrawals.any((w) => w.isPending || w.isProcessing);

  void _syncPendingRefreshTimer() {
    final shouldRun = hasPendingWithdrawals;
    if (!shouldRun) {
      _pendingRefreshTimer?.cancel();
      _pendingRefreshTimer = null;
      return;
    }

    // Already running
    if (_pendingRefreshTimer != null) return;

    // Poll lightly while there are pending withdrawals so the UI updates when
    // background jobs mark them completed/failed.
    _pendingRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await Future.wait([
        loadWallet(),
        loadWithdrawals(status: 'pending'),
      ]);
    });
  }

  /// Obtenir le solde formaté
  String get formattedBalance {
    return wallet.value?.formattedBalance ?? '0 FCFA';
  }

  /// Obtenir le solde
  double get balance {
    return wallet.value?.balance ?? 0;
  }
}
