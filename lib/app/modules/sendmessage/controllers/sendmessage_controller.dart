import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/data/services/message_service.dart';

class SendmessageController extends GetxController {
  final _messageService = MessageService();

  // Username du destinataire
  late String recipientUsername;

  // Text controller
  final messageController = TextEditingController();

  // State
  final isSending = false.obs;
  final messageLength = 0.obs;
  final maxLength = 500;

  @override
  void onInit() {
    super.onInit();

    // Récupérer le username depuis les paramètres de la route
    recipientUsername = Get.parameters['username'] ?? '';

    // Écouter les changements du message
    messageController.addListener(() {
      messageLength.value = messageController.text.length;
    });
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }

  /// Envoyer le message anonyme
  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) {
      Get.snackbar(
        'Message vide',
        'Veuillez écrire un message',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isSending.value = true;

      await _messageService.sendMessage(
        username: recipientUsername,
        content: messageController.text.trim(),
      );

      // Message envoyé avec succès
      Get.back(); // Retour à la page précédente
      Get.snackbar(
        'Succès',
        'Message anonyme envoyé !',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'envoyer le message: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSending.value = false;
    }
  }

  /// Vérifier si le message est valide
  bool get canSend => messageController.text.trim().isNotEmpty &&
                      messageController.text.trim().length <= maxLength &&
                      !isSending.value;
}
