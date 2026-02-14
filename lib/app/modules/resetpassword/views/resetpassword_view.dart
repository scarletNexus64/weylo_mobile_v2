import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';

import '../controllers/resetpassword_controller.dart';

class ResetpasswordView extends GetView<ResetpasswordController> {
  const ResetpasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.horizontalPadding,
            vertical: context.verticalPadding,
          ),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back_ios),
                  padding: EdgeInsets.zero,
                ),

                SizedBox(height: context.sectionSpacing),

                // Icon
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppThemeSystem.successColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_open_rounded,
                      size: 50,
                      color: AppThemeSystem.successColor,
                    ),
                  ),
                ),

                SizedBox(height: context.sectionSpacing),

                // Title
                Center(
                  child: Text(
                    'Nouveau code PIN',
                    style: context.textStyle(FontSizeType.h1).copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : AppThemeSystem.blackColor,
                    ),
                  ),
                ),

                SizedBox(height: context.elementSpacing / 2),

                // Subtitle
                Center(
                  child: Text(
                    'Créez un nouveau code PIN sécurisé pour votre compte',
                    style: context.textStyle(FontSizeType.body1).copyWith(
                      color: AppThemeSystem.grey600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: context.sectionSpacing * 1.5),

                // New PIN field
                TextFormField(
                  controller: controller.pinController,
                  decoration: InputDecoration(
                    labelText: 'Nouveau code PIN',
                    hintText: '• • • •',
                    border: OutlineInputBorder(
                      borderRadius: context.borderRadius(BorderRadiusType.medium),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: context.borderRadius(BorderRadiusType.medium),
                      borderSide: BorderSide(color: AppThemeSystem.grey300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: context.borderRadius(BorderRadiusType.medium),
                      borderSide: BorderSide(
                        color: AppThemeSystem.successColor,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: context.borderRadius(BorderRadiusType.medium),
                      borderSide: BorderSide(color: AppThemeSystem.errorColor),
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: AppThemeSystem.successColor,
                    ),
                    suffixIcon: Obx(() => IconButton(
                      onPressed: controller.togglePinVisibility,
                      icon: Icon(
                        controller.isPinVisible.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppThemeSystem.grey600,
                      ),
                    )),
                  ),
                  obscureText: !controller.isPinVisible.value,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: controller.validatePin,
                ),

                SizedBox(height: context.elementSpacing),

                // Confirm PIN field
                TextFormField(
                  controller: controller.confirmPinController,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le code PIN',
                    hintText: '• • • •',
                    border: OutlineInputBorder(
                      borderRadius: context.borderRadius(BorderRadiusType.medium),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: context.borderRadius(BorderRadiusType.medium),
                      borderSide: BorderSide(color: AppThemeSystem.grey300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: context.borderRadius(BorderRadiusType.medium),
                      borderSide: BorderSide(
                        color: AppThemeSystem.successColor,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: context.borderRadius(BorderRadiusType.medium),
                      borderSide: BorderSide(color: AppThemeSystem.errorColor),
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: AppThemeSystem.successColor,
                    ),
                    suffixIcon: Obx(() => IconButton(
                      onPressed: controller.toggleConfirmPinVisibility,
                      icon: Icon(
                        controller.isConfirmPinVisible.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppThemeSystem.grey600,
                      ),
                    )),
                  ),
                  obscureText: !controller.isConfirmPinVisible.value,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: controller.validateConfirmPin,
                ),

                SizedBox(height: context.elementSpacing),

                // Security tips
                Container(
                  padding: EdgeInsets.all(context.elementSpacing),
                  decoration: BoxDecoration(
                    color: AppThemeSystem.infoColor.withOpacity(0.1),
                    borderRadius: context.borderRadius(BorderRadiusType.medium),
                    border: Border.all(
                      color: AppThemeSystem.infoColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppThemeSystem.infoColor,
                        size: 20,
                      ),
                      SizedBox(width: context.elementSpacing / 2),
                      Expanded(
                        child: Text(
                          'Choisissez un code PIN unique et ne le partagez jamais',
                          style: context.textStyle(FontSizeType.body2).copyWith(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : AppThemeSystem.grey700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: context.sectionSpacing),

                // Reset button
                Obx(() => SizedBox(
                  width: double.infinity,
                  height: context.buttonHeight,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeSystem.successColor,
                      foregroundColor: Colors.white,
                      elevation: context.elevation(ElevationType.medium),
                      shape: RoundedRectangleBorder(
                        borderRadius: context.borderRadius(BorderRadiusType.medium),
                      ),
                      disabledBackgroundColor: AppThemeSystem.grey300,
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Réinitialiser le code PIN',
                            style: context.textStyle(FontSizeType.button).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
