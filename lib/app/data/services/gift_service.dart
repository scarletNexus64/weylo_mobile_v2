import '../core/api_service.dart';
import '../core/api_config.dart';
import '../models/gift_model.dart';

class GiftService {
  final _api = ApiService();

  /// Get all gift categories
  Future<List<GiftCategory>> getCategories() async {
    try {
      final response = await _api.get('/gift-categories');

      final categoriesData = response.data['categories'] as List;
      return categoriesData
          .map((json) => GiftCategory.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ [GIFT_SERVICE] Erreur lors de la récupération des catégories: $e');
      rethrow;
    }
  }

  /// Get gifts by category
  Future<List<GiftModel>> getGiftsByCategory(int categoryId) async {
    try {
      final response = await _api.get('/gift-categories/$categoryId/gifts');

      final giftsData = response.data['gifts'] as List;
      return giftsData
          .map((json) => GiftModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ [GIFT_SERVICE] Erreur lors de la récupération des cadeaux par catégorie: $e');
      rethrow;
    }
  }

  /// Get all available gifts (catalog)
  Future<List<GiftModel>> getGifts() async {
    try {
      final response = await _api.get(ApiConfig.gifts);

      final giftsData = response.data['gifts'] as List;
      return giftsData
          .map((json) => GiftModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ [GIFT_SERVICE] Erreur lors de la récupération des cadeaux: $e');
      rethrow;
    }
  }

  /// Get received gifts with pagination
  Future<GiftListResponse> getReceivedGifts({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _api.get(
        ApiConfig.receivedGifts,
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );

      return GiftListResponse.fromJson(response.data);
    } catch (e) {
      print('❌ [GIFT_SERVICE] Erreur lors de la récupération des cadeaux reçus: $e');
      rethrow;
    }
  }

  /// Get sent gifts with pagination
  Future<GiftListResponse> getSentGifts({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _api.get(
        ApiConfig.sentGifts,
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );

      return GiftListResponse.fromJson(response.data);
    } catch (e) {
      print('❌ [GIFT_SERVICE] Erreur lors de la récupération des cadeaux envoyés: $e');
      rethrow;
    }
  }

  /// Send a gift to a user
  Future<GiftTransactionModel> sendGift({
    required int giftId,
    required String recipientUsername,
    String? message,
  }) async {
    try {
      final response = await _api.post(
        '${ApiConfig.gifts}/send',
        data: {
          'gift_id': giftId,
          'recipient_username': recipientUsername,
          if (message != null) 'message': message,
        },
      );

      return GiftTransactionModel.fromJson(
        response.data['transaction'] as Map<String, dynamic>,
      );
    } catch (e) {
      print('❌ [GIFT_SERVICE] Erreur lors de l\'envoi du cadeau: $e');
      rethrow;
    }
  }

  /// Send a gift in an existing conversation
  Future<GiftTransactionModel> sendGiftInConversation({
    required int conversationId,
    required int giftId,
    String? message,
  }) async {
    try {
      final response = await _api.post(
        '/chat/conversations/$conversationId/gift',
        data: {
          'gift_id': giftId,
          if (message != null) 'message': message,
        },
      );

      return GiftTransactionModel.fromJson(
        response.data['transaction'] as Map<String, dynamic>,
      );
    } catch (e) {
      print('❌ [GIFT_SERVICE] Erreur lors de l\'envoi du cadeau dans la conversation: $e');
      rethrow;
    }
  }
}
