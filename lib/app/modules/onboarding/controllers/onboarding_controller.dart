import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/routes/app_pages.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';

// Modèle pour les pages d'onboarding
class OnboardingPageModel {
  final String title;
  final String description;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;

  OnboardingPageModel({
    required this.title,
    required this.description,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
  });
}

class OnboardingController extends GetxController {
  // PageController pour gérer le PageView
  late PageController pageController;

  // Page actuelle
  final currentPage = 0.obs;

  // Progrès de l'animation pour parallax
  final pageProgress = 0.0.obs;

  // Liste des pages d'onboarding optimisées pour un réseau social anonyme
  final List<OnboardingPageModel> pages = [
    OnboardingPageModel(
      title: 'Parle Sans Filtres',
      description:
          'Exprime-toi librement sans crainte du jugement. Partage tes vraies pensées, tes secrets, tes rêves.',
      icon: Icons.chat_bubble_outline_rounded,
      primaryColor: AppThemeSystem.primaryColor,
      secondaryColor: AppThemeSystem.secondaryColor,
    ),
    OnboardingPageModel(
      title: 'Reste Anonyme',
      description:
          'Protège ton identité. Sois qui tu veux être. Aucune pression sociale, juste l\'authenticité.',
      icon: Icons.theater_comedy_rounded,
      primaryColor: AppThemeSystem.tertiaryColor,
      secondaryColor: AppThemeSystem.primaryColor,
    ),
    OnboardingPageModel(
      title: 'Connecte-toi Vraiment',
      description:
          'Crée des connexions sincères basées sur les idées, pas les apparences. Découvre la vraie communication.',
      icon: Icons.favorite_border_rounded,
      primaryColor: AppThemeSystem.secondaryColor,
      secondaryColor: AppThemeSystem.tertiaryColor,
    ),
    OnboardingPageModel(
      title: 'Bienvenue sur Weylo',
      description:
          'Rejoins une communauté où tu peux être toi-même, sans masque. Ton aventure commence maintenant.',
      icon: Icons.rocket_launch_rounded,
      primaryColor: AppThemeSystem.primaryColor,
      secondaryColor: AppThemeSystem.accentColor,
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    pageController = PageController();
    pageController.addListener(_onPageScroll);
  }

  @override
  void onClose() {
    pageController.removeListener(_onPageScroll);
    pageController.dispose();
    super.onClose();
  }

  // Listener pour l'effet parallax
  void _onPageScroll() {
    if (pageController.hasClients) {
      pageProgress.value = pageController.page ?? 0.0;
    }
  }

  // Callback quand la page change
  void onPageChanged(int index) {
    currentPage.value = index;
  }

  // Aller à la page suivante
  void nextPage() {
    if (currentPage.value < pages.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  // Passer l'onboarding
  void skip() {
    pageController.animateToPage(
      pages.length - 1,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  // Terminer l'onboarding et aller à la page de bienvenue
  void finish() {
    Get.offAllNamed(Routes.WELCOMER);
  }
}
