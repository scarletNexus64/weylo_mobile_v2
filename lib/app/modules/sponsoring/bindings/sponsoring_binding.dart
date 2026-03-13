import 'package:get/get.dart';

import '../controllers/sponsoring_dashboard_controller.dart';
import '../controllers/sponsoring_entry_controller.dart';
import '../controllers/sponsoring_controller.dart';

class SponsoringBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SponsoringController>(() => SponsoringController());
    Get.lazyPut<SponsoringEntryController>(() => SponsoringEntryController());
    Get.lazyPut<SponsoringDashboardController>(
      () => SponsoringDashboardController(),
    );
  }
}
