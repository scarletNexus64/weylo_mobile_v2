import 'package:flutter/material.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';

class ContactSyncCard extends StatelessWidget {
  final VoidCallback onSyncTap;

  const ContactSyncCard({
    super.key,
    required this.onSyncTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = context.deviceType;

    return Container(
      margin: EdgeInsets.only(
        bottom: context.elementSpacing * 0.5,
      ),
      padding: EdgeInsets.all(context.elementSpacing * 1.2),
      decoration: BoxDecoration(
        color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
            width: 1,
          ),
          bottom: BorderSide(
            color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: deviceType == DeviceType.mobile ? 48 : 56,
            height: deviceType == DeviceType.mobile ? 48 : 56,
            decoration: BoxDecoration(
              color: AppThemeSystem.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.contacts_rounded,
              color: AppThemeSystem.primaryColor,
              size: deviceType == DeviceType.mobile ? 24 : 28,
            ),
          ),
          SizedBox(width: context.elementSpacing * 1.2),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Découvrez vos contacts sur Weylo',
                  style: context.textStyle(FontSizeType.body2).copyWith(
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.white : AppThemeSystem.blackColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: context.elementSpacing),

          // Sync Button
          Flexible(
            fit: FlexFit.loose,
            child: ElevatedButton(
              onPressed: onSyncTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeSystem.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: context.elementSpacing * 1.2,
                  vertical: context.elementSpacing * 0.8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppThemeSystem.getBorderRadius(context, BorderRadiusType.small),
                  ),
                ),
                elevation: 0,
              ),
              child: Text(
                'Synchroniser',
                style: context.textStyle(FontSizeType.body2).copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
