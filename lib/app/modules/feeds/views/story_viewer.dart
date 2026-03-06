import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';
import '../../../data/models/story_model.dart';
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

  @override
  void initState() {
    super.initState();
    _startStoryTimer();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  void _startStoryTimer() {
    _progressTimer?.cancel();
    _currentProgress.value = 0.0;

    final currentStory = controller.currentStory;
    if (currentStory == null) return;

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
            _resumeStory();

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
            _resumeStory();
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
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: _buildActionButtons(story),
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
                      Colors.black.withOpacity(0.6),
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
                        color: Colors.black.withOpacity(0.5),
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
                    color: Colors.black.withOpacity(0.3),
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
                      color: Colors.white.withOpacity(0.3),
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
                Text(
                  story.user.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _getTimeAgo(story.createdAt),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Views count - Left (Clickable)
          GestureDetector(
            onTap: () => _showViewersBottomSheet(story),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.visibility, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${story.viewsCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Delete button - Right
          FloatingActionButton(
            mini: true,
            backgroundColor: Colors.red.withOpacity(0.8),
            onPressed: () async {
              final confirm = await Get.dialog<bool>(
                AlertDialog(
                  title: const Text('Supprimer la story ?'),
                  content: const Text('Cette action est irréversible.'),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(result: false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Get.back(result: true),
                      child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                // Delete story first, then close viewer
                await controller.deleteStory(story.id);

                // If there are still stories left, stay in viewer
                // Otherwise, close the viewer
                if (controller.currentUserStories.isEmpty) {
                  Get.back(); // Close viewer
                } else {
                  // Restart timer for the current story (which is now a different one)
                  _startStoryTimer();
                }
              }
            },
            child: const Icon(Icons.delete, color: Colors.white),
          ),
        ],
      ),
    );
  }

  List<Color> _getGradientColors(String hexColor) {
    // Parse hex color and create gradient
    final color = _parseHexColor(hexColor);
    return [
      color,
      color.withOpacity(0.7),
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
                    Colors.black.withOpacity(0.6),
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
                      color: Colors.black.withOpacity(0.5),
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
