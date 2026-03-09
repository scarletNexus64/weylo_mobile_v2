import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:shimmer/shimmer.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';

class FeedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String videoId;

  const FeedVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.videoId,
  });

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isMuted = true;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _controller.initialize();
      _controller.setLooping(true);
      _controller.setVolume(_isMuted ? 0.0 : 1.0);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });

        // Si le widget est visible, démarrer la lecture
        if (_isVisible) {
          _controller.play();
        }
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

  Future<void> _retryVideo() async {
    if (mounted) {
      setState(() {
        _hasError = false;
        _isInitialized = false;
      });
      await _initializeVideo();
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final isVisible = info.visibleFraction > 0.5; // Visible à plus de 50%

    if (mounted) {
      setState(() {
        _isVisible = isVisible;
      });
    }

    if (_isInitialized) {
      if (isVisible && !_controller.value.isPlaying) {
        _controller.play();
      } else if (!isVisible && _controller.value.isPlaying) {
        _controller.pause();
      }
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    setState(() {});
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return VisibilityDetector(
      key: Key('video_${widget.videoId}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: GestureDetector(
        onTap: _togglePlayPause,
        child: Container(
          width: double.infinity,
          height: 320,
          color: Colors.black,
          child: _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.white54,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Impossible de charger la vidéo',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _retryVideo,
                        icon: Icon(Icons.refresh),
                        label: Text('Réessayer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemeSystem.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                )
              : !_isInitialized
                  ? Shimmer.fromColors(
                      baseColor: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
                      highlightColor: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey100,
                      child: Container(
                        width: double.infinity,
                        height: 320,
                        color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
                      ),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        // Vidéo
                        Center(
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          ),
                        ),

                        // Indicateur pause (affiché temporairement)
                        if (!_controller.value.isPlaying)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),

                        // Bouton mute/unmute en haut à droite
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _toggleMute,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isMuted ? Icons.volume_off : Icons.volume_up,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),

                        // Barre de progression en bas
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: VideoProgressIndicator(
                            _controller,
                            allowScrubbing: true,
                            colors: VideoProgressColors(
                              playedColor: AppThemeSystem.primaryColor,
                              bufferedColor: Colors.white.withValues(alpha: 0.3),
                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 2),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
