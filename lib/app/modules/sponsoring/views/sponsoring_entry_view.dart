import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../widgets/app_theme_system.dart';
import '../controllers/sponsoring_entry_controller.dart';

class SponsoringEntryView extends GetView<SponsoringEntryController> {
  const SponsoringEntryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final error = controller.errorMessage.value;
          if (error != null) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(context.horizontalPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppThemeSystem.errorColor,
                      size: 44,
                    ),
                    SizedBox(height: context.elementSpacing),
                    Text('Erreur', style: context.h5),
                    SizedBox(height: context.elementSpacing * 0.5),
                    Text(
                      error,
                      style: context.body2.copyWith(
                        color: context.secondaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: context.sectionSpacing),
                    SizedBox(
                      width: double.infinity,
                      height: context.buttonHeight,
                      child: ElevatedButton(
                        onPressed: controller.check,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemeSystem.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                context.borderRadius(BorderRadiusType.medium),
                          ),
                        ),
                        child: Text(
                          'Réessayer',
                          style: context.button.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        }),
      ),
    );
  }
}
