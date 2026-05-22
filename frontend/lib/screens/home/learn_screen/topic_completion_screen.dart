import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:fintech/services/topic_progress_service.dart';

class TopicCompletionScreen extends StatefulWidget {
  final String? topicId;
  final String topicTitle;
  final int lessonsCompleted;
  final int totalLessons;
  final int earnedXP;
  final double performanceScore;

  const TopicCompletionScreen({
    super.key,
    this.topicId,
    required this.topicTitle,
    required this.lessonsCompleted,
    required this.totalLessons,
    required this.earnedXP,
    this.performanceScore = 100.0,
  });

  @override
  State<TopicCompletionScreen> createState() => _TopicCompletionScreenState();
}

class _TopicCompletionScreenState extends State<TopicCompletionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Confetti animation
            _buildConfetti(),
            // Main content
            Column(
              children: [
                // Close button
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.black, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        _buildHeader(),
                        const SizedBox(height: 32),
                        _buildTopicCard(),
                        const SizedBox(height: 24),
                        _buildStatsCards(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                _buildBottomButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfetti() {
    return AnimatedBuilder(
      animation: _confettiController,
      builder: (context, child) {
        return CustomPaint(
          painter: ConfettiPainter(_confettiController.value),
          child: Container(),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'Topic Completed!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          "Well done! You're building strong financial\nhabits.",
          style: TextStyle(
            fontSize: 16,
            color: Colors.black.withValues(alpha: 0.6),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTopicCard() {
    final topicId = widget.topicId;
    final baseCard = (int lessonsCompleted, int totalLessons) {
      final safeTotal = totalLessons <= 0 ? 1 : totalLessons;
      final progress = (lessonsCompleted / safeTotal).clamp(0.0, 1.0);

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
          // Image section
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue[100]!,
                    Colors.blue[50]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Placeholder for coins/calculator image
                  Icon(
                    Icons.account_balance_wallet,
                    size: 64,
                    color: Colors.blue[300],
                  ),
                ],
              ),
            ),
          ),
          // Content section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.topicTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LESSONS COMPLETED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withValues(alpha: 0.5),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '$lessonsCompleted / $totalLessons',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 9,
                    backgroundColor: const Color(0xFFE0E0E0),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
                  ),
                ),
              ],
            ),
          ),
          ],
        ),
      );
    };

    if (topicId == null || topicId.isEmpty) {
      return baseCard(widget.lessonsCompleted, widget.totalLessons);
    }

    return StreamBuilder<Map<String, dynamic>?>(
      stream: TopicProgressService.instance.topicProgressStream(topicId),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final liveCompleted = (data?['lessonsCompleted'] as num?)?.toInt();
        final liveTotal = (data?['totalLessons'] as num?)?.toInt();
        return baseCard(
          (liveCompleted ?? widget.lessonsCompleted).clamp(0, 999),
          (liveTotal ?? widget.totalLessons).clamp(1, 999),
        );
      },
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        // XP Earned Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFF9800),
                width: 4,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'XP EARNED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.bolt,
                        color: Color(0xFFFF9800),
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+ ${widget.earnedXP}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Performance Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4CAF50),
                width: 4,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'PERFORMANCE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF4CAF50),
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.performanceScore.toInt()}%',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Navigate back to learn home
              Navigator.of(context).popUntil((route) => 
                route.isFirst || route.settings.name == '/learn');
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
                  'Back to Learn Home',
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
        ),
      ),
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final double animationValue;
  final List<ConfettiPiece> confettiPieces;

  ConfettiPainter(this.animationValue) : confettiPieces = _generateConfetti();

  static List<ConfettiPiece> _generateConfetti() {
    final random = math.Random(42); // Fixed seed for consistent animation
    return List.generate(30, (index) {
      return ConfettiPiece(
        x: random.nextDouble(),
        y: random.nextDouble() * 0.3 - 0.2,
        rotation: random.nextDouble() * math.pi * 2,
        color: [
          const Color(0xFF007AFF),
          const Color(0xFF4CAF50),
          const Color(0xFFFF9800),
          const Color(0xFFF44336),
          const Color(0xFF9C27B0),
          const Color(0xFFFFEB3B),
        ][random.nextInt(6)],
        width: 8 + random.nextDouble() * 8,
        height: 16 + random.nextDouble() * 16,
        speed: 0.3 + random.nextDouble() * 0.4,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (var piece in confettiPieces) {
      final paint = Paint()..color = piece.color;

      final y = (piece.y + animationValue * piece.speed) % 1.2;
      if (y > 1.0) continue; // Don't draw pieces that are off screen

      final x = piece.x * size.width;
      final yPos = y * size.height;

      canvas.save();
      canvas.translate(x, yPos);
      canvas.rotate(piece.rotation + animationValue * math.pi * 2);

      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: piece.width,
        height: piece.height,
      );
      canvas.drawRect(rect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}

class ConfettiPiece {
  final double x;
  final double y;
  final double rotation;
  final Color color;
  final double width;
  final double height;
  final double speed;

  ConfettiPiece({
    required this.x,
    required this.y,
    required this.rotation,
    required this.color,
    required this.width,
    required this.height,
    required this.speed,
  });
}
