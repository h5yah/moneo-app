import 'package:flutter/material.dart';

/// Shown when the user has already claimed today's reward for a mini-game.
class DailyRewardCompletedView extends StatelessWidget {
  const DailyRewardCompletedView({
    super.key,
    required this.gameTitle,
    this.subtitle,
    this.accentColor = const Color(0xFF6366F1),
  });

  final String gameTitle;
  final String? subtitle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 52,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Already played today',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle ??
                  'You\'ve claimed your daily $gameTitle reward.\nCome back tomorrow for another chance!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: isDark ? const Color(0xFFAAB0C6) : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Back to Rewards',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
