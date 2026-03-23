import '../core/api_service.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _api = ApiService();

  /// Get paginated notifications
  Future<NotificationListResponse> getNotifications({int page = 1, int perPage = 20}) async {
    print('🔔 [NOTIFICATION_SERVICE] Récupération des notifications (page: $page)');

    try {
      final response = await _api.get(
        '/notifications',
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );

      print('✅ [NOTIFICATION_SERVICE] Notifications récupérées avec succès');
      return NotificationListResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print('💥 [NOTIFICATION_SERVICE] Erreur: $e');
      rethrow;
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    print('🔔 [NOTIFICATION_SERVICE] Marquage de la notification $notificationId comme lue');

    try {
      await _api.post('/notifications/$notificationId/read');
      print('✅ [NOTIFICATION_SERVICE] Notification marquée comme lue');
    } catch (e) {
      print('💥 [NOTIFICATION_SERVICE] Erreur: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    print('🔔 [NOTIFICATION_SERVICE] Marquage de toutes les notifications comme lues');

    try {
      await _api.post('/notifications/read-all');
      print('✅ [NOTIFICATION_SERVICE] Toutes les notifications marquées comme lues');
    } catch (e) {
      print('💥 [NOTIFICATION_SERVICE] Erreur: $e');
      rethrow;
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    print('🔔 [NOTIFICATION_SERVICE] Suppression de la notification $notificationId');

    try {
      await _api.delete('/notifications/$notificationId');
      print('✅ [NOTIFICATION_SERVICE] Notification supprimée');
    } catch (e) {
      print('💥 [NOTIFICATION_SERVICE] Erreur: $e');
      rethrow;
    }
  }

  /// Delete all notifications
  Future<void> deleteAllNotifications() async {
    print('🔔 [NOTIFICATION_SERVICE] Suppression de toutes les notifications');

    try {
      await _api.delete('/notifications/delete-all');
      print('✅ [NOTIFICATION_SERVICE] Toutes les notifications supprimées');
    } catch (e) {
      print('💥 [NOTIFICATION_SERVICE] Erreur: $e');
      rethrow;
    }
  }

  /// Get unread notifications count
  Future<int> getUnreadCount() async {
    print('🔔 [NOTIFICATION_SERVICE] Récupération du nombre de notifications non lues');

    try {
      final response = await _api.get('/notifications/unread-count');
      final count = response.data['unread_count'] as int;
      print('✅ [NOTIFICATION_SERVICE] $count notifications non lues');
      return count;
    } catch (e) {
      print('💥 [NOTIFICATION_SERVICE] Erreur: $e');
      rethrow;
    }
  }
}
