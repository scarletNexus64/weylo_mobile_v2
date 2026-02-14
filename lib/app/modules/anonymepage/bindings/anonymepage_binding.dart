import 'package:get/get.dart';

import '../controllers/anonymepage_controller.dart';

class AnonymepageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AnonymepageController>(
      () => AnonymepageController(),
    );
  }
}
