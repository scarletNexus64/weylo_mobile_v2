import 'package:get/get.dart';

import '../controllers/entrypage_controller.dart';

class EntrypageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EntrypageController>(
      () => EntrypageController(),
    );
  }
}
