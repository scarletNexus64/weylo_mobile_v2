import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';
import '../controllers/sendmessage_controller.dart';

class SendmessageView extends GetView<SendmessageController> {
  const SendmessageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppThemeSystem.darkBackgroundColor
          : AppThemeSystem.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : AppThemeSystem.blackColor,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Message anonyme',
          style: context.textStyle(FontSizeType.h3).copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : AppThemeSystem.blackColor,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(context.horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: context.elementSpacing),

              // Info card
              Container(
                padding: EdgeInsets.all(context.elementSpacing * 1.5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppThemeSystem.primaryColor.withValues(alpha: 0.1),
                      AppThemeSystem.secondaryColor.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppThemeSystem.primaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      color: AppThemeSystem.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'À: @${controller.recipientUsername}',
                            style: context.textStyle(FontSizeType.body1).copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : AppThemeSystem.blackColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Votre identité restera secrète',
                            style: context.textStyle(FontSizeType.caption).copyWith(
                              color: AppThemeSystem.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: context.sectionSpacing),

              // Message input label
              Text(
                'Votre message',
                style: context.textStyle(FontSizeType.h4).copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppThemeSystem.blackColor,
                ),
              ),

              SizedBox(height: context.elementSpacing),

              // Message text field
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(context.elementSpacing),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppThemeSystem.darkCardColor
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppThemeSystem.grey700
                          : AppThemeSystem.grey300,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: controller.messageController,
                    maxLength: controller.maxLength,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: context.textStyle(FontSizeType.body1).copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : AppThemeSystem.blackColor,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Écrivez votre message anonyme ici...',
                      hintStyle: context.textStyle(FontSizeType.body1).copyWith(
                        color: AppThemeSystem.grey500,
                      ),
                      border: InputBorder.none,
                      counterText: '',
                    ),
                  ),
                ),
              ),

              SizedBox(height: context.elementSpacing),

              // Character counter
              Obx(() {
                final remaining = controller.maxLength - controller.messageLength.value;
                final isOverLimit = remaining < 0;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${controller.messageLength.value} / ${controller.maxLength}',
                      style: context.textStyle(FontSizeType.caption).copyWith(
                        color: isOverLimit ? Colors.red : AppThemeSystem.grey600,
                        fontWeight: isOverLimit ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (isOverLimit)
                      Text(
                        'Trop long de ${-remaining} caractères',
                        style: context.textStyle(FontSizeType.caption).copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                );
              }),

              SizedBox(height: context.elementSpacing),

              // Send button
              Obx(() {
                return SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: controller.canSend ? controller.sendMessage : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeSystem.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppThemeSystem.grey400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: controller.isSending.value
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Envoyer anonymement',
                                style: context.textStyle(FontSizeType.button).copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                );
              }),

              SizedBox(height: context.elementSpacing),
            ],
          ),
        ),
      ),
    );
  }
}
