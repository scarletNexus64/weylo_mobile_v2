import 'dart:io';
import 'dart:async';
import 'package:get/get.dart';
import 'package:weylo/app/data/services/group_service.dart';
import 'package:weylo/app/data/services/gift_service.dart';
import 'package:weylo/app/data/models/group_message_model.dart';
import 'package:weylo/app/data/models/group_model.dart';
import 'package:weylo/app/data/models/group_member_model.dart';
import 'package:weylo/app/data/models/gift_model.dart';
import 'package:weylo/app/data/services/auth_service.dart';
import 'package:weylo/app/data/services/realtime_service.dart';
import 'package:weylo/app/modules/home/controllers/home_controller.dart';
import 'package:weylo/app/modules/groupe/controllers/groupe_controller.dart';
import 'package:weylo/app/widgets/image_caption_dialog.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart' as ap;

class GroupeDetailController extends GetxController {
  final String groupName;
  final String groupId;
  final int memberCount;

  GroupeDetailController({
    required this.groupName,
    required this.groupId,
    required this.memberCount,
  });

  final GroupService _groupService = GroupService();
  final AuthService _authService = AuthService();
  final GiftService _giftService = GiftService();
  RealtimeService? _realtimeService;

  // Controllers
  final scrollController = ScrollController();
  final messageController = TextEditingController();

  // États
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  // Données
  final messages = <GroupMessageModel>[].obs;
  final group = Rx<GroupModel?>(null);
  int? currentUserId;

  // Pagination
  int currentPage = 1;
  int lastPage = 1;
  final canLoadMore = false.obs;

  // UI States
  final messageText = ''.obs;
  final isRecording = false.obs;
  final showGiftPicker = false.obs;
  final selectedGiftCategoryId = Rx<int?>(null);
  final isAnimatingGift = false.obs;
  final animatedGift = Rx<Map<String, dynamic>?>(null);

  // Gifts data from API
  final gifts = <GiftModel>[].obs;
  final giftCategories = <GiftCategory>[].obs;
  final isLoadingGifts = false.obs;

  // Reply state
  final Rx<GroupMessageModel?> replyToMessage = Rx<GroupMessageModel?>(null);

  // Audio recording
  FlutterSoundRecorder? _audioRecorder;
  final recordedAudioPath = Rxn<String>();
  final recordDuration = Rx<Duration>(Duration.zero);
  Timer? _recordTimer;
  final selectedVoiceType = 'normal'.obs;
  final showVoiceTypePicker = false.obs;

  // Audio playback
  final Map<int, ap.AudioPlayer> _audioPlayers = {};
  final audioPlayingStates = <int, bool>{}.obs;
  final audioLoadingStates = <int, bool>{}.obs;
  final audioDurations = <int, Duration>{}.obs;
  final audioPositions = <int, Duration>{}.obs;
  final audioPlayerUpdate = 0.obs; // Pour forcer les rebuilds

  @override
  void onInit() {
    super.onInit();
    _initializeController();
    scrollController.addListener(_onScroll);
    _initAudioRecorder();
    _loadGifts();
  }

  @override
  void onClose() {
    scrollController.dispose();
    messageController.dispose();
    _recordTimer?.cancel();
    _audioRecorder?.closeRecorder();
    // Nettoyer les audio players
    for (var player in _audioPlayers.values) {
      player.dispose();
    }
    _audioPlayers.clear();
    // Unsubscribe du WebSocket
    if (_realtimeService != null) {
      _realtimeService!.unsubscribeFromChannel('private-group.$groupId');
      print('🔌 [GroupeDetailController] Unsubscribed from WebSocket');
    }
    super.onClose();
  }

  /// Initialize audio recorder
  Future<void> _initAudioRecorder() async {
    _audioRecorder = FlutterSoundRecorder();
    await _audioRecorder!.openRecorder();
  }

  void _onScroll() {
    if (scrollController.position.pixels <= 100 && canLoadMore.value && !isLoadingMore.value) {
      loadMoreMessages();
    }
  }

  /// Initialiser le contrôleur
  Future<void> _initializeController() async {
    try {
      // Récupérer l'ID de l'utilisateur actuel
      final user = await _authService.getCurrentUser();
      currentUserId = user?.id;

      // Convertir groupId en int et charger les messages
      final groupIdInt = int.tryParse(groupId);
      if (groupIdInt != null) {
        // Charger les informations complètes du groupe
        await _loadGroupInfo(groupIdInt);

        await loadMessages(groupIdInt, initialLoad: true);
        // Marquer les messages comme lus
        await _markGroupAsRead(groupIdInt);
        // Configurer les listeners WebSocket après avoir chargé les messages
        await _setupRealtimeListeners();
      }
    } catch (e) {
      print('Error initializing group detail: $e');
      hasError.value = true;
      errorMessage.value = 'Impossible de charger le groupe';
    }
  }

