import 'package:get/get.dart';

enum MessageType { text, image, audio, gift }

class GroupMessage {
  final String id;
  final String content;
  final MessageType type;
  final bool isSentByMe;
  final DateTime timestamp;
  final String? senderName;  // Nom de l'expéditeur pour les groupes
  final String? senderAvatar; // Avatar de l'expéditeur
  final String? imageUrl;
  final String? audioUrl;
  final String? giftIcon;
  final String? giftName;

  GroupMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.isSentByMe,
    required this.timestamp,
    this.senderName,
    this.senderAvatar,
    this.imageUrl,
    this.audioUrl,
    this.giftIcon,
    this.giftName,
  });
}

class GroupeDetailController extends GetxController {
  final String groupName;
  final String groupId;
  final int memberCount;

  GroupeDetailController({
    required this.groupName,
    required this.groupId,
    required this.memberCount,
  });

  final messages = <GroupMessage>[].obs;
  final messageText = ''.obs;
  final isRecording = false.obs;
  final showGiftPicker = false.obs;
  final selectedGiftCategory = 'Romance'.obs;
  final isAnimatingGift = false.obs;
  final animatedGift = Rx<Map<String, dynamic>?>(null);

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
    _loadFakeMessages();
  }

  void _loadFakeMessages() {
    final fakeMembers = [
      'Alice',
      'Bob',
      'Charlie',
      'Diana',
      'Emma',
    ];

    messages.value = [
      GroupMessage(
        id: '1',
        content: 'Salut tout le monde! 👋',
        type: MessageType.text,
        isSentByMe: false,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        senderName: fakeMembers[0],
      ),
      GroupMessage(
        id: '2',
        content: 'Hey! Comment ça va?',
        type: MessageType.text,
        isSentByMe: false,
        timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 55)),
        senderName: fakeMembers[1],
      ),
      GroupMessage(
        id: '3',
        content: 'Très bien! On organise quelque chose ce week-end?',
        type: MessageType.text,
        isSentByMe: true,
        timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 50)),
      ),
      GroupMessage(
        id: '4',
        content: '🍕',
        type: MessageType.gift,
        isSentByMe: false,
        timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
        senderName: fakeMembers[2],
        giftIcon: '🍕',
        giftName: 'Pizza',
      ),
      GroupMessage(
        id: '5',
        content: 'Super idée! Je suis partant 🎉',
        type: MessageType.text,
        isSentByMe: false,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        senderName: fakeMembers[3],
      ),
      GroupMessage(
        id: '6',
        content: 'Message audio',
        type: MessageType.audio,
        isSentByMe: false,
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
        senderName: fakeMembers[4],
        audioUrl: 'fake_audio.mp3',
      ),
      GroupMessage(
        id: '7',
        content: 'J\'adore cette communauté! 🎊',
        type: MessageType.text,
        isSentByMe: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      GroupMessage(
        id: '8',
        content: '🎁',
        type: MessageType.gift,
        isSentByMe: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        giftIcon: '🎁',
        giftName: 'Cadeau',
      ),
    ];
  }

  void sendMessage() {
    if (messageText.value.trim().isEmpty) return;

    final newMessage = GroupMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: messageText.value,
      type: MessageType.text,
      isSentByMe: true,
      timestamp: DateTime.now(),
    );

    messages.add(newMessage);
    messageText.value = '';
  }

  void sendGift(Map<String, dynamic> gift) {
    // Start animation
    animatedGift.value = gift;
    isAnimatingGift.value = true;
    showGiftPicker.value = false;

    // Wait for animation to complete, then add message
    Future.delayed(const Duration(milliseconds: 1500), () {
      final newMessage = GroupMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: gift['icon']!,
        type: MessageType.gift,
        isSentByMe: true,
        timestamp: DateTime.now(),
        giftIcon: gift['icon'],
        giftName: gift['name'],
      );

      messages.add(newMessage);
      isAnimatingGift.value = false;
      animatedGift.value = null;
    });
  }

  void selectGiftCategory(String category) {
    selectedGiftCategory.value = category;
  }

  void sendImage(String imageUrl) {
    final newMessage = GroupMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: 'Image envoyée',
      type: MessageType.image,
      isSentByMe: true,
      timestamp: DateTime.now(),
      imageUrl: imageUrl,
    );

    messages.add(newMessage);
  }

  void toggleRecording() {
    isRecording.value = !isRecording.value;
  }

  void toggleGiftPicker() {
    showGiftPicker.value = !showGiftPicker.value;
  }
}
