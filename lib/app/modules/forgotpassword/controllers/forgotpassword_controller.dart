import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/routes/app_pages.dart';

class ForgotpasswordController extends GetxController {
  // Form key
  final formKey = GlobalKey<FormState>();

  // Text controllers
  final phoneController = TextEditingController();
  final verificationCodeController = TextEditingController();

  // Observable variables
  final isLoading = false.obs;
  final codeSent = false.obs;
  final phoneNumber = ''.obs;
  final countryCode = 'CM'.obs;
  final countryDialCode = '+237'.obs;

  @override
  void onClose() {
    phoneController.dispose();
    verificationCodeController.dispose();
    super.onClose();
  }

  // Validate phone number
  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre numéro de téléphone';
    }
    if (value.length < 9) {
      return 'Le numéro de téléphone doit contenir au moins 9 chiffres';
    }
    return null;
  }

  // Validate verification code
  String? validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer le code de vérification';
    }
    if (value.length != 6) {
      return 'Le code doit contenir 6 chiffres';
    }
    return null;
  }

  // Send verification code
  Future<void> sendCode() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      isLoading.value = true;

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // TODO: Implement actual send code logic
      final fullPhone = '$countryDialCode${phoneController.text}';
      print('Send verification code to: $fullPhone');

      codeSent.value = true;

      Get.snackbar(
        'Succès',
        'Un code de vérification a été envoyé à votre numéro',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Une erreur est survenue lors de l\'envoi du code',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Verify code and navigate to reset password
  Future<void> verifyCode() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      isLoading.value = true;

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // TODO: Implement actual verification logic
      final code = verificationCodeController.text;
      print('Verify code: $code');

      // Navigate to reset password screen with phone number
      Get.offNamed(
        Routes.RESETPASSWORD,
        arguments: {
          'phone': '$countryDialCode${phoneController.text}',
        },
      );

      Get.snackbar(
        'Succès',
        'Code vérifié avec succès',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Code de vérification invalide',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
