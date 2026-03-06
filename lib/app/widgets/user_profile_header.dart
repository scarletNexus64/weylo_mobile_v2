import 'package:flutter/material.dart';
import 'package:weylo/app/data/services/storage_service.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';

/// Widget pour le header avec menu hamburger et avatar badge
class UserProfileHeader extends StatelessWidget {
  final VoidCallback? onTap;

  const UserProfileHeader({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final deviceType = context.deviceType;
    final user = StorageService().getUser();
    final firstName = user?.firstName ?? 'Utilisateur';

    // Tailles responsives basées sur le système de thème
    final double iconSize = deviceType == DeviceType.mobile ? 24 : 28;
    final double avatarSize = deviceType == DeviceType.mobile ? 28 : 32;
    final double badgePaddingH = context.elementSpacing * 0.8;
    final double badgePaddingV = context.elementSpacing * 0.5;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Menu hamburger moderne
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: context.borderRadius(BorderRadiusType.medium),
            child: Container(
              padding: EdgeInsets.all(context.elementSpacing * 0.5),
              child: Icon(
                Icons.menu_rounded,
                size: iconSize,
                color: context.primaryTextColor,
              ),
            ),
          ),
        ),

        SizedBox(width: context.elementSpacing * 0.5),

        // Avatar badge avec nom - cliquable aussi
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: badgePaddingH,
                vertical: badgePaddingV,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isDark
                    ? AppThemeSystem.grey800.withValues(alpha: 0.5)
                    : AppThemeSystem.grey100,
                border: Border.all(
                  color: context.borderColor.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Mini avatar
                  Container(
                    width: avatarSize,
                    height: avatarSize,
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
                      boxShadow: [
                        BoxShadow(
                          color: AppThemeSystem.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        firstName.isNotEmpty ? firstName[0].toUpperCase() : 'W',
                        style: context.textStyle(FontSizeType.body2).copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: context.elementSpacing * 0.6),

                  // Nom compact
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: deviceType == DeviceType.mobile ? 80 : 120,
                    ),
                    child: Text(
                      firstName,
                      style: context.textStyle(FontSizeType.body2).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  SizedBox(width: context.elementSpacing * 0.4),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
