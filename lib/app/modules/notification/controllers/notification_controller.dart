import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/data/services/notification_service.dart';
import 'package:weylo/app/data/models/notification_model.dart';
import 'package:weylo/app/modules/home/controllers/home_controller.dart';
import '../views/widgets/notification_detail_bottomsheet.dart';

class NotificationController extends GetxController {
  final _notificationService = NotificationService();

  // Observable lists
  final notifications = <NotificationModel>[].obs;

  // Loading states
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final isRefreshing = false.obs;

  // Pagination
  final currentPage = 1.obs;
  final lastPage = 1.obs;
  final hasMore = true.obs;

  // Unread count
  final unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    print('🔔 [NOTIFICATION_CONTROLLER] Initialisation');
    loadNotifications();
    loadUnreadCount();
  }

  /// Load notifications (first page)
  Future<void> loadNotifications() async {
    print('🔔 [NOTIFICATION_CONTROLLER] Chargement des notifications');

    try {
      isLoading.value = true;
      currentPage.value = 1;

      final response = await _notificationService.getNotifications(
        page: currentPage.value,
      );

      notifications.value = response.notifications;
      lastPage.value = response.lastPage;
      hasMore.value = currentPage.value < lastPage.value;

      print('✅ [NOTIFICATION_CONTROLLER] ${notifications.length} notifications chargées');
    } catch (e) {
      print('💥 [NOTIFICATION_CONTROLLER] Erreur: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger les notifications',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh notifications
  Future<void> refreshNotifications() async {
    print('🔔 [NOTIFICATION_CONTROLLER] Rafraîchissement des notifications');

    try {
      isRefreshing.value = true;
      currentPage.value = 1;

      final response = await _notificationService.getNotifications(
        page: currentPage.value,
      );

      notifications.value = response.notifications;
      lastPage.value = response.lastPage;
      hasMore.value = currentPage.value < lastPage.value;

      // Also refresh unread count
      await loadUnreadCount();

      print('✅ [NOTIFICATION_CONTROLLER] Notifications rafraîchies');
    } catch (e) {
      print('💥 [NOTIFICATION_CONTROLLER] Erreur: $e');
    } finally {
      isRefreshing.value = false;
    }
  }

  /// Load more notifications (pagination)
  Future<void> loadMoreNotifications() async {
    if (!hasMore.value || isLoadingMore.value) return;

    print('🔔 [NOTIFICATION_CONTROLLER] Chargement de plus de notifications');

    try {
      isLoadingMore.value = true;
      currentPage.value++;

      final response = await _notificationService.getNotifications(
        page: currentPage.value,
      );

      notifications.addAll(response.notifications);
      lastPage.value = response.lastPage;
      hasMore.value = currentPage.value < lastPage.value;

      print('✅ [NOTIFICATION_CONTROLLER] ${response.notifications.length} notifications ajoutées');
    } catch (e) {
      print('💥 [NOTIFICATION_CONTROLLER] Erreur: $e');
      currentPage.value--; // Revert page increment on error
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Load unread count
  Future<void> loadUnreadCount() async {
    print('🔔 [NOTIFICATION_CONTROLLER] Chargement du compteur de notifications non lues');

    try {
      unreadCount.value = await _notificationService.getUnreadCount();
      print('✅ [NOTIFICATION_CONTROLLER] ${unreadCount.value} notifications non lues');
    } catch (e) {
      print('💥 [NOTIFICATION_CONTROLLER] Erreur: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    print('🔔 [NOTIFICATION_CONTROLLER] Marquage de la notification ${notification.id} comme lue');

    try {
      await _notificationService.markAsRead(notification.id);

      // Update local state
      final index = notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        notifications[index] = NotificationModel(
          id: notification.id,
          type: notification.type,
          title: notification.title,
          body: notification.body,
          data: notification.data,
          isRead: true,
          readAt: DateTime.now().toIso8601String(),
          createdAt: notification.createdAt,
        );
        notifications.refresh();
      }

      // Update unread count
      if (unreadCount.value > 0) {
        unreadCount.value--;
      }

      // Update home controller badge
      _updateHomeBadge();

      print('✅ [NOTIFICATION_CONTROLLER] Notification marquée comme lue');
    } catch (e) {
      print('💥 [NOTIFICATION_CONTROLLER] Erreur: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de marquer la notification comme lue',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    print('🔔 [NOTIFICATION_CONTROLLER] Marquage de toutes les notifications comme lues');

    try {
      await _notificationService.markAllAsRead();

      // Update local state
      notifications.value = notifications.map((notification) {
        return NotificationModel(
          id: notification.id,
          type: notification.type,
          title: notification.title,
          body: notification.body,
          data: notification.data,
          isRead: true,
          readAt: DateTime.now().toIso8601String(),
          createdAt: notification.createdAt,
        );
      }).toList();

      // Update unread count
      unreadCount.value = 0;

      // Update home controller badge
      _updateHomeBadge();

      Get.snackbar(
        'Succès',
        'Toutes les notifications ont été marquées comme lues',
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      print('✅ [NOTIFICATION_CONTROLLER] Toutes les notifications marquées comme lues');
    } catch (e) {
      print('💥 [NOTIFICATION_CONTROLLER] Erreur: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de marquer toutes les notifications comme lues',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Delete notification
  Future<void> deleteNotification(NotificationModel notification) async {
    print('🔔 [NOTIFICATION_CONTROLLER] Suppression de la notification ${notification.id}');

    try {
      await _notificationService.deleteNotification(notification.id);

      // Update local state
      notifications.removeWhere((n) => n.id == notification.id);

      // Update unread count if notification was unread
      if (!notification.isRead && unreadCount.value > 0) {
        unreadCount.value--;
      }

      // Update home controller badge
      _updateHomeBadge();

      Get.snackbar(
        'Succès',
        'Notification supprimée',
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      print('✅ [NOTIFICATION_CONTROLLER] Notification supprimée');
    } catch (e) {
      print('💥 [NOTIFICATION_CONTROLLER] Erreur: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer la notification',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Delete all notifications
  Future<void> deleteAllNotifications() async {
    print('🔔 [NOTIFICATION_CONTROLLER] Suppression de toutes les notifications');

    try {
      await _notificationService.deleteAllNotifications();

      // Update local state
      notifications.clear();
      unreadCount.value = 0;

      // Update home controller badge
      _updateHomeBadge();

      Get.snackbar(
        'Succès',
        'Toutes les notifications ont été supprimées',
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      print('✅ [NOTIFICATION_CONTROLLER] Toutes les notifications supprimées');
    } catch (e) {
      print('💥 [NOTIFICATION_CONTROLLER] Erreur: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer toutes les notifications',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Handle notification tap (open bottomsheet with details)
  void onNotificationTap(NotificationModel notification) {
    // Mark as read
    markAsRead(notification);

    // Update home controller badge
    _updateHomeBadge();

    // Show notification detail in bottomsheet
    _showNotificationDetailBottomSheet(notification);
  }

  /// Show notification detail bottomsheet
  void _showNotificationDetailBottomSheet(NotificationModel notification) {
    Get.bottomSheet(
      NotificationDetailBottomSheet(notification: notification),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
    );
  }

  /// Update home controller badge count
  void _updateHomeBadge() {
    // Try to find HomeController and update its badge
    try {
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        homeController.notificationsUnreadCount.value = unreadCount.value;
        print('✅ [NOTIFICATION_CONTROLLER] Home badge updated to ${unreadCount.value}');
      }
    } catch (e) {
      print('⚠️ [NOTIFICATION_CONTROLLER] Could not update home badge: $e');
    }
  }
}
