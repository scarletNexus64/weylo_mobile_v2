import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:weylo/app/widgets/animated_border_card.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';
import 'package:weylo/app/widgets/message_shimmer_loading.dart';
import 'package:weylo/app/widgets/empty_message_state.dart';
import 'package:weylo/app/widgets/animated_share_button.dart';
import 'package:flutter/services.dart';

import '../controllers/anonymepage_controller.dart';

class AnonymepageView extends GetView<AnonymepageController> {
  const AnonymepageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Show shimmer while loading
      if (controller.isLoading.value) {
        return _buildLoadingState(context);
      }

      // Show error state if error occurred
      if (controller.hasError.value) {
        return _buildErrorState(context);
      }

      // Build main content
      return RefreshIndicator(
        onRefresh: controller.refreshMessages,
        color: AppThemeSystem.primaryColor,
        child: SingleChildScrollView(
          controller: controller.hasMessages ? controller.scrollController : null,
          padding: EdgeInsets.all(context.horizontalPadding),
          physics: controller.hasMessages
              ? const AlwaysScrollableScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: context.elementSpacing),

              // My Anonymous Link Card
              _buildLinkCard(context),

              SizedBox(height: context.sectionSpacing),

              // Messages received header - only show if there are messages
              if (controller.hasMessages) ...[
                _buildMessagesHeader(context),
                SizedBox(height: context.elementSpacing),
              ],

              // Messages list or empty state
              controller.hasMessages
                  ? _buildMessagesList(context)
                  : const EmptyMessageState(),

              // Loading more indicator
              if (controller.isLoadingMore.value)
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: context.elementSpacing,
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppThemeSystem.primaryColor,
                    ),
                  ),
                ),

              SizedBox(height: context.sectionSpacing),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLoadingState(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.horizontalPadding),
      child: Column(
        children: [
          SizedBox(height: context.elementSpacing),
          const LinkCardShimmerLoading(),
          SizedBox(height: context.sectionSpacing),
          const MessageShimmerLoading(itemCount: 3),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            SizedBox(height: context.elementSpacing),
            Text(
              'Une erreur est survenue',
              style: context.textStyle(FontSizeType.h3).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: context.elementSpacing / 2),
            Text(
              controller.errorMessage.value,
              style: context.textStyle(FontSizeType.body2).copyWith(
                color: AppThemeSystem.grey600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.sectionSpacing),
            ElevatedButton.icon(
              onPressed: controller.fetchMessages,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeSystem.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkCard(BuildContext context) {
    return Obx(() {
      final shareLink = controller.userShareLink.value;

      if (controller.isLoadingShareLink.value) {
        return const LinkCardShimmerLoading();
      }

      // Si pas de lien disponible, ne rien afficher
      if (shareLink == null) {
        return const SizedBox.shrink();
      }

      return AnimatedBorderCard(
        borderRadius: 20,
        borderWidth: 3,
        borderColor: AppThemeSystem.primaryColor,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppThemeSystem.darkCardColor
            : Colors.white,
        padding: EdgeInsets.all(context.elementSpacing * 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppThemeSystem.primaryColor.withValues(alpha: 0.2),
                        AppThemeSystem.secondaryColor.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.link_rounded,
                    color: AppThemeSystem.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mon lien anonyme',
                        style: context.textStyle(FontSizeType.h4).copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : AppThemeSystem.blackColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Partagez et recevez des messages',
                        style: context.textStyle(FontSizeType.caption).copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppThemeSystem.grey400
                              : AppThemeSystem.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: context.elementSpacing * 1.2),

            // Link display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppThemeSystem.grey800.withValues(alpha: 0.4)
                    : AppThemeSystem.grey100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppThemeSystem.grey700
                      : AppThemeSystem.grey300,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      shareLink.link,
                      style: context.textStyle(FontSizeType.body2).copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppThemeSystem.blackColor,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: shareLink.link));
                      Get.snackbar(
                        'Copié !',
                        'Lien copié dans le presse-papiers',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppThemeSystem.successColor,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 2),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppThemeSystem.primaryColor.withValues(alpha: 0.15),
                            AppThemeSystem.secondaryColor.withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.copy_rounded,
                        color: AppThemeSystem.primaryColor,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: context.elementSpacing * 1.2),

            // Animated Share button
            AnimatedShareButton(
              onPressed: () async {
                await SharePlus.instance.share(
                  ShareParams(
                    text: '${shareLink.shareText} ${shareLink.link}',
                  ),
                );
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMessagesHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.mail_rounded,
          color: AppThemeSystem.primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'Messages reçus',
          style: context.textStyle(FontSizeType.h3).copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : AppThemeSystem.blackColor,
          ),
        ),
        const Spacer(),
        Obx(() {
          if (controller.unreadCount.value > 0) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppThemeSystem.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${controller.unreadCount.value} nouveau${controller.unreadCount.value > 1 ? 'x' : ''}',
                style: context.textStyle(FontSizeType.caption).copyWith(
                  color: AppThemeSystem.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildMessagesList(BuildContext context) {
    return Obx(() {
      return Column(
        children: controller.messages
            .map((message) => _buildAnonymousMessageCard(context, message))
            .toList(),
      );
    });
  }

  Widget _buildAnonymousMessageCard(BuildContext context, message) {
    final isNew = !message.isRead;

    return Container(
      margin: EdgeInsets.only(bottom: context.elementSpacing),
      padding: EdgeInsets.all(context.elementSpacing),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppThemeSystem.darkCardColor
            : Colors.white,
        borderRadius: context.borderRadius(BorderRadiusType.medium),
        border: isNew
            ? Border.all(
                color: AppThemeSystem.tertiaryColor.withValues(alpha: 0.3),
                width: 2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppThemeSystem.tertiaryColor.withValues(alpha: 0.2),
                      AppThemeSystem.secondaryColor.withValues(alpha: 0.2),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  message.senderInitial,
                  style: context.textStyle(FontSizeType.h4).copyWith(
                    color: AppThemeSystem.tertiaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          message.isIdentityRevealed
                              ? message.sender?.fullName ?? 'Message anonyme'
                              : 'Message anonyme',
                          style: context.textStyle(FontSizeType.body1).copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : AppThemeSystem.blackColor,
                          ),
                        ),
                        if (isNew) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppThemeSystem.primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'NOUVEAU',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message.timeAgo,
                      style: context.textStyle(FontSizeType.caption).copyWith(
                        color: AppThemeSystem.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: Icon(
                  Icons.more_vert,
                  color: AppThemeSystem.grey600,
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20),
                        SizedBox(width: 8),
                        Text('Supprimer'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.report_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Signaler'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteConfirmation(context, message.id);
                  } else if (value == 'report') {
                    Get.snackbar(
                      'Signaler',
                      'Fonctionnalité de signalement à venir',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
              ),
            ],
          ),

          SizedBox(height: context.elementSpacing),

          // Message content
          Container(
            padding: EdgeInsets.all(context.elementSpacing),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppThemeSystem.darkBackgroundColor
                  : AppThemeSystem.grey100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.content,
              style: context.textStyle(FontSizeType.body2).copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppThemeSystem.blackColor,
                height: 1.5,
              ),
            ),
          ),

          SizedBox(height: context.elementSpacing),

          // Reply button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Get.snackbar(
                  'Répondre',
                  'Fonctionnalité de réponse à venir',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              icon: const Icon(Icons.reply_rounded, size: 20),
              label: Text(
                'Répondre anonymement',
                style: context.textStyle(FontSizeType.button).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppThemeSystem.primaryColor,
                side: BorderSide(
                  color: AppThemeSystem.primaryColor,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, int messageId) {
    Get.defaultDialog(
      title: 'Supprimer le message',
      middleText: 'Êtes-vous sûr de vouloir supprimer ce message ?',
      textConfirm: 'Supprimer',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        controller.deleteMessage(messageId);
        Get.back();
      },
    );
  }
}
