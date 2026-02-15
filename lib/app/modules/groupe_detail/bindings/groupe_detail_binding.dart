import 'package:get/get.dart';
import '../controllers/groupe_detail_controller.dart';

class GroupeDetailBinding extends Bindings {
  @override
  void dependencies() {
    // Get arguments from navigation
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final groupName = args['groupName'] ?? 'Groupe';
    final groupId = args['groupId'] ?? '0';
    final memberCount = args['memberCount'] ?? 0;

    Get.lazyPut<GroupeDetailController>(
      () => GroupeDetailController(
        groupName: groupName,
        groupId: groupId,
        memberCount: memberCount,
      ),
    );
  }
}
