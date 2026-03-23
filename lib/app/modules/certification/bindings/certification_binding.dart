import 'package:get/get.dart';
import '../controllers/certification_controller.dart';

class CertificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CertificationController>(
      () => CertificationController(),
    );
  }
}
