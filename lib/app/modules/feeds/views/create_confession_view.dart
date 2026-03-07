import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';

class CreateConfessionView extends StatefulWidget {
  const CreateConfessionView({super.key});

  @override
  State<CreateConfessionView> createState() => _CreateConfessionViewState();
}

class _CreateConfessionViewState extends State<CreateConfessionView> {
  final TextEditingController _textController = TextEditingController();
  String selectedOption = 'text'; // text, image, video
  bool isAnonymous = false; // Publication anonyme ou pas

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = context.deviceType;

    return Scaffold(
      backgroundColor: isDark ? AppThemeSystem.darkBackgroundColor : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppThemeSystem.darkCardColor : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            size: deviceType == DeviceType.mobile ? 24 : 28,
          ),
          onPressed: () => Get.back(),
          color: isDark ? Colors.white : AppThemeSystem.blackColor,
        ),
        title: Text(
          'Nouvelle publication',
          style: context.textStyle(FontSizeType.h6).copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppThemeSystem.blackColor,
          ),
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: context.horizontalPadding,
                vertical: context.elementSpacing * 1.5,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info
                  Row(
                    children: [
                      Container(
                        width: deviceType == DeviceType.mobile ? 50 : 60,
                        height: deviceType == DeviceType.mobile ? 50 : 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isAnonymous
                                ? [
                                    AppThemeSystem.grey700,
                                    AppThemeSystem.grey600,
                                  ]
                                : [
                                    AppThemeSystem.primaryColor,
                                    AppThemeSystem.secondaryColor,
                                  ],
                          ),
                        ),
                        child: Icon(
                          isAnonymous ? Icons.lock_rounded : Icons.person_rounded,
                          color: Colors.white,
                          size: deviceType == DeviceType.mobile ? 26 : 32,
                        ),
                      ),
                      SizedBox(width: context.elementSpacing),
                      Expanded(
                        child: Text(
                          isAnonymous ? 'Anonyme' : 'Jr Steve',
                          style: context.textStyle(FontSizeType.body1).copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppThemeSystem.blackColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.elementSpacing),

                  // Anonyme Toggle
                  Container(
                    padding: EdgeInsets.all(context.elementSpacing),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppThemeSystem.grey800.withValues(alpha: 0.3)
                          : AppThemeSystem.grey100,
                      borderRadius: context.borderRadius(BorderRadiusType.medium),
                      border: Border.all(
                        color: isAnonymous
                            ? AppThemeSystem.primaryColor.withValues(alpha: 0.5)
                            : (isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300),
                        width: isAnonymous ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isAnonymous ? Icons.lock_rounded : Icons.person_outline_rounded,
                          size: deviceType == DeviceType.mobile ? 20 : 24,
                          color: isAnonymous
                              ? AppThemeSystem.primaryColor
                              : (isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600),
                        ),
                        SizedBox(width: context.elementSpacing),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Publier en anonyme',
                                style: context.textStyle(FontSizeType.body2).copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppThemeSystem.blackColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isAnonymous
                                    ? 'Votre identité sera cachée'
                                    : 'Votre nom sera visible',
                                style: context.textStyle(FontSizeType.caption).copyWith(
                                  color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isAnonymous,
                          onChanged: (value) {
                            setState(() {
                              isAnonymous = value;
                            });
                          },
                          activeTrackColor: AppThemeSystem.primaryColor.withValues(alpha: 0.5),
                          thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppThemeSystem.primaryColor;
                            }
                            return isDark ? AppThemeSystem.grey600 : AppThemeSystem.grey400;
                          }),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.elementSpacing * 1.5),

                  // Text Input
                  TextField(
                    controller: _textController,
                    maxLines: null,
                    minLines: 8,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Quoi de neuf ?',
                      hintStyle: context.textStyle(FontSizeType.body1).copyWith(
                        color: isDark ? AppThemeSystem.grey500 : AppThemeSystem.grey600,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: context.elementSpacing * 0.5,
                      ),
                    ),
                    style: context.textStyle(FontSizeType.body1).copyWith(
                      color: isDark ? Colors.white : AppThemeSystem.blackColor,
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: context.elementSpacing * 1.5),

                  // Content Preview based on selected option
                  if (selectedOption == 'image') _buildImageUploadSection(context, isDark),
                  if (selectedOption == 'video') _buildVideoUploadSection(context, isDark),
                ],
              ),
            ),
          ),

          // Bottom Options
          Container(
            padding: EdgeInsets.only(
              left: context.horizontalPadding,
              right: context.horizontalPadding,
              top: context.elementSpacing,
              bottom: context.elementSpacing,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Options Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOptionButton(
                      context: context,
                      icon: Icons.text_fields_rounded,
                      label: 'Texte',
                      isSelected: selectedOption == 'text',
                      onTap: () => setState(() => selectedOption = 'text'),
                      isDark: isDark,
                      deviceType: deviceType,
                    ),
                    SizedBox(width: context.elementSpacing),
                    _buildOptionButton(
                      context: context,
                      icon: Icons.image_outlined,
                      label: 'Image',
                      isSelected: selectedOption == 'image',
                      onTap: () => setState(() => selectedOption = 'image'),
                      isDark: isDark,
                      deviceType: deviceType,
                    ),
                    SizedBox(width: context.elementSpacing),
                    _buildOptionButton(
                      context: context,
                      icon: Icons.videocam_outlined,
                      label: 'Vidéo',
                      isSelected: selectedOption == 'video',
                      onTap: () => setState(() => selectedOption = 'video'),
                      isDark: isDark,
                      deviceType: deviceType,
                    ),
                  ],
                ),
                SizedBox(height: context.elementSpacing),

                // Publish Button
                SizedBox(
                  width: double.infinity,
                  height: context.buttonHeight,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      Get.snackbar(
                        'Publication créée',
                        isAnonymous
                            ? 'Votre confession anonyme a été publiée'
                            : 'Votre confession a été publiée avec succès',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppThemeSystem.successColor,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 3),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeSystem.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: context.borderRadius(BorderRadiusType.small),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Publier',
                      style: context.textStyle(FontSizeType.body1).copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required DeviceType deviceType,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: context.borderRadius(BorderRadiusType.small),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: context.elementSpacing * 1.2,
            horizontal: context.elementSpacing * 0.5,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppThemeSystem.primaryColor.withValues(alpha: 0.15)
                : (isDark
                    ? AppThemeSystem.grey800.withValues(alpha: 0.3)
                    : AppThemeSystem.grey100),
            borderRadius: context.borderRadius(BorderRadiusType.small),
            border: isSelected
                ? Border.all(
                    color: AppThemeSystem.primaryColor,
                    width: 2,
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: deviceType == DeviceType.mobile ? 28 : 34,
                color: isSelected
                    ? AppThemeSystem.primaryColor
                    : (isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600),
              ),
              SizedBox(height: context.elementSpacing * 0.4),
              Text(
                label,
                style: context.textStyle(FontSizeType.body2).copyWith(
                  color: isSelected
                      ? AppThemeSystem.primaryColor
                      : (isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadSection(BuildContext context, bool isDark) {
    final deviceType = context.deviceType;
    double uploadHeight;
    switch (deviceType) {
      case DeviceType.mobile:
        uploadHeight = 200;
        break;
      case DeviceType.tablet:
        uploadHeight = 280;
        break;
      case DeviceType.largeTablet:
      case DeviceType.iPadPro13:
        uploadHeight = 320;
        break;
      case DeviceType.desktop:
        uploadHeight = 360;
        break;
    }

    return Container(
      height: uploadHeight,
      decoration: BoxDecoration(
        color: isDark
            ? AppThemeSystem.grey800.withValues(alpha: 0.3)
            : AppThemeSystem.grey100,
        borderRadius: context.borderRadius(BorderRadiusType.medium),
        border: Border.all(
          color: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300,
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: deviceType == DeviceType.mobile ? 48 : 64,
              color: isDark ? AppThemeSystem.grey500 : AppThemeSystem.grey600,
            ),
            SizedBox(height: context.elementSpacing * 0.5),
            Text(
              'Ajouter une image',
              style: context.textStyle(FontSizeType.body1).copyWith(
                color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoUploadSection(BuildContext context, bool isDark) {
    final deviceType = context.deviceType;
    double uploadHeight;
    switch (deviceType) {
      case DeviceType.mobile:
        uploadHeight = 200;
        break;
      case DeviceType.tablet:
        uploadHeight = 280;
        break;
      case DeviceType.largeTablet:
      case DeviceType.iPadPro13:
        uploadHeight = 320;
        break;
      case DeviceType.desktop:
        uploadHeight = 360;
        break;
    }

    return Container(
      height: uploadHeight,
      decoration: BoxDecoration(
        color: isDark
            ? AppThemeSystem.grey800.withValues(alpha: 0.3)
            : AppThemeSystem.grey100,
        borderRadius: context.borderRadius(BorderRadiusType.medium),
        border: Border.all(
          color: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300,
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_outlined,
              size: deviceType == DeviceType.mobile ? 48 : 64,
              color: isDark ? AppThemeSystem.grey500 : AppThemeSystem.grey600,
            ),
            SizedBox(height: context.elementSpacing * 0.5),
            Text(
              'Ajouter une vidéo',
              style: context.textStyle(FontSizeType.body1).copyWith(
                color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
