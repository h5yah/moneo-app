import 'package:flutter/material.dart';
import 'dart:math' as math;

class UsedCouponScreen extends StatefulWidget {
  final String storeName;
  final String dealTitle;
  final String dealDescription;
  final String location;
  final String redeemedDate;
  final String redeemedTime;
  final String storeLogoUrl;

  const UsedCouponScreen({
    super.key,
    required this.storeName,
    required this.dealTitle,
    required this.dealDescription,
    required this.location,
    required this.redeemedDate,
    required this.redeemedTime,
    required this.storeLogoUrl,
  });

  @override
  State<UsedCouponScreen> createState() => _UsedCouponScreenState();
}

class _UsedCouponScreenState extends State<UsedCouponScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFE).withValues(alpha: 0.94),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [ 
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 24),
                      const Text(
                        'Coupon',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          letterSpacing: -0.408,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(
                          Icons.close,
                          size: 24,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 34),
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 106,
                        height: 106,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A3A52),
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(106, 106),
                              painter: StarBadgePainter(),
                            ),
                            const Text(
                              'OB',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.storeName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xB5000000),
                          letterSpacing: -0.408,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: widget.dealTitle.split(' ')[0],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                letterSpacing: -0.408,
                              ),
                            ),
                            TextSpan(
                              text: '  ',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            TextSpan(
                              text: widget.dealTitle.split(' ').skip(1).join(' '),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xB5000000),
                                letterSpacing: -0.408,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.dealDescription,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          letterSpacing: -0.408,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.location,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xB5000000),
                          letterSpacing: -0.408,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.grey[300],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.grey[300],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'REDEMPTION DETAILS',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xB5000000),
                                letterSpacing: -0.408,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildRedemptionRow(
                              label: 'Redeemed on',
                              value: widget.redeemedDate,
                            ),
                            const SizedBox(height: 20),
                            _buildRedemptionRow(
                              label: 'Time',
                              value: widget.redeemedTime,
                            ),
                            const SizedBox(height: 20),
                            _buildRedemptionRow(
                              label: 'Location',
                              value: widget.location,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRedemptionRow({
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0x78000000),
            letterSpacing: -0.408,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black,
            letterSpacing: -0.408,
          ),
        ),
      ],
    );
  }
}

class StarBadgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A3A52)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
      
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
