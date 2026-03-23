import 'dart:io';
import 'dart:async';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:weylo/app/data/services/chat_service.dart';
import 'package:weylo/app/data/services/message_cache_service.dart';
import 'package:weylo/app/data/services/realtime_service.dart';
import 'package:weylo/app/data/services/conversation_state_service.dart';
import 'package:weylo/app/data/services/gift_service.dart';
import 'package:weylo/app/data/models/chat_message_model.dart';
import 'package:weylo/app/data/models/conversation_model.dart';
import 'package:weylo/app/data/models/user_model.dart';
import 'package:weylo/app/data/models/gift_model.dart';
import 'package:weylo/app/data/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';
import 'package:weylo/app/modules/chat/controllers/chat_controller.dart';

class ChatDetailController extends GetxController {
  final String contactName;
  final String contactId;

  ChatDetailController({required this.contactName, required this.contactId});

  final ChatService _chatService = ChatService();
  final MessageCacheService _cacheService = MessageCacheService();
  final AuthService _authService = AuthService();
  final GiftService _giftService = GiftService();
  RealtimeService? _realtimeService;
  ConversationStateService? _conversationStateService;

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
  final TextEditingController messageTextController = TextEditingController();
  final ScrollController scrollController = ScrollController();
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
  final Rx<ChatMessageModel?> replyToMessage = Rx<ChatMessageModel?>(null);
  Map<String, dynamic>? _oneShotMetadata;

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

  // Typing indicator
  final showTypingIndicator = false.obs;
  final typingUserName = ''.obs;
  Timer? _typingTimer;
  Timer? _typingDisplayTimer;
  DateTime? _lastTypingEmit;
  static const Duration _typingThrottle = Duration(seconds: 3);
  static const Duration _typingDisplayDuration = Duration(seconds: 3);

  @override
  void onInit() {
    super.onInit();
    _setupScrollListener();
    _initializeController();
    _loadGifts();
  }

