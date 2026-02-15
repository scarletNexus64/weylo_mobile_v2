import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';
import '../controllers/groupe_detail_controller.dart';

class GroupeDetailView extends GetView<GroupeDetailController> {
  const GroupeDetailView({super.key});

  // Cache pour les positions du background
  static List<Map<String, dynamic>>? _cachedBackgroundPositions;

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
            CircleAvatar(
              radius: 20,
              backgroundColor: AppThemeSystem.tertiaryColor,
              child: const Icon(
                Icons.group_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
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
            onPressed: () {},
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
    final screenSize = MediaQuery.of(context).size;

    print('📐 [GroupeBackground] Building pattern - screenSize: ${screenSize.width}x${screenSize.height}');

    // Icons pour le background
    final backgroundIcons = [
      '💬', '❤️', '⭐', '✨', '🎁', '😊', '👍', '🔥',
      '💕', '💐', '🌹', '☕', '🍕', '🍷', '💎', '👑',
      '🎈', '🎆', '💫', '🌟', '📧', '💌', '🎉', '🎊'
    ];

    // Calculer les positions une seule fois (ou les régénérer si la taille d'écran a changé)
    if (_cachedBackgroundPositions == null || _cachedBackgroundPositions!.isEmpty) {
      print('🔄 [GroupeBackground] Generating NEW positions (first time or cache empty)');
      _cachedBackgroundPositions = [];
      final random = Random(42); // Seed fixe pour cohérence

      for (var i = 0; i < 150; i++) {
        final icon = backgroundIcons[i % backgroundIcons.length];
        final x = random.nextDouble() * screenSize.width;
        final y = random.nextDouble() * (screenSize.height * 1.5);
        final size = 24.0 + (random.nextDouble() * 28); // 24-52px
        final rotation = random.nextDouble() * 6.28; // 0-360°
        final opacity = 0.12 + (random.nextDouble() * 0.18); // 0.12-0.30

        _cachedBackgroundPositions!.add({
          'icon': icon,
          'x': x,
          'y': y,
          'size': size,
          'rotation': rotation,
          'opacity': opacity,
        });
      }
      print('✅ [GroupeBackground] Generated ${_cachedBackgroundPositions!.length} positions');
    } else {
      print('♻️ [GroupeBackground] Using CACHED positions (${_cachedBackgroundPositions!.length} items)');
    }

    // Construire les widgets à partir des positions cachées
    final positions = <Widget>[];
    for (var data in _cachedBackgroundPositions!) {
      positions.add(
        Positioned(
          left: data['x'] - data['size'] / 2,
          top: data['y'] - data['size'] / 2,
          child: Transform.rotate(
            angle: data['rotation'],
            child: Opacity(
              opacity: isDark ? data['opacity'] : data['opacity'] * 0.8,
              child: Text(
                data['icon'],
                style: TextStyle(
                  fontSize: data['size'],
                  color: isDark ? Colors.white : Colors.black,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
      );
    }

    print('🎨 [GroupeBackground] Rendering ${positions.length} emoji widgets');

    return Positioned.fill(
      child: Container(
        color: Colors.transparent,
        child: IgnorePointer(
          child: Stack(
            clipBehavior: Clip.none,
            children: positions,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, GroupMessage message, bool isDark) {
    return Align(
      alignment: message.isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: context.elementSpacing * 0.5,
          left: message.isSentByMe ? context.horizontalPadding * 2 : 0,
          right: message.isSentByMe ? 0 : context.horizontalPadding * 2,
        ),
        child: Column(
          crossAxisAlignment: message.isSentByMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Sender name for group messages (only for received messages)
            if (!message.isSentByMe && message.senderName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 12, right: 12),
                child: Text(
                  message.senderName!,
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
                gradient: message.isSentByMe
                    ? const LinearGradient(
                        colors: [
                          AppThemeSystem.primaryColor,
                          AppThemeSystem.secondaryColor,
                        ],
                      )
                    : null,
                color: message.isSentByMe
                    ? null
                    : (isDark
                        ? AppThemeSystem.darkCardColor
                        : AppThemeSystem.grey100),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isSentByMe ? 16 : 4),
                  bottomRight: Radius.circular(message.isSentByMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: message.isSentByMe
                        ? AppThemeSystem.primaryColor.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildMessageContent(context, message, isDark),
            ),

            // Timestamp
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
              child: Text(
                _formatTime(message.timestamp),
                style: context.textStyle(FontSizeType.caption).copyWith(
                  color: AppThemeSystem.grey600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, GroupMessage message, bool isDark) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: context.textStyle(FontSizeType.body2).copyWith(
            color: message.isSentByMe
                ? Colors.white
                : (isDark ? Colors.white : AppThemeSystem.blackColor),
          ),
        );

      case MessageType.gift:
        return Column(
          children: [
            Text(
              message.giftIcon ?? '🎁',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 4),
            Text(
              message.giftName ?? 'Cadeau',
              style: context.textStyle(FontSizeType.caption).copyWith(
                color: message.isSentByMe
                    ? Colors.white
                    : (isDark ? Colors.white : AppThemeSystem.blackColor),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );

      case MessageType.audio:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_circle_filled_rounded,
              color: message.isSentByMe
                  ? Colors.white
                  : AppThemeSystem.primaryColor,
              size: 32,
            ),
            const SizedBox(width: 8),
            Container(
              width: 100,
              height: 4,
              decoration: BoxDecoration(
                color: message.isSentByMe
                    ? Colors.white.withValues(alpha: 0.3)
                    : AppThemeSystem.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.4,
                child: Container(
                  decoration: BoxDecoration(
                    color: message.isSentByMe
                        ? Colors.white
                        : AppThemeSystem.primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '0:15',
              style: context.textStyle(FontSizeType.caption).copyWith(
                color: message.isSentByMe
                    ? Colors.white
                    : AppThemeSystem.grey600,
              ),
            ),
          ],
        );

      case MessageType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 200,
            height: 200,
            color: AppThemeSystem.grey300,
            child: const Icon(
              Icons.image_rounded,
              size: 64,
              color: AppThemeSystem.grey600,
            ),
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
            return SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: context.elementSpacing),
                children: controller.giftCategories.keys.map((category) {
                  final isSelected = controller.selectedGiftCategory.value == category;
                  return GestureDetector(
                    onTap: () => controller.selectGiftCategory(category),
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
                        category,
                        style: context.textStyle(FontSizeType.body2).copyWith(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppThemeSystem.grey300 : AppThemeSystem.grey700),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),

          const SizedBox(height: 12),

          // Gift grid
          Expanded(
            child: Obx(() {
              final category = controller.selectedGiftCategory.value;
              final gifts = controller.giftCategories[category] ?? [];

              return GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: context.elementSpacing),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: gifts.length,
                itemBuilder: (context, index) {
                  final gift = gifts[index];
                  final price = gift['price'] as int;

                  return GestureDetector(
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
                          Text(
                            gift['icon'].toString(),
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            gift['name'].toString(),
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
                              '${_formatPrice(price)} XAF',
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
      child: SafeArea(
        child: Row(
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
              onPressed: () {
                // Simulate image picker
                controller.sendImage('fake_image.jpg');
              },
              color: AppThemeSystem.tertiaryColor,
            ),

            // Input field
            Expanded(
              child: TextField(
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
                    : () => controller.toggleRecording(),
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
}
