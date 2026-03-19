import 'package:flutter/material.dart';
import 'dart:io';
import 'package:fintech/screens/auth/login_screen.dart';
import 'package:fintech/screens/auth/sign_up_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  final List<OnboardingPage> pages = [
    OnboardingPage(
      title: 'Learn by Doing',
      description:
          'Master financial concepts through bite-sized lessons and interactive simulations.',
      imagePath: 'assets/onboarding1.jpg',
      isAsset: true,
    ),
    OnboardingPage(
      title: 'Practice for Free',
      description:
          'Use our virtual simulators to practice budgeting and investing without any real-world risk.',
      imagePath:'assets/onboarding2.jpg',
      isAsset: true,
    ),
    OnboardingPage(
      title: 'Track your Goals',
      description:
          'Set personal milestones and watch your savings grow with interactive tracking.',
      imagePath: 'assets/onboarding3.png',
      isAsset: true,
    ),
    OnboardingPage(
      title: 'Earn Rewards',
      description:
          'Complete lessons and challenges to unlock exclusive discounts at your favorite local spots.',
      imagePath: 'assets/onboarding4.jpg',
      isAsset: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // PageView - Takes up available space
          Expanded(
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    return OnboardingContent(page: pages[index]);
                  },
                ),
                // Page Indicators
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: SizedBox(
                        height: 8,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            pages.length,
                            (index) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentPage == index
                                      ? const Color(0xFF007AFF)
                                      : const Color(0xFFD1D1D6),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Buttons at bottom
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Get started',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.408,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFF007AFF),
                        width: 1,
                      ),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Sign in',
                      style: TextStyle(
                        color: Color(0xFF007AFF),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.408,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String imagePath;
  final bool isAsset;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.imagePath,
    this.isAsset = false,
  });
}

class OnboardingContent extends StatelessWidget {
  final OnboardingPage page;

  const OnboardingContent({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Image - Full height with proper container
        ClipPath(
          clipper: DiagonalClipper(),
          child: Container(
            width: 430,
            height: 540,
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: _buildImage(page.imagePath, page.isAsset),
          ),
        ),
        // Text Content positioned at 633px from top
        Positioned(
          top: 600,
          left: 40,
          right: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                page.title,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.374,
                  color: Colors.black,
                  height: 41 / 34,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                page.description,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF48484A),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImage(String imagePath, bool isAsset) {
    if (isAsset) {
      // Asset image
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.image_not_supported),
                const SizedBox(height: 8),
                Text('Asset failed to load: $error'),
              ],
            ),
          );
        },
      );
    } else if (imagePath.startsWith('http')) {
      // Network image
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_not_supported),
                SizedBox(height: 8),
                Text('Image failed to load'),
              ],
            ),
          );
        },
      );
    } else {
      // Local file
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.image_not_supported),
                const SizedBox(height: 8),
                Text('Error: $error'),
              ],
            ),
          );
        },
      );
    }
  }
}

class DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    // Start with curve at top left corner (0.125 of height)
    path.lineTo(0, size.height * 0.875); // Go down to 87.5% of height
    path.quadraticBezierTo(
      -20, size.height * 0.9375, // Control point curves outward left
      0, size.height, // End at bottom left corner
    );
    // Bottom curve (facing bottom/outward) - half oval
    path.quadraticBezierTo(
      size.width * 0.0625, size.height + 200, // Control point far out for oval curve
      size.width * 0.10, size.height -0, // End of curve
    );
    path.lineTo(size.width, size.height - 100); // Right side, higher up
    path.lineTo(size.width, 0); // Top right
    path.close();
    return path;
  }


  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
