import 'package:get/get.dart';

import '../controllers/postannoncement_controller.dart';

class PostannoncementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PostannoncementController>(
      () => PostannoncementController(),
    );
  }
}
