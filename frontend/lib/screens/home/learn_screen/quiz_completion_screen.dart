import 'package:flutter/material.dart';
import 'topic_completion_screen.dart';
import 'package:fintech/services/xp_service.dart';

class QuizCompletionScreen extends StatelessWidget {
  final int score;
  final int totalQuestions;
  final int earnedXP;
  final int currentLevel;
  final int xpToNextLevel;
  final String? topicId;
  final String? topicTitle;
  final int? lessonsCompleted;
  final int? totalLessons;
  final int? preQuizScore;
  final int? preQuizTotal;

  const QuizCompletionScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.earnedXP,
    required this.currentLevel,
    required this.xpToNextLevel,
    this.topicId,
    this.topicTitle,
    this.lessonsCompleted,
    this.totalLessons,
    this.preQuizScore,
    this.preQuizTotal,
  });

  @override
  Widget build(BuildContext context) {
    final hasImprovementData =
      preQuizScore != null && preQuizTotal != null && preQuizTotal! > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // XP Badge with animation effect
                _buildXPBadge(),
                const SizedBox(height: 32),
                // Great job title
                const Text(
                  'Great job!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                // XP message
                StreamBuilder<int>(
                  stream: XpService.instance.xpStream(),
                  builder: (context, snapshot) {
                    final totalXp = (snapshot.data ?? 0).clamp(0, 1 << 30);
                    final levelMeta = XpService.levelMetaFromTotalXp(totalXp);
                    final liveCurrentLevel = levelMeta.level;
                    final liveXpToNext = levelMeta.xpToNextLevel;

                    return RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black.withValues(alpha: 0.6),
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: "You're "),
                          TextSpan(
                            text: '$liveXpToNext XP',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF007AFF),
                            ),
                          ),
                          const TextSpan(text: ' away from your next\nreward.'),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                // Level progress section
                StreamBuilder<int>(
                  stream: XpService.instance.xpStream(),
                  builder: (context, snapshot) {
                    final totalXp = (snapshot.data ?? 0).clamp(0, 1 << 30);
                    final levelMeta = XpService.levelMetaFromTotalXp(totalXp);
                    return _buildLevelProgress(
                      levelMeta.progressInLevel,
                      currentLevel: levelMeta.level,
                    );
                  },
                ),
                if (hasImprovementData) ...[
                  const SizedBox(height: 24),
                  _buildImprovementSection(),
                ],
                const SizedBox(height: 16),
                // Encouragement message
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Keep going — you’re building momentum!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Continue button
                _buildContinueButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildXPBadge() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Main XP card (rotated)
        Transform.rotate(
          angle: -0.1, // Slight rotation
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                'XP',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        // Earned XP badge
        Positioned(
          top: -10,
          right: -10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF007AFF),
                width: 2,
              ),
            ),
            child: Text(
              '+$earnedXP XP',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF007AFF),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelProgress(
    double progress, {
    required int currentLevel,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Level $currentLevel',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF007AFF),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Level ${currentLevel + 1}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 15,
            backgroundColor: const Color(0xFFE0E0E0),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    final resolvedTopicTitle = topicTitle;
    final resolvedLessonsCompleted = lessonsCompleted;
    final resolvedTotalLessons = totalLessons;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (resolvedTopicTitle == null ||
              resolvedLessonsCompleted == null ||
              resolvedTotalLessons == null) {
            Navigator.of(context).pop();
            return;
          }

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => TopicCompletionScreen(
                topicId: topicId,
                topicTitle: resolvedTopicTitle,
                lessonsCompleted: resolvedLessonsCompleted,
                totalLessons: resolvedTotalLessons,
                earnedXP: earnedXP,
                performanceScore: (score / totalQuestions * 100).clamp(0.0, 100.0),
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF007AFF),
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Continue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImprovementSection() {
    final beforePercent = ((preQuizScore! / preQuizTotal!) * 100).clamp(0, 100);
    final afterPercent = ((score / totalQuestions) * 100).clamp(0, 100);
    final improvement = afterPercent - beforePercent;
    final improvementLabel = improvement >= 0
        ? '+${improvement.toStringAsFixed(0)}%'
        : '${improvement.toStringAsFixed(0)}%';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF007AFF).withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What improved?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _buildScoreRow(
            label: 'Before Quiz',
            scoreText: '$preQuizScore / $preQuizTotal',
            percentText: '${beforePercent.toStringAsFixed(0)}%',
          ),
          const SizedBox(height: 8),
          _buildScoreRow(
            label: 'Final Quiz',
            scoreText: '$score / $totalQuestions',
            percentText: '${afterPercent.toStringAsFixed(0)}%',
          ),
          const SizedBox(height: 10),
          Text(
            improvement >= 0
                ? 'You improved by $improvementLabel. Keep it up!'
                : 'Your score changed by $improvementLabel. Review and try again! ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: improvement >= 0 ? const Color(0xFF2E7D32) : const Color(0xFFB26A00),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow({
    required String label,
    required String scoreText,
    required String percentText,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withValues(alpha: 0.65),
            ),
          ),
        ),
        Text(
          scoreText,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            percentText,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF007AFF),
            ),
          ),
        ),
      ],
    );
  }
}
