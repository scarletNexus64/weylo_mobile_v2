import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';

class MessageShimmerLoading extends StatelessWidget {
  final int itemCount;

  const MessageShimmerLoading({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: isDark
              ? AppThemeSystem.grey800.withValues(alpha: 0.3)
              : AppThemeSystem.grey300,
          highlightColor: isDark
              ? AppThemeSystem.grey700.withValues(alpha: 0.2)
              : AppThemeSystem.grey100,
          child: Container(
            margin: EdgeInsets.only(
              bottom: context.elementSpacing,
            ),
            padding: EdgeInsets.all(context.elementSpacing),
            decoration: BoxDecoration(
              color: isDark
                  ? AppThemeSystem.darkCardColor
                  : Colors.white,
              borderRadius: context.borderRadius(BorderRadiusType.medium),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppThemeSystem.grey700
                            : AppThemeSystem.grey300,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            height: 14,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppThemeSystem.grey700
                                  : AppThemeSystem.grey300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 80,
                            height: 12,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppThemeSystem.grey700
                                  : AppThemeSystem.grey300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.elementSpacing),
                // Content
                Container(
                  padding: EdgeInsets.all(context.elementSpacing),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppThemeSystem.darkBackgroundColor
                        : AppThemeSystem.grey100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppThemeSystem.grey700
                              : AppThemeSystem.grey300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppThemeSystem.grey700
                              : AppThemeSystem.grey300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 200,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppThemeSystem.grey700
                              : AppThemeSystem.grey300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.elementSpacing),
                // Button
                Container(
                  width: double.infinity,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppThemeSystem.grey700
                        : AppThemeSystem.grey300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Shimmer for link card
class LinkCardShimmerLoading extends StatelessWidget {
  const LinkCardShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark
          ? AppThemeSystem.grey800.withValues(alpha: 0.3)
          : AppThemeSystem.grey300,
      highlightColor: isDark
          ? AppThemeSystem.grey700.withValues(alpha: 0.2)
          : AppThemeSystem.grey100,
      child: Container(
        padding: EdgeInsets.all(context.elementSpacing * 1.5),
        decoration: BoxDecoration(
          color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppThemeSystem.grey700
                        : AppThemeSystem.grey300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 150,
                        height: 16,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppThemeSystem.grey700
                              : AppThemeSystem.grey300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 200,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppThemeSystem.grey700
                              : AppThemeSystem.grey300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: context.elementSpacing * 1.2),
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: isDark
                    ? AppThemeSystem.grey700
                    : AppThemeSystem.grey300,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            SizedBox(height: context.elementSpacing * 1.2),
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: isDark
                    ? AppThemeSystem.grey700
                    : AppThemeSystem.grey300,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
