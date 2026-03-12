import 'package:get/get.dart';
import '../core/api_service.dart';
import '../core/api_config.dart';
import '../models/wallet_model.dart';
import '../models/wallet_transaction_model.dart';
import '../models/withdrawal_model.dart';

class WalletService extends GetxService {
  final ApiService _apiService = ApiService();

  /// Obtenir le solde et les stats du wallet
  Future<WalletModel?> getWallet() async {
    try {
      final response = await _apiService.get(ApiConfig.wallet);

      if (response.data != null && response.data['wallet'] != null) {
        return WalletModel.fromJson(response.data['wallet']);
      }
      return null;
    } on ApiException catch (e) {
      print('❌ Error getting wallet: $e');
      rethrow;
    } catch (e) {
      print('❌ Unexpected error getting wallet: $e');
      throw ApiException(message: 'Une erreur est survenue');
    }
  }

  /// Obtenir les statistiques détaillées du wallet
  Future<WalletDetailedStats?> getWalletStats() async {
    try {
      final response = await _apiService.get(ApiConfig.walletStats);

      if (response.data != null) {
        return WalletDetailedStats.fromJson(response.data);
      }
      return null;
    } on ApiException catch (e) {
      print('❌ Error getting wallet stats: $e');
      rethrow;
    } catch (e) {
      print('❌ Unexpected error getting wallet stats: $e');
      throw ApiException(message: 'Une erreur est survenue');
    }
  }

  /// Obtenir l'historique des transactions
  Future<TransactionListResponse> getTransactions({
    int page = 1,
    int perPage = 20,
    String? type,
    String? from,
    String? to,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      if (type != null) {
        queryParameters['type'] = type;
      }
      if (from != null) {
        queryParameters['from'] = from;
      }
      if (to != null) {
        queryParameters['to'] = to;
      }

      final response = await _apiService.get(
        ApiConfig.transactions,
        queryParameters: queryParameters,
      );

      if (response.data != null) {
        return TransactionListResponse.fromJson(response.data);
      }

      return TransactionListResponse(
        transactions: [],
        meta: TransactionMeta(
          currentPage: 1,
          lastPage: 1,
          perPage: perPage,
          total: 0,
        ),
      );
    } on ApiException catch (e) {
      print('❌ Error getting transactions: $e');
      rethrow;
    } catch (e) {
      print('❌ Unexpected error getting transactions: $e');
      throw ApiException(message: 'Une erreur est survenue');
    }
  }

  /// Initier un dépôt
  Future<Map<String, dynamic>> initiateDeposit({
    required double amount,
    String? phoneNumber,
  }) async {
    try {
      final response = await _apiService.post(
        '${ApiConfig.wallet}/deposit/initiate',
        data: {
          'amount': amount,
          if (phoneNumber != null) 'phone_number': phoneNumber,
        },
      );

      if (response.data != null) {
        return {
          'success': response.data['success'] ?? false,
          'message': response.data['message'] ?? '',
          'data': response.data['data'],
        };
      }

      return {
        'success': false,
        'message': 'Erreur lors de l\'initiation du dépôt',
      };
    } on ApiException catch (e) {
      print('❌ Error initiating deposit: $e');
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e) {
      print('❌ Unexpected error initiating deposit: $e');
      return {
        'success': false,
        'message': 'Une erreur est survenue',
      };
    }
  }

  /// Demander un retrait
  Future<Map<String, dynamic>> requestWithdrawal({
    required double amount,
    required String phoneNumber,
    required String provider, // 'mtn_momo' or 'orange_money'
  }) async {
    try {
      final response = await _apiService.post(
        '${ApiConfig.wallet}/withdraw',
        data: {
          'amount': amount,
          'phone_number': phoneNumber,
          'provider': provider,
        },
      );

      if (response.data != null) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Demande de retrait créée',
          'withdrawal': response.data['withdrawal'] != null
              ? WithdrawalModel.fromJson(response.data['withdrawal'])
              : null,
        };
      }

