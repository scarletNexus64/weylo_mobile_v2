import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../controllers/story_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../../widgets/app_theme_system.dart';
import '../../../routes/app_pages.dart';

/// Écran d'aperçu et édition d'une story photo/vidéo
class StoryPreviewEditView extends StatefulWidget {
  final String mediaPath;
  final String mediaType; // 'photo' ou 'video'

  const StoryPreviewEditView({
    Key? key,
    required this.mediaPath,
    required this.mediaType,
  }) : super(key: key);

  @override
  State<StoryPreviewEditView> createState() => _StoryPreviewEditViewState();
}

class _StoryPreviewEditViewState extends State<StoryPreviewEditView> {
  final controller = Get.find<StoryController>();
  final _captionController = TextEditingController();
  final _captionFocusNode = FocusNode();

  // Video player controller
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasVideoError = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.mediaType == 'video') {
      _initializeVideoPlayer();
    }
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      _videoController = VideoPlayerController.file(File(widget.mediaPath));
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      // NE PAS auto-play - l'utilisateur doit taper pour jouer

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation de la vidéo de prévisualisation: $e');
      if (mounted) {
        setState(() {
          _hasVideoError = true;
        });
      }
    }
  }

  void _togglePlayPause() {
    if (_videoController == null || !_isVideoInitialized) return;

    setState(() {
      if (_isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
      } else {
        _videoController!.play();
        _isPlaying = true;
      }
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    _captionFocusNode.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _postStory() async {
    final caption = _captionController.text.trim();

    // Détecter si c'est une image ou une vidéo
    final bool success;
    if (widget.mediaType == 'video') {
      success = await controller.createVideoStory(
        videoPath: widget.mediaPath,
        duration: 15, // 15 secondes pour une vidéo
        caption: caption.isEmpty ? null : caption,
      );
    } else {
      success = await controller.createImageStory(
        imagePath: widget.mediaPath,
        duration: 5,
        caption: caption.isEmpty ? null : caption,
      );
    }

    if (success) {
      if (!mounted) return;

      // Navigate back to Home page (until we find it or reach the first route)
      Get.until((route) => route.settings.name == Routes.HOME || route.isFirst);

      // Wait for navigation to complete
      await Future.delayed(const Duration(milliseconds: 150));

      // Change to Feeds/Confession tab (index 3) to show the new story
      try {
        final homeController = Get.find<HomeController>();
        homeController.changeTab(3);
      } catch (e) {
        print('⚠️ HomeController not found, navigating to Home: $e');
        // If HomeController not found, navigate to Home explicitly
        Get.offAllNamed(Routes.HOME);

        // Wait for Home to initialize
        await Future.delayed(const Duration(milliseconds: 200));

        // Try to change tab again
        try {
          final homeController = Get.find<HomeController>();
          homeController.changeTab(3);
        } catch (e) {
          print('⚠️ Unable to change tab after navigation: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = context.deviceType;
    final elementSpacing = context.elementSpacing;
    final horizontalPadding = context.horizontalPadding;

    // Tailles responsive
    final iconSize = deviceType == DeviceType.mobile ? 28.0 : 32.0;
    final videoIconSize = deviceType == DeviceType.mobile ? 64.0 : 80.0;
    final buttonHeight = deviceType == DeviceType.mobile ? 54.0 : 60.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Aperçu de la photo/vidéo
          Center(
            child: widget.mediaType == 'photo'
                ? Image.file(
                    File(widget.mediaPath),
                    fit: BoxFit.contain,
                  )
                : _buildVideoPreview(videoIconSize, elementSpacing, context),
          ),

          // Top bar avec bouton fermer
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(horizontalPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: iconSize,
                    ),
                    onPressed: () => Get.back(),
                  ),
                  SizedBox(width: iconSize + 16), // Pour équilibrer
                ],
              ),
            ),
          ),

          // Bottom section avec caption et bouton publier
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.9),
                  ],
                ),
              ),
              padding: EdgeInsets.only(
                // Combine clavier (viewInsets) et barre de navigation système (padding)
                bottom: MediaQuery.of(context).viewInsets.bottom +
                       MediaQuery.of(context).padding.bottom,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: elementSpacing,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      // Champ de texte pour la caption
                      Container(
                        decoration: BoxDecoration(
                          // ✅ Respecte le thème dark/light
                          color: isDark
                              ? AppThemeSystem.grey800.withValues(alpha: 0.95)
                              : AppThemeSystem.whiteColor.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(20),
                          border: isDark
                              ? Border.all(
                                  color: AppThemeSystem.grey700,
                                  width: 1,
                                )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding * 0.9,
                          vertical: elementSpacing * 0.3,
                        ),
                        child: TextField(
                          controller: _captionController,
                          focusNode: _captionFocusNode,
                          style: context.textStyle(FontSizeType.body2).copyWith(
                            // ✅ Couleur adaptative
                            color: isDark
                                ? AppThemeSystem.grey100
                                : AppThemeSystem.grey900,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          minLines: 1,
                          maxLength: 200,
                          textAlign: TextAlign.start,
                          decoration: InputDecoration(
                            hintText: 'Ajouter une légende...',
                            hintStyle: context.textStyle(FontSizeType.body2).copyWith(
                              // ✅ Hint adaptatif
                              color: isDark
                                  ? AppThemeSystem.grey500
                                  : AppThemeSystem.grey500,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: elementSpacing * 0.7,
                              horizontal: 2,
                            ),
                            counterStyle: context.textStyle(FontSizeType.caption).copyWith(
                              // ✅ Counter adaptatif
                              color: isDark
                                  ? AppThemeSystem.grey500
                                  : AppThemeSystem.grey600,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: elementSpacing),

                      // Bouton publier
                      Obx(() => Container(
                            width: double.infinity,
                            height: buttonHeight,
                            decoration: BoxDecoration(
                              gradient: controller.isCreatingStory.value
                                  ? null
                                  : LinearGradient(
                                      colors: [
                                        AppThemeSystem.primaryColor,
                                        AppThemeSystem.secondaryColor,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              color: controller.isCreatingStory.value
                                  ? AppThemeSystem.grey700
                                  : null,
                              borderRadius: BorderRadius.circular(buttonHeight / 2),
                              boxShadow: controller.isCreatingStory.value
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: AppThemeSystem.primaryColor.withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: controller.isCreatingStory.value ? null : _postStory,
                                borderRadius: BorderRadius.circular(buttonHeight / 2),
                                child: Center(
                                  child: controller.isCreatingStory.value
                                      ? Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              height: 22,
                                              width: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: elementSpacing * 0.75),
                                            Text(
                                              'Envoi en cours ${(controller.uploadProgress.value * 100).toInt()}%',
                                              style: context.textStyle(FontSizeType.body2).copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          'Publier ma story',
                                          style: context.textStyle(FontSizeType.button).copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview(double videoIconSize, double elementSpacing, BuildContext context) {
    // Afficher l'erreur si la vidéo n'a pas pu être chargée
    if (_hasVideoError) {
      return Container(
        color: AppThemeSystem.grey800,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: videoIconSize,
              ),
              SizedBox(height: elementSpacing),
              Text(
                'Erreur de chargement de la vidéo',
                style: context.textStyle(FontSizeType.body1).copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Afficher le loader pendant le chargement
    if (!_isVideoInitialized || _videoController == null) {
      return Container(
        color: AppThemeSystem.grey800,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppThemeSystem.primaryColor,
                strokeWidth: 3,
              ),
              SizedBox(height: elementSpacing),
              Text(
                'Chargement de la vidéo...',
                style: context.textStyle(FontSizeType.body1).copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Afficher la vidéo avec contrôles play/pause
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Vidéo
          Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          ),

          // Bouton play/pause
          if (!_isPlaying)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: videoIconSize,
              ),
            ),
        ],
      ),
    );
  }
}
