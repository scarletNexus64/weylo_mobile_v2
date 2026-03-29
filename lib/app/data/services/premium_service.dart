import 'package:dio/dio.dart';
import 'package:weylo/app/data/core/api_service.dart';

/// Service pour gérer le système de certification premium
class PremiumService {
  final ApiService _apiService = ApiService();

  /// Récupérer les informations sur le passe premium
  /// GET /api/v1/premium-pass/info
  Future<Map<String, dynamic>> getPremiumInfo() async {
    try {
      final response = await _apiService.dio.get('/premium-pass/info');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to get premium info');
      }
    } on DioException catch (e) {
      print('❌ Error getting premium info: ${e.message}');
      throw Exception(e.response?.data['message'] ?? 'Failed to get premium info');
    }
  }

  /// Récupérer le statut premium de l'utilisateur connecté
  /// GET /api/v1/premium-pass/status
  Future<Map<String, dynamic>> getPremiumStatus() async {
    try {
      print('🔍 [PREMIUM SERVICE] Appel API /premium-pass/status...');
      final response = await _apiService.dio.get('/premium-pass/status');

      print('📡 [PREMIUM SERVICE] Réponse API:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ [PREMIUM SERVICE] Statut premium récupéré:');
        print('   - is_premium: ${data['is_premium']}');
        print('   - has_active_premium: ${data['has_active_premium']}');
        print('   - expires_at: ${data['expires_at']}');
        print('   - days_remaining: ${data['days_remaining']}');

        // L'API retourne directement les données sans wrapper 'data'
        return data;
      } else {
        throw Exception('Failed to get premium status');
      }
    } on DioException catch (e) {
      print('❌ [PREMIUM SERVICE] Error getting premium status: ${e.message}');
      print('   - Response: ${e.response?.data}');
      throw Exception(e.response?.data['message'] ?? 'Failed to get premium status');
    }
  }

  /// Acheter le passe premium via wallet
  /// POST /api/v1/premium-pass/purchase
  Future<Map<String, dynamic>> purchasePremium({bool autoRenew = false}) async {
    try {
      final response = await _apiService.dio.post(
        '/premium-pass/purchase',
        data: {
          'auto_renew': autoRenew,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['data'];
      } else {
        throw Exception('Failed to purchase premium');
      }
    } on DioException catch (e) {
      print('❌ Error purchasing premium: ${e.message}');

      // Gérer les erreurs spécifiques
      if (e.response?.statusCode == 402) {
        throw Exception('Solde insuffisant pour acheter le passe premium');
      } else if (e.response?.statusCode == 400) {
        throw Exception(e.response?.data['message'] ?? 'Requête invalide');
      }

      throw Exception(e.response?.data['message'] ?? 'Failed to purchase premium');
    }
  }

  /// Renouveler le passe premium
  /// POST /api/v1/premium-pass/renew
  Future<Map<String, dynamic>> renewPremium() async {
    try {
      final response = await _apiService.dio.post('/premium-pass/renew');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['data'];
      } else {
        throw Exception('Failed to renew premium');
      }
    } on DioException catch (e) {
      print('❌ Error renewing premium: ${e.message}');

      if (e.response?.statusCode == 402) {
        throw Exception('Solde insuffisant pour renouveler le passe premium');
      }

      throw Exception(e.response?.data['message'] ?? 'Failed to renew premium');
    }
  }

  /// Activer le renouvellement automatique
  /// POST /api/v1/premium-pass/auto-renew/enable
  Future<void> enableAutoRenew() async {
    try {
      await _apiService.dio.post('/premium-pass/auto-renew/enable');
    } on DioException catch (e) {
      print('❌ Error enabling auto-renew: ${e.message}');
      throw Exception(e.response?.data['message'] ?? 'Failed to enable auto-renew');
    }
  }

  /// Désactiver le renouvellement automatique
  /// POST /api/v1/premium-pass/auto-renew/disable
  Future<void> disableAutoRenew() async {
    try {
      await _apiService.dio.post('/premium-pass/auto-renew/disable');
    } on DioException catch (e) {
      print('❌ Error disabling auto-renew: ${e.message}');
      throw Exception(e.response?.data['message'] ?? 'Failed to disable auto-renew');
    }
  }

  /// Récupérer le prix du passe premium depuis les settings publics
  /// GET /api/v1/settings/public
  Future<int> getPremiumPrice() async {
    try {
      final response = await _apiService.dio.get('/settings/public');

      if (response.statusCode == 200) {
        final data = response.data['data'];

        // Le prix est dans premium_monthly_price
        final price = data['premium_monthly_price'];

        if (price is int) {
          return price;
        } else if (price is String) {
          return int.tryParse(price) ?? 5000; // Fallback à 5000 FCFA
        } else {
          return 5000; // Fallback
        }
      } else {
        throw Exception('Failed to get settings');
      }
    } on DioException catch (e) {
      print('❌ Error getting premium price: ${e.message}');
      return 5000; // Fallback en cas d'erreur
    }
  }

  /// Vérifier si l'utilisateur peut voir l'identité d'un autre utilisateur
  /// GET /api/v1/premium-pass/can-view-identity/{userId}
  Future<bool> canViewIdentity(int userId) async {
    try {
      final response = await _apiService.dio.get('/premium-pass/can-view-identity/$userId');

      if (response.statusCode == 200) {
        return response.data['data']['can_view'] ?? false;
      } else {
        return false;
      }
    } on DioException catch (e) {
      print('❌ Error checking identity view permission: ${e.message}');
      return false;
    }
  }

  /// Récupérer l'historique des passes premium achetés
  /// GET /api/v1/premium-pass/history
  Future<List<Map<String, dynamic>>> getPremiumHistory({int page = 1}) async {
    try {
      final response = await _apiService.dio.get(
        '/premium-pass/history',
        queryParameters: {'page': page},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Failed to get premium history');
      }
    } on DioException catch (e) {
      print('❌ Error getting premium history: ${e.message}');
      throw Exception(e.response?.data['message'] ?? 'Failed to get premium history');
    }
  }
}
