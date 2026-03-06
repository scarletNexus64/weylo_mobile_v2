import 'package:get/get.dart';

import '../controllers/feeds_controller.dart';
import '../controllers/story_controller.dart';

class ConfessionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ConfessionsController>(
      () => ConfessionsController(),
    );
    // Use lazyPut to avoid immediate initialization when not needed
    Get.lazyPut<StoryController>(
      () => StoryController(),
    );
  }
}
