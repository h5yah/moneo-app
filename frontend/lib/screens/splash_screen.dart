import 'package:flutter/material.dart';
import 'package:fintech/screens/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _splashController;
  late AnimationController _textController;

  late Animation<double> _splashScaleAnimation;
  
  late Animation<double> _mPart1Animation; 
  late Animation<double> _mPart2Animation; 
  late Animation<double> _mPart3Animation; 

  late Animation<double> _suffixWidthAnimation;
  late Animation<double> _suffixFadeAnimation;

  @override
  void initState() {
    super.initState();

    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), 
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _splashScaleAnimation = Tween<double>(begin: 0.0, end: 30.0).animate(
      CurvedAnimation(
        parent: _splashController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInExpo),
      ),
    );

    _mPart1Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _splashController,
        curve: const Interval(0.4, 0.6, curve: Curves.easeOut),
      ),
    );

    _mPart2Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _splashController,
        curve: const Interval(0.6, 0.8, curve: Curves.easeOut),
      ),
    );

    _mPart3Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _splashController,
        curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
      ),
    );

    _suffixWidthAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeInOutCubic),
      ),
    );

    _suffixFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
      ),
    );

    _splashController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _textController.forward();
      });
    });

    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _splashController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1020) : Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          ScaleTransition(
            scale: _splashScaleAnimation,
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF007AFF), 
              ),
            ),
          ),
          
          AnimatedBuilder(
            animation: Listenable.merge([_splashController, _textController]),
            builder: (context, child) {
              return Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CustomPaint(
                      size: const Size(60, 60), 
                      painter: MPainter(
                        progress1: _mPart1Animation.value,
                        progress2: _mPart2Animation.value,
                        progress3: _mPart3Animation.value,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(width: 10),
                    Transform.translate(
                      offset: const Offset(0, 9),
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          widthFactor: _suffixWidthAnimation.value,
                          heightFactor: 1.0,
                          child: Opacity(
                            opacity: _suffixFadeAnimation.value,
                            child: const Text(
                              'onéo',
                              style: TextStyle(
                                fontSize: 60,
                                height: 1.0,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                                color: Colors.white,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class MPainter extends CustomPainter {
  final double progress1;
  final double progress2;
  final double progress3;
  final Color color;

  MPainter({
    required this.progress1,
    required this.progress2,
    required this.progress3,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    if (progress1 > 0) {
      final p1Path = Path();
      p1Path.moveTo(0, h);
      p1Path.lineTo(0, h - (h * progress1));
      canvas.drawPath(p1Path, paint);
    }

    if (progress2 > 0) {
      final p2Path = Path();
      p2Path.moveTo(0, 0); 
      
      final midX = w / 2;
      final midY = h;
      
      if (progress2 < 0.5) {
         double t = progress2 * 2; 
         p2Path.lineTo(midX * t, midY * t);
      } else {
         p2Path.lineTo(midX, midY); 
         double t = (progress2 - 0.5) * 2; 
         p2Path.lineTo(midX + (midX * t), midY - (midY * t));
      }
      canvas.drawPath(p2Path, paint);
    }

    if (progress3 > 0) {
      final p3Path = Path();
      p3Path.moveTo(w, 0);
      p3Path.lineTo(w, h * progress3);
      canvas.drawPath(p3Path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant MPainter oldDelegate) {
    return oldDelegate.progress1 != progress1 ||
           oldDelegate.progress2 != progress2 ||
           oldDelegate.progress3 != progress3 ||
           oldDelegate.color != color;
  }
}
