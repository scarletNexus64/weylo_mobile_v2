import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:weylo/app/widgets/app_theme_system.dart';
import 'package:weylo/app/data/models/notification_model.dart';
import 'package:weylo/app/modules/profile/controllers/profile_controller.dart';
import 'package:weylo/app/modules/home/controllers/home_controller.dart';

class NotificationDetailBottomSheet extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailBottomSheet({super.key, required this.notification});

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
                        color: _getNotificationColor(
                          notification.type,
                        ).withValues(alpha: 0.1),
                        borderRadius: context.borderRadius(
                          BorderRadiusType.medium,
                        ),
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
                    color: isDark
                        ? AppThemeSystem.grey300
                        : AppThemeSystem.grey700,
                    height: 1.5,
                  ),
                ),

                SizedBox(height: context.sectionSpacing),

                // Action button (if applicable)
                if (_shouldShowActionButton(notification.type)) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back(); // Close bottomsheet
                        _handleNotificationAction(notification);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getNotificationColor(
                          notification.type,
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: context.verticalPadding,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _getActionButtonText(notification.type),
                        style: context.button.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: context.elementSpacing),
                ],

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
                SizedBox(height: context.elementSpacing * 2.5),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowActionButton(String type) {
    // Afficher le bouton d'action pour tous les types avec une action définie
    const typesWithActions = [
      // Messages
      'message',
      'new_message',
      'new_chat_message',
      // Confessions
      'new_confession',
      'confession_comment',
      'new_public_confession',
      // Cadeaux
      'gift',
      'gift_received',
      'gift_sent',
      // Wallet
      'wallet',
      'wallet_credit',
      'wallet_debit',
      'withdrawal_processed',
      'withdrawal_rejected',
      'withdrawal_failed',
      'deposit_completed',
      'deposit_failed',
      // Followers
      'follow',
      'new_follower',
      // Stories
      'story_reply',
      'story_like',
      'new_story',
      // Profil
      'profile_view',
      // Abonnement
      'subscription_expiring',
      // Bienvenue
      'welcome',
    ];
    return typesWithActions.contains(type);
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      // Messages
      case 'message':
      case 'new_chat_message':
      case 'new_message':
        return AppThemeSystem.primaryColor;

      // Confessions
      case 'new_confession':
      case 'confession_comment':
      case 'new_public_confession':
        return Colors.purple;

      // Cadeaux
      case 'gift':
      case 'gift_received':
      case 'gift_sent':
        return AppThemeSystem.accentColor;

      // Wallet
      case 'wallet':
      case 'wallet_credit':
      case 'wallet_debit':
      case 'deposit_completed':
        return Colors.green;
      case 'withdrawal_processed':
      case 'withdrawal_rejected':
      case 'withdrawal_failed':
      case 'deposit_failed':
        return Colors.orange;

      // Likes
      case 'like':
      case 'story_like':
        return Colors.pink;

      // Followers
      case 'follow':
      case 'new_follower':
        return AppThemeSystem.secondaryColor;

      // Stories
      case 'story_reply':
      case 'new_story':
        return Colors.deepPurple;

      // Premium/Abonnement
      case 'premium':
      case 'premium_upgrade':
      case 'subscription_expiring':
        return AppThemeSystem.tertiaryColor;

      // Profil
      case 'profile_view':
        return AppThemeSystem.primaryColor;

      // Bienvenue
      case 'welcome':
        return Colors.blue;

      default:
        return AppThemeSystem.primaryColor;
    }
  }

  String _getActionButtonText(String type) {
    switch (type) {
      // Messages
      case 'new_message':
        return 'Voir le message';
      case 'message':
      case 'new_chat_message':
        return 'Ouvrir la conversation';

      // Confessions
      case 'new_confession':
      case 'confession_comment':
      case 'new_public_confession':
        return 'Voir la confession';

      // Cadeaux
      case 'gift':
      case 'gift_received':
        return 'Voir le cadeau';
      case 'gift_sent':
        return 'Voir les détails';

      // Wallet
      case 'wallet':
      case 'wallet_credit':
      case 'wallet_debit':
      case 'withdrawal_processed':
      case 'withdrawal_rejected':
      case 'withdrawal_failed':
      case 'deposit_completed':
      case 'deposit_failed':
        return 'Voir le portefeuille';

      // Followers
      case 'follow':
      case 'new_follower':
        return 'Voir le profil';

      // Stories
      case 'story_reply':
        return 'Voir la réponse';
      case 'story_like':
        return 'Voir ma story';
      case 'new_story':
        return 'Voir les stories';

      // Profil
      case 'profile_view':
        return 'Voir mes visiteurs';

      // Abonnement
      case 'subscription_expiring':
        return 'Gérer mon abonnement';

      // Bienvenue
      case 'welcome':
        return 'Explorer l\'app';

      default:
        return 'Voir les détails';
    }
  }

  void _handleNotificationAction(NotificationModel notification) {
    final data = notification.data;

    switch (notification.type) {
      // ========== MESSAGES ==========
      case 'new_message':
        // Message anonyme - naviguer vers l'onglet des messages
        Get.offAllNamed('/home');
        Future.delayed(const Duration(milliseconds: 500), () {
          try {
            final homeController = Get.find<HomeController>();
            homeController.tabController.animateTo(2); // Messages tab index
          } catch (e) {
            print('❌ [NOTIFICATION] Erreur navigation messages: $e');
          }
        });
        break;

      case 'message':
      case 'new_chat_message':
      case 'story_reply':
        // Messages de chat - ouvrir la conversation
        if (data != null && data['conversation_id'] != null) {
          Get.toNamed(
            '/chat-detail',
            arguments: {'conversationId': data['conversation_id']},
          );
        }
        break;

      // ========== CONFESSIONS ==========
      case 'new_confession':
      case 'confession_comment':
      case 'new_public_confession':
        // Naviguer vers la confession
        if (data != null && data['confession_id'] != null) {
          Get.toNamed('/confession/${data['confession_id']}');
        } else {
          // Si pas d'ID, aller aux feeds
          Get.offAllNamed('/home');
          Future.delayed(const Duration(milliseconds: 500), () {
            try {
              final homeController = Get.find<HomeController>();
              homeController.tabController.animateTo(0); // Feeds tab index
            } catch (e) {
              print('❌ [NOTIFICATION] Erreur navigation feeds: $e');
            }
          });
        }
        break;

      // ========== CADEAUX ==========
      case 'gift':
      case 'gift_received':
      case 'gift_sent':
        Get.toNamed('/my-wallet');
        break;

      // ========== WALLET ==========
      case 'wallet':
      case 'wallet_credit':
      case 'wallet_debit':
      case 'withdrawal_processed':
      case 'withdrawal_rejected':
      case 'withdrawal_failed':
      case 'deposit_completed':
      case 'deposit_failed':
        Get.toNamed('/my-wallet');
        break;

      // ========== FOLLOWERS ==========
      case 'follow':
      case 'new_follower':
        if (data != null && data['user_id'] != null) {
          Get.toNamed('/user-profile', arguments: {'userId': data['user_id']});
        }
        break;

      // ========== STORIES ==========
      case 'story_like':
        // Aller à l'onglet stories
        Get.offAllNamed('/home');
        Future.delayed(const Duration(milliseconds: 500), () {
          try {
            final homeController = Get.find<HomeController>();
            homeController.tabController.animateTo(3); // Stories tab index
          } catch (e) {
            print('❌ [NOTIFICATION] Erreur navigation stories: $e');
          }
        });
        break;

      case 'new_story':
        // Voir les stories - naviguer vers l'utilisateur si ID fourni
        if (data != null && data['user_id'] != null) {
          Get.toNamed('/user-profile', arguments: {'userId': data['user_id']});
        } else {
          // Sinon aller à l'onglet stories
          Get.offAllNamed('/home');
          Future.delayed(const Duration(milliseconds: 500), () {
            try {
              final homeController = Get.find<HomeController>();
              homeController.tabController.animateTo(3); // Stories tab index
            } catch (e) {
              print('❌ [NOTIFICATION] Erreur navigation stories: $e');
            }
          });
        }
        break;

      // ========== PROFIL ==========
      case 'profile_view':
        print('🧭 [NOTIFICATION] Navigation vers les visiteurs du profil...');
        Get.offAllNamed('/home');
        Future.delayed(const Duration(milliseconds: 1000), () {
          try {
            print('🧭 [NOTIFICATION] Changement vers l\'onglet profil...');
            final homeController = Get.find<HomeController>();
            homeController.tabController.animateTo(4); // Profile tab index

            print(
              '🧭 [NOTIFICATION] Ouverture du bottomsheet des visiteurs...',
            );
            final profileController = Get.find<ProfileController>();

            profileController.loadProfileVisitors().then((_) {
              print(
                '🧭 [NOTIFICATION] Visiteurs rechargés, ouverture du bottomsheet...',
              );
              profileController.showProfileVisitors();
            });
          } catch (e) {
            print('❌ [NOTIFICATION] Erreur affichage visiteurs: $e');
          }
        });
        break;

      // ========== ABONNEMENT ==========
      case 'subscription_expiring':
        // Naviguer vers les paramètres ou page premium
        Get.toNamed('/seeting');
        break;

      // ========== BIENVENUE ==========
      case 'welcome':
        // Retourner à l'accueil
        Get.offAllNamed('/home');
        break;

      default:
        print(
          '⚠️ No action defined for notification type: ${notification.type}',
        );
    }
  }
}
