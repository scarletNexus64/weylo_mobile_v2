import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';
import '../../../data/models/story_model.dart';
import '../../../widgets/verified_badge.dart';
import '../../../widgets/app_theme_system.dart';
import '../controllers/story_controller.dart';
import 'widgets/story_viewers_bottom_sheet.dart';

/// Full-screen story viewer with automatic progression
class StoryViewer extends StatefulWidget {
  const StoryViewer({Key? key}) : super(key: key);

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  final controller = Get.find<StoryController>();
  Timer? _progressTimer;
  final _currentProgress = 0.0.obs;
  final _isPaused = false.obs;
  final _replyController = TextEditingController();
  final _isSendingReply = false.obs;
  final _replyFocusNode = FocusNode();
  final _isLiking = false.obs;
  final _hasLiked = false.obs;
  final _replyText = ''.obs;

  @override
  void initState() {
    super.initState();

    // Initialize like state from story
    final currentStory = controller.currentStory;
    if (currentStory != null) {
      _hasLiked.value = currentStory.isLiked;
    }

    _startStoryTimer();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  void _startStoryTimer() {
    _progressTimer?.cancel();
    _currentProgress.value = 0.0;

    final currentStory = controller.currentStory;
    if (currentStory == null) return;

    // Update like state for the new story
    _hasLiked.value = currentStory.isLiked;

    // Mark as viewed
    controller.markStoryAsViewed(currentStory.id);

    final duration = currentStory.duration;
    const tickDuration = Duration(milliseconds: 50);
    final totalTicks = (duration * 1000) / tickDuration.inMilliseconds;

    _progressTimer = Timer.periodic(tickDuration, (timer) {
      if (_isPaused.value) return;

      _currentProgress.value += 1 / totalTicks;

      if (_currentProgress.value >= 1.0) {
        timer.cancel();
        _goToNextStory();
      }
    });
  }

  void _goToNextStory() {
    if (controller.currentStoryIndex.value < controller.currentUserStories.length - 1) {
      controller.nextStory();
      _startStoryTimer();
    } else {
      Get.back();
    }
  }

  void _goToPreviousStory() {
    if (controller.currentStoryIndex.value > 0) {
      controller.previousStory();
      _startStoryTimer();
    }
  }

  void _pauseStory() {
    _isPaused.value = true;
  }

  void _resumeStory() {
    _isPaused.value = false;
  }

  void _showViewersBottomSheet(StoryModel story) {
    // Pause story while viewing the list
    _pauseStory();

    Get.bottomSheet(
      StoryViewersBottomSheet(
        storyId: story.id,
        initialViewsCount: story.viewsCount,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    ).then((_) {
      // Resume story when bottomsheet is closed
      _resumeStory();
    });
  }

  Future<void> _sendReply(StoryModel story, {bool closeModal = false}) async {
    final message = _replyController.text.trim();
    if (message.isEmpty || _isSendingReply.value) return;

    // Remove focus to hide keyboard
    _replyFocusNode.unfocus();

    _isSendingReply.value = true;

    try {
      await controller.replyToStory(story.id, message);

      // Clear the text field
      _replyController.clear();

      // Close modal if requested
      if (closeModal && mounted) {
        Get.back();
      }

      // Resume story after sending
      _resumeStory();

      // Show success message
      Get.snackbar(
        'Envoyé',
        'Votre réponse a été envoyée à ${story.user.username}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppThemeSystem.successColor,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      _isSendingReply.value = false;
    }
  }

  void _showReplyModal(StoryModel story) {
    // Pause story when modal opens
    _pauseStory();

    final deviceType = AppThemeSystem.getDeviceType(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Reset reply text
    _replyText.value = '';
    _replyController.clear();

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppThemeSystem.getHorizontalPadding(context),
                  ),
                  child: Row(
                    children: [
                      // User avatar
                      CircleAvatar(
                        radius: deviceType == DeviceType.mobile ? 20 : 24,
                        backgroundColor: const Color(0xFF667eea),
                        backgroundImage: story.user.avatarUrl.isNotEmpty &&
                                       !story.user.avatarUrl.contains('ui-avatars.com')
                            ? NetworkImage(story.user.avatarUrl)
                            : null,
                        child: story.user.avatarUrl.isEmpty ||
                               story.user.avatarUrl.contains('ui-avatars.com')
                            ? Text(
                                story.user.username.isNotEmpty
                                    ? story.user.username[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: deviceType == DeviceType.mobile ? 18 : 22,
                                ),
                              )
                            : null,
                      ),
                      SizedBox(width: AppThemeSystem.getElementSpacing(context)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  story.user.username,
                                  style: AppThemeSystem.getTextStyle(
                                    context,
                                    FontSizeType.subtitle1,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (story.user.shouldShowBlueBadge) ...{
                                  const SizedBox(width: 4),
                                  const VerifiedBadge(size: 16, showBackground: false),
                                },
                              ],
                            ),
                            Text(
                              'Répondre à la story',
                              style: AppThemeSystem.getTextStyle(
                                context,
                                FontSizeType.caption,
                                color: isDark
                                    ? AppThemeSystem.grey400
                                    : AppThemeSystem.grey600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppThemeSystem.getElementSpacing(context)),

                // Text field
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppThemeSystem.getHorizontalPadding(context),
                  ),
                  child: TextField(
                    controller: _replyController,
                    focusNode: _replyFocusNode,
                    autofocus: true,
                    maxLines: 4,
                    minLines: 1,
                    maxLength: 500,
                    onChanged: (value) {
                      _replyText.value = value;
                    },
                    style: AppThemeSystem.getTextStyle(
                      context,
                      FontSizeType.body1,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Écrivez votre réponse...',
                      hintStyle: AppThemeSystem.getTextStyle(
                        context,
                        FontSizeType.body2,
                        color: isDark
                            ? AppThemeSystem.grey500
                            : AppThemeSystem.grey500,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppThemeSystem.grey800.withValues(alpha: 0.5)
                          : AppThemeSystem.grey100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppThemeSystem.grey700
                              : AppThemeSystem.grey300,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppThemeSystem.primaryColor,
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppThemeSystem.getHorizontalPadding(context),
                        vertical: AppThemeSystem.getElementSpacing(context) * 1.2,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: AppThemeSystem.getElementSpacing(context) * 1.5),

                // Send button
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppThemeSystem.getHorizontalPadding(context),
                  ),
                  child: Obx(() => SizedBox(
                        width: double.infinity,
                        height: AppThemeSystem.getButtonHeight(context),
                        child: ElevatedButton(
                          onPressed: _isSendingReply.value ||
                                  _replyText.value.trim().isEmpty
                              ? null
                              : () => _sendReply(story, closeModal: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _replyText.value.trim().isNotEmpty
                                ? AppThemeSystem.primaryColor
                                : (isDark
                                    ? AppThemeSystem.grey800
                                    : AppThemeSystem.grey300),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: isDark
                                ? AppThemeSystem.grey800
                                : AppThemeSystem.grey300,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppThemeSystem.getButtonHeight(context) / 2,
                              ),
                            ),
                            elevation: _replyText.value.trim().isNotEmpty ? 2 : 0,
                          ),
                          child: _isSendingReply.value
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: AppThemeSystem.getElementSpacing(context),
                                    ),
                                    Text(
                                      'Envoi en cours...',
                                      style: AppThemeSystem.getTextStyle(
                                        context,
                                        FontSizeType.button,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Envoyer',
                                  style: AppThemeSystem.getTextStyle(
                                    context,
                                    FontSizeType.button,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      )),
                ),

                SizedBox(
                  height: AppThemeSystem.getElementSpacing(context) * 2,
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
    ).then((_) {
      // Resume story when modal is closed
      _replyController.clear();
      _resumeStory();
    });
  }

  Future<void> _likeStory(StoryModel story) async {
    if (_isLiking.value || _hasLiked.value) return;

    _isLiking.value = true;

    try {
      await controller.likeStory(story.id);
      _hasLiked.value = true;
    } finally {
      _isLiking.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        final story = controller.currentStory;
        if (story == null) {
          return Center(child: CircularProgressIndicator(color: Colors.white));
        }

        return GestureDetector(
          onTapDown: (details) {
            _pauseStory();
          },
          onTapUp: (details) {
            // Ne pas reprendre la story si le champ de réponse a le focus
            if (!_replyFocusNode.hasFocus) {
              _resumeStory();
            }

            // Detect tap position for navigation
            final screenWidth = MediaQuery.of(context).size.width;
            if (details.globalPosition.dx < screenWidth / 3) {
              // Tapped left third - go to previous
              _progressTimer?.cancel();
              _goToPreviousStory();
            } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
              // Tapped right third - go to next
              _progressTimer?.cancel();
              _goToNextStory();
            }
          },
          onTapCancel: () {
            // Ne pas reprendre la story si le champ de réponse a le focus
            if (!_replyFocusNode.hasFocus) {
              _resumeStory();
            }
          },
          child: Stack(
            children: [
              // Story content
              _buildStoryContent(story),

              // Progress bars
              SafeArea(
                child: Column(
                  children: [
                    _buildProgressBars(),
                    const SizedBox(height: 8),
                    _buildHeader(story),
                  ],
                ),
              ),

              // Action buttons (only for my stories)
              if (story.isOwner)
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 40,
                  left: 0,
                  right: 0,
                  child: _buildActionButtons(story),
                ),

              // Reply input (only for others' stories)
              if (!story.isOwner)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildReplyInput(story),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStoryContent(StoryModel story) {
    if (story.isVideoType && story.mediaUrl != null) {
      return _VideoStoryPlayer(
        videoUrl: story.mediaUrl!,
        caption: story.content,
      );
    } else if (story.isImageType && story.mediaUrl != null) {
      return Stack(
        children: [
          // Image
          Center(
            child: Image.network(
              story.mediaUrl!,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                    color: Colors.white,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(Icons.error, color: Colors.white, size: 48),
                );
              },
            ),
          ),

          // Caption en bas si elle existe
          if (story.content != null && story.content!.isNotEmpty)
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  story.content!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        offset: Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    } else if (story.isTextType && story.content != null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _getGradientColors(story.displayBackgroundColor),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              story.content!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Center(
      child: Text(
        'Type de story non supporté',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildProgressBars() {
    return Obx(() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(
              controller.currentUserStories.length,
              (index) {
                final isCurrent = index == controller.currentStoryIndex.value;
                final isPast = index < controller.currentStoryIndex.value;

                return Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: isPast ? 1.0 : (isCurrent ? _currentProgress.value : 0.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ));
  }

  Widget _buildHeader(StoryModel story) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // User avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF667eea),
            backgroundImage: story.user.avatarUrl.isNotEmpty &&
                           !story.user.avatarUrl.contains('ui-avatars.com')
                ? NetworkImage(story.user.avatarUrl)
                : null,
            child: story.user.avatarUrl.isEmpty ||
                   story.user.avatarUrl.contains('ui-avatars.com')
                ? Text(
                    story.user.username.isNotEmpty
                        ? story.user.username[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      story.user.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (story.user.shouldShowBlueBadge) ...[
                      const SizedBox(width: 4),
                      const VerifiedBadge(size: 14, showBackground: false),
                    ],
                  ],
                ),
                Text(
                  _getTimeAgo(story.createdAt),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Close button
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(StoryModel story) {
    final deviceType = AppThemeSystem.getDeviceType(context);
    final elementSpacing = AppThemeSystem.getElementSpacing(context);
    final horizontalPadding = AppThemeSystem.getHorizontalPadding(context);

    // Tailles responsive
    final buttonSize = deviceType == DeviceType.mobile ? 52.0 : 58.0;
    final iconSize = deviceType == DeviceType.mobile ? 22.0 : 26.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Views count - Left (Clickable) avec design moderne
          GestureDetector(
            onTap: () => _showViewersBottomSheet(story),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding * 1.2,
                vertical: elementSpacing,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(buttonSize / 2),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.visibility_rounded,
                    color: Colors.white,
                    size: iconSize,
                  ),
                  SizedBox(width: elementSpacing * 0.6),
                  Text(
                    '${story.viewsCount}',
                    style: AppThemeSystem.getTextStyle(
                      context,
                      FontSizeType.body1,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Delete button - Right avec design moderne
          GestureDetector(
            onTap: () async {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final confirm = await Get.dialog<bool>(
                AlertDialog(
                  backgroundColor: isDark
                      ? AppThemeSystem.darkCardColor
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(
                    'Supprimer la story ?',
                    style: AppThemeSystem.getTextStyle(
                      context,
                      FontSizeType.h6,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Text(
                    'Cette action est irréversible.',
                    style: AppThemeSystem.getTextStyle(
                      context,
                      FontSizeType.body2,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(result: false),
                      child: Text(
                        'Annuler',
                        style: AppThemeSystem.getTextStyle(
                          context,
                          FontSizeType.button,
                          color: isDark
                              ? AppThemeSystem.grey400
                              : AppThemeSystem.grey700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Get.back(result: true),
                      child: Text(
                        'Supprimer',
                        style: AppThemeSystem.getTextStyle(
                          context,
                          FontSizeType.button,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await controller.deleteStory(story.id);
                if (controller.currentUserStories.isEmpty) {
                  Get.back();
                } else {
                  _startStoryTimer();
                }
              }
            },
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.shade400,
                    Colors.red.shade600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.delete_rounded,
                color: Colors.white,
                size: iconSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyInput(StoryModel story) {
    final deviceType = AppThemeSystem.getDeviceType(context);
    final elementSpacing = AppThemeSystem.getElementSpacing(context);
    final horizontalPadding = AppThemeSystem.getHorizontalPadding(context);

    // Tailles responsive pour les boutons
    final buttonSize = deviceType == DeviceType.mobile ? 52.0 : 58.0;
    final iconSize = deviceType == DeviceType.mobile ? 24.0 : 28.0;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + elementSpacing * 3,
        top: elementSpacing * 2,
        left: horizontalPadding,
        right: horizontalPadding,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.7),
            Colors.black.withValues(alpha: 0.85),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bouton Like avec animation
            Obx(() => GestureDetector(
                  onTap: _isLiking.value || _hasLiked.value
                      ? null
                      : () => _likeStory(story),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: buttonSize,
                    height: buttonSize,
                    decoration: BoxDecoration(
                      gradient: _hasLiked.value
                          ? LinearGradient(
                              colors: [
                                Colors.pink.shade400,
                                Colors.red.shade500,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: _hasLiked.value
                          ? null
                          : Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _hasLiked.value
                            ? Colors.transparent
                            : Colors.white.withValues(alpha: 0.2),
                        width: 2,
                      ),
                      boxShadow: _hasLiked.value
                          ? [
                              BoxShadow(
                                color: Colors.pink.withValues(alpha: 0.5),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: _isLiking.value
                        ? Center(
                            child: SizedBox(
                              width: iconSize * 0.7,
                              height: iconSize * 0.7,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Icon(
                            _hasLiked.value ? Icons.favorite : Icons.favorite_border,
                            color: Colors.white,
                            size: iconSize,
                          ),
                  ),
                )),

            SizedBox(width: elementSpacing * 2),

            // Bouton Répondre pour ouvrir le modal
            GestureDetector(
              onTap: () => _showReplyModal(story),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding * 1.8,
                  vertical: elementSpacing * 0.9,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppThemeSystem.primaryColor,
                      AppThemeSystem.secondaryColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(buttonSize / 2),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppThemeSystem.primaryColor.withValues(alpha: 0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.reply_rounded,
                      color: Colors.white,
                      size: iconSize * 0.9,
                    ),
                    SizedBox(width: elementSpacing * 0.6),
                    Text(
                      'Répondre à ${story.user.username}',
                      style: AppThemeSystem.getTextStyle(
                        context,
                        FontSizeType.body2,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getGradientColors(String hexColor) {
    // Parse hex color and create gradient
    final color = _parseHexColor(hexColor);
    return [
      color,
      color.withValues(alpha: 0.7),
    ];
  }

  Color _parseHexColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return 'Il y a ${difference.inDays}j';
    }
  }
}

/// Widget pour afficher une vidéo dans la story
class _VideoStoryPlayer extends StatefulWidget {
  final String videoUrl;
  final String? caption;

  const _VideoStoryPlayer({
    required this.videoUrl,
    this.caption,
  });

  @override
  State<_VideoStoryPlayer> createState() => _VideoStoryPlayerState();
}

class _VideoStoryPlayerState extends State<_VideoStoryPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation de la vidéo: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.white, size: 48),
            SizedBox(height: 16),
            Text(
              'Erreur de lecture vidéo',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      children: [
        // Vidéo
        Center(
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),
        ),

        // Caption en bas si elle existe
        if (widget.caption != null && widget.caption!.isNotEmpty)
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Text(
                widget.caption!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      offset: Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
