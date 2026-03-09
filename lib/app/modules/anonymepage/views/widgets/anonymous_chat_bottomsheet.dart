import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:permission_handler/permission_handler.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../data/models/anonymous_message_model.dart';
import '../../../../data/models/gift_model.dart';
import '../../../../data/services/message_service.dart';
import '../../../../data/services/gift_service.dart';
import '../../../../widgets/app_theme_system.dart';

/// Bottom sheet pour répondre à un message anonyme
/// Supporte : Texte, Voice (5 types), Image, Gift
class AnonymousChatBottomSheet extends StatefulWidget {
  final AnonymousMessageModel originalMessage;
  final String recipientUsername;
  final VoidCallback? onMessageSent;

  const AnonymousChatBottomSheet({
    Key? key,
    required this.originalMessage,
    required this.recipientUsername,
    this.onMessageSent,
  }) : super(key: key);

  @override
  State<AnonymousChatBottomSheet> createState() => _AnonymousChatBottomSheetState();
}

class _AnonymousChatBottomSheetState extends State<AnonymousChatBottomSheet>
    with SingleTickerProviderStateMixin {
  // Services
  final _messageService = MessageService();
  final _giftService = GiftService();

  // Tab Controller
  late TabController _tabController;
  int _currentTabIndex = 0;

  // État général
  final _isLoading = false.obs;
  final _isSending = false.obs;

  // ====================
  // TAB 1: TEXTE
  // ====================
  final _textController = TextEditingController();
  final _showEmojiPicker = false.obs;
  final FocusNode _textFocusNode = FocusNode();

  // ====================
  // TAB 2: VOICE
  // ====================
  FlutterSoundRecorder? _audioRecorder;
  final _isRecording = false.obs;
  String? _recordedAudioPath;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;
  final _selectedVoiceType = 'normal'.obs;
  final _showVoiceTypePicker = false.obs;

  // Lecture audio
  ap.AudioPlayer? _audioPlayer;
  final _isPlayingRecordedAudio = false.obs;
  final _recordedAudioDuration = Duration.zero.obs;
  final _recordedAudioPosition = Duration.zero.obs;

  final List<Map<String, dynamic>> _voiceTypes = [
    {
      'id': 'normal',
      'name': 'Normale',
      'icon': Icons.record_voice_over_rounded,
      'description': 'Voix naturelle'
    },
    {
      'id': 'robot',
      'name': 'Robot',
      'icon': Icons.smart_toy_rounded,
      'description': 'Voix robotique'
    },
    {
      'id': 'alien',
      'name': 'Alien',
      'icon': Icons.psychology_rounded,
      'description': 'Voix extraterrestre'
    },
    {
      'id': 'mystery',
      'name': 'Mystérieux',
      'icon': Icons.masks_rounded,
      'description': 'Voix grave et sombre'
    },
    {
      'id': 'chipmunk',
      'name': 'Chipmunk',
      'icon': Icons.pets_rounded,
      'description': 'Voix aiguë'
    },
  ];

  // ====================
  // TAB 3: IMAGE
  // ====================
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  // ====================
  // TAB 4: GIFT
  // ====================
  final _gifts = <GiftModel>[].obs;
  final _categories = <GiftCategory>[].obs;
  final _isLoadingGifts = false.obs;
  GiftModel? _selectedGift;
  final _revealIdentityWithGift = false.obs;
  final _giftMessageController = TextEditingController();
  final _selectedCategoryId = Rx<int?>(null);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
          _showEmojiPicker.value = false;
        });
      }
    });

    _initAudioRecorder();
    _loadGifts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _textFocusNode.dispose();
    _giftMessageController.dispose();
    _recordTimer?.cancel();
    _audioRecorder?.closeRecorder();
    _audioPlayer?.dispose();
    super.dispose();
  }

  // ====================
  // AUDIO RECORDER INIT
  // ====================
  Future<void> _initAudioRecorder() async {
    _audioRecorder = FlutterSoundRecorder();
    await _audioRecorder!.openRecorder();
  }

  // ====================
  // LOAD GIFTS AND CATEGORIES
  // ====================
  Future<void> _loadGifts() async {
    try {
      _isLoadingGifts.value = true;

      // Charger les catégories et les cadeaux en parallèle
      final results = await Future.wait([
        _giftService.getCategories(),
        _giftService.getGifts(),
      ]);

      _categories.value = results[0] as List<GiftCategory>;
      _gifts.value = results[1] as List<GiftModel>;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les cadeaux',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoadingGifts.value = false;
    }
  }

  // ====================
  // SEND MESSAGE
  // ====================
  Future<void> _sendMessage() async {
    if (_isSending.value) return;

    // Validation selon le tab
    if (_currentTabIndex == 0) {
      // Texte
      if (_textController.text.trim().isEmpty) {
        Get.snackbar(
          'Erreur',
          'Veuillez saisir un message',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    } else if (_currentTabIndex == 1) {
      // Voice
      if (_recordedAudioPath == null) {
        Get.snackbar(
          'Erreur',
          'Veuillez enregistrer un message vocal',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    } else if (_currentTabIndex == 2) {
      // Image
      if (_selectedImage == null) {
        Get.snackbar(
          'Erreur',
          'Veuillez sélectionner une image',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    } else if (_currentTabIndex == 3) {
      // Gift
      if (_selectedGift == null) {
        Get.snackbar(
          'Erreur',
          'Veuillez sélectionner un cadeau',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }

    try {
      _isSending.value = true;

      File? mediaFile;
      String? mediaType;
      String? voiceType;
      int? giftId;
      String? giftMessage;
      bool? revealIdentity;

      // Préparer les données selon le tab
      if (_currentTabIndex == 1) {
        // Voice
        mediaFile = File(_recordedAudioPath!);
        mediaType = 'audio';
        voiceType = _selectedVoiceType.value;
      } else if (_currentTabIndex == 2) {
        // Image
        mediaFile = _selectedImage!;
        mediaType = 'image';
      } else if (_currentTabIndex == 3) {
        // Gift
        giftId = _selectedGift!.id;
        giftMessage = _giftMessageController.text.trim().isNotEmpty
            ? _giftMessageController.text.trim()
            : null;
        revealIdentity = _revealIdentityWithGift.value;
      }

      final response = await _messageService.sendMessage(
        username: widget.recipientUsername,
        content: _textController.text.trim().isNotEmpty
            ? _textController.text.trim()
            : null,
        replyToMessageId: widget.originalMessage.id,
        mediaFile: mediaFile,
        mediaType: mediaType,
        voiceType: voiceType,
        giftId: giftId,
        giftMessage: giftMessage,
        revealIdentityWithGift: revealIdentity,
      );

      // Succès
      Get.back();

      Get.snackbar(
        'Succès',
        'Message envoyé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );

      // Callback
      widget.onMessageSent?.call();

      // Si une conversation a été créée, proposer d'y aller
      if (response.conversationId != null) {
        Get.snackbar(
          'Conversation créée',
          'Votre réponse a créé une conversation',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: Duration(seconds: 3),
          mainButton: TextButton(
            onPressed: () {
              Get.toNamed('/chat/conversation/${response.conversationId}');
            },
            child: Text('Voir', style: TextStyle(color: Colors.white)),
          ),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'envoyer le message: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isSending.value = false;
    }
  }

  // ====================
  // VOICE: START RECORDING
  // ====================
  Future<void> _startRecording() async {
    try {
      // Demander permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        Get.snackbar(
          'Permission refusée',
          'Veuillez autoriser l\'accès au microphone',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Générer un nom de fichier unique
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordedAudioPath = '${directory.path}/voice_$timestamp.aac';

      // Démarrer l'enregistrement
      await _audioRecorder!.startRecorder(
        toFile: _recordedAudioPath,
        codec: Codec.aacADTS,
      );

      _isRecording.value = true;
      _recordDuration = Duration.zero;

      // Timer
      _recordTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _recordDuration = Duration(seconds: _recordDuration.inSeconds + 1);
        });
      });
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de démarrer l\'enregistrement: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ====================
  // VOICE: STOP RECORDING
  // ====================
  Future<void> _stopRecording() async {
    try {
      await _audioRecorder!.stopRecorder();
      _isRecording.value = false;
      _recordTimer?.cancel();

      // Initialiser le player pour la lecture
      _audioPlayer = ap.AudioPlayer();
      _audioPlayer!.onDurationChanged.listen((duration) {
        _recordedAudioDuration.value = duration;
      });
      _audioPlayer!.onPositionChanged.listen((position) {
        _recordedAudioPosition.value = position;
      });
      _audioPlayer!.onPlayerComplete.listen((_) {
        _isPlayingRecordedAudio.value = false;
        _recordedAudioPosition.value = Duration.zero;
      });
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'arrêter l\'enregistrement: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ====================
  // VOICE: CANCEL RECORDING
  // ====================
  void _cancelRecording() {
    if (_recordedAudioPath != null) {
      final file = File(_recordedAudioPath!);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
    _recordedAudioPath = null;
    _recordDuration = Duration.zero;
    _audioPlayer?.dispose();
    _audioPlayer = null;
  }

  // ====================
  // VOICE: PLAY/PAUSE RECORDED AUDIO
  // ====================
  Future<void> _togglePlayRecordedAudio() async {
    if (_audioPlayer == null || _recordedAudioPath == null) return;

    if (_isPlayingRecordedAudio.value) {
      await _audioPlayer!.pause();
      _isPlayingRecordedAudio.value = false;
    } else {
      await _audioPlayer!.play(ap.DeviceFileSource(_recordedAudioPath!));
      _isPlayingRecordedAudio.value = true;
    }
  }

  // ====================
  // IMAGE: PICK IMAGE
  // ====================
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de sélectionner une image: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ====================
  // IMAGE: REMOVE IMAGE
  // ====================
  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  // ====================
  // GIFT: SELECT GIFT
  // ====================
  void _selectGift(GiftModel gift) {
    setState(() {
      _selectedGift = gift;
    });
  }

  // ====================
  // EMOJI: ON EMOJI SELECTED
  // ====================
  void _onEmojiSelected(Emoji emoji) {
    _textController.text += emoji.emoji;
  }

  // ====================
  // BUILD
  // ====================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          _buildHeader(isDark),

          // Tabs
          _buildTabBar(isDark),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTextTab(isDark),
                _buildVoiceTab(isDark),
                _buildImageTab(isDark),
                _buildGiftTab(isDark),
              ],
            ),
          ),

          // Send button avec padding bottom pour navigation Android
          Padding(
            padding: EdgeInsets.only(bottom: bottomPadding > 0 ? bottomPadding : 0),
            child: _buildSendButton(isDark),
          ),
        ],
      ),
    );
  }

  // ====================
  // BUILD: HEADER
  // ====================
  Widget _buildHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Close button
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(Icons.close),
            iconSize: 24,
          ),

          SizedBox(width: 8),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Répondre au message',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Message original: "${widget.originalMessage.content.length > 50 ? widget.originalMessage.content.substring(0, 50) + '...' : widget.originalMessage.content}"',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ====================
  // BUILD: TAB BAR
  // ====================
  Widget _buildTabBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Theme.of(context).primaryColor,
        tabs: [
          Tab(icon: Icon(Icons.text_fields), text: 'Texte'),
          Tab(icon: Icon(Icons.mic), text: 'Voice'),
          Tab(icon: Icon(Icons.image), text: 'Image'),
          Tab(icon: Icon(Icons.card_giftcard), text: 'Gift'),
        ],
      ),
    );
  }

  // ====================
  // BUILD: TEXT TAB
  // ====================
  Widget _buildTextTab(bool isDark) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // TextField
                TextField(
                  controller: _textController,
                  focusNode: _textFocusNode,
                  maxLines: 8,
                  maxLength: 5000,
                  decoration: InputDecoration(
                    hintText: 'Écrivez votre message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[900] : Colors.grey[50],
                  ),
                  onTap: () {
                    _showEmojiPicker.value = false;
                  },
                ),

                SizedBox(height: 12),

                // Emoji button
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      _showEmojiPicker.value = !_showEmojiPicker.value;
                      if (_showEmojiPicker.value) {
                        _textFocusNode.unfocus();
                      }
                    },
                    icon: Icon(Icons.emoji_emotions_outlined),
                    label: Text('Ajouter un emoji'),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Emoji Picker
        Obx(() {
          if (_showEmojiPicker.value) {
            return SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _onEmojiSelected(emoji);
                },
                config: Config(
                  emojiViewConfig: EmojiViewConfig(
                    emojiSizeMax: 32.0,
                    backgroundColor: isDark ? Color(0xFF1E1E1E) : Color(0xFFF2F2F2),
                    noRecents: Text(
                      'Aucun emoji récent',
                      style: TextStyle(
                        fontSize: 20,
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  categoryViewConfig: CategoryViewConfig(
                    initCategory: Category.RECENT,
                    indicatorColor: Theme.of(context).primaryColor,
                    iconColor: isDark ? (Colors.grey[600] ?? AppThemeSystem.grey600) : Colors.grey,
                    iconColorSelected: Theme.of(context).primaryColor,
                    backspaceColor: Theme.of(context).primaryColor,
                    backgroundColor: isDark ? Color(0xFF1E1E1E) : Colors.white,
                    dividerColor: isDark ? (Colors.grey[800] ?? AppThemeSystem.grey800) : (Colors.grey[200] ?? AppThemeSystem.grey200),
                  ),
                  skinToneConfig: SkinToneConfig(
                    enabled: true,
                    dialogBackgroundColor: isDark ? Color(0xFF1E1E1E) : Colors.white,
                    indicatorColor: isDark ? (Colors.grey[600] ?? AppThemeSystem.grey600) : Colors.grey,
                  ),
                ),
              ),
            );
          }
          return SizedBox.shrink();
        }),
      ],
    );
  }

  // ====================
  // BUILD: VOICE TAB
  // ====================
  Widget _buildVoiceTab(bool isDark) {
    return Obx(() {
      // Si enregistrement en cours
      if (_isRecording.value) {
        return _buildRecordingInterface(isDark);
      }

      // Si audio enregistré
      if (_recordedAudioPath != null) {
        return _buildRecordedAudioInterface(isDark);
      }

      // Interface initiale
      return _buildVoiceInitialInterface(isDark);
    });
  }

  // Voice: Initial Interface
  Widget _buildVoiceInitialInterface(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Sélection du type de voix
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Type de voix',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _voiceTypes.map((voiceType) {
                    final isSelected = _selectedVoiceType.value == voiceType['id'];
                    return Obx(() => ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                voiceType['icon'] as IconData,
                                size: 18,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : Colors.black87),
                              ),
                              SizedBox(width: 6),
                              Text(voiceType['name'] as String),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            _selectedVoiceType.value = voiceType['id'] as String;
                          },
                          selectedColor: Theme.of(context).primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ));
                  }).toList(),
                ),
                if (_selectedVoiceType.value != 'normal') ...[
                  SizedBox(height: 8),
                  Text(
                    _voiceTypes.firstWhere(
                        (v) => v['id'] == _selectedVoiceType.value)['description'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 24),

          // Big record button
          Center(
            child: InkWell(
              onTap: _startRecording,
              borderRadius: BorderRadius.circular(100),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.mic,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          SizedBox(height: 16),

          Text(
            'Appuyez pour enregistrer',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Voice: Recording Interface
  Widget _buildRecordingInterface(bool isDark) {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Waveform animation (simplifié)
          Container(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(20, (index) {
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 2),
                  width: 4,
                  height: 20.0 + (index % 3) * 20,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),

          SizedBox(height: 24),

          // Timer
          Text(
            _formatDuration(_recordDuration),
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),

          SizedBox(height: 8),

          Text(
            'Enregistrement en cours...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),

          SizedBox(height: 48),

          // Stop button
          ElevatedButton.icon(
            onPressed: _stopRecording,
            icon: Icon(Icons.stop),
            label: Text('Arrêter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Voice: Recorded Audio Interface
  Widget _buildRecordedAudioInterface(bool isDark) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Audio player
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Play/Pause button + Progress
                Row(
                  children: [
                    Obx(() => IconButton(
                          onPressed: _togglePlayRecordedAudio,
                          icon: Icon(
                            _isPlayingRecordedAudio.value
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            size: 48,
                            color: Theme.of(context).primaryColor,
                          ),
                        )),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(() => LinearProgressIndicator(
                                value: _recordedAudioDuration.value.inMilliseconds > 0
                                    ? _recordedAudioPosition.value.inMilliseconds /
                                        _recordedAudioDuration.value.inMilliseconds
                                    : 0.0,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor,
                                ),
                              )),
                          SizedBox(height: 8),
                          Obx(() => Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(_recordedAudioPosition.value),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(_recordedAudioDuration.value),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              )),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Voice type indicator
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _voiceTypes.firstWhere(
                            (v) => v['id'] == _selectedVoiceType.value)['icon'] as IconData,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Voix: ${_voiceTypes.firstWhere((v) => v['id'] == _selectedVoiceType.value)['name']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Delete
              OutlinedButton.icon(
                onPressed: () {
                  _cancelRecording();
                  setState(() {});
                },
                icon: Icon(Icons.delete_outline, color: Colors.red),
                label: Text('Supprimer', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),

              // Re-record
              OutlinedButton.icon(
                onPressed: () {
                  _cancelRecording();
                  setState(() {});
                  Future.delayed(Duration(milliseconds: 100), () {
                    _startRecording();
                  });
                },
                icon: Icon(Icons.refresh),
                label: Text('Refaire'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ====================
  // BUILD: IMAGE TAB
  // ====================
  Widget _buildImageTab(bool isDark) {
    if (_selectedImage != null) {
      return _buildImagePreview(isDark);
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Aucune image sélectionnée',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: Icon(Icons.add_photo_alternate),
            label: Text('Choisir une image'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Image: Preview
  Widget _buildImagePreview(bool isDark) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: _removeImage,
                    icon: Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed: _pickImage,
            icon: Icon(Icons.refresh),
            label: Text('Changer l\'image'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  // ====================
  // BUILD: GIFT TAB
  // ====================
  Widget _buildGiftTab(bool isDark) {
    return Obx(() {
      if (_isLoadingGifts.value) {
        return Center(child: CircularProgressIndicator());
      }

      if (_gifts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.card_giftcard, size: 80, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'Aucun cadeau disponible',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }

      // Filtrer par catégorie si sélectionnée
      final filteredGifts = _selectedCategoryId.value != null
          ? _gifts.where((g) => g.categoryId == _selectedCategoryId.value).toList()
          : _gifts;

      return Column(
        children: [
          // Filtres par catégorie
          Container(
            height: 50,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Obx(() {
              if (_categories.isEmpty) {
                return Center(child: Text('Chargement...'));
              }

              return ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Tous
                  Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Obx(() => ChoiceChip(
                          label: Text('Tous'),
                          selected: _selectedCategoryId.value == null,
                          onSelected: (selected) {
                            _selectedCategoryId.value = null;
                          },
                        )),
                  ),
                  // Catégories
                  ..._categories.map((category) {
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Obx(() => ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(category.name),
                                if (category.giftsCount != null && category.giftsCount! > 0) ...[
                                  SizedBox(width: 4),
                                  Text(
                                    '(${category.giftsCount})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            selected: _selectedCategoryId.value == category.id,
                            onSelected: (selected) {
                              _selectedCategoryId.value =
                                  selected ? category.id : null;
                            },
                          )),
                    );
                  }),
                ],
              );
            }),
          ),

          Divider(height: 1),

          // Gifts grid
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filteredGifts.length,
              itemBuilder: (context, index) {
                final gift = filteredGifts[index];
                final isSelected = _selectedGift?.id == gift.id;

                return InkWell(
                  onTap: () => _selectGift(gift),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon emoji
                        if (gift.icon.isNotEmpty)
                          Text(
                            gift.icon,
                            style: TextStyle(fontSize: 48),
                          )
                        else
                          Icon(
                            Icons.card_giftcard,
                            size: 48,
                            color: _parseColor(gift.tierColor),
                          ),
                        SizedBox(height: 8),

                        // Name
                        Text(
                          gift.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        SizedBox(height: 4),

                        // Price
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _parseColor(gift.backgroundColor).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            gift.formattedPrice,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _parseColor(gift.tierColor),
                            ),
                          ),
                        ),

                        if (isSelected)
                          Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Icon(
                              Icons.check_circle,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Gift options (if gift selected)
          if (_selectedGift != null) _buildGiftOptions(isDark),
        ],
      );
    });
  }

  // Gift: Options (message + reveal identity)
  Widget _buildGiftOptions(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message optionnel
          TextField(
            controller: _giftMessageController,
            maxLines: 2,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Message accompagnant le cadeau (optionnel)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.white,
              isDense: true,
            ),
          ),

          SizedBox(height: 12),

          // Reveal identity toggle
          Obx(() => CheckboxListTile(
                value: _revealIdentityWithGift.value,
                onChanged: (value) {
                  _revealIdentityWithGift.value = value ?? false;
                },
                title: Text('Révéler mon identité avec ce cadeau'),
                subtitle: Text(
                  'Le destinataire saura qui vous êtes',
                  style: TextStyle(fontSize: 12),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              )),
        ],
      ),
    );
  }

  // ====================
  // BUILD: SEND BUTTON
  // ====================
  Widget _buildSendButton(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Obx(() => ElevatedButton(
            onPressed: _isSending.value ? null : _sendMessage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: Size(double.infinity, 50),
            ),
            child: _isSending.value
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Envoyer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          )),
    );
  }

  // ====================
  // HELPERS
  // ====================
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  /// Parse une couleur hex en Color
  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return AppThemeSystem.primaryColor; // Couleur par défaut
    }
  }
}
