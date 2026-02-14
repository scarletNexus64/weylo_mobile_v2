import 'package:get/get.dart';

import '../controllers/groupe_controller.dart';

class GroupeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GroupeController>(
      () => GroupeController(),
    );
  }
}
