import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SeetingController extends GetxController {
  final _storage = GetStorage();

  // Observable states
  final isNotificationsEnabled = true.obs;
  final appVersion = ''.obs;
  final appBuildNumber = ''.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
    _loadAppInfo();
  }

  /// Load saved settings from storage
  void _loadSettings() {
    try {
      // Load notification preference (default: true)
      isNotificationsEnabled.value = _storage.read('notifications_enabled') ?? true;
      print('✅ [SETTINGS] Paramètres chargés - Notifications: ${isNotificationsEnabled.value}');
    } catch (e) {
      print('❌ [SETTINGS] Erreur lors du chargement des paramètres: $e');
    }
  }

  /// Load app version information
  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion.value = packageInfo.version;
      appBuildNumber.value = packageInfo.buildNumber;
      print('✅ [SETTINGS] Version de l\'app: ${appVersion.value} (${appBuildNumber.value})');
    } catch (e) {
      print('❌ [SETTINGS] Erreur lors du chargement des infos de l\'app: $e');
      appVersion.value = '1.0.0';
      appBuildNumber.value = '1';
    }
  }

  /// Toggle notifications on/off
  Future<void> toggleNotifications(bool value) async {
    try {
      isNotificationsEnabled.value = value;
      await _storage.write('notifications_enabled', value);

      print('✅ [SETTINGS] Notifications ${value ? 'activées' : 'désactivées'}');

      Get.snackbar(
        'Notifications',
        value
          ? 'Les notifications ont été activées'
          : 'Les notifications ont été désactivées',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('❌ [SETTINGS] Erreur lors de la sauvegarde: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de sauvegarder les paramètres',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Get app description
  String getAppDescription() {
    return 'Weylo est votre espace de confession anonyme et de partage authentique. '
           'Exprimez-vous librement, partagez vos stories et connectez-vous avec une communauté bienveillante.';
  }
}
