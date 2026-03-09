import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:get/get.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:weylo/app/data/models/confession_model.dart';
import 'package:weylo/app/data/services/confession_service.dart';
import 'package:weylo/app/data/services/storage_service.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';
import '../../controllers/feeds_controller.dart';
import '../../controllers/confession_detail_controller.dart';

class CommentsBottomSheet extends StatefulWidget {
  final ConfessionModel confession;

  const CommentsBottomSheet({
    super.key,
    required this.confession,
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final _confessionService = ConfessionService();
  final _storageService = StorageService();
  final _commentController = TextEditingController();
  final _comments = <ConfessionComment>[].obs;
  final _isLoading = false.obs;
  final _isLoadingMore = false.obs;
  final _isSubmitting = false.obs;
  final _commentAsAnonymous = false.obs; // false = identifié, true = anonyme
  final ScrollController _scrollController = ScrollController();
  final ScrollController _listScrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _emojiShowing = false;

  // Pagination
  int _currentPage = 1;
  bool _hasMore = true;

  // Audio recording
  FlutterSoundRecorder? _audioRecorder;
  bool _isRecording = false;
  String? _recordedAudioPath;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;

  // Image selection
  File? _selectedImage;

  // Reply
  ConfessionComment? _replyingTo;

  // Expanded replies tracker
  final Set<int> _expandedCommentIds = {};

  String? _userName;

  // Voice type for anonymous comments
  String _selectedVoiceType = 'normal';

  // Audio players pour les commentaires vocaux
  final Map<int, ap.AudioPlayer> _audioPlayers = {};
  final Map<int, bool> _isPlayingAudio = {};
  final Map<int, bool> _isLoadingAudio = {}; // État de chargement pour chaque audio
  final Map<int, Duration> _audioDurations = {};
  final Map<int, Duration> _audioPositions = {};

  // Counts tracking for real-time updates
  late int _currentLikesCount;
  late int _currentCommentsCount;

  @override
  void initState() {
    super.initState();
    // Initialiser les counts avec les valeurs actuelles de la confession
    _currentLikesCount = widget.confession.likesCount;
    _currentCommentsCount = widget.confession.commentsCount;

    _loadComments();
    _loadUserName();

    // Listener pour détecter les changements du TextEditingController
    // (y compris les emojis ajoutés via l'EmojiPicker)
    _commentController.addListener(() {
      setState(() {
        // Force rebuild pour afficher/cacher le bouton send/mic
      });
    });

    // Listener pour la pagination au scroll
    _listScrollController.addListener(_onScroll);

    // Initialiser l'enregistreur audio
    _initAudioRecorder();
  }

  void _onScroll() {
    if (_isLoadingMore.value || !_hasMore) return;

    final maxScroll = _listScrollController.position.maxScrollExtent;
    final currentScroll = _listScrollController.position.pixels;
    final delta = 200.0; // Charger plus quand on est à 200px du bas

    if (maxScroll - currentScroll <= delta) {
      _loadMoreComments();
    }
  }

  void _loadUserName() {
    final user = _storageService.getUser();
    _userName = user?.firstName ?? 'Utilisateur';
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _listScrollController.dispose();
    _focusNode.dispose();
    _recordTimer?.cancel();
    _audioRecorder?.closeRecorder();

    // Disposer tous les audio players
    for (var player in _audioPlayers.values) {
      player.dispose();
    }
    _audioPlayers.clear();

    super.dispose();
  }

  // Fermer le bottom sheet et retourner les counts mis à jour
  void _closeBottomSheet() {
    Get.back(result: {
      'likesCount': _currentLikesCount,
      'commentsCount': _currentCommentsCount,
    });
  }

  Future<void> _initAudioRecorder() async {
    _audioRecorder = FlutterSoundRecorder();
    await _audioRecorder!.openRecorder();
  }

  Future<void> _loadComments() async {
    _isLoading.value = true;
    _currentPage = 1;
    try {
      final response = await _confessionService.getComments(
        widget.confession.id,
        page: _currentPage,
        limit: 10,
      );
      _comments.value = response.comments;
      _hasMore = response.hasMore;
    } catch (e) {
      print('Error loading comments: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger les commentaires',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _loadMoreComments() async {
    if (_isLoadingMore.value || !_hasMore) return;

    _isLoadingMore.value = true;
    try {
      _currentPage++;
      final response = await _confessionService.getComments(
        widget.confession.id,
        page: _currentPage,
        limit: 10,
      );
      _comments.addAll(response.comments);
      _hasMore = response.hasMore;
    } catch (e) {
      print('Error loading more comments: $e');
      _currentPage--; // Rollback en cas d'erreur
    } finally {
      _isLoadingMore.value = false;
    }
  }

  Future<void> _addComment() async {
    // Vérifier qu'il y a du contenu (texte ou image)
    if (_commentController.text.trim().isEmpty && _selectedImage == null) return;

    _isSubmitting.value = true;
    try {
      final comment = await _confessionService.addComment(
        confessionId: widget.confession.id,
        content: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
        isAnonymous: _commentAsAnonymous.value,
        parentId: _replyingTo?.id,
        imageFile: _selectedImage,
      );

      // Si c'est une réponse, l'ajouter aux réponses du commentaire parent
      if (_replyingTo != null) {
        final parentIndex = _comments.indexWhere((c) => c.id == _replyingTo!.id);
        if (parentIndex != -1) {
          final updatedParent = _comments[parentIndex].copyWith(
            repliesCount: _comments[parentIndex].repliesCount + 1,
            replies: [..._comments[parentIndex].replies, comment],
          );
          _comments[parentIndex] = updatedParent;

          // Expand automatiquement le commentaire parent pour montrer la nouvelle réponse
          _expandedCommentIds.add(_replyingTo!.id);
        }
      } else {
        // Sinon, l'ajouter en début de liste (les plus récents en premier)
        _comments.insert(0, comment);
      }

      // Incrémenter le count des commentaires
      _currentCommentsCount++;

      // Synchroniser avec les autres controllers
      _syncCommentCount(1);

      _commentController.clear();
      setState(() {
        _selectedImage = null;
        _emojiShowing = false;
        _replyingTo = null;
      });
    } catch (e) {
      print('Error adding comment: $e');
      Get.snackbar(
        'Erreur',
        'Impossible d\'ajouter le commentaire',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isSubmitting.value = false;
    }
  }

  Future<void> _deleteComment(ConfessionComment comment) async {
    try {
      await _confessionService.deleteComment(
        confessionId: widget.confession.id,
        commentId: comment.id,
      );

      _comments.remove(comment);

      // Décrémenter le count des commentaires
      _currentCommentsCount--;

      // Synchroniser avec les autres controllers
      _syncCommentCount(-1);

      Get.snackbar(
        'Succès',
        'Commentaire supprimé',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error deleting comment: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer le commentaire',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Synchroniser le count des commentaires avec ConfessionsController et ConfessionDetailController
  void _syncCommentCount(int delta) {
    try {
      // 1. Synchroniser avec le ConfessionsController
      if (Get.isRegistered<ConfessionsController>()) {
        final feedsController = Get.find<ConfessionsController>();

        // Trouver la confession dans la liste des feeds et mettre à jour le count
        final confessionIndex = feedsController.confessions.indexWhere(
          (c) => c.id == widget.confession.id,
        );

        if (confessionIndex != -1) {
          final currentConfession = feedsController.confessions[confessionIndex];
          feedsController.confessions[confessionIndex] = currentConfession.copyWith(
            commentsCount: currentConfession.commentsCount + delta,
          );
          feedsController.confessions.refresh();
        }
      }

      // 2. Synchroniser avec le ConfessionDetailController si il existe
      if (Get.isRegistered<ConfessionDetailController>()) {
        final detailController = Get.find<ConfessionDetailController>();

        // Vérifier que c'est bien la même confession
        if (detailController.confessionId == widget.confession.id) {
          if (detailController.confession.value != null) {
            detailController.confession.value = detailController.confession.value!.copyWith(
              commentsCount: detailController.confession.value!.commentsCount + delta,
            );
          }
        }
      }
    } catch (e) {
      // Ignorer les erreurs silencieusement
      if (foundation.kDebugMode) print('Sync error (non-critical): $e');
    }
  }

  // ==================== AUDIO RECORDING ====================

  Future<void> _startRecording() async {
    // Vérifier d'abord le statut actuel
    var status = await Permission.microphone.status;

    // Si la permission n'est pas accordée, la demander
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }

    // Gérer les différents cas de permission
    if (status.isGranted) {
      // Permission accordée, continuer
    } else if (status.isDenied) {
      // Permission refusée (peut redemander)
      Get.snackbar(
        'Permission requise',
        'L\'accès au microphone est nécessaire pour enregistrer un message vocal',
        backgroundColor: AppThemeSystem.warningColor,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    } else if (status.isPermanentlyDenied) {
      // Permission refusée définitivement, proposer d'aller dans les paramètres
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
      // Autre cas (restricted, limited, etc.)
      Get.snackbar(
        'Erreur',
        'Impossible d\'accéder au microphone',
        backgroundColor: AppThemeSystem.errorColor,
        colorText: Colors.white,
      );
      return;
    }

    try {
      // Créer le chemin du fichier audio
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/comment_audio_${DateTime.now().millisecondsSinceEpoch}.aac';

      if (foundation.kDebugMode) {
        print('📁 Recording to: $path');
        print('📁 Directory: ${directory.path}');
      }

      // Démarrer l'enregistrement avec sample rate et bitrate optimisés
      await _audioRecorder!.startRecorder(
        toFile: path,
        codec: Codec.aacADTS,
        sampleRate: 44100,  // Sample rate standard
        numChannels: 1,     // Mono
        bitRate: 128000,    // 128kbps
      );

      if (foundation.kDebugMode) print('✅ Recording started successfully!');

      setState(() {
        _isRecording = true;
        _recordedAudioPath = path;
        _recordDuration = Duration.zero;
        _emojiShowing = false;
      });

      // Démarrer le timer
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordDuration = Duration(seconds: timer.tick);
        });
        if (foundation.kDebugMode) print('⏱️ Recording duration: ${timer.tick}s');
      });
    } catch (e) {
      if (foundation.kDebugMode) print('❌ Error starting recording: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de démarrer l\'enregistrement',
        backgroundColor: AppThemeSystem.errorColor,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder!.stopRecorder();
      _recordTimer?.cancel();

      setState(() {
        _isRecording = false;
      });

      if (foundation.kDebugMode) {
        print('🎙️ Recording stopped. Path: $path');
        print('🎙️ Recorded path variable: $_recordedAudioPath');
      }

      // Envoyer automatiquement l'audio (le backend appliquera l'effet vocal)
      final audioPath = path ?? _recordedAudioPath;

      if (audioPath != null) {
        final audioFile = File(audioPath);

        if (await audioFile.exists()) {
          final fileSize = await audioFile.length();
          if (foundation.kDebugMode) {
            print('📁 Audio file exists! Size: ${fileSize} bytes');
          }

          if (fileSize > 0) {
            _sendAudioComment(audioFile);
          } else {
            if (foundation.kDebugMode) print('⚠️ Audio file is EMPTY!');
            Get.snackbar(
              'Erreur',
              'L\'enregistrement audio est vide. Veuillez réessayer.',
              backgroundColor: AppThemeSystem.errorColor,
              colorText: Colors.white,
            );
          }
        } else {
          if (foundation.kDebugMode) print('❌ Audio file does NOT exist!');
          Get.snackbar(
            'Erreur',
            'Fichier audio introuvable',
            backgroundColor: AppThemeSystem.errorColor,
            colorText: Colors.white,
          );
        }
      } else {
        if (foundation.kDebugMode) print('❌ No audio path recorded!');
      }
    } catch (e) {
      if (foundation.kDebugMode) print('❌ Error stopping recording: $e');
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await _audioRecorder!.stopRecorder();
      _recordTimer?.cancel();

      // Supprimer le fichier audio
      if (_recordedAudioPath != null) {
        final audioFile = File(_recordedAudioPath!);
        if (await audioFile.exists()) {
          await audioFile.delete();
        }
      }

      setState(() {
        _isRecording = false;
        _recordedAudioPath = null;
        _recordDuration = Duration.zero;
      });
    } catch (e) {
      if (foundation.kDebugMode) print('Error canceling recording: $e');
    }
  }

  Future<void> _sendAudioComment(File audioFile) async {
    setState(() {
      _recordedAudioPath = null;
      _recordDuration = Duration.zero;
    });

    if (foundation.kDebugMode) {
      print('📤 Sending audio comment...');
      print('📤 Is Anonymous: ${_commentAsAnonymous.value}');
      print('📤 Voice Type: $_selectedVoiceType');
      print('📤 File size: ${await audioFile.length()} bytes');
    }

    _isSubmitting.value = true;
    try {
      final comment = await _confessionService.addComment(
        confessionId: widget.confession.id,
        content: null,
        isAnonymous: _commentAsAnonymous.value,
        audioFile: audioFile,
        voiceType: _selectedVoiceType, // Envoyer le type de voix sélectionné
      );

      _comments.insert(0, comment); // Ajouter en début de liste (les plus récents en premier)

      // Incrémenter le count des commentaires
      _currentCommentsCount++;

      // Synchroniser avec les autres controllers
      _syncCommentCount(1);

      // Supprimer le fichier audio temporaire
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

      // Supprimer le fichier audio temporaire en cas d'erreur
      if (await audioFile.exists()) {
        await audioFile.delete();
      }
    } finally {
      _isSubmitting.value = false;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // ==================== IMAGE SELECTION ====================

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1920,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _emojiShowing = false;
      });
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _toggleCommentLike(ConfessionComment comment) async {
    // Trouver le commentaire (peut être parent ou réponse)
    int parentIndex = _comments.indexOf(comment);
    int? replyIndex;

    // Si pas trouvé dans les commentaires principaux, chercher dans les réponses
    if (parentIndex == -1) {
      for (int i = 0; i < _comments.length; i++) {
        replyIndex = _comments[i].replies.indexWhere((r) => r.id == comment.id);
        if (replyIndex != -1) {
          parentIndex = i;
          break;
        }
      }

      // Si toujours pas trouvé, arrêter
      if (parentIndex == -1 || replyIndex == null) return;
    }

    // Mise à jour optimiste
    final updatedComment = comment.copyWith(
      likesCount: comment.isLiked ? comment.likesCount - 1 : comment.likesCount + 1,
      isLiked: !comment.isLiked,
    );

    // Mettre à jour dans la liste appropriée
    if (replyIndex != null) {
      // C'est une réponse
      final updatedReplies = List<ConfessionComment>.from(_comments[parentIndex].replies);
      updatedReplies[replyIndex] = updatedComment;
      _comments[parentIndex] = _comments[parentIndex].copyWith(replies: updatedReplies);
    } else {
      // C'est un commentaire parent
      _comments[parentIndex] = updatedComment;
    }

    try {
      final result = comment.isLiked
          ? await _confessionService.unlikeComment(
              confessionId: widget.confession.id,
              commentId: comment.id,
            )
          : await _confessionService.likeComment(
              confessionId: widget.confession.id,
              commentId: comment.id,
            );

      // Mise à jour avec les vraies valeurs du serveur
      final finalComment = comment.copyWith(
        likesCount: result['likes_count'],
        isLiked: result['is_liked'],
      );

      if (replyIndex != null) {
        // Mettre à jour la réponse
        final updatedReplies = List<ConfessionComment>.from(_comments[parentIndex].replies);
        updatedReplies[replyIndex] = finalComment;
        _comments[parentIndex] = _comments[parentIndex].copyWith(replies: updatedReplies);
      } else {
        // Mettre à jour le commentaire parent
        _comments[parentIndex] = finalComment;
      }
    } catch (e) {
      print('Error toggling comment like: $e');
      // Rollback en cas d'erreur
      if (replyIndex != null) {
        final updatedReplies = List<ConfessionComment>.from(_comments[parentIndex].replies);
        updatedReplies[replyIndex] = comment;
        _comments[parentIndex] = _comments[parentIndex].copyWith(replies: updatedReplies);
      } else {
        _comments[parentIndex] = comment;
      }
    }
  }

  void _showCommentAsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        final isDark = Theme.of(modalContext).brightness == Brightness.dark;
        return Container(
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

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Commenter en tant que',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppThemeSystem.blackColor,
                    ),
                  ),
                ),

                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppThemeSystem.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: AppThemeSystem.primaryColor,
                    ),
                  ),
                  title: Text(
                    _userName ?? 'Utilisateur',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Votre identité sera visible'),
                  onTap: () {
                    setState(() {
                      _commentAsAnonymous.value = false;
                    });
                    Navigator.pop(modalContext);
                  },
                  trailing: !_commentAsAnonymous.value
                      ? Icon(Icons.check_circle, color: AppThemeSystem.primaryColor)
                      : null,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppThemeSystem.grey600.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      color: AppThemeSystem.grey600,
                    ),
                  ),
                  title: const Text(
                    'Anonyme',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Votre identité restera cachée'),
                  onTap: () {
                    setState(() {
                      _commentAsAnonymous.value = true;
                    });
                    Navigator.pop(modalContext);
                  },
                  trailing: _commentAsAnonymous.value
                      ? Icon(Icons.check_circle, color: AppThemeSystem.primaryColor)
                      : null,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onMicButtonPressed() {
    if (foundation.kDebugMode) {
      print('🎤 Mic button pressed. Is anonymous: ${_commentAsAnonymous.value}');
    }

    // Si l'utilisateur est anonyme, montrer le sélecteur de voix
    if (_commentAsAnonymous.value) {
      if (foundation.kDebugMode) print('📱 Opening voice type selector...');
      _showVoiceTypeSelector();
    } else {
      // Sinon, démarrer directement l'enregistrement
      if (foundation.kDebugMode) print('▶️ Starting normal recording...');
      _selectedVoiceType = 'normal'; // Mode normal pour utilisateurs identifiés
      _startRecording();
    }
  }

  void _showVoiceTypeSelector() {
    if (foundation.kDebugMode) print('🎭 Showing voice type selector bottom sheet');

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final voiceTypes = [
      {
        'id': 'normal',
        'name': 'Normale',
        'icon': Icons.record_voice_over_rounded,
        'color': AppThemeSystem.primaryColor,
        'description': 'Voix standard',
      },
      {
        'id': 'robot',
        'name': 'Robot',
        'icon': Icons.smart_toy_rounded,
        'color': const Color(0xFF00BCD4),
        'description': 'Voix robotique',
      },
      {
        'id': 'alien',
        'name': 'Alien',
        'icon': Icons.psychology_rounded,
        'color': const Color(0xFF9C27B0),
        'description': 'Voix extra-terrestre',
      },
      {
        'id': 'mystery',
        'name': 'Mystérieux',
        'icon': Icons.masks_rounded,
        'color': const Color(0xFF424242),
        'description': 'Voix grave et profonde',
      },
      {
        'id': 'chipmunk',
        'name': 'Chipmunk',
        'icon': Icons.pets_rounded,
        'color': const Color(0xFFFF9800),
        'description': 'Voix aiguë et rapide',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (modalContext) {
        return Container(
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

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.mic_rounded,
                            color: AppThemeSystem.primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Choisir le type de voix',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppThemeSystem.blackColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sélectionnez un effet vocal pour votre message anonyme',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Voice types list
                ...voiceTypes.map((voiceType) {
                  final isSelected = _selectedVoiceType == voiceType['id'];
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
                          if (foundation.kDebugMode) {
                            print('✅ Voice type selected: $selectedType');
                          }

                          setState(() {
                            _selectedVoiceType = selectedType;
                          });

                          Navigator.pop(modalContext);

                          // Attendre que le bottom sheet soit fermé avant de démarrer l'enregistrement
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (foundation.kDebugMode) {
                              print('🎙️ Starting recording with voice type: $_selectedVoiceType');
                            }
                            _startRecording();
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
                }),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = context.deviceType;

    return WillPopScope(
      onWillPop: () async {
        // Retourner les counts quand on ferme le bottom sheet
        Get.back(result: {
          'likesCount': _currentLikesCount,
          'commentsCount': _currentCommentsCount,
        });
        return false; // Ne pas laisser Flutter gérer la fermeture
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Stats Header (likes + partages)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.elementSpacing,
              vertical: context.elementSpacing * 0.5,
            ),
            child: Row(
              children: [
                // Likes
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1877F2), // Facebook blue
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.thumb_up,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.confession.likesCount}',
                      style: context.textStyle(FontSizeType.body2).copyWith(
                        color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey700,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Commentaires
                Obx(() => Text(
                  '${_comments.length} commentaire${_comments.length > 1 ? 's' : ''}',
                  style: context.textStyle(FontSizeType.body2).copyWith(
                    color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey700,
                  ),
                )),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
          ),

          // Comments List
          Expanded(
            child: Obx(() {
              if (_isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppThemeSystem.primaryColor,
                  ),
                );
              }

              if (_comments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: deviceType == DeviceType.mobile ? 60 : 80,
                        color: isDark ? AppThemeSystem.grey600 : AppThemeSystem.grey400,
                      ),
                      SizedBox(height: context.elementSpacing),
                      Text(
                        'Aucun commentaire',
                        style: context.textStyle(FontSizeType.body1).copyWith(
                          color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                        ),
                      ),
                      SizedBox(height: context.elementSpacing * 0.5),
                      Text(
                        'Soyez le premier à commenter',
                        style: context.textStyle(FontSizeType.body2).copyWith(
                          color: isDark ? AppThemeSystem.grey500 : AppThemeSystem.grey600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: _listScrollController,
                padding: EdgeInsets.only(
                  left: context.elementSpacing,
                  right: context.elementSpacing,
                  top: context.elementSpacing * 1.5,
                  bottom: context.elementSpacing * 2,
                ),
                itemCount: _comments.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  // Afficher l'indicateur de chargement à la fin
                  if (index == _comments.length) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: context.elementSpacing),
                      child: Center(
                        child: Obx(() => _isLoadingMore.value
                            ? CircularProgressIndicator(
                                color: AppThemeSystem.primaryColor,
                                strokeWidth: 2,
                              )
                            : const SizedBox.shrink(),
                        ),
                      ),
                    );
                  }

                  final comment = _comments[index];
                  return _buildCommentWithReplies(context, comment, isDark, deviceType);
                },
              );
            }),
          ),

          Divider(
            height: 1,
            color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
          ),

          // Comment Input (Modern style avec emoji et voix)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.elementSpacing * 0.5,
                  vertical: context.elementSpacing * 0.5,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
                ),
                child: SafeArea(
                  child: _isRecording
                      ? _buildRecordingInterface(context, isDark)
                      : _buildNormalInputInterface(context, isDark),
                ),
              ),

              // Emoji picker
              Offstage(
                offstage: !_emojiShowing,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.35,
                  decoration: BoxDecoration(
                    color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
                        width: 1,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: EmojiPicker(
                      textEditingController: _commentController,
                      scrollController: _scrollController,
                      config: Config(
                        height: MediaQuery.of(context).size.height * 0.35,
                        checkPlatformCompatibility: true,
                        emojiViewConfig: EmojiViewConfig(
                          emojiSizeMax: 28 *
                              (foundation.defaultTargetPlatform == TargetPlatform.iOS
                                  ? 1.2
                                  : 1.0),
                          backgroundColor: isDark ? AppThemeSystem.darkCardColor : Colors.white,
                          columns: 7,
                          verticalSpacing: 0,
                        ),
                        viewOrderConfig: const ViewOrderConfig(
                          top: EmojiPickerItem.categoryBar,
                          middle: EmojiPickerItem.emojiView,
                          bottom: EmojiPickerItem.searchBar,
                        ),
                        skinToneConfig: const SkinToneConfig(),
                        categoryViewConfig: CategoryViewConfig(
                          indicatorColor: AppThemeSystem.primaryColor,
                          iconColorSelected: AppThemeSystem.primaryColor,
                          iconColor: isDark ? AppThemeSystem.grey600 : AppThemeSystem.grey500,
                          categoryIcons: const CategoryIcons(),
                          backgroundColor: isDark ? AppThemeSystem.darkCardColor : Colors.white,
                          tabIndicatorAnimDuration: kTabScrollDuration,
                          dividerColor: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
                          recentTabBehavior: RecentTabBehavior.RECENT,
                        ),
                        bottomActionBarConfig: const BottomActionBarConfig(enabled: false),
                        searchViewConfig: SearchViewConfig(
                          backgroundColor: isDark ? AppThemeSystem.darkCardColor : Colors.white,
                          buttonIconColor: AppThemeSystem.primaryColor,
                          hintText: 'Rechercher un emoji...',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildRecordingInterface(BuildContext context, bool isDark) {
    return Row(
      children: [
        // Bouton annuler
        IconButton(
          onPressed: _cancelRecording,
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
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.3, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  onEnd: () {
                    if (_isRecording && mounted) {
                      setState(() {}); // Force rebuild to restart animation
                    }
                  },
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
                ),
                const SizedBox(width: 12),
                Text(
                  _formatDuration(_recordDuration),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppThemeSystem.errorColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Bouton envoyer
        Container(
          decoration: const BoxDecoration(
            color: AppThemeSystem.primaryColor,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: _stopRecording,
            icon: Icon(Icons.send, color: Colors.white, size: 22),
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }

  Widget _buildNormalInputInterface(BuildContext context, bool isDark) {
    // Vérifier s'il y a du contenu (texte, emoji ou image)
    final hasContent = _commentController.text.trim().isNotEmpty || _selectedImage != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Indicateur de réponse (si on répond à un commentaire)
        if (_replyingTo != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppThemeSystem.primaryColor.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(
                  color: AppThemeSystem.primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.reply,
                  size: 16,
                  color: AppThemeSystem.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Répondre à ${_replyingTo!.author.name}',
                    style: context.textStyle(FontSizeType.caption).copyWith(
                      color: AppThemeSystem.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _replyingTo = null;
                    });
                  },
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: AppThemeSystem.primaryColor,
                  ),
                ),
              ],
            ),
          ),

        // Indicateur de mode (anonyme ou identifié)
        Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Icon(
                _commentAsAnonymous.value ? Icons.lock_outline : Icons.person_outline,
                size: 16,
                color: AppThemeSystem.primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Commenter en tant que ${_commentAsAnonymous.value ? "Anonyme" : _userName}',
                style: context.textStyle(FontSizeType.caption).copyWith(
                  color: AppThemeSystem.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: _showCommentAsMenu,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppThemeSystem.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Changer',
                    style: context.textStyle(FontSizeType.caption).copyWith(
                      color: AppThemeSystem.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )),

        // Aperçu de l'image sélectionnée
        if (_selectedImage != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: _removeSelectedImage,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Zone de saisie principale
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
        // Champ de texte avec bouton emoji
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Bouton emoji
                InkWell(
                  onTap: () {
                    setState(() {
                      _emojiShowing = !_emojiShowing;
                      if (!_emojiShowing) {
                        _focusNode.requestFocus();
                      } else {
                        _focusNode.unfocus();
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      _emojiShowing ? Icons.keyboard : Icons.emoji_emotions_outlined,
                      color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                    // Champ de texte
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 100),
                        child: TextField(
                          controller: _commentController,
                          focusNode: _focusNode,
                          maxLines: null,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText: 'Écrivez un commentaire...',
                            hintStyle: context.textStyle(FontSizeType.body2).copyWith(
                              color: AppThemeSystem.grey500,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                            isDense: true,
                          ),
                          style: context.textStyle(FontSizeType.body2).copyWith(
                            color: isDark ? Colors.white : AppThemeSystem.blackColor,
                          ),
                        ),
                      ),
                    ),

                    // Bouton image
                    InkWell(
                      onTap: _pickImage,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.image_outlined,
                          color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Bouton audio/send (conditionnel basé sur le contenu)
            Obx(() => _isSubmitting.value
                ? SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppThemeSystem.primaryColor,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: hasContent ? AppThemeSystem.primaryColor : (isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey400),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: hasContent ? _addComment : _onMicButtonPressed,
                      icon: Icon(
                        hasContent ? Icons.send : Icons.mic,
                        color: Colors.white,
                        size: 22,
                      ),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(),
                    ),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommentItem(
    BuildContext context,
    ConfessionComment comment,
    bool isDark,
    DeviceType deviceType, {
    bool isExpanded = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.elementSpacing * 1.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: comment.isAnonymous
                  ? LinearGradient(
                      colors: [
                        AppThemeSystem.grey700,
                        AppThemeSystem.grey600,
                      ],
                    )
                  : LinearGradient(
                      colors: [
                        AppThemeSystem.primaryColor,
                        AppThemeSystem.secondaryColor,
                      ],
                    ),
            ),
            child: comment.author.avatarUrl != null && !comment.isAnonymous
                ? ClipOval(
                    child: Image.network(
                      comment.author.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            comment.author.initial,
                            style: context.textStyle(FontSizeType.caption).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Text(
                      comment.author.initial,
                      style: context.textStyle(FontSizeType.caption).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + Time + Content bubble
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and time
                    Row(
                      children: [
                        Text(
                          comment.author.name,
                          style: context.textStyle(FontSizeType.body2).copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppThemeSystem.blackColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatTime(comment.createdAt),
                          style: context.textStyle(FontSizeType.caption).copyWith(
                            color: AppThemeSystem.grey600,
                          ),
                        ),
                        if (comment.isMine) ...[
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_horiz_rounded,
                              size: 16,
                              color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                            ),
                            padding: EdgeInsets.zero,
                            onSelected: (value) {
                              if (value == 'delete') {
                                _deleteComment(comment);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, size: 18),
                                    SizedBox(width: 8),
                                    Text('Supprimer'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Content
                    if (comment.content.isNotEmpty)
                      Text(
                        comment.content,
                        style: context.textStyle(FontSizeType.body2).copyWith(
                          color: isDark ? AppThemeSystem.grey200 : AppThemeSystem.grey900,
                        ),
                      ),

                    // Image du commentaire
                    if (comment.mediaType == 'image' && comment.mediaUrl != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GestureDetector(
                          onTap: () {
                            // Afficher l'image en plein écran
                            Get.dialog(
                              Dialog(
                                backgroundColor: Colors.transparent,
                                insetPadding: EdgeInsets.zero,
                                child: Stack(
                                  children: [
                                    Center(
                                      child: InteractiveViewer(
                                        minScale: 0.5,
                                        maxScale: 4.0,
                                        child: Image.network(
                                          comment.mediaUrl!,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 40,
                                      right: 20,
                                      child: IconButton(
                                        onPressed: () => Get.back(),
                                        icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Image.network(
                            comment.mediaUrl!,
                            width: 200,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      color: AppThemeSystem.grey600,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Image non disponible',
                                      style: TextStyle(
                                        color: AppThemeSystem.grey600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],

                    // Audio du commentaire
                    if (comment.mediaType == 'audio' && comment.mediaUrl != null) ...[
                      const SizedBox(height: 8),
                      _buildAudioPlayer(context, comment, isDark),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                // Actions (Répondre + Like count)
                Row(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Bouton "Répondre" pour ouvrir l'input
                        InkWell(
                          onTap: () {
                            setState(() {
                              _replyingTo = comment;
                              _focusNode.requestFocus();
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                            child: Text(
                              'Répondre',
                              style: context.textStyle(FontSizeType.caption).copyWith(
                                color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        // Bouton pour voir les réponses (si existantes)
                        if (comment.repliesCount > 0) ...[
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (_expandedCommentIds.contains(comment.id)) {
                                  _expandedCommentIds.remove(comment.id);
                                } else {
                                  _expandedCommentIds.add(comment.id);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                    size: 16,
                                    color: AppThemeSystem.primaryColor,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${comment.repliesCount}',
                                    style: context.textStyle(FontSizeType.caption).copyWith(
                                      color: AppThemeSystem.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (comment.likesCount > 0) ...[
                      const SizedBox(width: 12),
                      // Like count (if any)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1877F2), // Facebook blue
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.thumb_up,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${comment.likesCount}',
                            style: context.textStyle(FontSizeType.caption).copyWith(
                              color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Like button
          IconButton(
            onPressed: () => _toggleCommentLike(comment),
            icon: Icon(
              comment.isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
              size: 18,
              color: comment.isLiked
                  ? const Color(0xFF1877F2) // Facebook blue when liked
                  : (isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentWithReplies(
    BuildContext context,
    ConfessionComment comment,
    bool isDark,
    DeviceType deviceType,
  ) {
    final isExpanded = _expandedCommentIds.contains(comment.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Commentaire principal
        _buildCommentItem(context, comment, isDark, deviceType, isExpanded: isExpanded),

        // Réponses (collapsibles)
        if (comment.replies.isNotEmpty && isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Column(
              children: comment.replies.map((reply) {
                return _buildCommentItem(context, reply, isDark, deviceType);
              }).toList(),
            ),
          ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} sem';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min';
    } else {
      return 'À l\'instant';
    }
  }

  // Audio Player Widget
  Widget _buildAudioPlayer(BuildContext context, ConfessionComment comment, bool isDark) {
    final commentId = comment.id;

    // Initialiser le player si nécessaire
    if (!_audioPlayers.containsKey(commentId)) {
      final player = ap.AudioPlayer();
      _audioPlayers[commentId] = player;
      _isPlayingAudio[commentId] = false;
      _isLoadingAudio[commentId] = false;
      _audioDurations[commentId] = Duration.zero;
      _audioPositions[commentId] = Duration.zero;

      // Écouter la durée totale
      player.onDurationChanged.listen((duration) {
        setState(() {
          _audioDurations[commentId] = duration;
        });
      });

      // Écouter la position actuelle
      player.onPositionChanged.listen((position) {
        setState(() {
          _audioPositions[commentId] = position;
        });
      });

      // Écouter l'état de lecture
      player.onPlayerStateChanged.listen((state) {
        if (foundation.kDebugMode) {
          print('🎵 Player state changed for comment $commentId: $state');
        }
        setState(() {
          _isPlayingAudio[commentId] = state == ap.PlayerState.playing;
          // Désactiver le loading quand le player démarre
          if (state == ap.PlayerState.playing) {
            _isLoadingAudio[commentId] = false;
          }
        });
      });

      // Réinitialiser quand terminé
      player.onPlayerComplete.listen((_) {
        setState(() {
          _isPlayingAudio[commentId] = false;
          _isLoadingAudio[commentId] = false;
          _audioPositions[commentId] = Duration.zero;
        });
      });
    }

    final isPlaying = _isPlayingAudio[commentId] ?? false;
    final isLoading = _isLoadingAudio[commentId] ?? false;
    final duration = _audioDurations[commentId] ?? Duration.zero;
    final position = _audioPositions[commentId] ?? Duration.zero;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppThemeSystem.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppThemeSystem.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Bouton Play/Pause
          GestureDetector(
            onTap: () async {
              // Ne pas permettre de cliquer si déjà en chargement
              if (isLoading) return;

              final player = _audioPlayers[commentId]!;

              if (foundation.kDebugMode) {
                print('🎵 Audio player button tapped');
                print('🎵 Comment ID: $commentId');
                print('🎵 Media URL: ${comment.mediaUrl}');
                print('🎵 Is playing: $isPlaying');
              }

              if (isPlaying) {
                if (foundation.kDebugMode) print('⏸️ Pausing audio...');
                await player.pause();
              } else {
                // Activer le loading
                setState(() {
                  _isLoadingAudio[commentId] = true;
                });

                // Arrêter tous les autres audios
                for (var entry in _audioPlayers.entries) {
                  if (entry.key != commentId) {
                    await entry.value.stop();
                  }
                }

                try {
                  // Jouer l'audio
                  if (position.inSeconds > 0 && position.inSeconds < duration.inSeconds) {
                    // Reprendre là où on s'était arrêté
                    if (foundation.kDebugMode) print('▶️ Resuming audio...');
                    await player.resume();
                  } else {
                    // Commencer depuis le début
                    if (foundation.kDebugMode) print('▶️ Playing audio from URL: ${comment.mediaUrl}');
                    await player.play(ap.UrlSource(comment.mediaUrl!));
                  }
                } catch (e) {
                  if (foundation.kDebugMode) print('❌ Error playing audio: $e');
                  // Désactiver le loading en cas d'erreur
                  setState(() {
                    _isLoadingAudio[commentId] = false;
                  });
                  Get.snackbar(
                    'Erreur',
                    'Impossible de lire l\'audio',
                    backgroundColor: AppThemeSystem.errorColor,
                    colorText: Colors.white,
                  );
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppThemeSystem.primaryColor,
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? const SizedBox(
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

          // Barre de progression et durée
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Durées
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatAudioDuration(position),
                      style: context.textStyle(FontSizeType.caption).copyWith(
                        color: AppThemeSystem.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      _formatAudioDuration(duration),
                      style: context.textStyle(FontSizeType.caption).copyWith(
                        color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
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
                    backgroundColor: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300,
                    valueColor: AlwaysStoppedAnimation<Color>(AppThemeSystem.primaryColor),
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
            color: isPlaying ? AppThemeSystem.primaryColor : (isDark ? AppThemeSystem.grey500 : AppThemeSystem.grey400),
            size: 20,
          ),
        ],
      ),
    );
  }

  String _formatAudioDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
