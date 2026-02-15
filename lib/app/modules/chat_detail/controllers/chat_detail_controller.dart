import 'package:get/get.dart';

enum MessageType { text, image, audio, gift }

class Message {
  final String id;
  final String content;
  final MessageType type;
  final bool isSentByMe;
  final DateTime timestamp;
  final String? imageUrl;
  final String? audioUrl;
  final String? giftIcon;
  final String? giftName;

  Message({
    required this.id,
    required this.content,
    required this.type,
    required this.isSentByMe,
    required this.timestamp,
    this.imageUrl,
    this.audioUrl,
    this.giftIcon,
    this.giftName,
  });
}

class ChatDetailController extends GetxController {
  final String contactName;
  final String contactId;

  ChatDetailController({required this.contactName, required this.contactId});

  final messages = <Message>[].obs;
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
    messages.value = [
      Message(
        id: '1',
        content: 'Salut! Comment ça va?',
        type: MessageType.text,
        isSentByMe: false,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Message(
        id: '2',
        content: 'Ça va super bien! Et toi?',
        type: MessageType.text,
        isSentByMe: true,
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 55)),
      ),
      Message(
        id: '3',
        content: '🍫',
        type: MessageType.gift,
        isSentByMe: false,
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 50)),
        giftIcon: '🍫',
        giftName: 'Chocolat',
      ),
      Message(
        id: '4',
        content: 'Merci pour le chocolat! 😊',
        type: MessageType.text,
        isSentByMe: true,
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
      ),
      Message(
        id: '5',
        content: 'Message audio',
        type: MessageType.audio,
        isSentByMe: false,
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
        audioUrl: 'fake_audio.mp3',
      ),
      Message(
        id: '6',
        content: '🍷',
        type: MessageType.gift,
        isSentByMe: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        giftIcon: '🍷',
        giftName: 'Vin Rouge',
      ),
      Message(
        id: '7',
        content: 'On se voit ce soir?',
        type: MessageType.text,
        isSentByMe: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      Message(
        id: '8',
        content: 'Oui avec plaisir!',
        type: MessageType.text,
        isSentByMe: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
    ];
  }

  void sendMessage() {
    if (messageText.value.trim().isEmpty) return;

    final newMessage = Message(
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
    print('🎁 [Controller] Starting gift animation for: ${gift['name']}');
    // Start animation
    animatedGift.value = gift;
    isAnimatingGift.value = true;
    showGiftPicker.value = false;
    print('🎬 [Controller] Animation state set: isAnimating=true, gift=${gift['icon']}');

    // Wait for animation to complete, then add message
    Future.delayed(const Duration(milliseconds: 1500), () {
      print('⏱️ [Controller] Animation delay completed (1500ms)');
      final newMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: gift['icon']!,
        type: MessageType.gift,
        isSentByMe: true,
        timestamp: DateTime.now(),
        giftIcon: gift['icon'],
        giftName: gift['name'],
      );

      messages.add(newMessage);
      print('💬 [Controller] Message added to list');

      isAnimatingGift.value = false;
      animatedGift.value = null;
      print('✅ [Controller] Animation STOPPED: isAnimating=false, gift=null');
    });
  }

  void selectGiftCategory(String category) {
    selectedGiftCategory.value = category;
  }

  void sendImage(String imageUrl) {
    final newMessage = Message(
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
