import 'dart:io';
import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import '../../../data/models/confession_model.dart';
import '../../../data/services/confession_service.dart';
import '../../../data/services/storage_service.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'feeds_controller.dart';

class ConfessionDetailController extends GetxController {
  final _confessionService = ConfessionService();
  final _storageService = StorageService();
  final int confessionId;

  // Observables
  final isLoading = true.obs;
  final isLoadingComments = true.obs;
  final isAddingComment = false.obs;
  Rx<ConfessionModel?> confession = Rx<ConfessionModel?>(null);
  final comments = <ConfessionComment>[].obs;

  // Form
  final commentController = TextEditingController();
  final isAnonymous = false.obs;

  // Audio recording
  FlutterSoundRecorder? _audioRecorder;
  final isRecording = false.obs;
  String? _recordedAudioPath;
  final recordDuration = Duration.zero.obs;
  Timer? _recordTimer;
  final selectedVoiceType = 'normal'.obs;

  // Image selection
  final Rx<File?> selectedImage = Rx<File?>(null);

  // Reply
  final Rx<ConfessionComment?> replyingTo = Rx<ConfessionComment?>(null);

  // Expanded replies tracker
  final expandedCommentIds = <int>{}.obs;

  // Audio players for voice comments
  final Map<int, ap.AudioPlayer> _audioPlayers = {};
  final Map<int, bool> _isPlayingAudio = {};
  final Map<int, bool> _isLoadingAudio = {};
  final Map<int, Duration> _audioDurations = {};
  final Map<int, Duration> _audioPositions = {};
  final audioPlayerUpdate = 0.obs; // Pour trigger les rebuilds (public)

  String? userName;

  ConfessionDetailController({required this.confessionId});

  @override
  void onInit() {
    super.onInit();
    loadConfession();
    loadComments();
    _loadUserName();
    _initAudioRecorder();
  }

  @override
  void onClose() {
    commentController.dispose();
    _recordTimer?.cancel();
    _audioRecorder?.closeRecorder();

    // Disposer tous les audio players
    for (var player in _audioPlayers.values) {
      player.dispose();
    }
    _audioPlayers.clear();

    super.onClose();
  }

  void _loadUserName() {
    final user = _storageService.getUser();
    userName = user?.firstName ?? 'Utilisateur';
  }

  Future<void> _initAudioRecorder() async {
    _audioRecorder = FlutterSoundRecorder();
    await _audioRecorder!.openRecorder();
  }