  @override
  void onClose() {
    // IMPORTANT: Marquer la conversation comme fermée
    if (conversationId != null) {
      _conversationStateService?.markConversationAsClosed();
      print('👁️ [ChatDetailController] Conversation marquée comme fermée');
    }

    // Sauvegarder les messages dans le cache avant de fermer
    if (conversationId != null && messages.isNotEmpty) {
      print('💾 [ChatDetailController] Sauvegarde des messages dans le cache avant fermeture...');
      _cacheService.saveMessagesCache(conversationId!, messages.toList());
    }

    // Se désabonner du WebSocket
    if (conversationId != null && _realtimeService != null) {
      _realtimeService!.unsubscribeFromChannel('private-conversation.$conversationId');
      print('🔌 [ChatDetailController] Unsubscribed from WebSocket');
    }

    // Nettoyer les audio players
    for (var player in _audioPlayers.values) {
      player.dispose();
    }
    _audioPlayers.clear();

    // Nettoyer le recorder
    _recordTimer?.cancel();
    _audioRecorder?.closeRecorder();

    // Nettoyer les timers de typing
    _typingTimer?.cancel();
    _typingDisplayTimer?.cancel();

    // Nettoyer les controllers
    messageTextController.dispose();
    scrollController.dispose();

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

      // Récupérer le ConversationStateService
      try {
        _conversationStateService = ConversationStateService.to;
        print('✅ [ChatDetailController] ConversationStateService récupéré');
      } catch (e) {
        print('⚠️ [ChatDetailController] ConversationStateService non disponible: $e');
      }

      // Récupérer l'ID de la conversation depuis les arguments
      final args = Get.arguments;
      print('📦 [ChatDetailController] Arguments: $args');

      if (args != null && args['conversationId'] != null) {
        conversationId = args['conversationId'];
        print('✅ [ChatDetailController] conversationId set to: $conversationId');

        // Pré-configurer une réponse (ex: depuis un post sponsorisé dans le feed)
        if (args is Map && args['replyPreset'] is Map) {
          try {
            final preset = args['replyPreset'] as Map;
            final senderUsername = (preset['sender'] as String?) ?? 'Sponsorisé';
            final content = (preset['content'] as String?) ?? '(Media)';
            final sponsorshipId = preset['sponsorshipId'];

            final sender = UserModel.fromJson({
              'id': 0,
              'first_name': senderUsername,
              'full_name': senderUsername,
              'username': senderUsername,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });

            final fakeId = sponsorshipId is int ? -sponsorshipId : -1;
            replyToMessage.value = ChatMessageModel(
              id: fakeId,
              conversationId: conversationId!,
              senderId: 0,
              sender: sender,
              content: content,
              type: ChatMessageType.text,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            if (preset['meta'] is Map) {
              _oneShotMetadata = Map<String, dynamic>.from(preset['meta'] as Map);
            }

            print('🧩 [ChatDetailController] Reply preset applied');
          } catch (e) {
            print('⚠️ [ChatDetailController] Reply preset failed: $e');
          }
        }

        // IMPORTANT: Marquer cette conversation comme ouverte (pour ne pas incrémenter le badge)
        _conversationStateService?.markConversationAsOpen(conversationId!);
        print('👁️ [ChatDetailController] Conversation marquée comme ouverte');

        // Charger la conversation complète pour avoir accès à isAnonymous et identityRevealed
        await loadConversation();

        // Toujours forcer un refresh au chargement initial pour avoir les données fraîches
        await loadMessages(refresh: true);

        // IMPORTANT: Marquer la conversation comme lue
        await _conversationStateService?.markConversationAsRead(conversationId!);
        print('✅ [ChatDetailController] Conversation marquée comme lue');

        // S'abonner au WebSocket pour les messages en temps réel
        _initializeWebSocket();
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

  /// Charger les messages depuis le cache ou l'API
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

    // NOUVEAU: Tentative de chargement depuis le cache si pas de refresh
    if (!refresh && _cacheService.isMessagesCacheValid(conversationId!)) {
      final cachedMessages = _cacheService.getMessagesCache(conversationId!);
      if (cachedMessages != null && cachedMessages.isNotEmpty) {
        messages.value = cachedMessages;
        currentPage = _cacheService.getMessagesCachedPage(conversationId!);
        print('📦 [ChatDetailController] ✅ Chargé depuis CACHE: ${cachedMessages.length} messages');

        // Auto-scroll vers le bas après chargement depuis cache
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollToBottom(animated: false);
        });

        return; // Sortir immédiatement
      }
    }

    // Si pas de cache valide ou refresh demandé: Fetch depuis API
    refresh ? isLoading.value = true : isLoadingMore.value = true;
    hasError.value = false;

    try {
      print('📡 [ChatDetailController] Calling ChatService.getMessages (API)...');
      final response = await _chatService.getMessages(
        conversationId: conversationId!,
        page: currentPage,
        perPage: 50,
      );

      print('✅ [ChatDetailController] Got ${response.messages.length} messages from API');

      // Backend retourne maintenant ASC (anciens en premier, récents en fin) - ordre chronologique naturel
      if (refresh) {
        messages.value = response.messages;
      } else {
        // Pour la pagination: insérer les anciens messages au début
        messages.insertAll(0, response.messages);
      }

      currentPage = response.meta.currentPage;
      lastPage = response.meta.lastPage;
      canLoadMore.value = response.meta.hasMorePages;

      // NOUVEAU: Sauvegarder dans le cache après fetch API
      await _cacheService.saveMessagesCache(conversationId!, messages.toList(), page: currentPage);

      print('📊 [ChatDetailController] Total messages in list: ${messages.length}');

      // Auto-scroll vers le bas après le premier chargement
      if (refresh || currentPage == 1) {
        // Attendre que le build soit terminé avant de scroller
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollToBottom(animated: false);
        });
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      print('❌ [ChatDetailController] Error loading messages: $e');

      // NOUVEAU: Mode dégradé - Afficher le cache expiré si disponible
      if (!refresh) {
        final expiredCache = _cacheService.getMessagesCacheExpired(conversationId!);
        if (expiredCache != null && expiredCache.isNotEmpty) {
          messages.value = expiredCache;
          print('⚠️ [ChatDetailController] Mode hors ligne: ${expiredCache.length} messages depuis cache expiré');

          Get.snackbar(
            'Mode hors ligne',
            'Affichage des messages en cache',
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 2),
          );
        }
      }
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

