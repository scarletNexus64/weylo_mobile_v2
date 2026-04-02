import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';
import 'package:weylo/app/widgets/gift_icon_image.dart';
import 'package:weylo/app/data/models/group_message_model.dart';
import '../controllers/groupe_detail_controller.dart';
import 'group_info_view.dart';

class GroupeDetailView extends GetView<GroupeDetailController> {
  const GroupeDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    print('🎨 [GroupeDetailView] Building view - isDark: $isDark');

    return Scaffold(
      backgroundColor: isDark
          ? AppThemeSystem.darkBackgroundColor
          : AppThemeSystem.grey100,
      appBar: AppBar(
        title: Row(
          children: [
            Obx(() {
              final group = controller.group.value;
              return CircleAvatar(
                radius: 20,
                backgroundColor: AppThemeSystem.tertiaryColor,
                backgroundImage: group?.avatarUrl != null
                    ? NetworkImage(group!.avatarUrl!)
                    : null,
                child: group?.avatarUrl == null
                    ? Text(
                        group?.initials ?? 'G',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
              );
            }),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.groupName,
                    style: context.textStyle(FontSizeType.body1).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${controller.memberCount} membres',
                    style: context.textStyle(FontSizeType.caption).copyWith(
                      color: AppThemeSystem.tertiaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () => _showGroupOptions(context),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          print('🏗️ [GroupeDetailView] Building body Stack');
          return Stack(
            children: [
              // Background with conversation icons
              _buildBackgroundPattern(context),

              // Main content
              Column(
            children: [
              // Messages list
              Expanded(
                child: Obx(() {
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
                if (controller.isAnimatingGift.value && controller.animatedGift.value != null) {
                  return _buildGiftAnimation(context);
                }
                return const SizedBox.shrink();
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackgroundPattern(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    print('🎨 [GroupeBackground] Building with wallpaper image');

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
          child: Opacity(
            opacity: isDark ? 0.08 : 0.12,
            child: Image.asset(
              'assets/images/wallpaper.png',
              fit: BoxFit.cover,
              repeat: ImageRepeat.repeat,
              colorBlendMode: BlendMode.overlay,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, GroupMessageModel message, bool isDark) {
    final isSentByMe = controller.isSentByMe(message);
    final senderName = message.sender?.fullName ?? 'Anonyme';

    // Skip system messages from swipe and actions
    if (message.type == GroupMessageType.system) {
      return Align(
        alignment: Alignment.center,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: context.elementSpacing * 0.5),
          padding: EdgeInsets.symmetric(
            horizontal: context.elementSpacing,
            vertical: context.elementSpacing * 0.5,
          ),
          decoration: BoxDecoration(
            color: (isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200)
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.content ?? '',
            style: context.textStyle(FontSizeType.caption).copyWith(
              color: AppThemeSystem.grey600,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

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
          if (isSentByMe) {
            _showMessageActions(context, message);
          } else {
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Avatar à gauche pour les messages reçus
                if (!isSentByMe) ...[
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppThemeSystem.tertiaryColor,
                    backgroundImage: message.sender?.avatarUrl != null
                        ? NetworkImage(message.sender!.avatarUrl!)
                        : null,
                    child: message.sender?.avatarUrl == null
                        ? Text(
                            _getUserInitials(message),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                ],

                // Contenu du message
                Flexible(
                  child: Column(
                    crossAxisAlignment: isSentByMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      // Nom de l'expéditeur pour les messages reçus
                      if (!isSentByMe)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4, left: 4),
                          child: Text(
                            senderName,
                            style: context.textStyle(FontSizeType.caption).copyWith(
                              color: AppThemeSystem.tertiaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

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

                      // Timestamp
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                        child: Text(
                          _formatTime(message.createdAt),
                          style: context.textStyle(FontSizeType.caption).copyWith(
                            color: AppThemeSystem.grey600,
                            fontSize: 10,
                          ),
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

  /// Obtenir les initiales de l'utilisateur pour l'avatar
  String _getUserInitials(GroupMessageModel message) {
    final sender = message.sender;

    // PRIORITÉ 1: Utiliser l'attribut 'initial' calculé par le backend si disponible
    // Cet attribut contient les initiales calculées côté serveur (2 lettres)
    final initial = sender?.initial;
    if (initial != null && initial.isNotEmpty) {
      return initial.toUpperCase();
    }

    // FALLBACK 1: Si on a le prénom et le nom, calculer les initiales
    if (sender?.firstName != null && sender!.firstName.isNotEmpty) {
      final lastName = sender.lastName;
      if (lastName != null && lastName.isNotEmpty) {
        return '${sender.firstName[0]}${lastName[0]}'.toUpperCase();
      }

      // Si on a juste le prénom, prendre les 2 premières lettres (ou 1 si trop court)
      final firstName = sender.firstName;
      if (firstName.length >= 2) {
        return firstName.substring(0, 2).toUpperCase();
      }
      return firstName[0].toUpperCase();
    }

    // FALLBACK 2: Si on a le username, prendre les 2 premières lettres
    if (sender?.username != null && sender!.username.isNotEmpty) {
      final username = sender.username;
      if (username.length >= 2) {
        return username.substring(0, 2).toUpperCase();
      }
      return username[0].toUpperCase();
    }

    // Par défaut, retourner 'A' pour Anonyme
    return 'A';
  }

  Widget _buildMessageContent(BuildContext context, GroupMessageModel message, bool isDark, bool isSentByMe) {
    // Widget pour afficher le message quoté (si c'est une réponse)
    Widget? replyWidget;
    if (message.metadata != null && message.metadata!['reply_to_message_id'] != null) {
      // Chercher le message original dans la liste pour obtenir le vrai nom du sender
      final replyToId = message.metadata!['reply_to_message_id'] as int?;
      final originalMessage = controller.messages.firstWhereOrNull(
        (msg) => msg.id == replyToId,
      );

      final replyContent = originalMessage?.content ??
                          (message.metadata!['reply_to_content'] as String? ?? '(Media)');
      // Utiliser le sender du message original si disponible, sinon fallback sur metadata
      final replySender = originalMessage?.sender?.fullName ??
                         (message.metadata!['reply_to_sender'] as String? ?? 'Anonyme');

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              replySender,
              style: context.textStyle(FontSizeType.caption).copyWith(
                color: isSentByMe
                    ? Colors.white.withValues(alpha: 0.9)
                    : AppThemeSystem.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              replyContent,
              style: context.textStyle(FontSizeType.caption).copyWith(
                color: isSentByMe
                    ? Colors.white.withValues(alpha: 0.7)
                    : (isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600),
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    // Contenu principal du message
    Widget mainContent;
    switch (message.type) {
      case GroupMessageType.text:
        mainContent = Text(
          message.content ?? '',
          style: context.textStyle(FontSizeType.body2).copyWith(
            color: isSentByMe
                ? Colors.white
                : (isDark ? Colors.white : AppThemeSystem.blackColor),
          ),
        );
        break;

      case GroupMessageType.gift:
        // Extract gift info from metadata (similar to chat_detail but using metadata only)
        final metadata = message.metadata;

        // Extract icon (emoji) from metadata
        String giftIcon = '🎁'; // Default value
        if (metadata?['icon'] != null) {
          final iconStr = metadata!['icon'].toString();
          if (iconStr.isNotEmpty) {
            giftIcon = iconStr;
          }
        }

        // Extract name from metadata
        String giftName = 'Cadeau'; // Default value
        if (metadata?['name'] != null) {
          final nameStr = metadata!['name'].toString();
          if (nameStr.isNotEmpty) {
            giftName = nameStr;
          }
        }

        // Extract image URL from metadata
        final giftImageUrl = metadata?['emoji_image_url'] as String?;

        // Extract price from metadata
        final giftPrice = metadata?['price'] != null ? '${metadata!['price']} FCFA' : null;

        mainContent = Container(
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
              // Display emoji as Twemoji image
              SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: GiftIconImage(
                    imageUrl: giftImageUrl,
                    emojiIcon: giftIcon,
                    size: 32,
                  ),
                ),
              ),
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
                  ],
                ),
              ),
            ],
          ),
        );
        break;

      case GroupMessageType.audio:
        mainContent = _buildAudioPlayer(context, message, isDark, isSentByMe);
        break;

      case GroupMessageType.image:
        mainContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: message.mediaUrl != null
                  ? () => _showFullscreenImage(context, message.mediaUrl!)
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
        break;

      case GroupMessageType.video:
      case GroupMessageType.system:
        mainContent = Text(
          message.content ?? '',
          style: context.textStyle(FontSizeType.body2).copyWith(
            color: AppThemeSystem.grey600,
            fontStyle: FontStyle.italic,
          ),
        );
        break;
    }

    // Retourner le contenu avec le reply widget si présent
    if (replyWidget != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          replyWidget,
          mainContent,
        ],
      );
    }

    return mainContent;
  }

  Widget _buildGiftPicker(BuildContext context, bool isDark) {
    // Calculer la hauteur maximale disponible (40% de l'écran ou 280px max)
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = (screenHeight * 0.4).clamp(220.0, 280.0);

    return Container(
      height: maxHeight,
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

                  return FadeInUp(
                    duration: const Duration(milliseconds: 300),
                    delay: Duration(milliseconds: index * 50),
                    child: GestureDetector(
                      onTap: () => controller.sendGift(gift),
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
                            Pulse(
                              duration: Duration(milliseconds: 2000 + (index * 200)),
                              infinite: true,
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: Stack(
                                  alignment: Alignment.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    ..._buildGiftSparkles(gift, index),
                                    GiftIconImage(
                                      imageUrl: gift.emojiImageUrl,
                                      emojiIcon: gift.icon,
                                      size: 32,
                                    ),
                                  ],
                                ),
                              ),
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

  String _formatPrice(int price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(1)}K';
    }
    return price.toString();
  }

  Widget _buildInputArea(BuildContext context, bool isDark) {
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
      child: Obx(() {
        // Vérifier si l'utilisateur peut poster
        final group = controller.group.value;
        final canPost = group?.canPost ?? true;

        // Debug logs
        print('🔍 [GroupeDetailView] Input bar check:');
        print('   - posting_permission: ${group?.postingPermission}');
        print('   - isCreator: ${group?.isCreator}');
        print('   - isAdmin: ${group?.isAdmin}');
        print('   - canPost: $canPost');

        // Si l'utilisateur ne peut pas poster, afficher un message informatif
        if (!canPost) {
          return SafeArea(
            child: Container(
              padding: EdgeInsets.all(context.elementSpacing * 1.5),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppThemeSystem.grey600,
                    size: 20,
                  ),
                  SizedBox(width: context.elementSpacing),
                  Expanded(
                    child: Text(
                      'Seuls les administrateurs peuvent poster des messages dans ce groupe',
                      style: context.textStyle(FontSizeType.body2).copyWith(
                        color: AppThemeSystem.grey600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Basculer entre l'interface d'enregistrement et l'interface normale
        if (controller.isRecording.value) {
          return _buildRecordingInterface(context, isDark);
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reply preview (if replying to a message)
              Obx(() {
                final replyMsg = controller.replyToMessage.value;
                if (replyMsg == null) return const SizedBox.shrink();

                final senderName = replyMsg.sender?.fullName ?? 'Anonyme';

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
                              'Répondre à $senderName',
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
                    color: AppThemeSystem.tertiaryColor,
                  ),

                  // Image button
                  IconButton(
                    icon: const Icon(Icons.image_rounded),
                    onPressed: () => controller.sendImage(),
                    color: AppThemeSystem.tertiaryColor,
                  ),

                  // Input field
                  Expanded(
                    child: TextField(
                      controller: controller.messageController,
                      onChanged: (value) => controller.messageText.value = value,
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
                      ? () => controller.sendMessage()
                      : () => _showVoiceTypePicker(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppThemeSystem.tertiaryColor,
                          AppThemeSystem.secondaryColor,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppThemeSystem.tertiaryColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      hasText ? Icons.send_rounded : Icons.mic_rounded,
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
        );
      }),
    );
  }

  Widget _buildAudioPlayer(BuildContext context, GroupMessageModel message, bool isDark, bool isSentByMe) {
    // Initialiser le player au premier build
    controller.initializeAudioPlayer(message.id);

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
                        color: Colors.white,
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildRecordingInterface(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.elementSpacing * 0.5,
        vertical: context.elementSpacing * 0.5,
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Bouton annuler
            IconButton(
              onPressed: () => controller.cancelRecording(),
              icon: Icon(Icons.delete, color: AppThemeSystem.errorColor),
              padding: const EdgeInsets.all(12),
            ),
            const SizedBox(width: 8),

            // Durée d'enregistrement
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppThemeSystem.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    // Icône micro animée (pulsation)
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
                        _formatDuration(controller.recordDuration.value),
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

            // Bouton stop/envoyer (carré)
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

  Widget _buildGiftAnimation(BuildContext context) {
    final gift = controller.animatedGift.value!;
    final screenSize = MediaQuery.of(context).size;

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
          opacity = progress.clamp(0.0, 1.0);
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
          opacity = (1.0 - progress).clamp(0.0, 1.0);
        }

        return Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: Colors.black.withValues(alpha: 0.4 * opacity),
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
                                color: AppThemeSystem.tertiaryColor.withValues(alpha: 0.6),
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

      final particleOpacity = (value < 0.5 ? opacity : opacity * (1.0 - ((value - 0.5) * 2))).clamp(0.0, 1.0);
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
      final ringOpacity = (opacity * (1.0 - adjustedValue) * 0.3).clamp(0.0, 1.0);

      rings.add(
        Center(
          child: Container(
            width: ringSize,
            height: ringSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppThemeSystem.tertiaryColor.withValues(alpha: ringOpacity),
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
      final sparkleOpacity = (opacity * (0.5 + (sparkleValue * 0.5))).clamp(0.0, 1.0);
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

  /// Show voice type picker bottom sheet
  void _showVoiceTypePicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final voiceTypes = [
      {
        'id': 'normal',
        'name': 'Normale',
        'icon': Icons.record_voice_over_rounded,
        'color': AppThemeSystem.primaryColor,
        'description': 'Voix naturelle'
      },
      {
        'id': 'robot',
        'name': 'Robot',
        'icon': Icons.smart_toy_rounded,
        'color': const Color(0xFF00BCD4),
        'description': 'Voix robotique'
      },
      {
        'id': 'alien',
        'name': 'Alien',
        'icon': Icons.psychology_rounded,
        'color': const Color(0xFF9C27B0),
        'description': 'Voix extraterrestre'
      },
      {
        'id': 'mystery',
        'name': 'Mystérieux',
        'icon': Icons.masks_rounded,
        'color': const Color(0xFF424242),
        'description': 'Voix grave et sombre'
      },
      {
        'id': 'chipmunk',
        'name': 'Chipmunk',
        'icon': Icons.pets_rounded,
        'color': const Color(0xFFFF9800),
        'description': 'Voix aiguë'
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (modalContext) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.mic_rounded,
                      color: AppThemeSystem.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Choisir le type de voix',
                      style: context.textStyle(FontSizeType.h6).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Voice types
              ...voiceTypes.map((voiceType) {
                return Obx(() {
                  final isSelected = controller.selectedVoiceType.value == voiceType['id'];
                  return Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (voiceType['color'] as Color).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            voiceType['icon'] as IconData,
                            color: voiceType['color'] as Color,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          voiceType['name'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppThemeSystem.blackColor,
                          ),
                        ),
                        subtitle: Text(
                          voiceType['description'] as String,
                          style: TextStyle(
                            color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: voiceType['color'] as Color,
                              )
                            : null,
                        onTap: () {
                          final selectedType = voiceType['id'] as String;
                          controller.selectVoiceType(selectedType);
                          Navigator.pop(modalContext);

                          // Attendre que le bottom sheet soit fermé avant de démarrer l'enregistrement
                          Future.delayed(const Duration(milliseconds: 300), () {
                            controller.startRecording();
                          });
                        },
                      ),
                      if (voiceType != voiceTypes.last)
                        Divider(
                          height: 1,
                          indent: 72,
                          color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
                        ),
                    ],
                  );
                });
              }),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Afficher l'image en plein écran avec zoom et pinch
  void _showFullscreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Image avec zoom/pinch
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
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
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 64,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
              // Bouton de fermeture
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        fullscreenDialog: true,
      ),
    );
  }

  /// Bottom sheet avec actions pour les messages envoyés (long-press)
  void _showMessageActions(BuildContext context, GroupMessageModel message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewPadding.bottom,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.symmetric(vertical: context.elementSpacing),
                  decoration: BoxDecoration(
                    color: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Supprimer
                _buildBottomSheetOption(
                  context: context,
                  icon: Icons.delete,
                  title: 'Supprimer',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context, message);
                  },
                  isDark: isDark,
                ),

                Divider(height: 1, color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200),

                // Répondre
                _buildBottomSheetOption(
                  context: context,
                  icon: Icons.reply,
                  title: 'Répondre',
                  color: AppThemeSystem.primaryColor,
                  onTap: () {
                    Navigator.pop(context);
                    controller.setReplyToMessage(message);
                  },
                  isDark: isDark,
                ),

                Divider(height: 1, color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200),

                // Annuler
                _buildBottomSheetOption(
                  context: context,
                  icon: Icons.close,
                  title: 'Annuler',
                  color: Colors.grey,
                  onTap: () => Navigator.pop(context),
                  isDark: isDark,
                ),

                SizedBox(height: context.elementSpacing),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Bottom sheet avec actions pour les messages reçus (long-press)
  void _showReceivedMessageActions(BuildContext context, GroupMessageModel message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewPadding.bottom,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.symmetric(vertical: context.elementSpacing),
                  decoration: BoxDecoration(
                    color: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Répondre
                _buildBottomSheetOption(
                  context: context,
                  icon: Icons.reply,
                  title: 'Répondre',
                  color: AppThemeSystem.primaryColor,
                  onTap: () {
                    Navigator.pop(context);
                    controller.setReplyToMessage(message);
                  },
                  isDark: isDark,
                ),

                Divider(height: 1, color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200),

                // Annuler
                _buildBottomSheetOption(
                  context: context,
                  icon: Icons.close,
                  title: 'Annuler',
                  color: Colors.grey,
                  onTap: () => Navigator.pop(context),
                  isDark: isDark,
                ),

                SizedBox(height: context.elementSpacing),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Dialog de confirmation de suppression
  void _showDeleteConfirmation(BuildContext context, GroupMessageModel message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Supprimer le message ?'),
          content: Text('Cette action est irréversible. Le message sera supprimé pour tout le monde.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.deleteMessage(message);
              },
              child: Text('Supprimer', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  /// Show group options bottom sheet
  void _showGroupOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final group = controller.group.value;

    if (group == null) return;

    final isCreator = group.isCreator;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewPadding.bottom,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.horizontalPadding * 2,
                    vertical: context.elementSpacing,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.settings,
                        color: AppThemeSystem.tertiaryColor,
                        size: context.deviceType == DeviceType.mobile ? 24 : 28,
                      ),
                      SizedBox(width: context.elementSpacing),
                      Text(
                        'Options du groupe',
                        style: context.textStyle(FontSizeType.h6).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200),

                // Option commune : Voir les informations
                _buildBottomSheetOption(
                  context: context,
                  icon: Icons.info_outline,
                  title: 'Informations du groupe',
                  color: AppThemeSystem.primaryColor,
                  onTap: () {
                    Navigator.pop(context);
                    Get.to(() => GroupInfoView(group: group));
                  },
                  isDark: isDark,
                ),

                Divider(height: 1, color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200),

                // Options for creator
                if (isCreator) ...[
                  _buildBottomSheetOption(
                    context: context,
                    icon: Icons.person_remove,
                    title: 'Gérer les membres',
                    color: AppThemeSystem.tertiaryColor,
                    onTap: () {
                      Navigator.pop(context);
                      controller.showMembersList();
                    },
                    isDark: isDark,
                  ),
                ],

                // Options for all members (except creator)
                if (!isCreator) ...[
                  _buildBottomSheetOption(
                    context: context,
                    icon: Icons.flag,
                    title: 'Signaler le groupe',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      _showReportDialog(context);
                    },
                    isDark: isDark,
                  ),
                  Divider(height: 1, color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200),
                  _buildBottomSheetOption(
                    context: context,
                    icon: Icons.exit_to_app,
                    title: 'Quitter le groupe',
                    color: Colors.grey,
                    onTap: () {
                      Navigator.pop(context);
                      _showLeaveGroupDialog(context);
                    },
                    isDark: isDark,
                  ),
                ],

                SizedBox(height: context.elementSpacing),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.horizontalPadding * 2,
          vertical: context.elementSpacing * 1.2,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: context.deviceType == DeviceType.mobile ? 24 : 28,
            ),
            SizedBox(width: context.elementSpacing * 1.5),
            Expanded(
              child: Text(
                title,
                style: context.textStyle(FontSizeType.body1).copyWith(
                  color: context.primaryTextColor,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.secondaryTextColor,
              size: context.deviceType == DeviceType.mobile ? 20 : 24,
            ),
          ],
        ),
      ),
    );
  }

  /// Show rename dialog
  void _showRenameDialog(BuildContext context) {
    final controller = Get.find<GroupeDetailController>();
    final textController = TextEditingController(text: controller.groupName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Renommer le groupe'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              hintText: 'Nouveau nom',
              border: OutlineInputBorder(),
            ),
            maxLength: 100,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                if (textController.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  controller.renameGroup(textController.text.trim());
                }
              },
              child: const Text('Renommer'),
            ),
          ],
        );
      },
    );
  }

  /// Show delete group dialog
  void _showDeleteGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer le groupe ?'),
          content: const Text(
            'Cette action est irréversible. Le groupe et tous ses messages seront supprimés définitivement.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                controller.deleteGroup();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  /// Show report dialog
  void _showReportDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedReason = 'spam';
    final descriptionController = TextEditingController();

    final reasons = {
      'spam': 'Spam',
      'harassment': 'Harcèlement',
      'inappropriate_content': 'Contenu inapproprié',
      'hate_speech': 'Discours haineux',
      'violence': 'Violence',
      'other': 'Autre',
    };

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Signaler le groupe'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Raison du signalement :'),
                    const SizedBox(height: 12),
                    ...reasons.entries.map((entry) {
                      return RadioListTile<String>(
                        title: Text(entry.value),
                        value: entry.key,
                        groupValue: selectedReason,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedReason = value;
                            });
                          }
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optionnel)',
                        hintText: 'Donnez plus de détails...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      maxLength: 1000,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    controller.reportGroup(
                      selectedReason,
                      descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                    );
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                  child: const Text('Signaler'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Show leave group dialog
  void _showLeaveGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Quitter le groupe ?'),
          content: const Text(
            'Vous ne recevrez plus les messages de ce groupe.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                controller.leaveGroup();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Quitter'),
            ),
          ],
        );
      },
    );
  }

  /// Construit les étincelles (sparkles) autour du cadeau
  List<Widget> _buildGiftSparkles(gift, int index) {
    // Couleur des étincelles basée sur la couleur d'arrière-plan du cadeau
    Color sparkleColor = AppThemeSystem.primaryColor;
    try {
      if (gift.backgroundColor != null && gift.backgroundColor.isNotEmpty) {
        final bgColor = gift.backgroundColor.replaceAll('#', '');
        sparkleColor = Color(int.parse('FF$bgColor', radix: 16));
      }
    } catch (_) {
      // Si parsing échoue, utiliser la couleur par défaut
    }

    final random = Random(index);
    const center = 20.0; // Centre du container (40/2)

    return List.generate(4, (i) {
      final angle = (i * pi / 2) + (random.nextDouble() * 0.5);
      final distance = 22.0 + (random.nextDouble() * 6);
      final size = 3.0 + (random.nextDouble() * 3);

      return Positioned(
        left: center + (cos(angle) * distance) - (size / 2),
        top: center + (sin(angle) * distance) - (size / 2),
        child: Flash(
          duration: Duration(milliseconds: 1500 + (i * 300)),
          infinite: true,
          delay: Duration(milliseconds: i * 200),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: sparkleColor.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: sparkleColor.withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
