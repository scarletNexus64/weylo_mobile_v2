import 'dart:io';
import 'dart:async';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:weylo/app/data/services/chat_service.dart';
import 'package:weylo/app/data/models/chat_message_model.dart';
import 'package:weylo/app/data/models/conversation_model.dart';
import 'package:weylo/app/data/services/auth_service.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';
import 'package:flutter/material.dart';

class ChatDetailController extends GetxController {
  final String contactName;
  final String contactId;

  ChatDetailController({required this.contactName, required this.contactId});

  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  // États
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  // Données
  final messages = <ChatMessageModel>[].obs;
  final conversation = Rx<ConversationModel?>(null);
  int? conversationId;
  int? currentUserId;

  // Pagination
  int currentPage = 1;
  int lastPage = 1;
  final canLoadMore = false.obs;

  // UI States
  final messageText = ''.obs;
  final isRecording = false.obs;
  final showGiftPicker = false.obs;
  final selectedGiftCategory = 'Romance'.obs;
  final isAnimatingGift = false.obs;
  final animatedGift = Rx<Map<String, dynamic>?>(null);

  // Audio recording
  FlutterSoundRecorder? _audioRecorder;
  String? _recordedAudioPath;
  final recordDuration = Duration.zero.obs;
  Timer? _recordTimer;
  final selectedVoiceType = 'normal'.obs;

  // Audio players pour les messages vocaux
  final Map<int, ap.AudioPlayer> _audioPlayers = {};
  final audioPlayingStates = <int, bool>{}.obs;
  final audioLoadingStates = <int, bool>{}.obs;
  final audioDurations = <int, Duration>{}.obs;
  final audioPositions = <int, Duration>{}.obs;
  final audioPlayerUpdate = 0.obs; // Pour trigger les rebuilds

  final giftCategories = {
    'Romance': [
      {'name': 'Rose', 'icon': '🌹', 'description': 'Rose rouge', 'price': 500},
      {'name': 'Coeur', 'icon': '❤️', 'description': 'Coeur d\'amour', 'price': 1000},
      {'name': 'Bouquet', 'icon': '💐', 'description': 'Bouquet de fleurs', 'price': 2500},
      {'name': 'Bague', 'icon': '💍', 'description': 'Bague de fiançailles', 'price': 50000},
    ],
    'Nourriture': [
      {'name': 'Chocolat', 'icon': '🍫', 'description': 'Barre de chocolat', 'price': 300},
      {'name': 'Gâteau', 'icon': '🍰', 'description': 'Gâteau délicieux', 'price': 1500},
      {'name': 'Pizza', 'icon': '🍕', 'description': 'Pizza chaude', 'price': 3000},
      {'name': 'Champagne', 'icon': '🍾', 'description': 'Bouteille de champagne', 'price': 8000},
    ],
    'Boissons': [
      {'name': 'Café', 'icon': '☕', 'description': 'Café chaud', 'price': 500},
      {'name': 'Jus', 'icon': '🧃', 'description': 'Jus de fruits', 'price': 800},
      {'name': 'Vin Rouge', 'icon': '🍷', 'description': 'Bouteille de vin', 'price': 5000},
      {'name': 'Cocktail', 'icon': '🍹', 'description': 'Cocktail tropical', 'price': 2500},
    ],
    'Luxe': [
      {'name': 'Diamant', 'icon': '💎', 'description': 'Diamant précieux', 'price': 100000},
      {'name': 'Couronne', 'icon': '👑', 'description': 'Couronne royale', 'price': 75000},
      {'name': 'Montre', 'icon': '⌚', 'description': 'Montre de luxe', 'price': 150000},
      {'name': 'Voiture', 'icon': '🚗', 'description': 'Voiture de luxe', 'price': 5000000},
    ],
    'Fun': [
      {'name': 'Cadeau', 'icon': '🎁', 'description': 'Cadeau surprise', 'price': 1000},
      {'name': 'Ballon', 'icon': '🎈', 'description': 'Ballon festif', 'price': 200},
      {'name': 'Feu d\'artifice', 'icon': '🎆', 'description': 'Feu d\'artifice', 'price': 10000},
      {'name': 'Trophée', 'icon': '🏆', 'description': 'Trophée gagnant', 'price': 5000},
    ],
  };

