import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:fintech/services/xp_service.dart';

class SpinWinScreen extends StatefulWidget {
  const SpinWinScreen({super.key});

  @override
  State<SpinWinScreen> createState() => _SpinWinScreenState();
}

class _SpinWinScreenState extends State<SpinWinScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isSpinning = false;
  int _selectedPrize = 0;

  final List<String> _prizes = [
    '100 XP',
    '500 XP',
    '50 XP',
    '1000 XP',
    '200 XP',
    '750 XP',
    '150 XP',
    '300 XP',
  ];

  final List<Color> _colors = [
    Color(0xFFFFEA2B),
    Color(0xFFFF4B20),
    Color(0xFF00C6FF),
    Color(0xFFFFEA2B),
    Color(0xFFFF4B20),
    Color(0xFF00C6FF),
    Color(0xFFFFEA2B),
    Color(0xFFFF4B20),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spin() {
    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
      _selectedPrize = math.Random().nextInt(_prizes.length);
    });

    _controller.reset();
    _controller.forward().then((_) {
      setState(() {
        _isSpinning = false;
      });
      _showPrizeDialog();
    });
  }

  void _showPrizeDialog() {
    final prizeXp = _parsePrizeXp(_prizes[_selectedPrize]);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.celebration_rounded,
                size: 80,
                color: Color(0xFFF39237),
              ),
              const SizedBox(height: 16),
              const Text(
                'Congratulations!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You won',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _prizes[_selectedPrize],
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFEA9C1D),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await XpService.instance.earnXp(
                      amount: prizeXp,
                      source: 'spin_win_reward',
                    );

                    if (!mounted) {
                      return;
                    }

                    Navigator.of(this.context).pop();
                    Navigator.of(this.context).pop();
                  } catch (error) {
                    if (!mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not claim reward right now. Try again.'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF2D84),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Claim Reward',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _parsePrizeXp(String prize) {
    return int.tryParse(prize.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Spin & Win',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 40,
                      color: Color(0xFFF39237),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Spin the wheel for a chance to win XP!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You can spin once per day',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Wheel
              Stack(
                alignment: Alignment.center,
                children: [
                  // Wheel container
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      double rotation = _controller.value * 8 * math.pi +
                          (_selectedPrize * 2 * math.pi / _prizes.length);
                      return Transform.rotate(
                        angle: rotation,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: WheelPainter(
                          prizes: _prizes,
                          colors: _colors,
                        ),
                      ),
                    ),
                  ),
                  // Center button
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.star,
                      size: 40,
                      color: Color(0xFFF39237),
                    ),
                  ),
                  // Pointer at top
                  Positioned(
                    top: -10,
                    child: Container(
                      width: 0,
                      height: 0,
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(
                              width: 15, color: Colors.transparent),
                          right: BorderSide(
                              width: 15, color: Colors.transparent),
                          bottom: BorderSide(
                              width: 30, color: Color(0xFF3F9EB2)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),
              // Spin Button
              ElevatedButton(
                onPressed: _isSpinning ? null : _spin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA9C1D),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSpinning ? 'Spinning...' : 'Spin Now',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (!_isSpinning) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.refresh_rounded, size: 24),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<String> prizes;
  final List<Color> colors;

  WheelPainter({required this.prizes, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = 2 * math.pi / prizes.length;

    for (int i = 0; i < prizes.length; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweepAngle - math.pi / 2,
        sweepAngle,
        true,
        paint,
      );

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweepAngle - math.pi / 2,
        sweepAngle,
        true,
        borderPaint,
      );

      // Draw text
      final textAngle = i * sweepAngle + sweepAngle / 2 - math.pi / 2;
      final textRadius = radius * 0.7;
      final textX = center.dx + textRadius * math.cos(textAngle);
      final textY = center.dy + textRadius * math.sin(textAngle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: prizes[i],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      canvas.save();
      canvas.translate(textX, textY);
      canvas.rotate(textAngle + math.pi / 2);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
