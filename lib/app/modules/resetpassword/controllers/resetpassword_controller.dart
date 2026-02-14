import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/routes/app_pages.dart';

class ResetpasswordController extends GetxController {
  // Form key
  final formKey = GlobalKey<FormState>();

  // Text controllers
  final pinController = TextEditingController();
  final confirmPinController = TextEditingController();

  // Observable variables
  final isLoading = false.obs;
  final isPinVisible = false.obs;
  final isConfirmPinVisible = false.obs;
  final phoneNumber = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Get phone number from arguments if passed
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('phone')) {
      phoneNumber.value = args['phone'];
    }
  }

  @override
  void onClose() {
    pinController.dispose();
    confirmPinController.dispose();
    super.onClose();
  }

  // Toggle PIN visibility
  void togglePinVisibility() {
    isPinVisible.value = !isPinVisible.value;
  }

  // Toggle confirm PIN visibility
  void toggleConfirmPinVisibility() {
    isConfirmPinVisible.value = !isConfirmPinVisible.value;
  }

  // Validate PIN
  String? validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre nouveau code PIN';
    }
    if (value.length != 4) {
      return 'Le code PIN doit contenir 4 chiffres';
    }
    return null;
  }

  // Validate confirm PIN
  String? validateConfirmPin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer votre code PIN';
    }
    if (value != pinController.text) {
      return 'Les codes PIN ne correspondent pas';
    }
    return null;
  }

  // Reset password
  Future<void> resetPassword() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      isLoading.value = true;

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // TODO: Implement actual reset password logic
      final pin = pinController.text;
      print('Reset password for ${phoneNumber.value}, new PIN: $pin');

      // Navigate to login screen
      Get.offAllNamed(Routes.LOGIN);

      Get.snackbar(
        'Succès',
        'Votre code PIN a été réinitialisé avec succès',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Une erreur est survenue lors de la réinitialisation',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
