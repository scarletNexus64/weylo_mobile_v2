import 'package:get/get.dart';

import '../controllers/sponsoring_controller.dart';

class SponsoringBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SponsoringController>(() => SponsoringController());
  }
}

