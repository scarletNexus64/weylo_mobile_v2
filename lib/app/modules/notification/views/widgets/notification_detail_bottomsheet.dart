import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:weylo/app/widgets/app_theme_system.dart';
import 'package:weylo/app/data/models/notification_model.dart';

class NotificationDetailBottomSheet extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailBottomSheet({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: context.verticalPadding),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppThemeSystem.grey400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(context.horizontalPadding * 1.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon and Title
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _getNotificationColor(notification.type).withValues(alpha: 0.1),
                        borderRadius: context.borderRadius(BorderRadiusType.medium),
                      ),
                      child: Center(
                        child: Text(
                          notification.getIcon(),
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    SizedBox(width: context.elementSpacing),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: context.h6.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: context.elementSpacing * 0.3),
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

                SizedBox(height: context.sectionSpacing),

                // Body
                Text(
                  notification.body,
                  style: context.body1.copyWith(
                    color: isDark ? AppThemeSystem.grey300 : AppThemeSystem.grey700,
                    height: 1.5,
                  ),
                ),

                // Additional data if available
                if (notification.data != null && notification.data!.isNotEmpty) ...[
                  SizedBox(height: context.sectionSpacing),
                  Container(
                    padding: EdgeInsets.all(context.elementSpacing),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppThemeSystem.grey800.withValues(alpha: 0.5)
                          : AppThemeSystem.grey100,
                      borderRadius: context.borderRadius(BorderRadiusType.medium),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Détails',
                          style: context.body2.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: context.elementSpacing * 0.5),
                        ...notification.data!.entries.map((entry) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: context.elementSpacing * 0.3),
                            child: Row(
                              children: [
                                Text(
                                  '${entry.key}: ',
                                  style: context.caption.copyWith(
                                    color: AppThemeSystem.grey500,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${entry.value}',
                                    style: context.caption.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: context.sectionSpacing),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      _handleNotificationAction(notification);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeSystem.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: context.verticalPadding,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: context.borderRadius(BorderRadiusType.medium),
                      ),
                    ),
                    child: Text(
                      _getActionButtonText(notification.type),
                      style: context.button,
                    ),
                  ),
                ),

                SizedBox(height: context.elementSpacing * 0.5),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Get.back(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: context.verticalPadding,
                      ),
                    ),
                    child: Text(
                      'Fermer',
                      style: context.button.copyWith(
                        color: AppThemeSystem.grey600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  String _getActionButtonText(String type) {
    switch (type) {
      case 'message':
      case 'new_chat_message':
      case 'new_message':
        return 'Ouvrir la conversation';
      case 'gift':
      case 'gift_received':
        return 'Voir le cadeau';
      case 'gift_sent':
        return 'Voir les détails';
      case 'follow':
      case 'new_follower':
        return 'Voir le profil';
      case 'wallet':
      case 'wallet_credit':
      case 'wallet_debit':
        return 'Voir le portefeuille';
      default:
        return 'Voir les détails';
    }
  }

  void _handleNotificationAction(NotificationModel notification) {
    final data = notification.data;
    if (data == null) return;

    switch (notification.type) {
      case 'message':
      case 'new_chat_message':
      case 'new_message':
        if (data['conversation_id'] != null) {
          Get.toNamed('/chat-detail', arguments: {
            'conversationId': data['conversation_id'],
          });
        }
        break;

      case 'gift':
      case 'gift_received':
      case 'gift_sent':
        // Navigate to gift or wallet page
        Get.toNamed('/wallet');
        break;

      case 'follow':
      case 'new_follower':
        if (data['user_id'] != null) {
          Get.toNamed('/profile', arguments: {
            'userId': data['user_id'],
          });
        }
        break;

      case 'wallet':
      case 'wallet_credit':
      case 'wallet_debit':
        Get.toNamed('/wallet');
        break;

      default:
        print('⚠️ No action defined for notification type: ${notification.type}');
    }
  }
}
