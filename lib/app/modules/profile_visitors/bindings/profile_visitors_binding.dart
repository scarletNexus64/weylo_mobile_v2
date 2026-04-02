import 'package:get/get.dart';
import '../controllers/profile_visitors_controller.dart';

class ProfileVisitorsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileVisitorsController>(
      () => ProfileVisitorsController(),
    );
  }
}
