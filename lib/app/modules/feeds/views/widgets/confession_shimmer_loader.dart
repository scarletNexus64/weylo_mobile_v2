import 'package:flutter/material.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';

/// Shimmer loading placeholder for confessions
class ConfessionShimmerLoader extends StatefulWidget {
  final int itemCount;

  const ConfessionShimmerLoader({
    super.key,
    this.itemCount = 3,
  });

  @override
  State<ConfessionShimmerLoader> createState() => _ConfessionShimmerLoaderState();
}

class _ConfessionShimmerLoaderState extends State<ConfessionShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = context.deviceType;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        return _buildShimmerCard(context, isDark, deviceType);
      },
    );
  }

  Widget _buildShimmerCard(BuildContext context, bool isDark, DeviceType deviceType) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          margin: EdgeInsets.only(
            bottom: context.elementSpacing * 1.2,
          ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(context.elementSpacing),
                child: Row(
                  children: [
                    // Avatar shimmer
                    _buildShimmerBox(
                      width: deviceType == DeviceType.mobile ? 40 : 48,
                      height: deviceType == DeviceType.mobile ? 40 : 48,
                      borderRadius: 100,
                      isDark: isDark,
                    ),
                    SizedBox(width: context.elementSpacing),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name shimmer
                          _buildShimmerBox(
                            width: 120,
                            height: 14,
                            borderRadius: 4,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 6),
                          // Time shimmer
                          _buildShimmerBox(
                            width: 80,
                            height: 12,
                            borderRadius: 4,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content shimmer
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.elementSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerBox(
                      width: double.infinity,
                      height: 12,
                      borderRadius: 4,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildShimmerBox(
                      width: double.infinity,
                      height: 12,
                      borderRadius: 4,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildShimmerBox(
                      width: 200,
                      height: 12,
                      borderRadius: 4,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              SizedBox(height: context.elementSpacing),

              // Actions shimmer
              Padding(
                padding: EdgeInsets.all(context.elementSpacing),
                child: Row(
                  children: [
                    _buildShimmerBox(
                      width: 60,
                      height: 28,
                      borderRadius: 14,
                      isDark: isDark,
                    ),
                    SizedBox(width: context.elementSpacing),
                    _buildShimmerBox(
                      width: 60,
                      height: 28,
                      borderRadius: 14,
                      isDark: isDark,
                    ),
                    SizedBox(width: context.elementSpacing),
                    _buildShimmerBox(
                      width: 60,
                      height: 28,
                      borderRadius: 14,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    required double borderRadius,
    required bool isDark,
  }) {
    final shimmerGradient = LinearGradient(
      colors: isDark
          ? [
              AppThemeSystem.grey800,
              AppThemeSystem.grey700,
              AppThemeSystem.grey800,
            ]
          : [
              AppThemeSystem.grey200,
              AppThemeSystem.grey100,
              AppThemeSystem.grey200,
            ],
      stops: const [
        0.0,
        0.5,
        1.0,
      ],
      begin: Alignment(-1.0 - _shimmerController.value * 2, 0.0),
      end: Alignment(1.0 - _shimmerController.value * 2, 0.0),
      tileMode: TileMode.clamp,
    );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: shimmerGradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