  /// Auto-scroll vers le bas de la liste de messages
  void scrollToBottom({bool animated = true}) {
    print('📜 [ChatDetailController] scrollToBottom called - hasClients: ${scrollController.hasClients}');
    if (scrollController.hasClients) {
      final maxScroll = scrollController.position.maxScrollExtent;
      print('📜 [ChatDetailController] Scrolling to bottom - maxScrollExtent: $maxScroll');

      if (animated) {
        scrollController.animateTo(
          maxScroll,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        scrollController.jumpTo(maxScroll);
      }
    } else {
      print('⚠️ [ChatDetailController] ScrollController has no clients yet, retrying...');
      // Réessayer après un court délai
      Future.delayed(const Duration(milliseconds: 100), () {
        if (scrollController.hasClients) {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
          print('✅ [ChatDetailController] Scrolled to bottom after retry');
        }
      });
    }
  }

  /// Initialiser le listener pour la pagination inverse
  void _setupScrollListener() {
    scrollController.addListener(() {
      // Si on scroll vers le haut et qu'on atteint le début
      if (scrollController.position.pixels <= 100 && canLoadMore.value && !isLoadingMore.value) {
        print('📜 [ChatDetailController] Reached top - loading more messages...');
        loadMoreMessages();
      }
    });
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
      // Si on répond à un message, ajouter le replyToMessageId dans metadata
      final finalMetadata = <String, dynamic>{};
      if (_oneShotMetadata != null) {
        finalMetadata.addAll(_oneShotMetadata!);
      }
      if (metadata != null) {
        finalMetadata.addAll(metadata);
      }
      if (replyToMessage.value != null) {
        finalMetadata['reply_to_message_id'] = replyToMessage.value!.id;
        finalMetadata['reply_to_content'] = replyToMessage.value!.content;
        finalMetadata['reply_to_sender'] = replyToMessage.value!.sender?.username;
      }

      final message = await _chatService.sendMessage(
        conversationId: conversationId!,
        content: content?.trim(),
        type: type,
        audioFile: audioFile,
        imageFile: imageFile,
        videoFile: videoFile,
        voiceType: voiceType,
        metadata: finalMetadata,
      );

      // Ajouter le message à la liste des messages
      messages.add(message);

      // Auto-scroll vers le bas après l'ajout du message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom(animated: true);
      });

      // Vider le champ de texte et annuler la réponse
      messageText.value = '';
      messageTextController.clear();
      cancelReply();
      _oneShotMetadata = null;

      // Invalider le cache après envoi
      await _cacheService.invalidateConversationCache(conversationId!);
      await _cacheService.invalidateAllConversationsCache();
      print('🗑️ [ChatDetailController] Cache invalidé après envoi de message');

      // Rafraîchir la liste des conversations pour mettre à jour le preview
      try {
        final chatController = Get.find<ChatController>();
        await chatController.refreshConversations();
        print('✅ [ChatDetailController] Liste des conversations rafraîchie');
      } catch (e) {
        print('⚠️ [ChatDetailController] ChatController not found, skipping refresh: $e');
      }

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

