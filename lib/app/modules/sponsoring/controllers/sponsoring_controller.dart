import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/core/api_service.dart';
import '../../../data/models/sponsorship_checkout_args.dart';
import '../../../data/models/sponsorship_package_model.dart';
import '../../../data/services/sponsorship_service.dart';
import '../../../routes/app_pages.dart';

class SponsoringController extends GetxController {
  final _sponsorshipService = SponsorshipService();
  final _imagePicker = ImagePicker();

  final isLoadingPackages = false.obs;
  final packages = <SponsorshipPackageModel>[].obs;

  final selectedMediaType = Rxn<SponsoredMediaType>();
  final pickedMediaFile = Rxn<File>();
  final textController = TextEditingController();

  final selectedPackage = Rxn<SponsorshipPackageModel>();

  @override
  void onInit() {
    super.onInit();
    loadPackages();
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }

  Future<void> loadPackages() async {
    isLoadingPackages.value = true;
    try {
      final result = await _sponsorshipService.getPackages();
      packages.value = result.where((p) => p.isActive).toList();
    } on ApiException catch (e) {
      Get.snackbar(
        'Erreur',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les packages',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingPackages.value = false;
    }
  }

  Future<void> chooseMediaType(SponsoredMediaType type) async {
    selectedMediaType.value = type;
    selectedPackage.value = null;
    textController.text = '';
    pickedMediaFile.value = null;

    if (type == SponsoredMediaType.image) {
      await pickImage();
    } else if (type == SponsoredMediaType.video) {
      await pickVideo();
    }
  }

  Future<void> pickImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;
      pickedMediaFile.value = File(picked.path);
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de sélectionner l\'image',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> pickVideo() async {
    try {
      final picked = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );
      if (picked == null) return;
      pickedMediaFile.value = File(picked.path);
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de sélectionner la vidéo',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  bool get canContinueToPayment {
    final mediaType = selectedMediaType.value;
    final package = selectedPackage.value;
    if (mediaType == null || package == null) return false;

    if (mediaType == SponsoredMediaType.text) {
      return textController.text.trim().isNotEmpty;
    }

    return pickedMediaFile.value != null;
  }

  void goToWalletPayment() {
    final mediaType = selectedMediaType.value;
    final package = selectedPackage.value;
    if (mediaType == null || package == null) return;

    final args = SponsorshipCheckoutArgs(
      packageId: package.id,
      packageName: package.name,
      reachMin: package.reachMin,
      reachMax: package.reachMax,
      price: package.price,
      durationDays: package.durationDays,
      mediaType: mediaType,
      mediaPath: pickedMediaFile.value?.path,
      textContent: mediaType == SponsoredMediaType.text
          ? textController.text.trim()
          : null,
    );

    Get.toNamed(Routes.MY_WALLET, arguments: args);
  }
}