  @override
  void onInit() {
    super.onInit();
    _initializeController();
  }

  @override
  void onClose() {
    // Nettoyer les audio players
    for (var player in _audioPlayers.values) {
      player.dispose();
    }
    _audioPlayers.clear();

    // Nettoyer le recorder
    _recordTimer?.cancel();
    _audioRecorder?.closeRecorder();

    super.onClose();
  }

  /// Initialiser le contrôleur
  Future<void> _initializeController() async {
    try {
      print('🚀 [ChatDetailController] _initializeController called');

      // Initialiser l'enregistreur audio
      _audioRecorder = FlutterSoundRecorder();
      await _audioRecorder!.openRecorder();

      // Récupérer l'ID de l'utilisateur actuel
      final user = _authService.getCurrentUser();
      currentUserId = user?.id;
      print('👤 [ChatDetailController] Current user ID: $currentUserId');

      // Récupérer l'ID de la conversation depuis les arguments
      final args = Get.arguments;
      print('📦 [ChatDetailController] Arguments: $args');

      if (args != null && args['conversationId'] != null) {
        conversationId = args['conversationId'];
        print('✅ [ChatDetailController] conversationId set to: $conversationId');

        // Charger la conversation complète pour avoir accès à isAnonymous et identityRevealed
        await loadConversation();

        await loadMessages();
      } else {
        print('❌ [ChatDetailController] No conversationId in arguments!');
      }
    } catch (e) {
      print('❌ [ChatDetailController] Error initializing: $e');
      hasError.value = true;
      errorMessage.value = 'Impossible de charger la conversation';
    }
  }

  /// Charger la conversation complète
  Future<void> loadConversation() async {
    try {
      print('💬 [ChatDetailController] Loading conversation details...');
      final conv = await _chatService.getConversation(conversationId!);
      conversation.value = conv;
      print('✅ [ChatDetailController] Conversation loaded - isAnonymous: ${conv.isAnonymous}, identityRevealed: ${conv.identityRevealed}');
    } catch (e) {
      print('❌ [ChatDetailController] Error loading conversation: $e');
    }
  }

  /// Charger les messages depuis l'API
  Future<void> loadMessages({bool refresh = false}) async {
    print('💬 [ChatDetailController] loadMessages - conversationId: $conversationId, refresh: $refresh');

    if (conversationId == null) {
      print('❌ [ChatDetailController] conversationId is null, aborting');
      return;
    }

    if (refresh) {
      currentPage = 1;
      messages.clear();
      print('🔄 [ChatDetailController] Cleared messages for refresh');
    }

    if (isLoading.value || isLoadingMore.value) {
      print('⚠️ [ChatDetailController] Already loading, skipping...');
      return;
    }

    refresh ? isLoading.value = true : isLoadingMore.value = true;
    hasError.value = false;

    try {
      print('📡 [ChatDetailController] Calling ChatService.getMessages...');
      final response = await _chatService.getMessages(
        conversationId: conversationId!,
        page: currentPage,
        perPage: 50,
      );

      print('✅ [ChatDetailController] Got ${response.messages.length} messages');

      if (refresh) {
        messages.value = response.messages.reversed.toList();
      } else {
        messages.insertAll(0, response.messages.reversed.toList());
      }

      currentPage = response.meta.currentPage;
      lastPage = response.meta.lastPage;
      canLoadMore.value = response.meta.hasMorePages;

      print('📊 [ChatDetailController] Total messages in list: ${messages.length}');
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      print('❌ [ChatDetailController] Error loading messages: $e');
      print('❌ [ChatDetailController] Stack trace: ${StackTrace.current}');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
      print('✅ [ChatDetailController] Loading completed');
    }
  }