      print('✅ [ChatDetailController] Loaded ${gifts.length} gifts and ${giftCategories.length} categories');
    } catch (e) {
      print('❌ [ChatDetailController] Error loading gifts: $e');
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

  // ==================== AUDIO RECORDING ====================

  Future<void> toggleRecording() async {
    if (isRecording.value) {
      await stopRecording();
    } else {
      // Afficher le sélecteur de voix avant de démarrer l'enregistrement
      showVoiceTypeSelector();
    }
  }

  /// Afficher le sélecteur de type de voix
  void showVoiceTypeSelector() {
    final context = Get.context;
    if (context == null) return;

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

                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.mic_rounded,
                        size: 40,
                        color: AppThemeSystem.primaryColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Choisissez un type de voix',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppThemeSystem.blackColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sélectionnez le type de voix pour votre message vocal',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                Divider(
                  height: 1,
                  color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
                ),

                // Voice types list
                ...voiceTypes.map((voiceType) {
                  final isSelected = selectedVoiceType.value == voiceType['id'];
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
                          selectedVoiceType.value = selectedType;
                          print('✅ Voice type selected: $selectedType');

                          Navigator.pop(modalContext);

                          // Attendre que le bottom sheet soit fermé avant de démarrer l'enregistrement
                          Future.delayed(const Duration(milliseconds: 300), () {
                            print('🎙️ Starting recording with voice type: ${selectedVoiceType.value}');
                            startRecording();
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
                }).toList(),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
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

  // ==================== REPLY & DELETE ====================

  /// Répondre à un message
  void setReplyToMessage(ChatMessageModel message) {
    replyToMessage.value = message;
    print('📝 [ChatDetailController] Reply to message ${message.id}');
  }

  /// Annuler la réponse
  void cancelReply() {
    replyToMessage.value = null;
    print('❌ [ChatDetailController] Reply cancelled');
  }

  /// Obtenir le nom à afficher (Anonyme si conversation anonyme non révélée)
  String get displayName {
    final conv = conversation.value;
    // Vérifier si l'utilisateur connecté a le forfait Premium/Certification
    final currentUser = _authService.getCurrentUser();
    final hasPremium = currentUser?.hasActivePremium ?? false;

    // Si Premium, toujours montrer la vraie identité
    if (conv != null && conv.isAnonymous && !conv.identityRevealed && !hasPremium) {
      return 'Anonyme';
    }
    return contactName;
  }

  /// Obtenir l'initial à afficher dans l'avatar
  String get displayInitial {
    final conv = conversation.value;
    // Vérifier si l'utilisateur connecté a le forfait Premium/Certification
    final currentUser = _authService.getCurrentUser();
    final hasPremium = currentUser?.hasActivePremium ?? false;

    // Si Premium, toujours montrer la vraie initial
    if (conv != null && conv.isAnonymous && !conv.identityRevealed && !hasPremium) {
      return '?';
    }
    return contactName[0].toUpperCase();
  }

  /// Vérifier si on doit afficher le badge vérifié
  bool get shouldShowBadge {
    final conv = conversation.value;
    // Vérifier si l'utilisateur connecté a le forfait Premium/Certification
    final currentUser = _authService.getCurrentUser();
    final hasPremium = currentUser?.hasActivePremium ?? false;

    // Si Premium, montrer le badge même si anonyme
    if (conv != null && conv.isAnonymous && !conv.identityRevealed && !hasPremium) {
      return false; // Pas de badge si anonyme non révélé ET pas Premium
    }
    return conv?.otherParticipant?.shouldShowBlueBadge ?? false;
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
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('🎵 [ChatDetailController] TOGGLE AUDIO PLAYBACK');
    print('═══════════════════════════════════════════════════════════');
    print('🎵 Message ID: $messageId');
    print('🎵 Audio URL: $audioUrl');

    final player = initializeAudioPlayer(messageId);
    final isPlaying = audioPlayingStates[messageId] ?? false;
    final isLoading = audioLoadingStates[messageId] ?? false;

    print('🎵 Is playing: $isPlaying');
    print('🎵 Is loading: $isLoading');

    if (isLoading) {
      print('⚠️ Already loading, aborting');
      print('═══════════════════════════════════════════════════════════');
      print('');
      return;
    }

    if (isPlaying) {
      print('⏸️ Pausing audio...');
      await player.pause();
      print('✅ Audio paused');
      print('═══════════════════════════════════════════════════════════');
      print('');
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

      final position = audioPositions[messageId] ?? Duration.zero;
      final duration = audioDurations[messageId] ?? Duration.zero;

      print('📊 Position: ${position.inSeconds}s, Duration: ${duration.inSeconds}s');

      try {
        if (position.inSeconds > 0 && position.inSeconds < duration.inSeconds) {
          print('▶️ Resuming audio from position ${position.inSeconds}s...');
          await player.resume();
        } else {
          print('▶️ Playing audio from URL...');
          print('🌐 Full URL: $audioUrl');
          await player.play(ap.UrlSource(audioUrl));
        }
        print('✅ Audio play command sent successfully');

        // Safety timeout: si après 5 secondes le loading est toujours actif, le désactiver
        Future.delayed(const Duration(seconds: 5), () {
          if (audioLoadingStates[messageId] == true && audioPlayingStates[messageId] == false) {
            print('⚠️ Audio loading timeout - forcing loading state to false');
            audioLoadingStates[messageId] = false;
            audioPlayerUpdate.value++;
          }
        });

        print('═══════════════════════════════════════════════════════════');
        print('');
      } catch (e) {
        print('❌ Error playing audio: $e');
        print('❌ Error type: ${e.runtimeType}');
        print('❌ Stack trace: ${StackTrace.current}');
        audioLoadingStates[messageId] = false;
        audioPlayerUpdate.value++; // Trigger rebuild

        Get.snackbar(
          'Erreur',
          'Impossible de lire l\'audio: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        print('═══════════════════════════════════════════════════════════');
        print('');
      }
    }
  }

  /// Éditer un message existant
  Future<void> editMessage(ChatMessageModel message, String newContent) async {
    if (conversationId == null) {
      print('❌ Error: conversationId is null');
      return;
    }

    if (newContent.trim().isEmpty) {
      Get.snackbar(
        'Erreur',
        'Le message ne peut pas être vide',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Vérifier si le message peut être édité
    if (!message.canBeEdited(currentUserId!)) {
      Get.snackbar(
        'Erreur',
        'Ce message ne peut plus être modifié (délai de 15 minutes dépassé)',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      print('✏️ [ChatDetailController] Editing message ${message.id}...');

      final updatedMessage = await _chatService.updateMessage(
        conversationId: conversationId!,
        messageId: message.id,
        content: newContent.trim(),
      );

      // Mettre à jour le message dans la liste
      final index = messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        messages[index] = updatedMessage;
        print('✅ [ChatDetailController] Message mis à jour dans la liste');
      }

      // Invalider le cache
      await _cacheService.invalidateConversationCache(conversationId!);
      print('🗑️ [ChatDetailController] Cache invalidé après édition');

      Get.snackbar(
        'Succès',
        'Message modifié',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('❌ [ChatDetailController] Error editing message: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de modifier le message',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Supprimer un message
  Future<void> deleteMessage(ChatMessageModel message) async {
    if (conversationId == null) {
      print('❌ Error: conversationId is null');
      return;
    }

    try {
      print('🗑️ [ChatDetailController] Deleting message ${message.id}...');

      await _chatService.deleteMessage(
        conversationId: conversationId!,
        messageId: message.id,
      );

      // Retirer le message de la liste
      messages.removeWhere((m) => m.id == message.id);
      print('✅ [ChatDetailController] Message supprimé de la liste');

      // Invalider le cache
      await _cacheService.invalidateConversationCache(conversationId!);
      print('🗑️ [ChatDetailController] Cache invalidé après suppression');

      Get.snackbar(
        'Succès',
        'Message supprimé',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('❌ [ChatDetailController] Error deleting message: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer le message',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Gérer le changement de texte dans le TextField (typing indicator)
  void onMessageTextChanged(String text) {
    if (conversationId == null) return;

    // Si le texte est vide, ne pas émettre
    if (text.trim().isEmpty) {
      return;
    }

    // Throttle: Émettre seulement si au moins 3 secondes se sont écoulées
    final now = DateTime.now();
    if (_lastTypingEmit != null && now.difference(_lastTypingEmit!) < _typingThrottle) {
      print('⚠️ [ChatDetailController] Typing throttled');
      return;
    }

    // Émettre l'événement de typing
    _emitTypingEvent();
    _lastTypingEmit = now;

    // Reset le timer pour arrêter l'émission après 3s d'inactivité
    _typingTimer?.cancel();
    _typingTimer = Timer(_typingThrottle, () {
      _lastTypingEmit = null;
      print('⏱️ [ChatDetailController] Typing timer reset');
    });
  }

  /// Émettre l'événement de typing vers l'API
  void _emitTypingEvent() async {
    if (conversationId == null) return;

    try {
      print('⌨️ [ChatDetailController] Emitting typing event...');
      await _chatService.sendTypingIndicator(conversationId!);
      print('✅ [ChatDetailController] Typing event sent');
    } catch (e) {
      // Fail silently - typing n'est pas critique
      print('⚠️ [ChatDetailController] Typing event failed (non-critical): $e');
    }
  }

  /// Afficher l'indicateur de typing (appelé par WebSocket - Phase 2)
  /// TODO: Implémenter avec Pusher/Laravel Echo
  void _showTypingIndicator(String username) {
    typingUserName.value = username;
    showTypingIndicator.value = true;

    print('⌨️ [ChatDetailController] Showing typing indicator for $username');

    // Cacher automatiquement après 3 secondes
    _typingDisplayTimer?.cancel();
    _typingDisplayTimer = Timer(_typingDisplayDuration, () {
      showTypingIndicator.value = false;
      print('⏱️ [ChatDetailController] Hiding typing indicator');
    });
  }

  /// Initialiser la connexion WebSocket pour cette conversation
  void _initializeWebSocket() async {
    if (conversationId == null) {
      print('⚠️ [ChatDetailController] Cannot initialize WebSocket: conversationId is null');
      return;
    }

    try {
      // Récupérer ou créer le RealtimeService
      if (!Get.isRegistered<RealtimeService>()) {
        Get.put(RealtimeService());
      }
      _realtimeService = Get.find<RealtimeService>();

      print('🔌 [ChatDetailController] Initializing WebSocket for conversation $conversationId');

      // S'abonner au canal de la conversation
      await _realtimeService!.subscribeToPrivateChannel(
        channelName: 'private-conversation.$conversationId',
        onEvent: _handleNewMessageFromWebSocket,
      );

      print('✅ [ChatDetailController] WebSocket subscribed successfully');
    } catch (e) {
      print('❌ [ChatDetailController] Error initializing WebSocket: $e');
    }
  }

  /// Gérer la réception d'un nouveau message via WebSocket
  void _handleNewMessageFromWebSocket(Map<String, dynamic> eventData) {
    try {
      print('📨 [ChatDetailController] New message received from WebSocket');
      print('📨 [ChatDetailController] Event data: $eventData');

      // Extraire l'événement
      final event = eventData['_event'] as String?;
      print('📨 [ChatDetailController] Event name: $event');

      // Vérifier que c'est bien un message.sent
      if (event != 'message.sent') {
        // Gérer d'autres événements (typing, etc.)
        if (event == 'user.typing') {
          // Vérifier que ce n'est pas notre propre événement de typing
          final typingUserId = eventData['user_id'] as int?;
          if (typingUserId == currentUserId) {
            print('⚠️ [ChatDetailController] Ignoring own typing event');
            return;
          }

          // Afficher l'indicateur de typing pour l'autre utilisateur
          final username = eventData['username'] as String? ?? 'Utilisateur';
          print('⌨️ [ChatDetailController] User $username (ID: $typingUserId) is typing');
          _showTypingIndicator(username);
        }
        return;
      }

      // Vérifier que ce n'est pas notre propre message
      final senderId = eventData['sender_id'] as int?;
      if (senderId == currentUserId) {
        print('⚠️ [ChatDetailController] Ignoring own message from WebSocket');
        return;
      }

      // Créer le modèle de message depuis les données
      final newMessage = ChatMessageModel.fromJson(eventData);

      // Vérifier si le message existe déjà (éviter les doublons)
      final exists = messages.any((m) => m.id == newMessage.id);
      if (exists) {
        print('⚠️ [ChatDetailController] Message already exists, skipping');
        return;
      }

      // Ajouter le nouveau message à la liste
      messages.add(newMessage);
      print('✅ [ChatDetailController] New message added to list');

      // Invalider le cache
      _cacheService.invalidateConversationCache(conversationId!);

      // Auto-scroll vers le bas
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom(animated: true);
      });

      // Pas besoin de marquer comme lu manuellement :
      // ConversationStateService gère déjà automatiquement le markAsRead
      // car la conversation est marquée comme "ouverte" (currentOpenConversationId)
    } catch (e) {
      print('❌ [ChatDetailController] Error handling new message from WebSocket: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }
}
