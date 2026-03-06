import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/data/services/auth_service.dart';
import 'package:weylo/app/data/services/storage_service.dart';
import 'package:weylo/app/routes/app_pages.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = context.deviceType;
    final user = StorageService().getUser();

    return Drawer(
      backgroundColor: isDark ? AppThemeSystem.darkCardColor : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header with user profile
            _buildDrawerHeader(context, isDark, deviceType, user),

            const SizedBox(height: 16),

            // Menu items
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: context.horizontalPadding * 0.5,
                ),
                child: Column(
                  children: [
                    _buildMenuSection(context, isDark, deviceType, 'Compte', [
                      _DrawerMenuItem(
                        icon: Icons.account_circle_outlined,
                        title: 'Mon Profil',
                        onTap: () {
                          Get.back();
                          // Navigate to profile
                        },
                        gradient: LinearGradient(
                          colors: [
                            AppThemeSystem.primaryColor,
                            AppThemeSystem.secondaryColor,
                          ],
                        ),
                      ),
                      _DrawerMenuItem(
                        icon: Icons.settings_outlined,
                        title: 'Paramètres',
                        onTap: () {
                          Get.back();
                          Get.snackbar(
                            'Paramètres',
                            'Fonctionnalité à venir',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                      ),
                    ]),

                    const SizedBox(height: 8),

                    _buildMenuSection(
                      context,
                      isDark,
                      deviceType,
                      'Financier',
                      [
                        _DrawerMenuItem(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Mon Wallet',
                          subtitle: 'Gérer mes fonds',
                          onTap: () {
                            Get.back();
                            Get.snackbar(
                              'Wallet',
                              'Fonctionnalité à venir',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          },
                          gradient: LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                          ),
                        ),
                        _DrawerMenuItem(
                          icon: Icons.campaign_outlined,
                          title: 'Sponsoring',
                          subtitle: 'Faire connaître Weylo',
                          onTap: () {
                            Get.back();
                            Get.snackbar(
                              'Sponsoring',
                              'Fonctionnalité à venir',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          },
                        ),
                        _DrawerMenuItem(
                          icon: Icons.verified,
                          title: 'Certification',
                          subtitle: 'Faire certifier mon compte',
                          onTap: () {
                            Get.back();
                            Get.snackbar(
                              'Sponsoring',
                              'Fonctionnalité à venir',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          },
                          gradient: LinearGradient(
                            colors: [const Color.fromARGB(255, 115, 110, 220), const Color.fromARGB(255, 76, 94, 198)],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    _buildMenuSection(context, isDark, deviceType, 'Support', [
                      _DrawerMenuItem(
                        icon: Icons.help_outline,
                        title: 'Aide',
                        onTap: () {
                          Get.back();
                          Get.snackbar(
                            'Aide',
                            'Fonctionnalité à venir',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                      ),
                      _DrawerMenuItem(
                        icon: Icons.question_answer_outlined,
                        title: 'FAQ',
                        onTap: () {
                          Get.back();
                          Get.snackbar(
                            'FAQ',
                            'Fonctionnalité à venir',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                      ),
                    ]),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Logout button at bottom
            Container(
              padding: EdgeInsets.all(context.horizontalPadding * 0.5),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppThemeSystem.grey800.withValues(alpha: 0.6)
                        : AppThemeSystem.grey200,
                    width: 1,
                  ),
                ),
              ),
              child: _buildLogoutButton(context, isDark, deviceType),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(
    BuildContext context,
    bool isDark,
    DeviceType deviceType,
    dynamic user,
  ) {
    final firstName = user?.firstName ?? 'Utilisateur';
    final username = user?.username ?? '@user';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.horizontalPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemeSystem.primaryColor.withValues(alpha: 0.1),
            AppThemeSystem.secondaryColor.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppThemeSystem.grey800.withValues(alpha: 0.6)
                : AppThemeSystem.grey200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: deviceType == DeviceType.mobile ? 64 : 80,
            height: deviceType == DeviceType.mobile ? 64 : 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppThemeSystem.primaryColor,
                  AppThemeSystem.secondaryColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppThemeSystem.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                firstName.isNotEmpty ? firstName[0].toUpperCase() : 'W',
                style: TextStyle(
                  fontSize: deviceType == DeviceType.mobile ? 32 : 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Greeting
          Text(
            'Salut, $firstName!',
            style: context
                .textStyle(FontSizeType.h5)
                .copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: deviceType == DeviceType.mobile ? 20 : 24,
                ),
          ),

          const SizedBox(height: 4),

          // Username
          Text(
            username,
            style: context
                .textStyle(FontSizeType.body1)
                .copyWith(
                  color: isDark
                      ? AppThemeSystem.grey400
                      : AppThemeSystem.grey600,
                  fontSize: deviceType == DeviceType.mobile ? 14 : 16,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context,
    bool isDark,
    DeviceType deviceType,
    String title,
    List<_DrawerMenuItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: context
                .textStyle(FontSizeType.caption)
                .copyWith(
                  color: isDark
                      ? AppThemeSystem.grey500
                      : AppThemeSystem.grey600,
                  fontWeight: FontWeight.w600,
                  fontSize: deviceType == DeviceType.mobile ? 12 : 14,
                  letterSpacing: 0.5,
                ),
          ),
        ),
        ...items.map(
          (item) => _buildMenuItem(context, isDark, deviceType, item),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    bool isDark,
    DeviceType deviceType,
    _DrawerMenuItem item,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: deviceType == DeviceType.mobile ? 12 : 14,
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: deviceType == DeviceType.mobile ? 40 : 48,
                  height: deviceType == DeviceType.mobile ? 40 : 48,
                  decoration: BoxDecoration(
                    gradient: item.gradient,
                    color: item.gradient == null
                        ? (isDark
                              ? AppThemeSystem.grey800.withValues(alpha: 0.5)
                              : AppThemeSystem.grey100)
                        : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.gradient != null
                        ? Colors.white
                        : (isDark
                              ? AppThemeSystem.grey300
                              : AppThemeSystem.grey700),
                    size: deviceType == DeviceType.mobile ? 20 : 24,
                  ),
                ),

                const SizedBox(width: 16),

                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: context
                            .textStyle(FontSizeType.body1)
                            .copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: deviceType == DeviceType.mobile
                                  ? 15
                                  : 17,
                            ),
                      ),
                      if (item.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle!,
                          style: context
                              .textStyle(FontSizeType.caption)
                              .copyWith(
                                color: isDark
                                    ? AppThemeSystem.grey400
                                    : AppThemeSystem.grey600,
                                fontSize: deviceType == DeviceType.mobile
                                    ? 12
                                    : 14,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Arrow icon
                Icon(
                  Icons.chevron_right,
                  color: isDark
                      ? AppThemeSystem.grey500
                      : AppThemeSystem.grey400,
                  size: deviceType == DeviceType.mobile ? 20 : 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(
    BuildContext context,
    bool isDark,
    DeviceType deviceType,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          // Show confirmation dialog
          final confirm = await Get.dialog<bool>(
            AlertDialog(
              backgroundColor: isDark
                  ? AppThemeSystem.darkCardColor
                  : Colors.white,
              title: Text(
                'Déconnexion',
                style: context
                    .textStyle(FontSizeType.h6)
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              content: Text(
                'Êtes-vous sûr de vouloir vous déconnecter ?',
                style: context.textStyle(FontSizeType.body1),
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: Text(
                    'Annuler',
                    style: TextStyle(
                      color: isDark
                          ? AppThemeSystem.grey400
                          : AppThemeSystem.grey600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Get.back(result: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemeSystem.errorColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Déconnexion'),
                ),
              ],
            ),
          );

          if (confirm == true) {
            // Close drawer
            Get.back();

            // Show loading
            Get.dialog(
              Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: AppThemeSystem.primaryColor,
                        ),
                        const SizedBox(height: 16),
                        const Text('Déconnexion en cours...'),
                      ],
                    ),
                  ),
                ),
              ),
              barrierDismissible: false,
            );

            try {
              // Perform logout
              await AuthService().logout();

              // Close loading dialog
              Get.back();

              // Navigate to login
              Get.offAllNamed(Routes.LOGIN);

              Get.snackbar(
                'Déconnexion',
                'Vous avez été déconnecté avec succès',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppThemeSystem.successColor,
                colorText: Colors.white,
              );
            } catch (e) {
              // Close loading dialog
              Get.back();

              Get.snackbar(
                'Erreur',
                'Une erreur est survenue lors de la déconnexion',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppThemeSystem.errorColor,
                colorText: Colors.white,
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: deviceType == DeviceType.mobile ? 14 : 16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppThemeSystem.errorColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: deviceType == DeviceType.mobile ? 40 : 48,
                height: deviceType == DeviceType.mobile ? 40 : 48,
                decoration: BoxDecoration(
                  color: AppThemeSystem.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.logout,
                  color: AppThemeSystem.errorColor,
                  size: deviceType == DeviceType.mobile ? 20 : 24,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Text(
                  'Déconnexion',
                  style: context
                      .textStyle(FontSizeType.body1)
                      .copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppThemeSystem.errorColor,
                        fontSize: deviceType == DeviceType.mobile ? 15 : 17,
                      ),
                ),
              ),

              Icon(
                Icons.chevron_right,
                color: AppThemeSystem.errorColor.withValues(alpha: 0.6),
                size: deviceType == DeviceType.mobile ? 20 : 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerMenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Gradient? gradient;

  _DrawerMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.gradient,
  });
}
