import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_native_video_trimmer/flutter_native_video_trimmer.dart';
import '../widgets/app_theme_system.dart';

/// Page pour rogner/trimmer une vidéo avant de créer une story
class VideoTrimmerPage extends StatefulWidget {
  final String videoPath;

  const VideoTrimmerPage({
    super.key,
    required this.videoPath,
  });

  @override
  State<VideoTrimmerPage> createState() => _VideoTrimmerPageState();
}

class _VideoTrimmerPageState extends State<VideoTrimmerPage> {
  VideoPlayerController? _videoController;
  bool _isLoading = true;
  bool _isSaving = false;
  double _startValue = 0.0;
  double _endValue = 0.0;
  double _currentPosition = 0.0;
  bool _isPlaying = false;
  final _trimmer = VideoTrimmer();

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    setState(() => _isLoading = true);

    try {
      _videoController = VideoPlayerController.file(File(widget.videoPath));
      await _videoController!.initialize();

      // Écouter la position de la vidéo
      _videoController!.addListener(_videoListener);

      final duration = _videoController!.value.duration;

      if (mounted) {
        setState(() {
          _startValue = 0.0;
          _endValue = duration.inMilliseconds.toDouble();
          _currentPosition = 0.0;
          _isLoading = false;
        });

        print('✅ Vidéo chargée : durée = ${duration.inSeconds} secondes');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement de la vidéo: $e');

      if (mounted) {
        Get.snackbar(
          'Erreur',
          'Impossible de charger la vidéo',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        Get.back();
      }
    }
  }

  void _videoListener() {
    if (_videoController != null && mounted) {
      final position = _videoController!.value.position.inMilliseconds.toDouble();

      // Arrêter si on dépasse la fin sélectionnée
      if (position >= _endValue) {
        _videoController!.pause();
        _videoController!.seekTo(Duration(milliseconds: _startValue.toInt()));
        setState(() => _isPlaying = false);
      } else if (position < _startValue) {
        _videoController!.seekTo(Duration(milliseconds: _startValue.toInt()));
      }

      setState(() {
        _currentPosition = position;
      });
    }
  }

  void _togglePlayPause() {
    if (_videoController == null) return;

    setState(() {
      if (_isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
      } else {
        // Si on est à la fin, recommencer au début
        if (_currentPosition >= _endValue || _currentPosition < _startValue) {
          _videoController!.seekTo(Duration(milliseconds: _startValue.toInt()));
        }
        _videoController!.play();
        _isPlaying = true;
      }
    });
  }

  Future<void> _saveVideo() async {
    setState(() => _isSaving = true);

    try {
      final startSeconds = (_startValue / 1000);
      final endSeconds = (_endValue / 1000);
      final totalDuration = endSeconds - startSeconds;

      print('🎬 Rognage : start=${startSeconds}s, end=${endSeconds}s, duration=${totalDuration}s');

      // Vérifier que la sélection est valide
      if (totalDuration < 1) {
        _showError('La vidéo doit durer au moins 1 seconde');
        setState(() => _isSaving = false);
        return;
      }

      // Si la vidéo entière est sélectionnée, retourner l'originale
      final videoDuration = _videoController!.value.duration.inMilliseconds.toDouble();
      if (_startValue < 1000 && (_endValue >= videoDuration - 1000)) {
        print('✅ Vidéo complète sélectionnée');
        Get.back(result: File(widget.videoPath));
        return;
      }

      // Charger la vidéo dans le trimmer
      await _trimmer.loadVideo(widget.videoPath);

      // Rogner la vidéo avec l'API native
      final outputPath = await _trimmer.trimVideo(
        startTimeMs: _startValue.toInt(),
        endTimeMs: _endValue.toInt(),
        includeAudio: true,
      );

      if (outputPath == null) {
        throw Exception('Le rognage a échoué, aucun fichier créé');
      }

      // Vérifier que le fichier existe
      final outputFile = File(outputPath);
      if (await outputFile.exists()) {
        print('✅ Vidéo rognée : $outputPath');

        // NE PAS nettoyer le cache ici - le fichier est encore nécessaire
        // pour la vue de prévisualisation et l'upload
        // Le cache sera nettoyé automatiquement par le système

        if (mounted) {
          Get.back(result: outputFile);
        }
      } else {
        throw Exception('Le fichier rogné n\'a pas été créé');
      }
    } catch (e) {
      print('❌ Erreur lors du rognage: $e');

      if (mounted) {
        _showError('Impossible de rogner la vidéo: ${e.toString()}');
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Erreur',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  String _formatDuration(double milliseconds) {
    final duration = Duration(milliseconds: milliseconds.toInt());
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _isSaving ? null : () => Get.back(result: null),
        ),
        title: Text(
          'Rogner la vidéo',
          style: context.textStyle(FontSizeType.h6).copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_isLoading && !_isSaving)
            TextButton(
              onPressed: _saveVideo,
              child: Text(
                'Terminé',
                style: context.textStyle(FontSizeType.button).copyWith(
                  color: AppThemeSystem.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (_isSaving)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppThemeSystem.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chargement de la vidéo...',
                    style: context.textStyle(FontSizeType.body1).copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Video player avec contrôles play/pause
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_videoController!.value.isInitialized)
                        Center(
                          child: AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          ),
                        ),

                      // Bouton play/pause
                      GestureDetector(
                        onTap: _togglePlayPause,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Contrôles de rognage
                Container(
                  color: isDark ? AppThemeSystem.darkCardColor : Colors.grey[900],
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Durées
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_startValue),
                            style: context.textStyle(FontSizeType.body2).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Durée: ${_formatDuration(_endValue - _startValue)}',
                            style: context.textStyle(FontSizeType.body2).copyWith(
                              color: AppThemeSystem.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatDuration(_endValue),
                            style: context.textStyle(FontSizeType.body2).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Barre de progression
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
                        ),
                        child: Slider(
                          value: _currentPosition.clamp(_startValue, _endValue),
                          min: 0,
                          max: _videoController!.value.duration.inMilliseconds.toDouble(),
                          activeColor: Colors.white.withValues(alpha: 0.3),
                          inactiveColor: Colors.white.withValues(alpha: 0.1),
                          onChanged: null,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Slider de début
                      Row(
                        children: [
                          Icon(Icons.first_page, color: AppThemeSystem.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: AppThemeSystem.primaryColor,
                                inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                                thumbColor: AppThemeSystem.primaryColor,
                                overlayColor: AppThemeSystem.primaryColor.withValues(alpha: 0.2),
                              ),
                              child: Slider(
                                value: _startValue,
                                min: 0,
                                max: _endValue - 1000, // Au moins 1 seconde
                                label: 'Début: ${_formatDuration(_startValue)}',
                                onChanged: (value) {
                                  setState(() {
                                    _startValue = value;
                                    if (_currentPosition < _startValue) {
                                      _videoController!.seekTo(Duration(milliseconds: value.toInt()));
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                          Text(
                            'Début',
                            style: context.textStyle(FontSizeType.caption).copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),

                      // Slider de fin
                      Row(
                        children: [
                          Icon(Icons.last_page, color: AppThemeSystem.secondaryColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: AppThemeSystem.secondaryColor,
                                inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                                thumbColor: AppThemeSystem.secondaryColor,
                                overlayColor: AppThemeSystem.secondaryColor.withValues(alpha: 0.2),
                              ),
                              child: Slider(
                                value: _endValue,
                                min: _startValue + 1000, // Au moins 1 seconde
                                max: _videoController!.value.duration.inMilliseconds.toDouble(),
                                label: 'Fin: ${_formatDuration(_endValue)}',
                                onChanged: (value) {
                                  setState(() {
                                    _endValue = value;
                                  });
                                },
                              ),
                            ),
                          ),
                          Text(
                            'Fin',
                            style: context.textStyle(FontSizeType.caption).copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Instructions
                      Text(
                        'Déplacez les curseurs pour sélectionner la portion à conserver',
                        style: context.textStyle(FontSizeType.caption).copyWith(
                          color: Colors.white60,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
