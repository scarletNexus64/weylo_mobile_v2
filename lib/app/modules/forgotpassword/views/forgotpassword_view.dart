import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';

import '../controllers/forgotpassword_controller.dart';

class ForgotpasswordView extends GetView<ForgotpasswordController> {
  const ForgotpasswordView({super.key});

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
                      color: AppThemeSystem.tertiaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_reset_rounded,
                      size: 50,
                      color: AppThemeSystem.tertiaryColor,
                    ),
                  ),
                ),

                SizedBox(height: context.sectionSpacing),

                // Title
                Center(
                  child: Text(
                    'Code PIN oublié ?',
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
                    'Pas de souci ! Entrez votre numéro de téléphone pour réinitialiser votre code PIN',
                    style: context.textStyle(FontSizeType.body1).copyWith(
                      color: AppThemeSystem.grey600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: context.sectionSpacing * 1.5),

                Obx(() => !controller.codeSent.value
                    ? Column(
                        children: [
                          // Phone number field
                          IntlPhoneField(
                            controller: controller.phoneController,
                            decoration: InputDecoration(
                              labelText: 'Numéro de téléphone',
                              hintText: '6 XX XX XX XX',
                              border: OutlineInputBorder(
                                borderRadius: context.borderRadius(
                                  BorderRadiusType.medium,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: context.borderRadius(
                                  BorderRadiusType.medium,
                                ),
                                borderSide:
                                    BorderSide(color: AppThemeSystem.grey300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: context.borderRadius(
                                  BorderRadiusType.medium,
                                ),
                                borderSide: BorderSide(
                                  color: AppThemeSystem.tertiaryColor,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: context.borderRadius(
                                  BorderRadiusType.medium,
                                ),
                                borderSide:
                                    BorderSide(color: AppThemeSystem.errorColor),
                              ),
                              prefixIcon: Icon(
                                Icons.phone_outlined,
                                color: AppThemeSystem.tertiaryColor,
                              ),
                            ),
                            initialCountryCode: 'CM',
                            onChanged: (phone) {
                              controller.phoneNumber.value =
                                  phone.completeNumber;
                              controller.countryCode.value = phone.countryCode;
                              controller.countryDialCode.value =
                                  '+${phone.countryISOCode}';
                            },
                            invalidNumberMessage: 'Numéro de téléphone invalide',
                          ),

                          SizedBox(height: context.sectionSpacing),

                          // Send code button
                          Obx(() => SizedBox(
                                width: double.infinity,
                                height: context.buttonHeight,
                                child: ElevatedButton(
                                  onPressed: controller.isLoading.value
                                      ? null
                                      : controller.sendCode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        AppThemeSystem.tertiaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: context.elevation(
                                      ElevationType.medium,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: context.borderRadius(
                                        BorderRadiusType.medium,
                                      ),
                                    ),
                                    disabledBackgroundColor:
                                        AppThemeSystem.grey300,
                                  ),
                                  child: controller.isLoading.value
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          'Envoyer le code',
                                          style: context
                                              .textStyle(FontSizeType.button)
                                              .copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                ),
                              )),
                        ],
                      )
                    : Column(
                        children: [
                          // Verification code field
                          TextFormField(
                            controller: controller.verificationCodeController,
                            decoration: InputDecoration(
                              labelText: 'Code de vérification',
                              hintText: '000000',
                              border: OutlineInputBorder(
                                borderRadius: context.borderRadius(
                                  BorderRadiusType.medium,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: context.borderRadius(
                                  BorderRadiusType.medium,
                                ),
                                borderSide:
                                    BorderSide(color: AppThemeSystem.grey300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: context.borderRadius(
                                  BorderRadiusType.medium,
                                ),
                                borderSide: BorderSide(
                                  color: AppThemeSystem.tertiaryColor,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: context.borderRadius(
                                  BorderRadiusType.medium,
                                ),
                                borderSide:
                                    BorderSide(color: AppThemeSystem.errorColor),
                              ),
                              prefixIcon: Icon(
                                Icons.dialpad,
                                color: AppThemeSystem.tertiaryColor,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            validator: controller.validateCode,
                          ),

                          SizedBox(height: context.elementSpacing),

                          // Resend code link
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                controller.codeSent.value = false;
                                controller.verificationCodeController.clear();
                              },
                              child: Text(
                                'Renvoyer le code',
                                style: context
                                    .textStyle(FontSizeType.body2)
                                    .copyWith(
                                      color: AppThemeSystem.tertiaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ),

                          SizedBox(height: context.sectionSpacing),

                          // Verify code button
                          Obx(() => SizedBox(
                                width: double.infinity,
                                height: context.buttonHeight,
                                child: ElevatedButton(
                                  onPressed: controller.isLoading.value
                                      ? null
                                      : controller.verifyCode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        AppThemeSystem.tertiaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: context.elevation(
                                      ElevationType.medium,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: context.borderRadius(
                                        BorderRadiusType.medium,
                                      ),
                                    ),
                                    disabledBackgroundColor:
                                        AppThemeSystem.grey300,
                                  ),
                                  child: controller.isLoading.value
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          'Vérifier le code',
                                          style: context
                                              .textStyle(FontSizeType.button)
                                              .copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                ),
                              )),
                        ],
                      )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
