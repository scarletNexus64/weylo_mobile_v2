import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/routes/app_pages.dart';

class WelcomerController extends GetxController {
  // Form controllers
  final phoneController = TextEditingController();
  final pinController = TextEditingController();

  // Animation reactive variables
  final logoScale = 0.0.obs;
  final illustrationOpacity = 0.0.obs;
  final titleOpacity = 0.0.obs;
  final formOpacity = 0.0.obs;
  final socialOpacity = 0.0.obs;

  // Form state variables
  final phoneNumber = ''.obs;
  final countryCode = ''.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initAnimations();
  }

  @override
  void onReady() {
    super.onReady();
    _startAnimations();
  }

  @override
  void onClose() {
    phoneController.dispose();
    pinController.dispose();
    super.onClose();
  }

  // Initialize animation values
  void _initAnimations() {
    logoScale.value = 0.0;
    illustrationOpacity.value = 0.0;
    titleOpacity.value = 0.0;
    formOpacity.value = 0.0;
    socialOpacity.value = 0.0;
  }

  // Start sequential animations
  void _startAnimations() async {
    // Animate logo first
    await Future.delayed(const Duration(milliseconds: 100));
    logoScale.value = 1.0;

    // Then animate illustration
    await Future.delayed(const Duration(milliseconds: 300));
    illustrationOpacity.value = 1.0;

    // Then animate title
    await Future.delayed(const Duration(milliseconds: 300));
    titleOpacity.value = 1.0;

    // Then animate form
    await Future.delayed(const Duration(milliseconds: 300));
    formOpacity.value = 1.0;

    // Finally animate social buttons
    await Future.delayed(const Duration(milliseconds: 300));
    socialOpacity.value = 1.0;
  }

  // Update phone number
  void updatePhoneNumber(String phone, String code) {
    phoneNumber.value = phone;
    countryCode.value = code;
  }

  // Sign in with phone and PIN
  Future<void> signInWithPhonePin() async {
    if (!_validateForm()) return;

    isLoading.value = true;

    try {
      // TODO: Implement actual authentication logic here
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      Get.snackbar(
        'Succès',
        'Connexion réussie!',
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      // Navigate to home or dashboard
      Get.offAllNamed(Routes.HOME);
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Échec de la connexion: ${e.toString()}',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    isLoading.value = true;

    try {
      // TODO: Implement Google Sign In logic here
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      Get.snackbar(
        'Succès',
        'Connexion avec Google réussie!',
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Échec de la connexion Google: ${e.toString()}',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Sign in with Facebook
  Future<void> signInWithFacebook() async {
    isLoading.value = true;

    try {
      // TODO: Implement Facebook Sign In logic here
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      Get.snackbar(
        'Succès',
        'Connexion avec Facebook réussie!',
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Échec de la connexion Facebook: ${e.toString()}',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Navigate to forgot password
  void navigateToForgotPassword() {
    Get.snackbar(
      'Info',
      'Page de récupération de mot de passe en cours de développement',
      backgroundColor: Colors.blue.withValues(alpha: 0.8),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
    // TODO: Navigate to forgot password page
    // Get.toNamed(Routes.FORGOT_PASSWORD);
  }

  // Navigate to register
  void navigateToRegister() {
    Get.toNamed(Routes.REGISTER);
  }

  // Form validation
  bool _validateForm() {
    if (phoneNumber.value.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez entrer votre numéro de téléphone',
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (phoneNumber.value.length < 9) {
      Get.snackbar(
        'Erreur',
        'Veuillez entrer un numéro de téléphone valide',
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (pinController.text.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez entrer votre code PIN',
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (pinController.text.length < 4) {
      Get.snackbar(
        'Erreur',
        'Le code PIN doit contenir au moins 4 chiffres',
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    return true;
  }
}
