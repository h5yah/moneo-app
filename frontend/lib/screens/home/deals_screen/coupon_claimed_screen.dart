import 'package:flutter/material.dart';
import 'dart:math' as math;

class CouponClaimedScreen extends StatefulWidget {
  final String dealStore;
  final String dealTitle;
  final String discount;
  final String description;
  final String location;
  final String couponCode;
  final DateTime validUntil;
  final String storeLogoUrl;

  const CouponClaimedScreen({
    super.key,
    required this.dealStore,
    required this.dealTitle,
    required this.discount,
    required this.description,
    required this.location,
    required this.couponCode,
    required this.validUntil,
    required this.storeLogoUrl,
  });

  @override
  State<CouponClaimedScreen> createState() => _CouponClaimedScreenState();
}

class _CouponClaimedScreenState extends State<CouponClaimedScreen> {
  @override
  Widget build(BuildContext context) {
    final validUntilText =
        'Valid until ${widget.validUntil.day} ${_getMonthName(widget.validUntil.month)} ${widget.validUntil.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFE).withValues(alpha: 0.94),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header with close button
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
                // Main coupon card
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
                      // Store logo
                      _buildStoreLogo(),
                      const SizedBox(height: 16),
                      // Store name
                      Text(
                        widget.dealStore,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xB5000000),
                          letterSpacing: -0.408,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Discount and title
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: widget.discount,
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
                              text: widget.dealTitle,
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
                      // Description
                      Text(
                        widget.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          letterSpacing: -0.408,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Location
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
                      const SizedBox(height: 20),
                      // Terms and conditions bullets
                      Column(
                        children: [
                          _buildTermBullet(
                            'Must be presented to merchant.',
                          ),
                          const SizedBox(height: 8),
                          _buildTermBullet(
                            'Not combinable with other promotions.',
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Decorative dividers
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
                            child: _buildDecorativeDot(),
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
                      // QR Code
                      _buildQRCode(),
                      const SizedBox(height: 20),
                      // Coupon code
                      Text(
                        widget.couponCode,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          letterSpacing: -0.408,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Validity date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.share,
                            size: 16,
                            color: Color(0xFF666666),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Center(
                              child: Text(
                                validUntilText,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0x73000000),
                                  letterSpacing: -0.408,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Color(0xFF666666),
                          ),
                        ],
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

  Widget _buildStoreLogo() {
    return Container(
      width: 106,
      height: 106,
      decoration: BoxDecoration(
        color: const Color(0xFF004D40),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF004D40), width: 8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Create a star-like badge background
          CustomPaint(
            size: const Size(106, 106),
            painter: StarBadgePainter(),
          ),
          // Store initials or logo
          Text(
            _getInitials(widget.dealStore),
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String text) {
    final parts = text.split(' ');
    if (parts.isEmpty) return '?';
    return parts.map((part) => part.isNotEmpty ? part[0] : '').join('').toUpperCase();
  }

  Widget _buildTermBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 20),
        Padding(
          padding: const EdgeInsets.only(top: 6, right: 12),
          child: Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: Color(0xB5000000),
              letterSpacing: -0.408,
            ),
          ),
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildDecorativeDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildQRCode() {
    return Container(
      width: 164,
      height: 164,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          Icons.qr_code_2,
          size: 80,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return monthNames[month - 1];
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
