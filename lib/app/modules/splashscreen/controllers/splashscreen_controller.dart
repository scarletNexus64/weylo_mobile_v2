import 'dart:async';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';

class SplashscreenController extends GetxController {
  // Liste des tags avec emojis qui défilent
  final tagsList = [
    '😊 Anonyme',
    '🔒 Qui es-tu?',
    '💬 Parle librement',
    '🎭 Sois toi-même',
    '✨ Sans jugement',
    '🌟 Expression libre',
    '💭 Tes pensées',
    '🤫 Secret gardé',
    '🎪 Ton espace',
    '💜 Weylo',
  ];

  final currentTagIndex = 0.obs;
  final progress = 0.0.obs;
  Timer? _tagTimer;
  Timer? _progressTimer;

  @override
  void onInit() {
    super.onInit();
    _startTagAnimation();
    _startProgressAnimation();
  }

  // Anime le défilement des tags
  void _startTagAnimation() {
    _tagTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      currentTagIndex.value = (currentTagIndex.value + 1) % tagsList.length;
    });
  }

  // Anime la barre de progression
  void _startProgressAnimation() {
    const totalDuration = 3000; // 3 secondes
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
  void _navigateToNext() {
    // TODO: Vérifier si l'utilisateur a déjà vu l'onboarding
    // Pour l'instant, on va vers l'onboarding
    Get.offAllNamed(Routes.ONBOARDING);
  }

  @override
  void onClose() {
    _tagTimer?.cancel();
    _progressTimer?.cancel();
    super.onClose();
  }
}
