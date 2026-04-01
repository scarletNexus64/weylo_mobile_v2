import 'package:flutter/material.dart';
import 'package:weylo/app/data/models/conversation_model.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';

/// Widget to display streak flame with progress bar
class FlameIndicator extends StatelessWidget {
  final StreakData streak;

  const FlameIndicator({
    super.key,
    required this.streak,
  });

  String get _progressText {
    if (streak.count >= 30) {
      return '${streak.count} jours 🔥';
    }
    return '${streak.count}/${streak.nextMilestone} jours';
  }

  @override
  Widget build(BuildContext context) {
    if (!streak.hasStreak) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          // Flame GIF
          Image.asset(
            'assets/gif/flame.gif',
            width: 16,
            height: 16,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 6),
          // Progress bar
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: streak.progressToNextLevel,
                backgroundColor: AppThemeSystem.grey600.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(AppThemeSystem.primaryColor),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Progress text
          Text(
            _progressText,
            style: const TextStyle(
              color: AppThemeSystem.primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
