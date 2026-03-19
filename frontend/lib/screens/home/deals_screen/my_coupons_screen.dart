import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'used_coupon_screen.dart';
import 'expired_coupon_screen.dart';

class MyCouponsScreen extends StatefulWidget {
  const MyCouponsScreen({super.key});

  @override
  State<MyCouponsScreen> createState() => _MyCouponsScreenState();
}

class _MyCouponsScreenState extends State<MyCouponsScreen> {
  bool _showExpired = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFE),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.arrow_back_ios,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                    const Text(
                      'My Coupons',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        letterSpacing: -0.408,
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Coupons list
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 43),
                child: Column(
                  children: [
                    _buildCouponCard(
                      storeLogoInitials: 'OB',
                      storeLogoColor: const Color(0xFF1A3A52),
                      storeName: 'OCEAN BASKET',
                      dealTitle: '15% Off Total Bill',
                      validity: 'Valid until 18 February 2025',
                      status: 'active',
                    ),
                    if (_showExpired) ...[
                      const SizedBox(height: 24),
                      _buildCouponCard(
                        storeLogoInitials: 'KFC',
                        storeLogoColor: const Color(0xFFFF0000),
                        storeName: 'KFC MAURITIUS',
                        dealTitle: 'Rs 100 Off Zinger Meal',
                        validity: 'Expired 18 Jan 2025',
                        status: 'expired',
                      ),
                      const SizedBox(height: 24),
                      _buildCouponCard(
                        storeLogoInitials: 'M&B',
                        storeLogoColor: const Color(0xFF1A1A1A),
                        storeName: 'MUGG & BEAN',
                        dealTitle: 'Buy 1 Get 1 Coffee',
                        validity: 'Used on 16 Jan 2025',
                        status: 'used',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Show expired button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 103),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showExpired = !_showExpired;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3F9EB2).withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Show used or expired my Coupons',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF3F9EB2),
                            letterSpacing: -0.408,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _showExpired
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 10,
                          color: const Color(0xFF3F9EB2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCouponCard({
    required String storeLogoInitials,
    required Color storeLogoColor,
    required String storeName,
    required String dealTitle,
    required String validity,
    required String status,
  }) {
    return GestureDetector(
      onTap: () {
        if (status == 'expired') {
          // Navigate to ExpiredCouponScreen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ExpiredCouponScreen(
                storeName: storeName,
                dealTitle: dealTitle,
                dealDescription: dealTitle == 'Rs 100 Off Zinger Meal'
                    ? 'Get Rs 100 off on any Zinger meal combo. Valid for dine-in and delivery orders.'
                    : 'Special offer on selected items. Terms and conditions apply.',
                location: 'Valid at Bagatelle, Phoenix, Grand-Baie, and all other Mauritius locations.',
                expiredDate: '12 Dec 2024',
                storeLogoUrl: '',
              ),
            ),
          );
        } else if (status == 'used') {
          // Navigate to UsedCouponScreen
          String redeemedDate = '';
          String redeemedTime = '';
          
          if (storeLogoInitials == 'M&B') {
            redeemedDate = '16 Jan 2025';
            redeemedTime = '11:15';
          }
          
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => UsedCouponScreen(
                storeName: storeName,
                dealTitle: dealTitle,
                dealDescription: dealTitle == 'Buy 1 Get 1 Coffee'
                    ? 'Buy any coffee beverage and get another one free. Valid for in-store purchases only.'
                    : 'Special offer on selected items. Terms and conditions apply.',
                location: dealTitle == 'Buy 1 Get 1 Coffee'
                    ? 'Valid at all Mugg & Bean locations'
                    : 'Valid at multiple locations',
                redeemedDate: redeemedDate,
                redeemedTime: redeemedTime,
                storeLogoUrl: '',
              ),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store logo badge
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: storeLogoColor,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(78, 78),
                      painter: StarBadgePainter(color: storeLogoColor),
                    ),
                    Text(
                      storeLogoInitials,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Divider line
            Container(
              width: 1,
              height: 128,
              color: Colors.grey[300],
              margin: const EdgeInsets.symmetric(vertical: 8),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0x91000000),
                        letterSpacing: -0.408,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: dealTitle.split(' ')[0],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              letterSpacing: -0.408,
                            ),
                          ),
                          TextSpan(
                            text: ' ',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(
                            text: dealTitle.split(' ').skip(1).join(' '),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                              letterSpacing: -0.408,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (status == 'expired')
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: const Color(0x91000000),
                          )
                        else if (status == 'used')
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: const Color(0x91000000),
                          ),
                        if (status != 'active') const SizedBox(width: 6),
                        Text(
                          validity,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Color(0x91000000),
                            letterSpacing: -0.408,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StarBadgePainter extends CustomPainter {
  final Color color;

  StarBadgePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw a star-shaped badge
    _drawStar(canvas, center, radius, 12, paint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, int points, Paint paint) {
    final path = Path();
    final angleSlice = (2 * math.pi) / points;

    for (int i = 0; i < points; i++) {
      final angle = angleSlice * i - math.pi / 2;
      final outerRadiusFactor = i.isEven ? 1.0 : 0.5;
      
      final x = center.dx + radius * outerRadiusFactor * math.cos(angle);
      final y = center.dy + radius * outerRadiusFactor * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(StarBadgePainter oldDelegate) => false;
}
