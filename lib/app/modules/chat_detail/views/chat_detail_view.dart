import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';
import 'package:weylo/app/widgets/verified_badge.dart';
import 'package:weylo/app/data/models/chat_message_model.dart';
import '../controllers/chat_detail_controller.dart';
import 'widgets/chat_image_picker_bottom_sheet.dart';
import '../../feeds/controllers/story_controller.dart';
import '../../feeds/views/story_viewer.dart';

class ChatDetailView extends GetView<ChatDetailController> {
  const ChatDetailView({super.key});

  /// Construit l'aperçu de la story selon son type
  Widget _buildStoryPreview(StoryReplyInfo story) {
    const double previewSize = 36;

    switch (story.type) {
      case 'image':
        // Afficher l'image de la story
        if (story.mediaUrl != null && story.mediaUrl!.isNotEmpty) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              story.mediaUrl!,
              width: previewSize,
              height: previewSize,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: previewSize,
                  height: previewSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.image, size: 16, color: Color(0xFF667eea)),
                );
              },
            ),
          );
        }
        break;

      case 'video':
        // Afficher le thumbnail de la vidéo
        if (story.thumbnailUrl != null && story.thumbnailUrl!.isNotEmpty) {
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  story.thumbnailUrl!,
                  width: previewSize,
                  height: previewSize,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: previewSize,
                      height: previewSize,
                      decoration: BoxDecoration(
                        color: const Color(0xFF667eea).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.videocam, size: 16, color: Color(0xFF667eea)),
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.black.withValues(alpha: 0.3),
                  ),
                  child: const Center(
                    child: Icon(Icons.play_arrow, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        }
        break;

      case 'text':
        // Afficher un aperçu coloré pour les stories texte
        return Container(
          width: previewSize,
          height: previewSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _getGradientColors(story.backgroundColor ?? '#6366f1'),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Center(
            child: Icon(Icons.text_fields, size: 16, color: Colors.white),
          ),
        );
    }

    // Fallback : icône story par défaut
    return Container(
      width: previewSize,
      height: previewSize,
      decoration: BoxDecoration(
        color: const Color(0xFF667eea).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.auto_stories, size: 16, color: Color(0xFF667eea)),
    );
  }

  /// Parse une couleur hexadécimale et crée un gradient
  List<Color> _getGradientColors(String hexColor) {
    final color = _parseHexColor(hexColor);
    return [
      color,
      color.withValues(alpha: 0.7),
    ];
  }

  /// Parse une couleur hexadécimale
  Color _parseHexColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    print('🎨 [ChatDetailView] Building view - isDark: $isDark');

    return Scaffold(
      backgroundColor: isDark
          ? AppThemeSystem.darkBackgroundColor
          : Colors.white,
      appBar: AppBar(
        title: Obx(() => Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppThemeSystem.primaryColor,
              child: Text(
                controller.displayInitial,
                style: const TextStyle(
                  color: Colors.white,
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
                      Flexible(
                        child: Text(
                          controller.displayName,
                          style: context.textStyle(FontSizeType.body1).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (controller.shouldShowBadge) ...[
                        const SizedBox(width: 4),
                        const VerifiedBadge(size: 14),
                      ],
                    ],
                  ),
                  Text(
                    'En ligne',
                    style: context.textStyle(FontSizeType.caption).copyWith(
                      color: AppThemeSystem.successColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        )),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          print('🏗️ [ChatDetailView] Building body Stack');
          return Stack(
            children: [
              // Background simple et fiable
              _buildSimpleBackground(context),

              // Main content
              Column(
                children: [
              // NOUVEAU: Typing indicator
              Obx(() {
                if (controller.showTypingIndicator.value) {
                  return Container(
                    padding: EdgeInsets.all(context.elementSpacing),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppThemeSystem.primaryColor,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'en train d\'écrire...',
                          style: context.textStyle(FontSizeType.caption).copyWith(
                            color: AppThemeSystem.primaryColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              // Messages list
              Expanded(
                child: Obx(() {
                  print('📱 [ListView] Building message list - ${controller.messages.length} messages');
                  return ListView.builder(
                    controller: controller.scrollController,
                    padding: EdgeInsets.all(context.elementSpacing),
                    itemCount: controller.messages.length,
                    itemBuilder: (context, index) {
                      final message = controller.messages[index];
                      return _buildMessageBubble(context, message, isDark);
                    },
                  );
                }),
              ),

              // Gift picker (if visible)
              Obx(() {
                if (controller.showGiftPicker.value) {
                  return _buildGiftPicker(context, isDark);
                }
                return const SizedBox.shrink();
              }),

              // Input area
              _buildInputArea(context, isDark),
                ],
              ),

              // Gift Animation Overlay
              Obx(() {
                print('🎁 [GiftAnimation] isAnimating=${controller.isAnimatingGift.value}, gift=${controller.animatedGift.value != null}');
                if (controller.isAnimatingGift.value && controller.animatedGift.value != null) {
                  print('🎬 [GiftAnimation] SHOWING animation overlay');
                  return _buildGiftAnimation(context);
                }
                print('✅ [GiftAnimation] NOT showing (normal background visible)');
                return const SizedBox.shrink();
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSimpleBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;

    print('🎨 [SimpleBackground] Building with ${screenSize.width}x${screenSize.height}');

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppThemeSystem.darkBackgroundColor,
                    AppThemeSystem.darkBackgroundColor.withValues(alpha: 0.95),
                    AppThemeSystem.darkCardColor.withValues(alpha: 0.8),
                  ]
                : [
                    Colors.white,
                    const Color(0xFFFAFAFA),
                    const Color(0xFFF5F5F5),
                  ],
          ),
        ),
        child: IgnorePointer(
          child: Stack(
            children: [
              // Quelques icônes fixes positionnées stratégiquement - opacity augmentée pour visibilité
              _buildFixedIcon('💬', 0.1, 0.15, 40, 0.25, isDark, screenSize),
              _buildFixedIcon('❤️', 0.85, 0.12, 35, 0.22, isDark, screenSize),
              _buildFixedIcon('⭐', 0.2, 0.35, 32, 0.28, isDark, screenSize),
              _buildFixedIcon('✨', 0.75, 0.28, 38, 0.24, isDark, screenSize),
              _buildFixedIcon('🎁', 0.15, 0.55, 42, 0.26, isDark, screenSize),
              _buildFixedIcon('😊', 0.9, 0.48, 36, 0.23, isDark, screenSize),
              _buildFixedIcon('💕', 0.3, 0.72, 40, 0.25, isDark, screenSize),
              _buildFixedIcon('🌹', 0.8, 0.68, 34, 0.27, isDark, screenSize),
              _buildFixedIcon('☕', 0.12, 0.85, 38, 0.24, isDark, screenSize),
              _buildFixedIcon('🎈', 0.7, 0.82, 36, 0.26, isDark, screenSize),
              _buildFixedIcon('💫', 0.45, 0.25, 32, 0.22, isDark, screenSize),
              _buildFixedIcon('🌟', 0.55, 0.6, 40, 0.25, isDark, screenSize),
              _buildFixedIcon('💐', 0.35, 0.42, 38, 0.23, isDark, screenSize),
              _buildFixedIcon('🎉', 0.65, 0.9, 35, 0.24, isDark, screenSize),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFixedIcon(
    String icon,
    double xPercent,
    double yPercent,
    double size,
    double opacity,
    bool isDark,
    Size screenSize,
  ) {
    return Positioned(
      left: screenSize.width * xPercent,
      top: screenSize.height * yPercent,
      child: Transform.rotate(
        angle: (xPercent * 6.28).clamp(-0.3, 0.3), // Légère rotation basée sur la position
        child: Text(
          icon,
          style: TextStyle(
            fontSize: size,
            color: isDark
                ? Colors.white.withValues(alpha: opacity)
                : Colors.black.withValues(alpha: opacity),
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessageModel message, bool isDark) {
    final isSentByMe = controller.isSentByMe(message);
    return Dismissible(
      key: ValueKey(message.id),
      direction: isSentByMe ? DismissDirection.endToStart : DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        // Ne pas vraiment supprimer lors du swipe, juste répondre
        controller.setReplyToMessage(message);
        return false; // Ne pas supprimer le message
      },
      background: Container(
        alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
        child: Icon(
          Icons.reply_rounded,
          color: AppThemeSystem.primaryColor,
          size: 24,
        ),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () {
          print('🔴 Long press detected on message ${message.id}, isSentByMe: $isSentByMe');
          if (isSentByMe) {
            _showMessageActions(context, message);
          } else {
            // Pour les messages reçus, on peut aussi afficher des options (répondre, etc.)
            _showReceivedMessageActions(context, message);
          }
        },
        child: Align(
          alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
        margin: EdgeInsets.only(
          bottom: context.elementSpacing * 0.5,
          left: isSentByMe ? context.horizontalPadding * 2 : 0,
          right: isSentByMe ? 0 : context.horizontalPadding * 2,
        ),
        child: Column(
          crossAxisAlignment: isSentByMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Message content
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.elementSpacing,
                vertical: context.elementSpacing * 0.7,
              ),
              decoration: BoxDecoration(
                gradient: isSentByMe
                    ? const LinearGradient(
                        colors: [
                          AppThemeSystem.primaryColor,
                          AppThemeSystem.secondaryColor,
                        ],
                      )
                    : null,
                color: isSentByMe
                    ? null
                    : (isDark
                        ? AppThemeSystem.darkCardColor
                        : AppThemeSystem.grey100),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isSentByMe ? 16 : 4),
                  bottomRight: Radius.circular(isSentByMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSentByMe
                        ? AppThemeSystem.primaryColor.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildMessageContent(context, message, isDark, isSentByMe),
            ),

            // Timestamp with read receipts
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Read receipt indicators (only for sent messages)
                  if (isSentByMe) ...[
                    Icon(
                      Icons.done_all_rounded,
                      size: 14,
                      color: message.isRead
                          ? const Color(0xFF4FC3F7) // Blue for read
                          : AppThemeSystem.grey600,  // Gray for delivered
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    _formatTime(message.createdAt),
                    style: context.textStyle(FontSizeType.caption).copyWith(
                      color: AppThemeSystem.grey600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, ChatMessageModel message, bool isDark, bool isSentByMe) {
    // Widget pour le "reply-to" style WhatsApp
    Widget? replyWidget;

    // Debug: Log metadata
    if (message.metadata != null) {
      print('📦 Message ${message.id} metadata: ${message.metadata}');
    }

    // Si c'est une réponse à un message (vérifier metadata)
    if (message.metadata != null && message.metadata!['reply_to_message_id'] != null) {
      print('✅ Reply widget should display for message ${message.id}');
      final replyContent = message.metadata!['reply_to_content'] as String? ?? '(Media)';
      final replySender = message.metadata!['reply_to_sender'] as String? ?? 'Utilisateur';

      replyWidget = Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(
          horizontal: context.elementSpacing * 0.6,
          vertical: context.elementSpacing * 0.4,
        ),
        decoration: BoxDecoration(
          color: isSentByMe
              ? Colors.white.withValues(alpha: 0.2)
              : (isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey200)
                  .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border(
            left: BorderSide(
              color: isSentByMe ? Colors.white : AppThemeSystem.primaryColor,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.reply_rounded,
              size: 12,
              color: isSentByMe
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppThemeSystem.grey600,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    replySender,
                    style: context.textStyle(FontSizeType.caption).copyWith(
                      color: isSentByMe ? Colors.white : AppThemeSystem.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    replyContent,
                    style: context.textStyle(FontSizeType.caption).copyWith(
                      color: isSentByMe
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppThemeSystem.grey600,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    // Sinon, si c'est un message anonyme
    else if (message.anonymousMessage != null) {
      final anonMsg = message.anonymousMessage!;

      replyWidget = Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(
          horizontal: context.elementSpacing * 0.6,
          vertical: context.elementSpacing * 0.4,
        ),
        decoration: BoxDecoration(
          color: isSentByMe
              ? Colors.white.withValues(alpha: 0.2)
              : (isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey200)
                  .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border(
            left: BorderSide(
              color: isSentByMe ? Colors.white : AppThemeSystem.primaryColor,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.visibility_off_rounded,
              size: 12,
              color: isSentByMe
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppThemeSystem.grey600,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Message anonyme',
                    style: context.textStyle(FontSizeType.caption).copyWith(
                      color: isSentByMe ? Colors.white : AppThemeSystem.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    anonMsg.content,
                    style: context.textStyle(FontSizeType.caption).copyWith(
                      color: isSentByMe
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppThemeSystem.grey600,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    // Sinon, si c'est une réponse à une story
    else if (message.story != null) {
      final story = message.story!;

      replyWidget = GestureDetector(
        onTap: () async {
          // Ouvrir la story si l'utilisateur existe
          if (story.user != null) {
            try {
              // Obtenir le StoryController
              final storyController = Get.find<StoryController>();

              // Charger les stories de l'utilisateur
              await storyController.loadUserStoriesById(story.user!.id);

              // Naviguer vers le StoryViewer si des stories existent
              if (storyController.currentUserStories.isNotEmpty) {
                Get.to(
                  () => const StoryViewer(),
                  fullscreenDialog: true,
                  transition: Transition.fadeIn,
                );
              } else {
                Get.snackbar(
                  'Story expirée',
                  'Cette story n\'est plus disponible',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            } catch (e) {
              print('❌ Erreur lors de l\'ouverture de la story: $e');
              Get.snackbar(
                'Erreur',
                'Impossible d\'ouvrir la story',
                snackPosition: SnackPosition.BOTTOM,
              );
            }
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.symmetric(
            horizontal: context.elementSpacing * 0.6,
            vertical: context.elementSpacing * 0.4,
          ),
          decoration: BoxDecoration(
            color: isSentByMe
                ? Colors.white.withValues(alpha: 0.2)
                : (isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey200)
                    .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(6),
            border: Border(
              left: BorderSide(
                color: isSentByMe ? Colors.white : const Color(0xFF667eea),
                width: 3,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Afficher l'aperçu de la story selon son type
              _buildStoryPreview(story),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_stories_rounded,
                          size: 12,
                          color: isSentByMe
                              ? Colors.white.withValues(alpha: 0.7)
                              : const Color(0xFF667eea),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Story',
                          style: context.textStyle(FontSizeType.caption).copyWith(
                            color: isSentByMe ? Colors.white : const Color(0xFF667eea),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    if (story.user != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        story.user!.username,
                        style: context.textStyle(FontSizeType.caption).copyWith(
                          color: isSentByMe
                              ? Colors.white.withValues(alpha: 0.8)
                              : AppThemeSystem.grey600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (story.content != null && story.content!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        story.content!,
                        style: context.textStyle(FontSizeType.caption).copyWith(
                          color: isSentByMe
                              ? Colors.white.withValues(alpha: 0.8)
                              : AppThemeSystem.grey600,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    switch (message.type) {
      case ChatMessageType.text:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (replyWidget != null) replyWidget,
            Text(
              message.content ?? '',
              style: context.textStyle(FontSizeType.body2).copyWith(
                color: isSentByMe
                    ? Colors.white
                    : (isDark ? Colors.white : AppThemeSystem.blackColor),
              ),
            ),
            // NOUVEAU: Badge "édité" si message édité
            if (message.isEdited)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '(édité)',
                  style: context.textStyle(FontSizeType.caption).copyWith(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: isSentByMe ? Colors.white70 : Colors.grey,
                  ),
                ),
              ),
          ],
        );

      case ChatMessageType.gift:
        final gift = message.giftData;
        final giftIcon = (gift?.icon.trim().isNotEmpty ?? false) ? gift!.icon.trim() : '🎁';
        final giftName = (gift?.name.trim().isNotEmpty ?? false) ? gift!.name.trim() : 'Cadeau';
        final giftPrice = gift?.formattedPrice ?? (gift?.price != null ? '${gift!.price} FCFA' : null);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (replyWidget != null) replyWidget,
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSentByMe
                    ? Colors.white.withValues(alpha: 0.18)
                    : (isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey200)
                        .withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSentByMe
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppThemeSystem.grey300.withValues(alpha: 0.8),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(giftIcon, style: const TextStyle(fontSize: 34)),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          giftName,
                          style: context.textStyle(FontSizeType.body2).copyWith(
                            color: isSentByMe
                                ? Colors.white
                                : (isDark ? Colors.white : AppThemeSystem.blackColor),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (giftPrice != null && giftPrice.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            giftPrice,
                            style: context.textStyle(FontSizeType.caption).copyWith(
                              color: isSentByMe
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : AppThemeSystem.grey600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                        if ((message.content ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            message.content!.trim(),
                            style: context.textStyle(FontSizeType.caption).copyWith(
                              color: isSentByMe
                                  ? Colors.white.withValues(alpha: 0.92)
                                  : AppThemeSystem.grey700,
                              fontSize: 12,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case ChatMessageType.audio:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (replyWidget != null) replyWidget,
            _buildAudioPlayer(context, message, isDark, isSentByMe),
          ],
        );

      case ChatMessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (replyWidget != null) replyWidget,
            GestureDetector(
              onTap: message.mediaUrl != null
                  ? () => _showImageZoom(context, message.mediaUrl!)
                  : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: message.mediaUrl != null
                    ? Image.network(
                        message.mediaUrl!,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 200,
                          height: 200,
                          color: AppThemeSystem.grey300,
                          child: const Icon(
                            Icons.image_rounded,
                            size: 64,
                            color: AppThemeSystem.grey600,
                          ),
                        ),
                      )
                    : Container(
                        width: 200,
                        height: 200,
                        color: AppThemeSystem.grey300,
                        child: const Icon(
                          Icons.image_rounded,
                          size: 64,
                          color: AppThemeSystem.grey600,
                        ),
                      ),
              ),
            ),
            // Caption text below image (if present)
            if (message.content != null && message.content!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  message.content!,
                  style: context.textStyle(FontSizeType.body2).copyWith(
                    color: isSentByMe
                        ? Colors.white
                        : (isDark ? Colors.white : AppThemeSystem.blackColor),
                  ),
                ),
              ),
          ],
        );

      case ChatMessageType.video:
        return Container(
          width: 200,
          height: 200,
          color: AppThemeSystem.grey300,
          child: const Center(
            child: Icon(
              Icons.play_circle_outline_rounded,
              size: 64,
              color: AppThemeSystem.grey600,
            ),
          ),
        );

      case ChatMessageType.system:
        // Message système simple (le reply-to est maintenant dans le message de réponse)
        return Text(
          message.content ?? '',
          style: context.textStyle(FontSizeType.body2).copyWith(
            color: AppThemeSystem.grey600,
            fontStyle: FontStyle.italic,
            fontSize: 13,
          ),
        );
    }
  }

  Widget _buildGiftPicker(BuildContext context, bool isDark) {
    return Container(
      height: 350,
      decoration: BoxDecoration(
        color: isDark
            ? AppThemeSystem.darkCardColor
            : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(context.elementSpacing),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Envoyer un cadeau',
                  style: context.textStyle(FontSizeType.h6).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => controller.toggleGiftPicker(),
                ),
              ],
            ),
          ),

          // Category tabs
          Obx(() {
            if (controller.isLoadingGifts.value) {
              return const SizedBox(
                height: 40,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            return SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: context.elementSpacing),
                children: [
                  // "Tous" button
                  GestureDetector(
                    onTap: () => controller.selectGiftCategory(null),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: controller.selectedGiftCategoryId.value == null
                            ? const LinearGradient(
                                colors: [
                                  AppThemeSystem.primaryColor,
                                  AppThemeSystem.secondaryColor,
                                ],
                              )
                            : null,
                        color: controller.selectedGiftCategoryId.value == null
                            ? null
                            : (isDark
                                ? AppThemeSystem.grey800.withValues(alpha: 0.4)
                                : AppThemeSystem.grey100),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Tous',
                        style: context.textStyle(FontSizeType.body2).copyWith(
                          color: controller.selectedGiftCategoryId.value == null
                              ? Colors.white
                              : (isDark ? AppThemeSystem.grey300 : AppThemeSystem.grey700),
                          fontWeight: controller.selectedGiftCategoryId.value == null ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  // Categories from API
                  ...controller.giftCategories.map((category) {
                    final isSelected = controller.selectedGiftCategoryId.value == category.id;
                    return GestureDetector(
                      onTap: () => controller.selectGiftCategory(category.id),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [
                                    AppThemeSystem.primaryColor,
                                    AppThemeSystem.secondaryColor,
                                  ],
                                )
                              : null,
                          color: isSelected
                              ? null
                              : (isDark
                                  ? AppThemeSystem.grey800.withValues(alpha: 0.4)
                                  : AppThemeSystem.grey100),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category.name,
                          style: context.textStyle(FontSizeType.body2).copyWith(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppThemeSystem.grey300 : AppThemeSystem.grey700),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),

          const SizedBox(height: 12),

          // Gift grid
          Expanded(
            child: Obx(() {
              if (controller.isLoadingGifts.value) {
                return const Center(child: CircularProgressIndicator());
              }

              // Filtrer les cadeaux par catégorie si nécessaire
              final filteredGifts = controller.selectedGiftCategoryId.value != null
                  ? controller.gifts.where((g) => g.categoryId == controller.selectedGiftCategoryId.value).toList()
                  : controller.gifts;

              if (filteredGifts.isEmpty) {
                return Center(
                  child: Text(
                    'Aucun cadeau disponible',
                    style: context.textStyle(FontSizeType.body2).copyWith(
                      color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                    ),
                  ),
                );
              }

              return GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: context.elementSpacing),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: filteredGifts.length,
                itemBuilder: (context, index) {
                  final gift = filteredGifts[index];

                  return GestureDetector(
                    onTap: () {
                      // TODO: Implement sendGift when POST is ready
                      // controller.sendGift(gift);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppThemeSystem.grey800.withValues(alpha: 0.4)
                            : AppThemeSystem.grey100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppThemeSystem.grey700.withValues(alpha: 0.5)
                              : AppThemeSystem.grey200,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            gift.icon,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            gift.name,
                            style: context.textStyle(FontSizeType.caption).copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppThemeSystem.primaryColor,
                                  AppThemeSystem.secondaryColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              gift.formattedPrice,
                              style: context.textStyle(FontSizeType.caption).copyWith(
                                fontSize: 8,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer(BuildContext context, ChatMessageModel message, bool isDark, bool isSentByMe) {
    // Initialiser le player au premier build
    controller.initializeAudioPlayer(message.id);

    print('🎵 [AudioPlayer Widget] Building for message ${message.id}');
    print('🎵 Media URL: ${message.mediaUrl}');

    return Obx(() {
      // Écouter audioPlayerUpdate pour forcer les rebuilds
      final _ = controller.audioPlayerUpdate.value;

      final isPlaying = controller.audioPlayingStates[message.id] ?? false;
      final isLoading = controller.audioLoadingStates[message.id] ?? false;
      final duration = controller.audioDurations[message.id] ?? Duration.zero;
      final position = controller.audioPositions[message.id] ?? Duration.zero;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton Play/Pause
          GestureDetector(
            onTap: message.mediaUrl != null
                ? () {
                    controller.initializeAudioPlayer(message.id);
                    controller.toggleAudioPlayback(message.id, message.mediaUrl!);
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSentByMe
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppThemeSystem.primaryColor,
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: isSentByMe ? Colors.white : Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Barre de progression
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Durées
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatAudioDuration(position),
                      style: context.textStyle(FontSizeType.caption).copyWith(
                        color: isSentByMe ? Colors.white : AppThemeSystem.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      _formatAudioDuration(duration),
                      style: context.textStyle(FontSizeType.caption).copyWith(
                        color: isSentByMe
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppThemeSystem.grey600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Barre de progression
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: duration.inMilliseconds > 0
                        ? position.inMilliseconds / duration.inMilliseconds
                        : 0.0,
                    backgroundColor: isSentByMe
                        ? Colors.white.withValues(alpha: 0.3)
                        : AppThemeSystem.grey300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isSentByMe ? Colors.white : AppThemeSystem.primaryColor,
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Icône waveform
          Icon(
            Icons.graphic_eq,
            color: isPlaying
                ? (isSentByMe ? Colors.white : AppThemeSystem.primaryColor)
                : (isSentByMe
                    ? Colors.white.withValues(alpha: 0.5)
                    : AppThemeSystem.grey400),
            size: 20,
          ),
        ],
      );
    });
  }

  String _formatAudioDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _formatPrice(int price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(1)}K';
    }
    return price.toString();
  }

  Widget _buildInputArea(BuildContext context, bool isDark) {
    // Show recording interface when recording
    return Obx(() {
      if (controller.isRecording.value) {
        return _buildRecordingInterface(context, isDark);
      }

      return Container(
        padding: EdgeInsets.all(context.elementSpacing),
        decoration: BoxDecoration(
          color: isDark
              ? AppThemeSystem.darkCardColor
              : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Reply preview (if replying to a message)
            Obx(() {
              final replyMsg = controller.replyToMessage.value;
              if (replyMsg == null) return const SizedBox.shrink();

              return Container(
                margin: EdgeInsets.only(bottom: context.elementSpacing * 0.5),
                padding: EdgeInsets.symmetric(
                  horizontal: context.elementSpacing,
                  vertical: context.elementSpacing * 0.5,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(
                      color: AppThemeSystem.primaryColor,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Répondre à ${replyMsg.sender?.username ?? "Utilisateur"}',
                            style: context.textStyle(FontSizeType.caption).copyWith(
                              color: AppThemeSystem.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            replyMsg.content ?? '(Media)',
                            style: context.textStyle(FontSizeType.caption).copyWith(
                              color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 18),
                      onPressed: controller.cancelReply,
                      color: AppThemeSystem.grey600,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              );
            }),

            // Input row
            Row(
          children: [
            // Gift button
            IconButton(
              icon: const Icon(Icons.card_giftcard_rounded),
              onPressed: () => controller.toggleGiftPicker(),
              color: AppThemeSystem.primaryColor,
            ),

            // Image button
            IconButton(
              icon: const Icon(Icons.image_rounded),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const ChatImagePickerBottomSheet(),
                );
              },
              color: AppThemeSystem.primaryColor,
            ),

            // Input field
            Expanded(
              child: TextField(
                controller: controller.messageTextController,
                onChanged: (text) {
                  controller.messageText.value = text;
                  controller.onMessageTextChanged(text); // NOUVEAU - Typing indicator
                },
                decoration: InputDecoration(
                  hintText: 'Message...',
                  hintStyle: context.textStyle(FontSizeType.body2).copyWith(
                    color: AppThemeSystem.grey600,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppThemeSystem.grey800.withValues(alpha: 0.4)
                      : AppThemeSystem.grey100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                style: context.textStyle(FontSizeType.body2),
              ),
            ),

            const SizedBox(width: 8),

            // Send/Record button
            Obx(() {
              final hasText = controller.messageText.value.trim().isNotEmpty;

              return GestureDetector(
                onTap: hasText
                    ? () {
                        controller.sendMessage(
                          content: controller.messageText.value,
                          type: 'text',
                        );
                      }
                    : () => controller.toggleRecording(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppThemeSystem.primaryColor,
                        AppThemeSystem.secondaryColor,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppThemeSystem.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    hasText
                        ? Icons.send_rounded
                        : (controller.isRecording.value
                            ? Icons.stop_rounded
                            : Icons.mic_rounded),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              );
            }),
          ],
        ),
        ],
          ),
        ),
      );
    });
  }

  Widget _buildRecordingInterface(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(context.elementSpacing),
      decoration: BoxDecoration(
        color: isDark
            ? AppThemeSystem.darkCardColor
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Cancel button
            IconButton(
              onPressed: () => controller.cancelRecording(),
              icon: Icon(Icons.delete, color: AppThemeSystem.errorColor),
              padding: const EdgeInsets.all(12),
            ),
            const SizedBox(width: 8),

            // Recording duration
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppThemeSystem.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    // Animated microphone icon (pulsing)
                    Obx(() {
                      return TweenAnimationBuilder<double>(
                        key: ValueKey(controller.recordDuration.value.inSeconds),
                        tween: Tween(begin: 0.3, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Icon(
                              Icons.mic,
                              color: AppThemeSystem.errorColor,
                              size: 20,
                            ),
                          );
                        },
                      );
                    }),
                    const SizedBox(width: 12),
                    Obx(() {
                      return Text(
                        _formatAudioDuration(controller.recordDuration.value),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppThemeSystem.errorColor,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Stop/Send button
            Container(
              decoration: const BoxDecoration(
                color: AppThemeSystem.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => controller.stopRecording(),
                icon: Icon(Icons.stop_rounded, color: Colors.white, size: 22),
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildGiftAnimation(BuildContext context) {
    final gift = controller.animatedGift.value!;
    final screenSize = MediaQuery.of(context).size;

    print('🎬 [GiftAnimation] Building animation for gift: ${gift['name']}');

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        // Phase 1: Entrance (0.0 - 0.3)
        // Phase 2: Bounce & Pulse (0.3 - 0.7)
        // Phase 3: Exit (0.7 - 1.0)

        double scale;
        double rotation;
        double opacity;

        if (value < 0.3) {
          // Entrance: explosive scale + rotation
          final progress = value / 0.3;
          scale = 0.3 + (progress * 1.5);
          rotation = progress * 0.5;
          opacity = progress;
        } else if (value < 0.7) {
          // Bounce & Pulse
          final progress = (value - 0.3) / 0.4;
          final bounce = (1.0 - progress).abs();
          scale = 1.3 + (bounce * 0.3);
          rotation = 0.5 + (progress * 0.2);
          opacity = 1.0;
        } else {
          // Exit
          final progress = (value - 0.7) / 0.3;
          scale = 1.3 - (progress * 0.5);
          rotation = 0.7 + (progress * 0.3);
          opacity = 1.0 - progress;
        }

        return Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              children: [
                // Confetti particles
                ..._buildConfettiParticles(screenSize, value, opacity),

                // Glow rings
                ..._buildGlowRings(screenSize, value, opacity),

                // Main gift
                Center(
                  child: Transform.rotate(
                    angle: rotation,
                    child: Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppThemeSystem.primaryColor,
                                AppThemeSystem.secondaryColor,
                                AppThemeSystem.tertiaryColor,
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppThemeSystem.primaryColor.withValues(alpha: 0.6),
                                blurRadius: 40,
                                spreadRadius: 20,
                              ),
                              BoxShadow(
                                color: AppThemeSystem.secondaryColor.withValues(alpha: 0.4),
                                blurRadius: 80,
                                spreadRadius: 40,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              gift['icon'].toString(),
                              style: TextStyle(
                                fontSize: 100,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Sparkles
                ..._buildSparkles(screenSize, value, opacity),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildConfettiParticles(Size screenSize, double value, double opacity) {
    final particles = <Widget>[];
    final colors = [
      AppThemeSystem.primaryColor,
      AppThemeSystem.secondaryColor,
      AppThemeSystem.tertiaryColor,
      AppThemeSystem.accentColor,
      AppThemeSystem.successColor,
    ];

    for (var i = 0; i < 30; i++) {
      final angle = (i / 30) * 6.28; // 360 degrees in radians
      final distance = value * 300;
      final x = screenSize.width / 2 + (distance * cos(angle * 0.5));
      final y = screenSize.height / 2 + (distance * sin(angle * 0.5));

      final particleOpacity = value < 0.5 ? opacity : opacity * (1.0 - ((value - 0.5) * 2));
      final size = 8.0 + ((i % 3) * 4);

      particles.add(
        Positioned(
          left: x - size / 2,
          top: y - size / 2,
          child: Transform.rotate(
            angle: value * 6.28 * (i % 2 == 0 ? 1 : -1),
            child: Opacity(
              opacity: particleOpacity,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: colors[i % colors.length],
                  shape: i % 3 == 0 ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: i % 3 != 0 ? BorderRadius.circular(2) : null,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return particles;
  }

  List<Widget> _buildGlowRings(Size screenSize, double value, double opacity) {
    final rings = <Widget>[];

    for (var i = 0; i < 3; i++) {
      final delay = i * 0.1;
      final adjustedValue = (value - delay).clamp(0.0, 1.0);
      final ringSize = 100.0 + (adjustedValue * 300);
      final ringOpacity = opacity * (1.0 - adjustedValue) * 0.3;

      rings.add(
        Center(
          child: Container(
            width: ringSize,
            height: ringSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppThemeSystem.primaryColor.withValues(alpha: ringOpacity),
                width: 3,
              ),
            ),
          ),
        ),
      );
    }

    return rings;
  }

  List<Widget> _buildSparkles(Size screenSize, double value, double opacity) {
    final sparkles = <Widget>[];
    final sparkleIcons = ['✨', '⭐', '💫', '🌟'];

    for (var i = 0; i < 12; i++) {
      final angle = (i / 12) * 6.28;
      final radius = 150.0 + (value * 50 * ((i % 2) + 1));
      final x = screenSize.width / 2 + (radius * cos(angle));
      final y = screenSize.height / 2 + (radius * sin(angle));

      final sparkleValue = ((value * 4) - (i * 0.1)) % 1.0;
      final sparkleOpacity = opacity * (0.5 + (sparkleValue * 0.5));
      final sparkleScale = 0.5 + (sparkleValue * 0.5);

      sparkles.add(
        Positioned(
          left: x - 15,
          top: y - 15,
          child: Transform.scale(
            scale: sparkleScale,
            child: Opacity(
              opacity: sparkleOpacity,
              child: Text(
                sparkleIcons[i % sparkleIcons.length],
                style: const TextStyle(fontSize: 30),
              ),
            ),
          ),
        ),
      );
    }

    return sparkles;
  }

  /// Show image in full screen with zoom capability
  void _showImageZoom(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Image with zoom
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 200,
                    height: 200,
                    color: AppThemeSystem.grey800,
                    child: const Icon(
                      Icons.broken_image_rounded,
                      size: 64,
                      color: AppThemeSystem.grey600,
                    ),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: AppThemeSystem.primaryColor,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Close button
            Positioned(
              top: 40,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom sheet avec actions pour long-press
  void _showMessageActions(BuildContext context, ChatMessageModel message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppThemeSystem.darkCardColor
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final canEdit = message.canBeEdited(controller.currentUserId!);

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Modifier (si < 15 min et texte)
              if (canEdit && message.type == ChatMessageType.text)
                ListTile(
                  leading: Icon(Icons.edit, color: AppThemeSystem.primaryColor),
                  title: Text('Modifier'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(context, message);
                  },
                ),

              // Supprimer
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, message);
                },
              ),

              // Répondre
              ListTile(
                leading: Icon(Icons.reply, color: AppThemeSystem.primaryColor),
                title: Text('Répondre'),
                onTap: () {
                  Navigator.pop(context);
                  controller.setReplyToMessage(message);
                },
              ),

              // Annuler
              ListTile(
                leading: Icon(Icons.close, color: Colors.grey),
                title: Text('Annuler'),
                onTap: () => Navigator.pop(context),
              ),

              SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Bottom sheet avec actions pour les messages reçus (long-press)
  void _showReceivedMessageActions(BuildContext context, ChatMessageModel message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppThemeSystem.darkCardColor
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Répondre
              ListTile(
                leading: Icon(Icons.reply, color: AppThemeSystem.primaryColor),
                title: Text('Répondre'),
                onTap: () {
                  Navigator.pop(context);
                  controller.setReplyToMessage(message);
                },
              ),

              // Annuler
              ListTile(
                leading: Icon(Icons.close, color: Colors.grey),
                title: Text('Annuler'),
                onTap: () => Navigator.pop(context),
              ),

              SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Dialogue d'édition
  void _showEditDialog(BuildContext context, ChatMessageModel message) {
    final TextEditingController editController = TextEditingController(text: message.content);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppThemeSystem.darkCardColor
              : Colors.white,
          title: Text('Modifier le message'),
          content: TextField(
            controller: editController,
            maxLines: 3,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Nouveau texte...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final newText = editController.text.trim();
                if (newText.isNotEmpty && newText != message.content) {
                  controller.editMessage(message, newText);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeSystem.primaryColor,
              ),
              child: Text('Modifier'),
            ),
          ],
        );
      },
    );
  }

  /// Confirmation de suppression
  void _showDeleteConfirmation(BuildContext context, ChatMessageModel message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppThemeSystem.darkCardColor
              : Colors.white,
          title: Text('Supprimer le message'),
          content: Text('Êtes-vous sûr de vouloir supprimer ce message ? Cette action est irréversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                controller.deleteMessage(message);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }
}
