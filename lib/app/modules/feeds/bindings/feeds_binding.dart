import 'package:get/get.dart';

import '../controllers/feeds_controller.dart';
import '../controllers/story_controller.dart';

class ConfessionsBinding extends Bindings {
  @override
  void dependencies() {
    // Utiliser put au lieu de lazyPut pour éviter les problèmes de lifecycle
    Get.put<ConfessionsController>(
      ConfessionsController(),
      permanent: true, // Garder le controller en mémoire
    );
    // Use lazyPut pour StoryController car moins critique
    Get.lazyPut<StoryController>(
      () => StoryController(),
    );
  }
}