  /// Charger plus de messages (pagination)
  Future<void> loadMoreMessages() async {
    if (canLoadMore.value && !isLoadingMore.value) {
      currentPage++;
      await loadMessages();
    }
  }

  /// Rafraîchir les messages
  Future<void> refreshMessages() async {
    await loadMessages(refresh: true);
  }

  /// Vérifier si un message a été envoyé par moi
  bool isSentByMe(ChatMessageModel message) {
    return message.senderId == currentUserId;
  }

  /// Envoyer un message dans la conversation
  Future<void> sendMessage({
    String? content,
    String type = 'text',
    File? audioFile,
    File? imageFile,
    File? videoFile,
    String? voiceType,
    Map<String, dynamic>? metadata,
  }) async {
    if (conversationId == null) {
      print('Error: conversationId is null');
      return;
    }

    if ((content == null || content.trim().isEmpty) && audioFile == null && imageFile == null && videoFile == null) {
      print('Error: Cannot send empty message');
      return;
    }

    try {
      final message = await _chatService.sendMessage(
        conversationId: conversationId!,
        content: content?.trim(),
        type: type,
        audioFile: audioFile,
        imageFile: imageFile,
        videoFile: videoFile,
        voiceType: voiceType,
        metadata: metadata,
      );

      // Ajouter le message à la liste des messages
      messages.add(message);

      // Vider le champ de texte
      messageText.value = '';

      // Marquer comme lu
      await _chatService.markAsRead(conversationId!);
    } catch (e) {
      print('Error sending message: $e');
      Get.snackbar(
        'Erreur',
        'Impossible d\'envoyer le message',
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    }
  }

  void selectGiftCategory(String category) {
    selectedGiftCategory.value = category;
  }

  // ==================== AUDIO RECORDING ====================

  Future<void> toggleRecording() async {
    if (isRecording.value) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  Future<void> startRecording() async {
    var status = await Permission.microphone.status;

    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }

    if (!status.isGranted) {
      Get.snackbar(
        'Permission requise',
        'L\'accès au microphone est nécessaire pour enregistrer un message vocal',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/chat_audio_${DateTime.now().millisecondsSinceEpoch}.aac';

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
      print('❌ Error starting recording: $e');
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
            await sendAudioMessage(audioFile);
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
      print('❌ Error stopping recording: $e');
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
      print('Error canceling recording: $e');
    }
  }

  Future<void> sendAudioMessage(File audioFile) async {
    _recordedAudioPath = null;
    recordDuration.value = Duration.zero;

    try {
      await sendMessage(
        type: 'audio',
        audioFile: audioFile,
        voiceType: selectedVoiceType.value,
      );

      // Supprimer le fichier temporaire
      if (await audioFile.exists()) {
        await audioFile.delete();
      }
    } catch (e) {
      print('Error sending audio message: $e');
      Get.snackbar(
        'Erreur',
        'Impossible d\'envoyer le message audio',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Supprimer le fichier en cas d'erreur
      if (await audioFile.exists()) {
        await audioFile.delete();
      }
    }
  }

  void toggleGiftPicker() {
    showGiftPicker.value = !showGiftPicker.value;
  }

  /// Obtenir le nom à afficher (Anonyme si conversation anonyme non révélée)
  String get displayName {
    final conv = conversation.value;
    if (conv != null && conv.isAnonymous && !conv.identityRevealed) {
      return 'Anonyme';
    }
    return contactName;
  }

  /// Obtenir l'initial à afficher dans l'avatar
  String get displayInitial {
    final conv = conversation.value;
    if (conv != null && conv.isAnonymous && !conv.identityRevealed) {
      return '?';
    }
    return contactName[0].toUpperCase();
  }

  /// Initialiser un audio player pour un message
  ap.AudioPlayer initializeAudioPlayer(int messageId) {
    if (_audioPlayers.containsKey(messageId)) {
      return _audioPlayers[messageId]!;
    }

    final player = ap.AudioPlayer();
    _audioPlayers[messageId] = player;
    audioPlayingStates[messageId] = false;
    audioLoadingStates[messageId] = false;
    audioDurations[messageId] = Duration.zero;
    audioPositions[messageId] = Duration.zero;

    // Écouter la durée
    player.onDurationChanged.listen((duration) {
      if (audioDurations[messageId] != duration) {
        audioDurations[messageId] = duration;
        audioPlayerUpdate.value++; // Trigger rebuild
      }
    });

    // Écouter la position - throttle pour éviter trop de rebuilds
    DateTime? lastPositionUpdate;
    player.onPositionChanged.listen((position) {
      final now = DateTime.now();
      // Mettre à jour seulement toutes les 500ms
      if (lastPositionUpdate == null ||
          now.difference(lastPositionUpdate!) > const Duration(milliseconds: 500)) {
        audioPositions[messageId] = position;
        lastPositionUpdate = now;
        audioPlayerUpdate.value++; // Trigger rebuild
      } else {
        // Mettre à jour la position sans rebuild
        audioPositions[messageId] = position;
      }
    });

    // Écouter l'état
    player.onPlayerStateChanged.listen((state) {
      final wasPlaying = audioPlayingStates[messageId] ?? false;
      final isPlaying = state == ap.PlayerState.playing;

      if (wasPlaying != isPlaying) {
        audioPlayingStates[messageId] = isPlaying;
        if (isPlaying) {
          audioLoadingStates[messageId] = false;
        }
        audioPlayerUpdate.value++; // Trigger rebuild
      }
    });

    // Quand terminé
    player.onPlayerComplete.listen((_) {
      audioPlayingStates[messageId] = false;
      audioLoadingStates[messageId] = false;
      audioPositions[messageId] = Duration.zero;
      audioPlayerUpdate.value++; // Trigger rebuild
    });

    return player;
  }

  /// Jouer ou mettre en pause un message vocal
  Future<void> toggleAudioPlayback(int messageId, String audioUrl) async {
    print('🎵 [ChatDetailController] Toggle audio playback');
    print('🎵 Message ID: $messageId');
    print('🎵 Audio URL: $audioUrl');

    final player = initializeAudioPlayer(messageId);
    final isPlaying = audioPlayingStates[messageId] ?? false;
    final isLoading = audioLoadingStates[messageId] ?? false;

    print('🎵 Is playing: $isPlaying');
    print('🎵 Is loading: $isLoading');

    if (isLoading) {
      print('⚠️ Already loading, aborting');
      return;
    }

    if (isPlaying) {
      print('⏸️ Pausing audio...');
      await player.pause();
    } else {
      // Stopper tous les autres
      print('🛑 Stopping other players...');
      for (var entry in _audioPlayers.entries) {
        if (entry.key != messageId) {
          await entry.value.stop();
        }
      }

      audioLoadingStates[messageId] = true;
      audioPlayerUpdate.value++; // Trigger rebuild
      print('⏳ Loading state set to true');

      try {
        final position = audioPositions[messageId] ?? Duration.zero;
        final duration = audioDurations[messageId] ?? Duration.zero;

        print('📊 Position: ${position.inSeconds}s, Duration: ${duration.inSeconds}s');

        if (position.inSeconds > 0 && position.inSeconds < duration.inSeconds) {
          print('▶️ Resuming audio...');
          await player.resume().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Audio resume timeout');
            },
          );
        } else {
          print('▶️ Playing audio from URL...');
          await player.play(ap.UrlSource(audioUrl)).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Audio play timeout');
            },
          );
        }
        print('✅ Audio play command sent');
      } catch (e) {
        print('❌ Error playing audio: $e');
        print('❌ Stack trace: ${StackTrace.current}');
        audioLoadingStates[messageId] = false;
        audioPlayerUpdate.value++; // Trigger rebuild

        String errorMessage = 'Impossible de lire l\'audio';
        if (e is TimeoutException) {
          errorMessage = 'Le fichier audio ne peut pas être chargé. Veuillez réessayer.';
        }

        Get.snackbar(
          'Erreur',
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }
}
