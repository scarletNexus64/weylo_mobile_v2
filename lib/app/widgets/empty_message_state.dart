import 'package:flutter/material.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';

class EmptyMessageState extends StatelessWidget {
  const EmptyMessageState({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: context.sectionSpacing * 1.5,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated illustration
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppThemeSystem.primaryColor.withValues(alpha: 0.15),
                      AppThemeSystem.secondaryColor.withValues(alpha: 0.15),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mail_outline_rounded,
                  size: 60,
                  color: AppThemeSystem.primaryColor,
                ),
              ),
            ),

            SizedBox(height: context.sectionSpacing * 1.5),

            // Title
            Text(
              'Aucun message',
              style: context.textStyle(FontSizeType.h3).copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppThemeSystem.blackColor,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: context.elementSpacing),

            // Description
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
              child: Text(
                'C\'est ici que vos messages anonymes\nseront affichés',
                style: context.textStyle(FontSizeType.body2).copyWith(
                  color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
