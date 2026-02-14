import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/routes/app_pages.dart';

class LoginController extends GetxController {
  // Text controllers
  final phoneController = TextEditingController();
  final pinController = TextEditingController();

  // Observable variables
  final isLoading = false.obs;
  final phoneNumber = ''.obs;
  final countryCode = 'CM'.obs;
  final countryDialCode = '+237'.obs;

  // Animation variables
  final logoOpacity = 0.0.obs;
  final titleOpacity = 0.0.obs;
  final formOpacity = 0.0.obs;
  final buttonOpacity = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _startAnimations();
  }

  @override
  void onClose() {
    phoneController.dispose();
    pinController.dispose();
    super.onClose();
  }

  // Start animations
  void _startAnimations() async {
    // Animate logo
    await Future.delayed(const Duration(milliseconds: 100));
    logoOpacity.value = 1.0;

    // Animate title
    await Future.delayed(const Duration(milliseconds: 300));
    titleOpacity.value = 1.0;

    // Animate form
    await Future.delayed(const Duration(milliseconds: 300));
    formOpacity.value = 1.0;

    // Animate button
    await Future.delayed(const Duration(milliseconds: 300));
    buttonOpacity.value = 1.0;
  }

  // Update phone number
  void updatePhoneNumber(String phone, String code) {
    phoneNumber.value = phone;
    countryCode.value = code;
  }

  // Login method
  Future<void> login() async {
    if (!_validateForm()) return;

    try {
      isLoading.value = true;

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // TODO: Implement actual login logic
      final fullPhone = phoneNumber.value;
      final pin = pinController.text;

      print('Login with: $fullPhone, PIN: $pin');

      Get.snackbar(
        'Succès',
        'Connexion réussie !',
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      // Navigate to home on success
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAllNamed(Routes.HOME);

    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Une erreur est survenue lors de la connexion',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Validate form
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

    if (phoneController.text.length < 9) {
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
        'Le code PIN doit contenir 4 chiffres',
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    return true;
  }

  // Navigate to register
  void navigateToRegister() {
    Get.toNamed(Routes.REGISTER);
  }

  // Navigate to forgot password
  void navigateToForgotPassword() {
    Get.snackbar(
      'Info',
      'Page de récupération de code PIN en cours de développement',
      backgroundColor: Colors.blue.withValues(alpha: 0.8),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
    // TODO: Navigate to forgot password page
    // Get.toNamed(Routes.FORGOTPASSWORD);
  }
}