  /// Charger la confession
  Future<void> loadConfession() async {
    try {
      isLoading.value = true;
      final data = await _confessionService.getConfession(confessionId);
      confession.value = data;
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      print('❌ Erreur chargement confession: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger la confession',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Charger les commentaires
  Future<void> loadComments() async {
    try {
      isLoadingComments.value = true;
      final response = await _confessionService.getComments(confessionId);
      comments.value = response.comments;
      isLoadingComments.value = false;
    } catch (e) {
      isLoadingComments.value = false;
      print('❌ Erreur chargement commentaires: $e');
    }
  }

  /// Refresh (pull-to-refresh)
  Future<void> refresh() async {
    await Future.wait([
      loadConfession(),
      loadComments(),
    ]);
  }

  /// Liker/Unliker la confession
  Future<void> toggleLike() async {
    if (confession.value == null) return;

    final currentConfession = confession.value!;
    final wasLiked = currentConfession.isLiked;

    // Optimistic update
    confession.value = currentConfession.copyWith(
      isLiked: !wasLiked,
      likesCount: wasLiked
          ? currentConfession.likesCount - 1
          : currentConfession.likesCount + 1,
    );

    try {
      final result = wasLiked
          ? await _confessionService.unlikeConfession(confessionId)
          : await _confessionService.likeConfession(confessionId);

      // Update avec le vrai count du serveur
      confession.value = currentConfession.copyWith(
        isLiked: result['is_liked'] as bool,
        likesCount: result['likes_count'] as int,
      );
    } catch (e) {
      // Rollback en cas d'erreur
      confession.value = currentConfession;
      print('❌ Erreur toggle like: $e');
    }
  }

  /// Ajouter un commentaire
  Future<void> addComment({int? parentId}) async {
    // Vérifier qu'il y a du contenu (texte ou image)
    if (commentController.text.trim().isEmpty && selectedImage.value == null) return;

    try {
      isAddingComment.value = true;

      final newComment = await _confessionService.addComment(
        confessionId: confessionId,
        content: commentController.text.trim().isEmpty ? null : commentController.text.trim(),
        isAnonymous: isAnonymous.value,
        parentId: parentId ?? replyingTo.value?.id,
        imageFile: selectedImage.value,
      );

      // Si c'est une réponse, l'ajouter aux réponses du commentaire parent
      if (replyingTo.value != null) {
        final parentIndex = comments.indexWhere((c) => c.id == replyingTo.value!.id);
        if (parentIndex != -1) {
          final updatedParent = comments[parentIndex].copyWith(
            repliesCount: comments[parentIndex].repliesCount + 1,
            replies: [...comments[parentIndex].replies, newComment],
          );
          comments[parentIndex] = updatedParent;

          // Expand automatiquement le commentaire parent pour montrer la nouvelle réponse
          expandedCommentIds.add(replyingTo.value!.id);
        }
      } else {
        // Sinon, l'ajouter en début de liste (les plus récents en premier)
        comments.insert(0, newComment);
      }

      // Mettre à jour le count localement
      if (confession.value != null) {
        confession.value = confession.value!.copyWith(
          commentsCount: confession.value!.commentsCount + 1,
        );
      }

      // Synchroniser avec le ConfessionsController si il existe
      _syncCommentCountWithFeeds(1);

      // Clear form
      commentController.clear();
      isAnonymous.value = false;
      selectedImage.value = null;
      replyingTo.value = null;

      isAddingComment.value = false;

      Get.snackbar(
        'Succès',
        'Commentaire ajouté',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      isAddingComment.value = false;
      print('❌ Erreur ajout commentaire: $e');
      Get.snackbar(
        'Erreur',
        'Impossible d\'ajouter le commentaire',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Liker un commentaire
  Future<void> toggleCommentLike(int commentId) async {
    try {
      final index = comments.indexWhere((c) => c.id == commentId);
      if (index == -1) return;

      final comment = comments[index];
      final wasLiked = comment.isLiked;

      // Optimistic update
      comments[index] = comment.copyWith(
        isLiked: !wasLiked,
        likesCount: wasLiked ? comment.likesCount - 1 : comment.likesCount + 1,
      );

      // API call
      final result = wasLiked
          ? await _confessionService.unlikeComment(
              confessionId: confessionId,
              commentId: commentId,
            )
          : await _confessionService.likeComment(
              confessionId: confessionId,
              commentId: commentId,
            );

      // Update avec les vraies valeurs
      comments[index] = comment.copyWith(
        isLiked: result['is_liked'] as bool,
        likesCount: result['likes_count'] as int,
      );
    } catch (e) {
      print('❌ Erreur toggle like commentaire: $e');
      // Recharger en cas d'erreur
      await loadComments();
    }
  }

  /// Supprimer un commentaire
  Future<void> deleteComment(int commentId) async {
    try {
      await _confessionService.deleteComment(
        confessionId: confessionId,
        commentId: commentId,
      );

      // Retirer de la liste
      comments.removeWhere((c) => c.id == commentId);

      // Mettre à jour le count localement
      if (confession.value != null) {
        confession.value = confession.value!.copyWith(
          commentsCount: confession.value!.commentsCount - 1,
        );
      }

      // Synchroniser avec le ConfessionsController si il existe
      _syncCommentCountWithFeeds(-1);

      Get.snackbar(
        'Succès',
        'Commentaire supprimé',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('❌ Erreur suppression commentaire: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer le commentaire',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ==================== AUDIO RECORDING ====================

  Future<void> startRecording() async {
    var status = await Permission.microphone.status;

    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }

    if (status.isGranted) {
      // Permission accordée
    } else if (status.isDenied) {
      Get.snackbar(
        'Permission requise',
        'L\'accès au microphone est nécessaire pour enregistrer un message vocal',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    } else if (status.isPermanentlyDenied) {
      Get.dialog(
        AlertDialog(
          title: const Text('Permission microphone'),
          content: const Text('L\'accès au microphone a été refusé de manière permanente. Veuillez activer l\'accès dans les paramètres de l\'application.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                openAppSettings();
              },
              child: const Text('Ouvrir paramètres'),
            ),
          ],
        ),
      );
      return;
    } else {
      Get.snackbar(
        'Erreur',
        'Impossible d\'accéder au microphone',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/comment_audio_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _audioRecorder!.startRecorder(
        toFile: path,
        codec: Codec.aacADTS,
        sampleRate: 44100,
        numChannels: 1,
        bitRate: 128000,
      );

      isRecording.value = true;
      _recordedAudioPath = path;
      recordDuration.value = Duration.zero;

      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        recordDuration.value = Duration(seconds: timer.tick);
      });
    } catch (e) {
      if (foundation.kDebugMode) print('❌ Error starting recording: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de démarrer l\'enregistrement',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> stopRecording() async {
    try {
      final path = await _audioRecorder!.stopRecorder();
      _recordTimer?.cancel();

      isRecording.value = false;

      final audioPath = path ?? _recordedAudioPath;

      if (audioPath != null) {
        final audioFile = File(audioPath);

        if (await audioFile.exists()) {
          final fileSize = await audioFile.length();

          if (fileSize > 0) {
            _sendAudioComment(audioFile);
          } else {
            Get.snackbar(
              'Erreur',
              'L\'enregistrement audio est vide. Veuillez réessayer.',
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        } else {
          Get.snackbar(
            'Erreur',
            'Fichier audio introuvable',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } catch (e) {
      if (foundation.kDebugMode) print('❌ Error stopping recording: $e');
    }
  }

  Future<void> cancelRecording() async {
    try {
      await _audioRecorder!.stopRecorder();
      _recordTimer?.cancel();

      if (_recordedAudioPath != null) {
        final audioFile = File(_recordedAudioPath!);
        if (await audioFile.exists()) {
          await audioFile.delete();
        }
      }

      isRecording.value = false;
      _recordedAudioPath = null;
      recordDuration.value = Duration.zero;
    } catch (e) {
      if (foundation.kDebugMode) print('Error canceling recording: $e');
    }
  }

  Future<void> _sendAudioComment(File audioFile) async {
    _recordedAudioPath = null;
    recordDuration.value = Duration.zero;

    isAddingComment.value = true;
    try {
      final newComment = await _confessionService.addComment(
        confessionId: confessionId,
        content: null,
        isAnonymous: isAnonymous.value,
        audioFile: audioFile,
        voiceType: selectedVoiceType.value,
      );

      comments.insert(0, newComment);

      // Mettre à jour le count
      if (confession.value != null) {
        confession.value = confession.value!.copyWith(
          commentsCount: confession.value!.commentsCount + 1,
        );
      }

      if (await audioFile.exists()) {
        await audioFile.delete();
      }
    } catch (e) {
      if (foundation.kDebugMode) print('Error sending audio comment: $e');
      Get.snackbar(
        'Erreur',
        'Impossible d\'envoyer le commentaire audio',
        snackPosition: SnackPosition.BOTTOM,
      );

      if (await audioFile.exists()) {
        await audioFile.delete();
      }
    } finally {
      isAddingComment.value = false;
    }
  }

  // ==================== IMAGE SELECTION ====================

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1920,
    );

    if (pickedFile != null) {
      selectedImage.value = File(pickedFile.path);
    }
  }

  void removeSelectedImage() {
    selectedImage.value = null;
  }

  // ==================== AUDIO PLAYER ====================

  ap.AudioPlayer? getAudioPlayer(int commentId) {
    return _audioPlayers[commentId];
  }

  bool isAudioPlaying(int commentId) {
    return _isPlayingAudio[commentId] ?? false;
  }

  bool isAudioLoading(int commentId) {
    return _isLoadingAudio[commentId] ?? false;
  }

  Duration getAudioDuration(int commentId) {
    return _audioDurations[commentId] ?? Duration.zero;
  }

  Duration getAudioPosition(int commentId) {
    return _audioPositions[commentId] ?? Duration.zero;
  }

  void initAudioPlayer(int commentId) {
    // Ne créer le player qu'une seule fois
    if (_audioPlayers.containsKey(commentId)) return;

    final player = ap.AudioPlayer();
    _audioPlayers[commentId] = player;
    _isPlayingAudio[commentId] = false;
    _isLoadingAudio[commentId] = false;
    _audioDurations[commentId] = Duration.zero;
    _audioPositions[commentId] = Duration.zero;

    // Duration change (une seule fois)
    player.onDurationChanged.listen((duration) {
      if (_audioDurations[commentId] != duration) {
        _audioDurations[commentId] = duration;
        audioPlayerUpdate.value++; // Trigger rebuild
      }
    });

    // Position change - throttle pour éviter trop de rebuilds
    DateTime? lastPositionUpdate;
    player.onPositionChanged.listen((position) {
      final now = DateTime.now();
      // Mettre à jour seulement toutes les 500ms
      if (lastPositionUpdate == null ||
          now.difference(lastPositionUpdate!) > const Duration(milliseconds: 500)) {
        _audioPositions[commentId] = position;
        lastPositionUpdate = now;
        audioPlayerUpdate.value++; // Trigger rebuild
      } else {
        // Mettre à jour la position sans rebuild
        _audioPositions[commentId] = position;
      }
    });

    // State change
    player.onPlayerStateChanged.listen((state) {
      final wasPlaying = _isPlayingAudio[commentId] ?? false;
      final isPlaying = state == ap.PlayerState.playing;

      if (wasPlaying != isPlaying) {
        _isPlayingAudio[commentId] = isPlaying;
        if (isPlaying) {
          _isLoadingAudio[commentId] = false;
        }
        audioPlayerUpdate.value++; // Trigger rebuild
      }
    });

    // Complete
    player.onPlayerComplete.listen((_) {
      _isPlayingAudio[commentId] = false;
      _isLoadingAudio[commentId] = false;
      _audioPositions[commentId] = Duration.zero;
      audioPlayerUpdate.value++; // Trigger rebuild
    });
  }

  Future<void> toggleAudioPlayback(int commentId, String audioUrl) async {
    if (_isLoadingAudio[commentId] == true) return;

    final player = _audioPlayers[commentId]!;
    final isPlaying = _isPlayingAudio[commentId] ?? false;

    if (isPlaying) {
      await player.pause();
    } else {
      _isLoadingAudio[commentId] = true;
      audioPlayerUpdate.value++; // Trigger rebuild

      // Arrêter tous les autres audios
      for (var entry in _audioPlayers.entries) {
        if (entry.key != commentId) {
          await entry.value.stop();
        }
      }

      try {
        final position = _audioPositions[commentId] ?? Duration.zero;
        final duration = _audioDurations[commentId] ?? Duration.zero;

        if (position.inSeconds > 0 && position.inSeconds < duration.inSeconds) {
          await player.resume();
        } else {
          await player.play(ap.UrlSource(audioUrl));
        }
      } catch (e) {
        if (foundation.kDebugMode) print('❌ Error playing audio: $e');
        _isLoadingAudio[commentId] = false;
        audioPlayerUpdate.value++; // Trigger rebuild
        Get.snackbar(
          'Erreur',
          'Impossible de lire l\'audio',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  /// Synchroniser le count des commentaires avec le ConfessionsController
  void _syncCommentCountWithFeeds(int delta) {
    try {
      // Vérifier si le ConfessionsController existe
      if (Get.isRegistered<ConfessionsController>()) {
        final feedsController = Get.find<ConfessionsController>();

        // Trouver la confession dans la liste des feeds et mettre à jour le count
        final confessionIndex = feedsController.confessions.indexWhere(
          (c) => c.id == confessionId,
        );

        if (confessionIndex != -1) {
          final currentConfession = feedsController.confessions[confessionIndex];
          feedsController.confessions[confessionIndex] = currentConfession.copyWith(
            commentsCount: currentConfession.commentsCount + delta,
          );
          feedsController.confessions.refresh();
        }
      }
    } catch (e) {
      // Ignorer les erreurs silencieusement
      if (foundation.kDebugMode) print('Sync error (non-critical): $e');
    }
  }
}