      return {
        'success': false,
        'message': 'Erreur lors de la demande de retrait',
      };
    } on ApiException catch (e) {
      print('❌ Error requesting withdrawal: $e');
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e) {
      print('❌ Unexpected error requesting withdrawal: $e');
      return {
        'success': false,
        'message': 'Une erreur est survenue',
      };
    }
  }

  /// Obtenir la liste des retraits
  Future<WithdrawalListResponse> getWithdrawals({
    int page = 1,
    int perPage = 20,
    String? status,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      if (status != null) {
        queryParameters['status'] = status;
      }

      final response = await _apiService.get(
        '${ApiConfig.wallet}/withdrawals',
        queryParameters: queryParameters,
      );

      if (response.data != null) {
        return WithdrawalListResponse.fromJson(response.data);
      }

      return WithdrawalListResponse(
        withdrawals: [],
        meta: WithdrawalMeta(
          currentPage: 1,
          lastPage: 1,
          perPage: perPage,
          total: 0,
        ),
      );
    } on ApiException catch (e) {
      print('❌ Error getting withdrawals: $e');
      rethrow;
    } catch (e) {
      print('❌ Unexpected error getting withdrawals: $e');
      throw ApiException(message: 'Une erreur est survenue');
    }
  }

  /// Obtenir les détails d'un retrait
  Future<WithdrawalModel?> getWithdrawal(int withdrawalId) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.wallet}/withdrawals/$withdrawalId',
      );

      if (response.data != null && response.data['withdrawal'] != null) {
        return WithdrawalModel.fromJson(response.data['withdrawal']);
      }
      return null;
    } on ApiException catch (e) {
      print('❌ Error getting withdrawal: $e');
      rethrow;
    } catch (e) {
      print('❌ Unexpected error getting withdrawal: $e');
      throw ApiException(message: 'Une erreur est survenue');
    }
  }

  /// Annuler un retrait en attente
  Future<bool> cancelWithdrawal(int withdrawalId) async {
    try {
      final response = await _apiService.delete(
        '${ApiConfig.wallet}/withdrawals/$withdrawalId',
      );

      return response.statusCode == 200;
    } on ApiException catch (e) {
      print('❌ Error cancelling withdrawal: $e');
      return false;
    } catch (e) {
      print('❌ Unexpected error cancelling withdrawal: $e');
      return false;
    }
  }

  /// Obtenir les méthodes de retrait disponibles
  Future<WithdrawalMethodsResponse?> getWithdrawalMethods() async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.wallet}/withdrawal-methods',
      );

      if (response.data != null) {
        return WithdrawalMethodsResponse.fromJson(response.data);
      }
      return null;
    } on ApiException catch (e) {
      print('❌ Error getting withdrawal methods: $e');
      rethrow;
    } catch (e) {
      print('❌ Unexpected error getting withdrawal methods: $e');
      throw ApiException(message: 'Une erreur est survenue');
    }
  }

  /// Vérifier le statut d'un dépôt FreeMoPay
  Future<Map<String, dynamic>> checkDepositStatus({
    required int transactionId,
  }) async {
    try {
      final response = await _apiService.post(
        '${ApiConfig.wallet}/deposit/check-status',
        data: {
          'transaction_id': transactionId,
        },
      );

      if (response.data != null) {
        return {
          'success': response.data['success'] ?? false,
          'status': response.data['status'] ?? 'pending',
          'message': response.data['message'] ?? '',
          'amount': response.data['amount'],
          'freemopay_status': response.data['freemopay_status'],
          'completed_at': response.data['completed_at'],
        };
      }

      return {
        'success': false,
        'status': 'unknown',
        'message': 'Erreur lors de la vérification',
      };
    } on ApiException catch (e) {
      print('❌ Error checking deposit status: $e');
      return {
        'success': false,
        'status': 'error',
        'message': e.message,
      };
    } catch (e) {
      print('❌ Unexpected error checking deposit status: $e');
      return {
        'success': false,
        'status': 'error',
        'message': 'Une erreur est survenue',
      };
    }
  }
}
