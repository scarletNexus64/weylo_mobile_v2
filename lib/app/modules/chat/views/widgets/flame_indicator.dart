import 'package:flutter/material.dart';
import 'package:weylo/app/data/models/conversation_model.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';

/// Widget to display streak flame with progress bar
class FlameIndicator extends StatelessWidget {
  final StreakData streak;
  final bool showCount; // Afficher le "x2" sur la progress bar

  const FlameIndicator({
    super.key,
    required this.streak,
    this.showCount = true,
  });

  String get _progressText {
    if (streak.count >= 30) {
      return '${streak.count}/${streak.nextMilestone}';
    }
    return '${streak.count}/${streak.nextMilestone}';
  }

  @override
  Widget build(BuildContext context) {
    if (!streak.hasStreak) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          // Flame GIF
          Image.asset(
            'assets/gif/flame.gif',
            width: 14,
            height: 14,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 6),
          // Progress bar avec le count "x2" dessus
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Progress bar en arrière-plan
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: streak.progressToNextLevel,
                    backgroundColor: AppThemeSystem.grey600.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppThemeSystem.primaryColor,
                    ),
                    minHeight: 6,
                  ),
                ),
                // Count "x2" au-dessus de la progress bar
                if (showCount)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      'x${streak.count}',
                      style: const TextStyle(
                        color: AppThemeSystem.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Progress text "2/7"
          Text(
            _progressText,
            style: TextStyle(
              color: AppThemeSystem.grey600,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