  /// Charger les informations complètes du groupe
  Future<void> _loadGroupInfo(int groupId) async {
    try {
      print('📋 [GroupeDetailController] Loading group info...');
      final groupData = await _groupService.getGroup(groupId);
      group.value = groupData;
      print('✅ [GroupeDetailController] Group info loaded: ${groupData.name}');
    } catch (e) {
      print('❌ [GroupeDetailController] Error loading group info: $e');
      // Ne pas bloquer si ça échoue
    }
  }

  /// Marquer le groupe comme lu
  Future<void> _markGroupAsRead(int groupId) async {
    try {
      await _groupService.markAsRead(groupId);
      print('✅ [GroupeDetailController] Group marked as read');

      // Rafraîchir le count dans le HomeController
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        homeController.refreshNotificationCounts();
      }
    } catch (e) {
      print('⚠️ [GroupeDetailController] Error marking group as read: $e');
      // Ne pas bloquer si ça échoue
    }
  }

  /// Charger les messages du groupe depuis l'API
  Future<void> loadMessages(int groupId, {bool refresh = false, bool initialLoad = false}) async {
    if (refresh) {
      currentPage = 1;
      messages.clear();
    }

    if (isLoading.value || isLoadingMore.value) return;

    refresh ? isLoading.value = true : isLoadingMore.value = true;
    hasError.value = false;

    try {
      final response = await _groupService.getMessages(
        groupId: groupId,
        page: currentPage,
        perPage: 50,
      );

      print('📥 [GroupeDetailController] Loaded ${response.messages.length} messages');

      // Debug: Log image messages with captions
      for (var msg in response.messages) {
        if (msg.type == GroupMessageType.image) {
          print('🖼️ Image message: id=${msg.id}, content="${msg.content}", mediaUrl=${msg.mediaUrl}');
        }
      }

      if (refresh || initialLoad) {
        // Backend déjà envoie les messages dans l'ordre chronologique (ancien→récent)
        // Pas besoin de reverser!
        messages.value = response.messages;
        // Scroll vers le bas après un délai pour laisser le temps au widget de se construire
        // Utiliser plusieurs tentatives pour s'assurer que le scroll fonctionne
        Future.delayed(const Duration(milliseconds: 100), () => _scrollToBottom());
        Future.delayed(const Duration(milliseconds: 300), () => _scrollToBottom());
        Future.delayed(const Duration(milliseconds: 600), () => _scrollToBottom());
      } else {
        // Pour la pagination, insérer au début (messages plus anciens)
        messages.insertAll(0, response.messages);
      }

      currentPage = response.meta.currentPage;
      lastPage = response.meta.lastPage;
      canLoadMore.value = response.meta.hasMorePages;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      print('Error loading group messages: $e');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Charger plus de messages (pagination)
  Future<void> loadMoreMessages() async {
    final groupIdInt = int.tryParse(groupId);
    if (groupIdInt != null && canLoadMore.value && !isLoadingMore.value) {
      currentPage++;
      await loadMessages(groupIdInt);
    }
  }

  /// Rafraîchir les messages
  Future<void> refreshMessages() async {
    final groupIdInt = int.tryParse(groupId);
    if (groupIdInt != null) {
      await loadMessages(groupIdInt, refresh: true);
    }
  }

  /// Vérifier si un message a été envoyé par moi
  bool isSentByMe(GroupMessageModel message) {
    return message.senderId == currentUserId;
  }

  void selectGiftCategory(int? categoryId) {
    selectedGiftCategoryId.value = categoryId;
  }

  /// Charger les cadeaux et catégories depuis l'API
  Future<void> _loadGifts() async {
    try {
      isLoadingGifts.value = true;

      // Charger les catégories et les cadeaux en parallèle
      final results = await Future.wait([
        _giftService.getCategories(),
        _giftService.getGifts(),
      ]);

      giftCategories.value = results[0] as List<GiftCategory>;
      gifts.value = results[1] as List<GiftModel>;

      print('✅ [GroupeDetailController] Loaded ${gifts.length} gifts and ${giftCategories.length} categories');
    } catch (e) {
      print('❌ [GroupeDetailController] Error loading gifts: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger les cadeaux',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoadingGifts.value = false;
    }
  }

  void toggleVoiceTypePicker() {
    showVoiceTypePicker.value = !showVoiceTypePicker.value;
  }

  void selectVoiceType(String voiceType) {
    selectedVoiceType.value = voiceType;
  }

  /// Start recording audio
  Future<void> startRecording() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        Get.snackbar(
          'Permission refusée',
          'Veuillez autoriser l\'accès au microphone',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Generate unique filename
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      recordedAudioPath.value = '${directory.path}/voice_$timestamp.aac';

      // Start recording
      await _audioRecorder!.startRecorder(
        toFile: recordedAudioPath.value,
        codec: Codec.aacADTS,
        sampleRate: 44100,
        numChannels: 1,
        bitRate: 128000,
      );

      isRecording.value = true;
      recordDuration.value = Duration.zero;

      // Timer
      _recordTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        recordDuration.value = Duration(seconds: recordDuration.value.inSeconds + 1);
      });
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de démarrer l\'enregistrement',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Stop recording and send automatically
  Future<void> stopRecording() async {
    try {
      final path = await _audioRecorder!.stopRecorder();
      isRecording.value = false;
      _recordTimer?.cancel();

      final audioPath = path ?? recordedAudioPath.value;

      if (audioPath != null) {
        final audioFile = File(audioPath);

        if (await audioFile.exists()) {
          final fileSize = await audioFile.length();

          if (fileSize > 0) {
            // Send automatically
            await sendAudio(audioFile);
          } else {
            Get.snackbar(
              'Erreur',
              'L\'enregistrement audio est vide',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        }
      }

      // Reset
      recordedAudioPath.value = null;
      recordDuration.value = Duration.zero;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'arrêter l\'enregistrement',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Cancel recording without sending
  Future<void> cancelRecording() async {
    try {
      await _audioRecorder!.stopRecorder();
      _recordTimer?.cancel();

      // Delete the audio file if it exists
      if (recordedAudioPath.value != null) {
        final audioFile = File(recordedAudioPath.value!);
        if (await audioFile.exists()) {
          await audioFile.delete();
        }
      }

      // Reset states
      isRecording.value = false;
      recordedAudioPath.value = null;
      recordDuration.value = Duration.zero;
    } catch (e) {
      print('Error canceling recording: $e');
    }
  }

  void toggleGiftPicker() {
    showGiftPicker.value = !showGiftPicker.value;
  }

  /// Envoyer un message texte dans le groupe
  Future<void> sendMessage() async {
    final content = messageController.text.trim();
    if (content.isEmpty) return;

    final groupIdInt = int.tryParse(groupId);
    if (groupIdInt == null) return;

    try {
      // Préparer les metadata pour le reply si présent
      Map<String, dynamic>? metadata;
      if (replyToMessage.value != null) {
        metadata = {
          'reply_to_message_id': replyToMessage.value!.id,
          'reply_to_content': replyToMessage.value!.content ?? '(Media)',
          'reply_to_sender': replyToMessage.value!.sender?.fullName ?? 'Anonyme',
        };
      }

      // Ajouter le message optimiste dans l'UI
      final tempMessage = GroupMessageModel(
        id: -DateTime.now().millisecondsSinceEpoch,
        groupId: groupIdInt,
        senderId: currentUserId ?? 0,
        content: content,
        type: GroupMessageType.text,
        metadata: metadata,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      messages.add(tempMessage);

      // Effacer le champ de texte et annuler le reply
      messageController.clear();
      messageText.value = '';
      cancelReply();

      // Scroller vers le bas
      _scrollToBottom();

      // Envoyer au backend
      final sentMessage = await _groupService.sendMessage(
        groupId: groupIdInt,
        content: content,
        type: 'text',
        metadata: metadata,
        replyToMessageId: replyToMessage.value?.id,
      );

      // Remplacer le message temporaire par le vrai
      final index = messages.indexWhere((m) => m.id == tempMessage.id);
      if (index != -1) {
        messages[index] = sentMessage;
      }
    } catch (e) {
      print('Error sending message: $e');
      Get.snackbar(
        'Erreur',
        'Impossible d\'envoyer le message',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Scroller vers le bas de la liste
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        try {
          // Utiliser jumpTo au lieu de animateTo pour un scroll instantané et fiable
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
          print('📜 [GroupeDetailController] Scrolled to bottom (max: ${scrollController.position.maxScrollExtent})');
        } catch (e) {
          print('❌ [GroupeDetailController] Failed to scroll: $e');
        }
      } else {
        print('⚠️ [GroupeDetailController] ScrollController has no clients yet');
      }
    });
  }

  /// Envoyer une image dans le groupe
  Future<void> sendImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final imageFile = File(pickedFile.path);

      // Afficher le dialog pour ajouter une légende
      await Get.dialog(
        ImageCaptionDialog(
          imageFile: imageFile,
          onSend: (caption) async {
            await _sendImageWithCaption(imageFile, caption);
          },
        ),
      );
    } catch (e) {
      print('❌ Error picking image: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de sélectionner l\'image',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Envoyer l'image avec sa légende
  Future<void> _sendImageWithCaption(File imageFile, String caption) async {
    try {
      final groupIdInt = int.tryParse(groupId);
      if (groupIdInt == null) return;

      // Préparer les metadata pour le reply si présent
      Map<String, dynamic>? metadata;
      if (replyToMessage.value != null) {
        metadata = {
          'reply_to_message_id': replyToMessage.value!.id,
          'reply_to_content': replyToMessage.value!.content ?? '(Media)',
          'reply_to_sender': replyToMessage.value!.sender?.fullName ?? 'Anonyme',
        };
      }

      // Ajouter un message de chargement
      final tempMessage = GroupMessageModel(
        id: -DateTime.now().millisecondsSinceEpoch,
        groupId: groupIdInt,
        senderId: currentUserId ?? 0,
        content: caption.isEmpty ? 'Envoi de l\'image...' : caption,
        type: GroupMessageType.image,
        metadata: metadata,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      messages.add(tempMessage);
      _scrollToBottom();

      // Envoyer au backend
      final sentMessage = await _groupService.sendMessage(
        groupId: groupIdInt,
        content: caption.isEmpty ? '' : caption,
        type: 'image',
        imageFile: imageFile,
        metadata: metadata,
        replyToMessageId: replyToMessage.value?.id,
      );

      // Annuler le reply après l'envoi
      cancelReply();

      // Remplacer le message temporaire par le vrai
      final index = messages.indexWhere((m) => m.id == tempMessage.id);
      if (index != -1) {
        messages[index] = sentMessage;
      }
    } catch (e) {
      print('Error sending image: $e');
      Get.snackbar(
        'Erreur',
        'Impossible d\'envoyer l\'image',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Envoyer un message audio dans le groupe
  Future<void> sendAudio(File audioFile) async {
    try {
      final groupIdInt = int.tryParse(groupId);
      if (groupIdInt == null) return;

      // Préparer les metadata pour le reply si présent
      Map<String, dynamic>? metadata;
      if (replyToMessage.value != null) {
        metadata = {
          'reply_to_message_id': replyToMessage.value!.id,
          'reply_to_content': replyToMessage.value!.content ?? '(Media)',
          'reply_to_sender': replyToMessage.value!.sender?.fullName ?? 'Anonyme',
        };
      }

      // Ajouter un message de chargement
      final tempMessage = GroupMessageModel(
        id: -DateTime.now().millisecondsSinceEpoch,
        groupId: groupIdInt,
        senderId: currentUserId ?? 0,
        content: 'Envoi de l\'audio...',
        type: GroupMessageType.audio,
        metadata: metadata,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      messages.add(tempMessage);
      _scrollToBottom();

      // Envoyer au backend avec le type de voix
      final sentMessage = await _groupService.sendMessage(
        groupId: groupIdInt,
        content: '',
        type: 'audio',
        audioFile: audioFile,
        voiceType: selectedVoiceType.value,
        metadata: metadata,
        replyToMessageId: replyToMessage.value?.id,
      );

      // Annuler le reply après l'envoi
      cancelReply();

      // Remplacer le message temporaire par le vrai
      final index = messages.indexWhere((m) => m.id == tempMessage.id);
      if (index != -1) {
        messages[index] = sentMessage;
      }

      // Arrêter l'enregistrement
      isRecording.value = false;
    } catch (e) {
      print('Error sending audio: $e');
      Get.snackbar(
        'Erreur',
        'Impossible d\'envoyer l\'audio',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Envoyer un cadeau dans le groupe
  Future<void> sendGift(GiftModel gift) async {
    try {
      final groupIdInt = int.tryParse(groupId);
      if (groupIdInt == null) return;

      // ⚠️ Dans un groupe, on ne peut envoyer un cadeau QU'EN REPLY à quelqu'un
      if (replyToMessage.value == null) {
        Get.snackbar(
          'Attention',
          'Pour envoyer un cadeau dans un groupe, vous devez répondre au message de quelqu\'un',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      final recipient = replyToMessage.value!.sender;
      final recipientName = recipient?.fullName ?? 'Anonyme';

      // Préparer les metadata avec le cadeau ET le reply
      final metadata = {
        'gift': true,
        'icon': gift.icon,
        'name': gift.name,
        'price': gift.price,
        'reply_to_message_id': replyToMessage.value!.id,
        'reply_to_content': replyToMessage.value!.content ?? '(Media)',
        'reply_to_sender': recipientName,
        'recipient_id': replyToMessage.value!.senderId,
      };

      // Sauvegarder le reply message avant de l'annuler
      final replyMessageId = replyToMessage.value!.id;

      // Ajouter un message temporaire AVANT l'animation pour l'afficher immédiatement
      final tempMessage = GroupMessageModel(
        id: -DateTime.now().millisecondsSinceEpoch,
        groupId: groupIdInt,
        senderId: currentUserId ?? 0,
        content: '🎁 ${gift.name} envoyé à $recipientName',
        type: GroupMessageType.gift,
        metadata: metadata,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      messages.add(tempMessage);

      // Fermer le gift picker explicitement
      showGiftPicker.value = false;

      _scrollToBottom();

      // Animation du cadeau (en arrière-plan)
      animatedGift.value = {
        'icon': gift.icon,
        'name': gift.name,
        'price': gift.price,
      };
      isAnimatingGift.value = true;

      // Arrêter l'animation après 1.5 secondes
      await Future.delayed(const Duration(milliseconds: 1500));
      isAnimatingGift.value = false;
      animatedGift.value = null;

      // Envoyer au backend avec type 'gift'
      final sentMessage = await _groupService.sendMessage(
        groupId: groupIdInt,
        content: '🎁 ${gift.name} envoyé à $recipientName',
        type: 'gift',
        metadata: metadata,
        replyToMessageId: replyMessageId,
      );

      // Annuler le reply APRÈS l'envoi
      cancelReply();

      // Remplacer le message temporaire par le vrai
      final index = messages.indexWhere((m) => m.id == tempMessage.id);
      if (index != -1) {
        messages[index] = sentMessage;
      }

      // Notification de succès
      Get.snackbar(
        'Succès',
        'Cadeau envoyé à $recipientName ! 💝',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('Error sending gift: $e');

      // Gérer l'erreur de solde insuffisant
      String errorMessage = 'Impossible d\'envoyer le cadeau';
      if (e.toString().contains('402') || e.toString().contains('Solde insuffisant')) {
        errorMessage = 'Solde insuffisant pour envoyer ce cadeau 💸';
      }

      Get.snackbar(
        'Erreur',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Recharger les messages pour supprimer le message temporaire
      await refreshMessages();
    } finally {
      // S'assurer que l'animation et le gift picker sont toujours arrêtés
      isAnimatingGift.value = false;
      animatedGift.value = null;
      if (showGiftPicker.value) {
        showGiftPicker.value = false;
      }
    }
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

    // Écouter la position
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
    final player = initializeAudioPlayer(messageId);
    final isPlaying = audioPlayingStates[messageId] ?? false;
    final isLoading = audioLoadingStates[messageId] ?? false;

    if (isLoading) return;

    if (isPlaying) {
      await player.pause();
    } else {
      // Stopper tous les autres
      for (var entry in _audioPlayers.entries) {
        if (entry.key != messageId) {
          await entry.value.stop();
        }
      }

      audioLoadingStates[messageId] = true;
      audioPlayerUpdate.value++; // Trigger rebuild

      final position = audioPositions[messageId] ?? Duration.zero;
      final duration = audioDurations[messageId] ?? Duration.zero;

      try {
        if (position.inSeconds > 0 && position.inSeconds < duration.inSeconds) {
          player.resume();
        } else {
          player.play(ap.UrlSource(audioUrl));
        }
      } catch (e) {
        audioLoadingStates[messageId] = false;
        audioPlayerUpdate.value++; // Trigger rebuild

        Get.snackbar(
          'Erreur',
          'Impossible de lire l\'audio',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  /// Configurer les listeners WebSocket pour recevoir les messages en temps réel
  Future<void> _setupRealtimeListeners() async {
    try {
      // Récupérer ou créer le RealtimeService
      if (!Get.isRegistered<RealtimeService>()) {
        Get.put(RealtimeService());
      }
      _realtimeService = Get.find<RealtimeService>();

      print('🔌 [GroupeDetailController] Initializing WebSocket for group $groupId');

      // S'abonner au canal du groupe
      await _realtimeService!.subscribeToPrivateChannel(
        channelName: 'private-group.$groupId',
        onEvent: _handleNewMessageFromWebSocket,
      );

      print('✅ [GroupeDetailController] WebSocket subscribed successfully');
    } catch (e) {
      print('❌ [GroupeDetailController] Error initializing WebSocket: $e');
    }
  }

  /// Gérer la réception d'un nouveau message via WebSocket
  void _handleNewMessageFromWebSocket(Map<String, dynamic> eventData) {
    try {
      print('📨 [GroupeDetailController] New message received from WebSocket');
      print('📨 [GroupeDetailController] Event data: $eventData');

      // Extraire l'événement
      final event = eventData['_event'] as String?;
      print('📨 [GroupeDetailController] Event name: $event');

      // Gérer les différents types d'événements
      if (event == 'message.deleted') {
        // Gérer la suppression d'un message
        final messageId = eventData['message_id'] as int?;
        if (messageId != null) {
          messages.removeWhere((m) => m.id == messageId);
          print('✅ [GroupeDetailController] Message $messageId supprimé via WebSocket');
        }
        return;
      }

      // Vérifier que c'est bien un message.sent
      if (event != 'message.sent') {
        print('⚠️ [GroupeDetailController] Ignoring event: $event');
        return;
      }

      // Vérifier que c'est pour notre groupe
      final groupIdFromEvent = eventData['group_id'] as int?;
      final groupIdInt = int.tryParse(groupId);
      if (groupIdFromEvent != groupIdInt) {
        print('⚠️ [GroupeDetailController] Message is for group $groupIdFromEvent, ignoring');
        return;
      }

      // Ne pas ajouter notre propre message (déjà ajouté de manière optimiste)
      final senderId = eventData['sender_id'] as int?;
      if (senderId == currentUserId) {
        print('⚠️ [GroupeDetailController] Ignoring our own message');
        return;
      }

      // Créer un message à partir des données reçues en utilisant fromJson
      // pour bénéficier du parsing des champs sender_*
      final newMessage = GroupMessageModel.fromJson(eventData);

      // Ajouter à la liste
      messages.add(newMessage);
      print('✅ [GroupeDetailController] Message added to list');

      // Scroller vers le bas
      _scrollToBottom();
    } catch (e) {
      print('❌ [GroupeDetailController] Error handling WebSocket message: $e');
    }
  }

  /// Mapper le type de message string vers l'enum
  GroupMessageType _mapStringToMessageType(String? type) {
    switch (type) {
      case 'text':
        return GroupMessageType.text;
      case 'audio':
        return GroupMessageType.audio;
      case 'image':
        return GroupMessageType.image;
      case 'video':
        return GroupMessageType.video;
      case 'system':
        return GroupMessageType.system;
      case 'gift':
        return GroupMessageType.gift;
      default:
        return GroupMessageType.text;
    }
  }

  // ==================== REPLY & DELETE ====================

  /// Répondre à un message
  void setReplyToMessage(GroupMessageModel message) {
    replyToMessage.value = message;
    print('📝 [GroupeDetailController] Reply to message ${message.id}');
  }

  /// Annuler la réponse
  void cancelReply() {
    replyToMessage.value = null;
    print('❌ [GroupeDetailController] Reply cancelled');
  }

  /// Supprimer un message du groupe
  Future<void> deleteMessage(GroupMessageModel message) async {
    final groupIdInt = int.tryParse(groupId);
    if (groupIdInt == null) {
      print('❌ Error: groupId is invalid');
      return;
    }

    // Vérifier que c'est bien notre message
    if (message.senderId != currentUserId) {
      Get.snackbar(
        'Erreur',
        'Vous ne pouvez supprimer que vos propres messages',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Les messages système ne peuvent pas être supprimés
    if (message.type == GroupMessageType.system) {
      Get.snackbar(
        'Erreur',
        'Les messages système ne peuvent pas être supprimés',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      print('🗑️ [GroupeDetailController] Deleting message ${message.id}...');

      // Retirer le message de l'UI immédiatement (optimistic update)
      messages.removeWhere((m) => m.id == message.id);

      // Appeler l'API pour supprimer le message
      await _groupService.deleteMessage(
        groupId: groupIdInt,
        messageId: message.id,
      );

      print('✅ [GroupeDetailController] Message supprimé avec succès');

      Get.snackbar(
        'Succès',
        'Message supprimé',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('❌ [GroupeDetailController] Error deleting message: $e');

      // Recharger les messages en cas d'erreur
      await refreshMessages();

      Get.snackbar(
        'Erreur',
        'Impossible de supprimer le message',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ==================== GROUP MANAGEMENT ====================

  /// Rename group (creator only)
  Future<void> renameGroup(String newName) async {
    if (newName.trim().isEmpty) return;

    final groupIdInt = int.tryParse(groupId);
    if (groupIdInt == null) return;

    try {
      print('✏️ [GroupeDetailController] Renaming group to: $newName');

      final updatedGroup = await _groupService.updateGroup(
        groupId: groupIdInt,
        name: newName,
      );

      // Mettre à jour le groupe local
      group.value = updatedGroup;

      Get.snackbar(
        'Succès',
        'Le groupe a été renommé',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeSystem.successColor,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('❌ [GroupeDetailController] Error renaming group: $e');

      Get.snackbar(
        'Erreur',
        'Impossible de renommer le groupe',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeSystem.errorColor,
        colorText: Colors.white,
      );
    }
  }

  /// Update group info (name, description, avatar, max_members) - creator only
  Future<void> updateGroupInfo({
    String? name,
    String? description,
    int? maxMembers,
    File? avatarFile,
  }) async {
    final groupIdInt = int.tryParse(groupId);
    if (groupIdInt == null) return;

    try {
      print('🔄 [GroupeDetailController] Updating group info...');

      final updatedGroup = await _groupService.updateGroup(
        groupId: groupIdInt,
        name: name,
        description: description,
        maxMembers: maxMembers,
        avatarFile: avatarFile, // Maintenant supporté par le backend !
      );

      // Debug: Afficher les données reçues du backend
      print('📊 [GroupeDetailController] Updated group data:');
      print('   - ID: ${updatedGroup.id}');
      print('   - Name: ${updatedGroup.name}');
      print('   - Members count: ${updatedGroup.membersCount}');
      print('   - Avatar URL: ${updatedGroup.avatarUrl}');
      print('   - Is creator: ${updatedGroup.isCreator}');
      print('   - Is admin: ${updatedGroup.isAdmin}');

      // Mettre à jour le groupe local
      group.value = updatedGroup;

      // Mettre à jour les listes du GroupeController en temps réel
      try {
        final groupeController = Get.find<GroupeController>();

        // Trouver et mettre à jour le groupe dans "Mes groupes"
        final myGroupIndex = groupeController.myGroups.indexWhere((g) => g.id == groupIdInt);
        if (myGroupIndex != -1) {
          print('📝 [GroupeDetailController] Updating myGroups at index $myGroupIndex');
          print('   - Old members count: ${groupeController.myGroups[myGroupIndex].membersCount}');
          print('   - New members count: ${updatedGroup.membersCount}');
          print('   - Old avatar: ${groupeController.myGroups[myGroupIndex].avatarUrl}');
          print('   - New avatar: ${updatedGroup.avatarUrl}');

          groupeController.myGroups[myGroupIndex] = updatedGroup;
          groupeController.myGroups.refresh();
        }

        // Mettre à jour aussi dans "Découvrir" si présent
        final discoverIndex = groupeController.discoverGroups.indexWhere((g) => g.id == groupIdInt);
        if (discoverIndex != -1) {
          print('📝 [GroupeDetailController] Updating discoverGroups at index $discoverIndex');
          groupeController.discoverGroups[discoverIndex] = updatedGroup;
          groupeController.discoverGroups.refresh();
        }

        print('✅ [GroupeDetailController] Updated GroupeController lists after edit');
      } catch (e) {
        print('⚠️ [GroupeDetailController] Could not update GroupeController: $e');
      }

      // Recharger les informations complètes du groupe pour s'assurer que tout est à jour
      await _loadGroupInfo(groupIdInt);

      Get.snackbar(
        'Succès',
        'Les informations du groupe ont été mises à jour',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeSystem.successColor,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Retourner avec un résultat pour indiquer qu'il faut rafraîchir
      Get.back(result: 'updated');
    } catch (e) {
      print('❌ [GroupeDetailController] Error updating group info: $e');

      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour les informations',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeSystem.errorColor,
        colorText: Colors.white,
      );
    }
  }

  /// Delete group (creator only)
  Future<void> deleteGroup() async {
    final groupIdInt = int.tryParse(groupId);
    if (groupIdInt == null) return;

    try {
      print('🗑️ [GroupeDetailController] Deleting group...');

      await _groupService.deleteGroup(groupIdInt);

      // Mettre à jour les listes du GroupeController en temps réel
      try {
        final groupeController = Get.find<GroupeController>();

        // Retirer le groupe de "Mes groupes"
        groupeController.myGroups.removeWhere((g) => g.id == groupIdInt);

        // Retirer aussi le groupe de "Découvrir" s'il y est
        groupeController.discoverGroups.removeWhere((g) => g.id == groupIdInt);

        print('✅ [GroupeDetailController] Updated GroupeController lists after deletion');
      } catch (e) {
        print('⚠️ [GroupeDetailController] Could not update GroupeController: $e');
      }

      // Attendre un peu avant de naviguer pour voir le changement dans l'UI
      await Future.delayed(const Duration(milliseconds: 100));

      // Fermer les overlays/snackbars pour permettre la navigation
      print('📍 [GroupeDetailController] DELETE - Current route before navigation: ${Get.currentRoute}');
      Get.closeAllSnackbars();

      // Navigation simple : fermer GroupInfoView si présente, puis GroupDetailView
      // On fait 2 backs pour couvrir les deux cas (GroupInfoView + GroupDetailView OU juste GroupDetailView)
      print('📍 [GroupeDetailController] DELETE - Attempting first back...');
      if (Get.key.currentState?.canPop() ?? false) {
        Get.back();
        await Future.delayed(const Duration(milliseconds: 100));
        print('📍 [GroupeDetailController] DELETE - After first back, route: ${Get.currentRoute}');
      }

      print('📍 [GroupeDetailController] DELETE - Attempting second back...');
      if (Get.key.currentState?.canPop() ?? false) {
        Get.back();
        await Future.delayed(const Duration(milliseconds: 100));
        print('📍 [GroupeDetailController] DELETE - After second back, route: ${Get.currentRoute}');
      }

      // Afficher le snackbar après la navigation
      Get.snackbar(
        'Succès',
        'Le groupe a été supprimé',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeSystem.successColor,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('❌ [GroupeDetailController] Error deleting group: $e');

      Get.snackbar(
        'Erreur',
        'Impossible de supprimer le groupe',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeSystem.errorColor,
        colorText: Colors.white,
      );
    }
  }

  /// Report group (members only, not creator)
  Future<void> reportGroup(String reason, String? description) async {
    final groupIdInt = int.tryParse(groupId);
    if (groupIdInt == null) return;

    try {
      print('🚩 [GroupeDetailController] Reporting group for: $reason');

      await _groupService.reportGroup(
        groupId: groupIdInt,
        reason: reason,
        description: description,
      );

      Get.snackbar(
        'Succès',
        'Signalement envoyé. Notre équipe va examiner votre demande.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeSystem.successColor,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      print('❌ [GroupeDetailController] Error reporting group: $e');

      String errorMessage = 'Impossible d\'envoyer le signalement';
      if (e.toString().contains('déjà signalé')) {
        errorMessage = 'Vous avez déjà signalé ce groupe récemment';
      } else if (e.toString().contains('créateur')) {
        errorMessage = 'Vous ne pouvez pas signaler votre propre groupe';
      }

      Get.snackbar(
        'Erreur',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeSystem.errorColor,
        colorText: Colors.white,
      );
    }
  }

  /// Leave group (all members except creator)
  Future<void> leaveGroup() async {
    final groupIdInt = int.tryParse(groupId);
    if (groupIdInt == null) return;

    try {
      print('👋 [GroupeDetailController] Leaving group...');

      await _groupService.leaveGroup(groupIdInt);

      // Mettre à jour les listes du GroupeController en temps réel
      try {
        final groupeController = Get.find<GroupeController>();

        // Retirer le groupe de "Mes groupes"
        groupeController.myGroups.removeWhere((g) => g.id == groupIdInt);

        // Rafraîchir la liste "Découvrir" pour montrer à nouveau le groupe
        await groupeController.loadDiscoverGroups(refresh: true);

        print('✅ [GroupeDetailController] Updated GroupeController lists');
      } catch (e) {
        print('⚠️ [GroupeDetailController] Could not update GroupeController: $e');
      }

      // Attendre un peu avant de naviguer pour voir le changement dans l'UI
      await Future.delayed(const Duration(milliseconds: 100));

      // Fermer les overlays/snackbars pour permettre la navigation
      print('📍 [GroupeDetailController] LEAVE - Current route before navigation: ${Get.currentRoute}');
      Get.closeAllSnackbars();

      // Navigation simple : fermer GroupInfoView si présente, puis GroupDetailView
      // On fait 2 backs pour couvrir les deux cas (GroupInfoView + GroupDetailView OU juste GroupDetailView)
      print('📍 [GroupeDetailController] LEAVE - Attempting first back...');
      if (Get.key.currentState?.canPop() ?? false) {
        Get.back();
        await Future.delayed(const Duration(milliseconds: 100));
        print('📍 [GroupeDetailController] LEAVE - After first back, route: ${Get.currentRoute}');
      }

      print('📍 [GroupeDetailController] LEAVE - Attempting second back...');
      if (Get.key.currentState?.canPop() ?? false) {
        Get.back();
        await Future.delayed(const Duration(milliseconds: 100));
        print('📍 [GroupeDetailController] LEAVE - After second back, route: ${Get.currentRoute}');
      }

      // Afficher le snackbar après la navigation
      Get.snackbar(
        'Succès',
        'Vous avez quitté le groupe',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeSystem.successColor,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('❌ [GroupeDetailController] Error leaving group: $e');

      String errorMessage = 'Impossible de quitter le groupe';
      if (e.toString().contains('créateur') || e.toString().contains('creator')) {
        errorMessage = 'Le créateur ne peut pas quitter son propre groupe';
      } else if (e.toString().contains('membre') || e.toString().contains('member')) {
        errorMessage = 'Vous n\'êtes pas membre de ce groupe';
      }

      Get.snackbar(
        'Erreur',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeSystem.errorColor,
        colorText: Colors.white,
      );
    }
  }

  /// Show members list (for managing members)
  Future<void> showMembersList() async {
    final groupIdInt = int.tryParse(groupId);
    if (groupIdInt == null) return;

    try {
      print('👥 [GroupeDetailController] Loading members list...');

      final members = await _groupService.getGroupMembers(groupIdInt);

      // Afficher un bottom sheet avec la liste des membres
      Get.bottomSheet(
        Container(
          decoration: BoxDecoration(
            color: Get.isDarkMode ? AppThemeSystem.darkCardColor : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.people, color: AppThemeSystem.tertiaryColor),
                    const SizedBox(width: 12),
                    Text(
                      'Membres du groupe (${members.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Members list
              Expanded(
                child: ListView.builder(
                  itemCount: members.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final isCurrentUser = member.userId == currentUserId;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppThemeSystem.tertiaryColor,
                        backgroundImage: member.avatarUrl != null
                            ? NetworkImage(member.avatarUrl!)
                            : null,
                        child: member.avatarUrl == null
                            ? Text(
                                member.effectiveInitial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        member.effectiveDisplayName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        member.role == 'creator'
                            ? 'Créateur'
                            : member.role == 'admin'
                                ? 'Administrateur'
                                : 'Membre',
                        style: TextStyle(
                          color: member.role == 'creator'
                              ? AppThemeSystem.primaryColor
                              : AppThemeSystem.grey600,
                        ),
                      ),
                      trailing: !isCurrentUser && group.value?.isCreator == true
                          ? IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () {
                                _confirmRemoveMember(member);
                              },
                            )
                          : null,
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
        isScrollControlled: true,
        enableDrag: true,
      );
    } catch (e) {
      print('❌ [GroupeDetailController] Error loading members: $e');

      Get.snackbar(
        'Erreur',
        'Impossible de charger la liste des membres',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeSystem.errorColor,
        colorText: Colors.white,
      );
    }
  }

  /// Confirm removing a member
  void _confirmRemoveMember(GroupMemberModel member) {
    Get.dialog(
      AlertDialog(
        title: const Text('Retirer le membre ?'),
        content: Text('Voulez-vous retirer ${member.effectiveDisplayName} du groupe ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _removeMember(member);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
  }

  /// Remove a member from the group
  Future<void> _removeMember(GroupMemberModel member) async {
    final groupIdInt = int.tryParse(groupId);
    if (groupIdInt == null) return;

    try {
      print('👤❌ [GroupeDetailController] Removing member ${member.id}...');

      await _groupService.removeMember(
        groupId: groupIdInt,
        memberId: member.id,
      );

      Get.snackbar(
        'Succès',
        '${member.effectiveDisplayName} a été retiré du groupe',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeSystem.successColor,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Refresh members list
      Get.back();
      showMembersList();
    } catch (e) {
      print('❌ [GroupeDetailController] Error removing member: $e');

      Get.snackbar(
        'Erreur',
        'Impossible de retirer le membre',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeSystem.errorColor,
        colorText: Colors.white,
      );
    }
  }
}
