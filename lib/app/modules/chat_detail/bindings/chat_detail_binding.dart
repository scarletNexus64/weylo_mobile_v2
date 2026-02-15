import 'package:get/get.dart';
import '../controllers/chat_detail_controller.dart';

class ChatDetailBinding extends Bindings {
  @override
  void dependencies() {
    // Get arguments from navigation
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final contactName = args['contactName'] ?? 'Contact';
    final contactId = args['contactId'] ?? '0';

    Get.lazyPut<ChatDetailController>(
      () => ChatDetailController(
        contactName: contactName,
        contactId: contactId,
      ),
    );
  }
}
