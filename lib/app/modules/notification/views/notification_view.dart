import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:weylo/app/widgets/app_theme_system.dart';
import 'package:weylo/app/data/models/notification_model.dart';
import '../controllers/notification_controller.dart';

class NotificationView extends GetView<NotificationController> {
  const NotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppThemeSystem.darkBackgroundColor : AppThemeSystem.backgroundColor,
      appBar: _buildAppBar(context, isDark),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return _buildLoadingState(context);
        }

        if (controller.notifications.isEmpty) {
          return _buildEmptyState(context, isDark);
        }

        return _buildNotificationsList(context, isDark);
      }),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor: isDark ? AppThemeSystem.darkCardColor : Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: Icon(
          Icons.arrow_back_ios,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      title: Obx(() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Notifications',
            style: context.h5.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (controller.unreadCount.value > 0) ...[
            SizedBox(width: context.elementSpacing * 0.5),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.elementSpacing * 0.6,
                vertical: context.elementSpacing * 0.3,
              ),
              decoration: BoxDecoration(
                color: AppThemeSystem.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${controller.unreadCount.value}',
                style: context.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      )),
      actions: [
        Obx(() {
          if (controller.notifications.isEmpty) {
            return const SizedBox.shrink();
          }

          return PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: isDark ? Colors.white : Colors.black,
            ),
            tooltip: 'Plus d\'options',
            onSelected: (value) async {
              if (value == 'mark_all_read') {
                controller.markAllAsRead();
              } else if (value == 'delete_all') {
                // Show confirmation dialog
                final confirmed = await Get.dialog<bool>(
                  AlertDialog(
                    title: const Text('Supprimer tout'),
                    content: const Text(
                      'Voulez-vous vraiment supprimer toutes les notifications ?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(result: false),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () => Get.back(result: true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Supprimer tout'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  controller.deleteAllNotifications();
                }
              }
            },
            itemBuilder: (context) => [
              if (controller.unreadCount.value > 0)
                const PopupMenuItem<String>(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, size: 20),
                      SizedBox(width: 12),
                      Text('Tout marquer comme lu'),
                    ],
                  ),
                ),
              const PopupMenuItem<String>(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text(
                      'Supprimer tout',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppThemeSystem.primaryColor,
          ),
          SizedBox(height: context.elementSpacing),
          Text(
            'Chargement...',
            style: context.body2.copyWith(
              color: AppThemeSystem.grey500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppThemeSystem.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              size: 60,
              color: AppThemeSystem.primaryColor,
            ),
          ),
          SizedBox(height: context.sectionSpacing),
          Text(
            'Aucune notification',
            style: context.h5.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: context.elementSpacing * 0.5),
          Text(
            'Vous n\'avez pas encore de notifications',
            style: context.body2.copyWith(
              color: AppThemeSystem.grey500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(BuildContext context, bool isDark) {
    return RefreshIndicator(
      onRefresh: controller.refreshNotifications,
      color: AppThemeSystem.primaryColor,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (!controller.isLoadingMore.value &&
              controller.hasMore.value &&
              scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
            controller.loadMoreNotifications();
          }
          return false;
        },
        child: ListView.separated(
          padding: EdgeInsets.symmetric(
            vertical: context.verticalPadding,
          ),
          itemCount: controller.notifications.length + (controller.hasMore.value ? 1 : 0),
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
          ),
          itemBuilder: (context, index) {
            if (index == controller.notifications.length) {
              return _buildLoadingMoreIndicator(context);
            }

            final notification = controller.notifications[index];
            return _buildNotificationItem(context, isDark, notification);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.verticalPadding),
      child: Center(
        child: CircularProgressIndicator(
          color: AppThemeSystem.primaryColor,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    bool isDark,
    NotificationModel notification,
  ) {
    return Dismissible(
      key: Key('notification_${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: context.horizontalPadding),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Supprimer'),
            content: const Text('Voulez-vous vraiment supprimer cette notification ?'),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (direction) {
        controller.deleteNotification(notification);
      },
      child: InkWell(
        onTap: () => controller.onNotificationTap(notification),
        child: Container(
          color: !notification.isRead
              ? (isDark
                  ? AppThemeSystem.primaryColor.withValues(alpha: 0.05)
                  : AppThemeSystem.primaryColor.withValues(alpha: 0.02))
              : Colors.transparent,
          padding: EdgeInsets.symmetric(
            horizontal: context.horizontalPadding * 1.5,
            vertical: context.verticalPadding,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: context.isTabletOrLarger ? 56 : 48,
                height: context.isTabletOrLarger ? 56 : 48,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type).withValues(alpha: 0.1),
                  borderRadius: context.borderRadius(BorderRadiusType.medium),
                ),
                child: Center(
                  child: Text(
                    notification.getIcon(),
                    style: TextStyle(
                      fontSize: context.isTabletOrLarger ? 28 : 24,
                    ),
                  ),
                ),
              ),
              SizedBox(width: context.elementSpacing),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: context.body1.copyWith(
                              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppThemeSystem.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: context.elementSpacing * 0.3),
                    Text(
                      notification.body,
                      style: context.body2.copyWith(
                        color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: context.elementSpacing * 0.5),
                    Text(
                      timeago.format(
                        DateTime.parse(notification.createdAt),
                        locale: 'fr',
                      ),
                      style: context.caption.copyWith(
                        color: AppThemeSystem.grey500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'message':
      case 'new_chat_message':
      case 'new_message':
        return AppThemeSystem.primaryColor;
      case 'gift':
      case 'gift_received':
      case 'gift_sent':
        return AppThemeSystem.accentColor;
      case 'like':
        return Colors.pink;
      case 'follow':
      case 'new_follower':
        return AppThemeSystem.secondaryColor;
      case 'premium':
      case 'premium_upgrade':
        return AppThemeSystem.tertiaryColor;
      case 'wallet':
      case 'wallet_credit':
      case 'wallet_debit':
        return Colors.green;
      default:
        return AppThemeSystem.primaryColor;
    }
  }
}
