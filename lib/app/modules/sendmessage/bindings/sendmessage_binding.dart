import 'package:get/get.dart';
import '../controllers/sendmessage_controller.dart';

class SendmessageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SendmessageController>(
      () => SendmessageController(),
    );
  }
}
