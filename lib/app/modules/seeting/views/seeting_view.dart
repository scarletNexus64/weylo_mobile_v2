import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/seeting_controller.dart';
import '../../../widgets/app_theme_system.dart';

class SeetingView extends GetView<SeetingController> {
  const SeetingView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = context.deviceType;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppThemeSystem.darkCardColor : Colors.white,
        foregroundColor: context.primaryTextColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Paramètres',
          style: context.textStyle(FontSizeType.h6).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: context.primaryTextColor,
            size: deviceType == DeviceType.mobile ? 20 : 24,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.horizontalPadding,
            vertical: context.verticalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Info Section
              _buildAppInfoSection(context, isDark, deviceType),

              SizedBox(height: context.sectionSpacing),

              // Notifications Section
              _buildNotificationsSection(context, isDark, deviceType),

              SizedBox(height: context.sectionSpacing),

              // About Section
              _buildAboutSection(context, isDark, deviceType),

              SizedBox(height: context.sectionSpacing),

              // Support Section
              _buildSupportSection(context, isDark, deviceType),

              SizedBox(height: context.sectionSpacing),

              // Version Info
              _buildVersionInfo(context, isDark, deviceType),
            ],
          ),
        ),
      ),
    );
  }

  /// App Info Section with logo and description
  Widget _buildAppInfoSection(
    BuildContext context,
    bool isDark,
    DeviceType deviceType,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.elementSpacing * 1.5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemeSystem.primaryColor.withValues(alpha: 0.1),
            AppThemeSystem.secondaryColor.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: context.borderRadius(BorderRadiusType.large),
        border: Border.all(
          color: AppThemeSystem.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // App Logo/Icon
          Container(
            width: deviceType == DeviceType.mobile ? 80 : 100,
            height: deviceType == DeviceType.mobile ? 80 : 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppThemeSystem.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                width: deviceType == DeviceType.mobile ? 80 : 100,
                height: deviceType == DeviceType.mobile ? 80 : 100,
                fit: BoxFit.cover,
              ),
            ),
          ),

          SizedBox(height: context.elementSpacing),

          // App Name
          Text(
            'Weylo',
            style: context.textStyle(FontSizeType.h4).copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: context.elementSpacing * 0.5),

          // App Tagline
          Text(
            'Confessions Anonymes & Stories',
            style: context.textStyle(FontSizeType.body2).copyWith(
              color: context.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Notifications Section
  Widget _buildNotificationsSection(
    BuildContext context,
    bool isDark,
    DeviceType deviceType,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: EdgeInsets.only(
            left: context.elementSpacing * 0.5,
            bottom: context.elementSpacing * 0.5,
          ),
          child: Text(
            'PRÉFÉRENCES',
            style: context.textStyle(FontSizeType.caption).copyWith(
              color: context.secondaryTextColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // Notification Toggle Card
        Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: context.borderRadius(BorderRadiusType.medium),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Obx(
            () => SwitchListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.elementSpacing,
                vertical: context.elementSpacing * 0.5,
              ),
              secondary: Container(
                width: deviceType == DeviceType.mobile ? 40 : 48,
                height: deviceType == DeviceType.mobile ? 40 : 48,
                decoration: BoxDecoration(
                  color: controller.isNotificationsEnabled.value
                    ? AppThemeSystem.primaryColor.withValues(alpha: 0.1)
                    : (isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey100),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  controller.isNotificationsEnabled.value
                    ? Icons.notifications_active
                    : Icons.notifications_off_outlined,
                  color: controller.isNotificationsEnabled.value
                    ? AppThemeSystem.primaryColor
                    : context.secondaryTextColor,
                  size: deviceType == DeviceType.mobile ? 20 : 24,
                ),
              ),
              title: Text(
                'Notifications',
                style: context.textStyle(FontSizeType.body1).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                controller.isNotificationsEnabled.value
                  ? 'Recevoir les notifications de l\'application'
                  : 'Les notifications sont désactivées',
                style: context.textStyle(FontSizeType.caption).copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
              value: controller.isNotificationsEnabled.value,
              onChanged: (value) => controller.toggleNotifications(value),
              activeTrackColor: AppThemeSystem.primaryColor.withValues(alpha: 0.5),
              activeThumbColor: AppThemeSystem.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  /// About Section
  Widget _buildAboutSection(
    BuildContext context,
    bool isDark,
    DeviceType deviceType,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: EdgeInsets.only(
            left: context.elementSpacing * 0.5,
            bottom: context.elementSpacing * 0.5,
          ),
          child: Text(
            'À PROPOS',
            style: context.textStyle(FontSizeType.caption).copyWith(
              color: context.secondaryTextColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // About Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(context.elementSpacing * 1.5),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: context.borderRadius(BorderRadiusType.medium),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: deviceType == DeviceType.mobile ? 40 : 48,
                    height: deviceType == DeviceType.mobile ? 40 : 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppThemeSystem.primaryColor,
                          AppThemeSystem.secondaryColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: deviceType == DeviceType.mobile ? 20 : 24,
                    ),
                  ),
                  SizedBox(width: context.elementSpacing),
                  Text(
                    'Description',
                    style: context.textStyle(FontSizeType.body1).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              SizedBox(height: context.elementSpacing),

              Text(
                controller.getAppDescription(),
                style: context.textStyle(FontSizeType.body2).copyWith(
                  color: context.secondaryTextColor,
                  height: 1.6,
                ),
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Support Section
  Widget _buildSupportSection(
    BuildContext context,
    bool isDark,
    DeviceType deviceType,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: EdgeInsets.only(
            left: context.elementSpacing * 0.5,
            bottom: context.elementSpacing * 0.5,
          ),
          child: Text(
            'SUPPORT',
            style: context.textStyle(FontSizeType.caption).copyWith(
              color: context.secondaryTextColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // Support Card
        Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: context.borderRadius(BorderRadiusType.medium),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showContactBottomSheet(context, isDark, deviceType),
              borderRadius: context.borderRadius(BorderRadiusType.medium),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.elementSpacing,
                  vertical: context.elementSpacing * 1.25,
                ),
                child: Row(
                  children: [
                    Container(
                      width: deviceType == DeviceType.mobile ? 40 : 48,
                      height: deviceType == DeviceType.mobile ? 40 : 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppThemeSystem.primaryColor,
                            AppThemeSystem.secondaryColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.support_agent_outlined,
                        color: Colors.white,
                        size: deviceType == DeviceType.mobile ? 20 : 24,
                      ),
                    ),

                    SizedBox(width: context.elementSpacing),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nous contacter',
                            style: context.textStyle(FontSizeType.body1).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: context.elementSpacing * 0.25),
                          Text(
                            'Besoin d\'aide ? Contactez notre équipe',
                            style: context.textStyle(FontSizeType.caption).copyWith(
                              color: context.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Icon(
                      Icons.chevron_right,
                      color: context.secondaryTextColor,
                      size: deviceType == DeviceType.mobile ? 20 : 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Afficher le bottomsheet de contact
  void _showContactBottomSheet(BuildContext context, bool isDark, DeviceType deviceType) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nous contacter',
                      style: context.textStyle(FontSizeType.h6).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,
                color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
              ),

              SizedBox(height: context.elementSpacing),

              // Contact items
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.horizontalPadding,
                  vertical: context.elementSpacing,
                ),
                child: Column(
                  children: [
                    // Email
                    _buildContactItem(
                      context: context,
                      isDark: isDark,
                      deviceType: deviceType,
                      icon: Icons.email_outlined,
                      iconColor: AppThemeSystem.primaryColor,
                      title: 'Email',
                      value: 'Weyloapp@gmail.com',
                      onTap: () {
                        // TODO: Ouvrir l'app email
                        Get.snackbar(
                          'Email',
                          'Ouverture de l\'application email...',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),

                    SizedBox(height: context.elementSpacing),

                    // WhatsApp
                    _buildContactItem(
                      context: context,
                      isDark: isDark,
                      deviceType: deviceType,
                      icon: Icons.chat_bubble_outline,
                      iconColor: const Color(0xFF25D366),
                      title: 'WhatsApp',
                      value: '+237 691 592 882',
                      onTap: () {
                        // TODO: Ouvrir WhatsApp
                        Get.snackbar(
                          'WhatsApp',
                          'Ouverture de WhatsApp...',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: context.elementSpacing * 2),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// Construire un élément de contact
  Widget _buildContactItem({
    required BuildContext context,
    required bool isDark,
    required DeviceType deviceType,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: context.borderRadius(BorderRadiusType.medium),
        child: Container(
          padding: EdgeInsets.all(context.elementSpacing),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
            ),
            borderRadius: context.borderRadius(BorderRadiusType.medium),
          ),
          child: Row(
            children: [
              Container(
                width: deviceType == DeviceType.mobile ? 48 : 56,
                height: deviceType == DeviceType.mobile ? 48 : 56,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: deviceType == DeviceType.mobile ? 24 : 28,
                ),
              ),

              SizedBox(width: context.elementSpacing),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textStyle(FontSizeType.body2).copyWith(
                        color: context.secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: context.elementSpacing * 0.25),
                    Text(
                      value,
                      style: context.textStyle(FontSizeType.body1).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_ios,
                color: context.secondaryTextColor,
                size: deviceType == DeviceType.mobile ? 16 : 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Version Info Section
  Widget _buildVersionInfo(
    BuildContext context,
    bool isDark,
    DeviceType deviceType,
  ) {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: EdgeInsets.all(context.elementSpacing * 1.5),
        decoration: BoxDecoration(
          color: isDark
            ? AppThemeSystem.grey900.withValues(alpha: 0.3)
            : AppThemeSystem.grey100,
          borderRadius: context.borderRadius(BorderRadiusType.medium),
          border: Border.all(
            color: context.borderColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.verified_outlined,
              color: AppThemeSystem.primaryColor,
              size: deviceType == DeviceType.mobile ? 32 : 40,
            ),

            SizedBox(height: context.elementSpacing * 0.5),

            Text(
              'Version ${controller.appVersion.value}',
              style: context.textStyle(FontSizeType.body1).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: context.elementSpacing * 0.25),

            Text(
              'Build ${controller.appBuildNumber.value}',
              style: context.textStyle(FontSizeType.caption).copyWith(
                color: context.secondaryTextColor,
              ),
            ),

            SizedBox(height: context.elementSpacing * 0.5),

            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.elementSpacing,
                vertical: context.elementSpacing * 0.5,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppThemeSystem.primaryColor.withValues(alpha: 0.1),
                    AppThemeSystem.secondaryColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppThemeSystem.primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                '© 2026 Weylo - Tous droits réservés',
                style: context.textStyle(FontSizeType.caption).copyWith(
                  color: AppThemeSystem.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
