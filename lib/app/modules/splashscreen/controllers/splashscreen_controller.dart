import 'dart:async';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/storage_service.dart';

class SplashscreenController extends GetxController {
  final _authService = AuthService();
  final _storage = StorageService();

  final progress = 0.0.obs;
  Timer? _progressTimer;

  @override
  void onInit() {
    super.onInit();
    print('🚀 [SPLASH] Initialisation du SplashScreen');
    _startProgressAnimation();
  }

  // Anime la barre de progression
  void _startProgressAnimation() {
    const totalDuration = 2000; // 2 secondes (réduit de 3s)
    const intervalDuration = 30; // Update toutes les 30ms
    const totalSteps = totalDuration / intervalDuration;
    var step = 0;

    _progressTimer = Timer.periodic(const Duration(milliseconds: intervalDuration), (timer) {
      step++;
      progress.value = (step / totalSteps).clamp(0.0, 1.0);

      if (progress.value >= 1.0) {
        timer.cancel();
        _navigateToNext();
      }
    });
  }

  // Navigation vers la page suivante
  void _navigateToNext() async {
    print('🔍 [SPLASH] Vérification du parcours utilisateur...');

    try {
      // TODO: SUPPRIMER CETTE LIGNE APRÈS LE TEST
      // await _storage.resetOnboarding(); // Décommentez pour tester l'onboarding

      // 1. Vérifier d'abord si l'utilisateur a complété l'onboarding
      final onboardingCompleted = _storage.isOnboardingCompleted();

      if (!onboardingCompleted) {
        // Première visite, aller vers ONBOARDING
        print('🎯 [SPLASH] Première visite - Navigation vers ONBOARDING');
        Get.offAllNamed(Routes.ONBOARDING);
        return;
      }

      // 2. Vérifier si l'utilisateur a un token valide
      print('📱 [SPLASH] Appel de verifyToken()');
      final isAuthenticated = await _authService.verifyToken();

      if (isAuthenticated) {
        // Token valide, aller vers HOME
        print('✅ [SPLASH] Token valide - Navigation vers HOME');
        final user = _authService.getCurrentUser();
        print('👤 [SPLASH] Utilisateur connecté: ${user?.username} (${user?.firstName})');
        Get.offAllNamed(Routes.HOME);
      } else {
        // Pas de token ou token invalide, aller vers WELCOMER
        print('❌ [SPLASH] Pas de token valide - Navigation vers WELCOMER');
        Get.offAllNamed(Routes.WELCOMER);
      }
    } catch (e) {
      // En cas d'erreur, vérifier l'onboarding puis aller vers WELCOMER
      print('💥 [SPLASH] Erreur lors de la vérification: $e');

      final onboardingCompleted = _storage.isOnboardingCompleted();
      if (!onboardingCompleted) {
        print('🎯 [SPLASH] Navigation vers ONBOARDING');
        Get.offAllNamed(Routes.ONBOARDING);
      } else {
        print('🔄 [SPLASH] Navigation vers WELCOMER par défaut');
        Get.offAllNamed(Routes.WELCOMER);
      }
    }
  }

  @override
  void onClose() {
    _progressTimer?.cancel();
    super.onClose();
  }
}
