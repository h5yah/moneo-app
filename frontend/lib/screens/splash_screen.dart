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
  
  // M Parts Animations
  late Animation<double> _mPart1Animation; // Left Vertical
  late Animation<double> _mPart2Animation; // Middle V
  late Animation<double> _mPart3Animation; // Right Vertical

  late Animation<double> _suffixWidthAnimation;
  late Animation<double> _suffixFadeAnimation;

  @override
  void initState() {
    super.initState();

    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // Slightly longer for 3 parts
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // 1. Splash Background Expansion (0% - 40% of standard time)
    _splashScaleAnimation = Tween<double>(begin: 0.0, end: 30.0).animate(
      CurvedAnimation(
        parent: _splashController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInExpo),
      ),
    );

    // 2. M Construction (40% - 100% of splash time)
    // Part 1: Left Vertical (0.4 - 0.6)
    _mPart1Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _splashController,
        curve: const Interval(0.4, 0.6, curve: Curves.easeOut),
      ),
    );

    // Part 2: Middle V (0.6 - 0.8)
    _mPart2Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _splashController,
        curve: const Interval(0.6, 0.8, curve: Curves.easeOut),
      ),
    );

    // Part 3: Right Vertical (0.8 - 1.0)
    _mPart3Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _splashController,
        curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
      ),
    );

    // 3. Slide & Reveal 'onéo' (Independent controller, starts after M)
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

    // Choreographed Sequence
    _splashController.forward().then((_) {
      // Pause briefly before showing text
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _textController.forward();
      });
    });

    // Navigate to OnboardingScreen after total sequence
    // Total time = Splash(2000) + Delay(200) + Text(1000) + ReadingTime(1000) ~= 4.2s
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Expanding Green Splash Background
          ScaleTransition(
            scale: _splashScaleAnimation,
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF007AFF), // App Blue - Consider changing to Emerald if rebrand matches
              ),
            ),
          ),
          
          // 2. Animated Content
          AnimatedBuilder(
            animation: Listenable.merge([_splashController, _textController]),
            builder: (context, child) {
              return Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The 'M' Custom Painter
                    CustomPaint(
                      size: const Size(60, 60), // Match approx text size
                      painter: MPainter(
                        progress1: _mPart1Animation.value,
                        progress2: _mPart2Animation.value,
                        progress3: _mPart3Animation.value,
                        color: Colors.white,
                      ),
                    ),
                    
                    // Gap between M and text
                    const SizedBox(width: 4),

                    // The 'ONÉO' Reveal
                    ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: _suffixWidthAnimation.value,
                        child: Opacity(
                          opacity: _suffixFadeAnimation.value,
                          child: const Text(
                            'onéo',
                            style: TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                              color: Colors.white,
                              fontFamily: 'Roboto',
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

    // Part 1: Left Vertical Line (Bottom to Top)
    if (progress1 > 0) {
      final p1Path = Path();
      p1Path.moveTo(0, h);
      // Animate height from bottom
      p1Path.lineTo(0, h - (h * progress1));
      canvas.drawPath(p1Path, paint);
    }

    // Part 2: Middle V (Left Top -> Middle Bottom -> Right Top)
    // We treat the V as two segments connected
    if (progress2 > 0) {
      final p2Path = Path();
      // Start from top left of the V
      p2Path.moveTo(0, 0); 
      
      // Calculate intermediate points
      final midX = w / 2;
      final midY = h;
      
      // Simple linear progression along the V shape? 
      // Let's do it simply: Draw the full V but use a clip or just progress calculation?
      // Better: Break V into Left-Down and Right-Up? 
      // Let's assume Part 2 transforms the Left Vertical into the V? 
      // No, requirements say Part 1, then Part 2, then Part 3.
      
      // Let's draw the V progressively.
      // Total V length approx = dist(0,0->w/2,h) + dist(w/2,h->w,0).
      // actually, let's keep it simple. Part 2 draws the V.
      // We will draw Left Top to Middle Bottom.
      
      // Let's split Part 2 into 2 sub-parts within itself? Or just draw the whole V?
      // I will draw the left diagonal part of the V first, then right diagonal?
      // Actually let's assume Part 2 is the LEFT DIAGONAL and Part 3 is the RIGHT DIAGONAL?
      // Wait, standard M has 4 strokes: Vertical, Diag, Diag, Vertical.
      // User said "Part 1, Part 2, Part 3".
      // Maybe: 
      // 1. Left Vertical.
      // 2. The "V" (both diagonals).
      // 3. Right Vertical.
      
      // Let's implement that: Part 2 draws the V.
      // To animate the V drawing, we can interpret progress2 as path length.
      
      if (progress2 < 0.5) {
         // Drawing first leg of V
         double t = progress2 * 2; // 0 to 1
         p2Path.lineTo(midX * t, midY * t);
      } else {
         // Drawn first leg, drawing second leg
         p2Path.lineTo(midX, midY); // Finish first leg
         double t = (progress2 - 0.5) * 2; // 0 to 1
         p2Path.lineTo(midX + (midX * t), midY - (midY * t));
      }
      canvas.drawPath(p2Path, paint);
    }

    // Part 3: Right Vertical Line (Top to Bottom)
    if (progress3 > 0) {
      final p3Path = Path();
      p3Path.moveTo(w, 0);
      // Animate height to bottom
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
