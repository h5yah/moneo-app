import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fintech/services/coupon_service.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
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
  final List<String> validationPoints;

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
    this.validationPoints = UserCoupon.defaultValidationPoints,
  });

  @override
  State<CouponClaimedScreen> createState() => _CouponClaimedScreenState();
}

class _CouponClaimedScreenState extends State<CouponClaimedScreen> {
  static final _validUntilFormat = DateFormat('d MMMM yyyy');

  bool _showsDiscountSeparately(String title, String discount) {
    if (discount.isEmpty) return false;
    final normalizedTitle = title.toLowerCase();
    final normalizedDiscount = discount.toLowerCase();
    return !normalizedTitle.contains(normalizedDiscount);
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: widget.couponCode));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coupon code copied'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareCoupon() async {
    final validUntil = _validUntilFormat.format(widget.validUntil);
    await Share.share(
      '${widget.dealStore} — ${widget.dealTitle}\n'
      'Code: ${widget.couponCode}\n'
      'Valid until $validUntil\n'
      '${widget.location}',
      subject: '${widget.dealStore} coupon',
    );
  }

  void _showTermsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1B1D33) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terms & conditions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                ...widget.validationPoints.map(
                  (point) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6, right: 10),
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white70 : Colors.black,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            point,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.35,
                              color: isDark ? const Color(0xFFAAB0C6) : const Color(0xB5000000),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final validUntilText = 'Valid until ${_validUntilFormat.format(widget.validUntil)}';
    final showDiscount = _showsDiscountSeparately(widget.dealTitle, widget.discount);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F1020)
          : const Color(0xFFFFFFFE).withValues(alpha: 0.94),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 24),
                    Text(
                      'Coupon',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: -0.408,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.close,
                        size: 24,
                        color: isDark ? Colors.white : Colors.black,
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
                  color: isDark ? const Color(0xFF1B1D33) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildStoreLogo(),
                    const SizedBox(height: 16),
                    Text(
                      widget.dealStore.toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : const Color(0xB5000000),
                        letterSpacing: -0.408,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildOfferHeadline(isDark, showDiscount),
                    const SizedBox(height: 24),
                    Text(
                      widget.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: -0.408,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.location,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: isDark ? const Color(0xFFAAB0C6) : const Color(0xB5000000),
                        letterSpacing: -0.408,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      children: [
                        for (var i = 0; i < widget.validationPoints.length; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          _buildTermBullet(widget.validationPoints[i], isDark),
                        ],
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: _buildDecorativeDot(),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildQRCode(isDark),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _copyCode,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.couponCode,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.copy,
                            size: 16,
                            color: isDark ? const Color(0xFFAAB0C6) : const Color(0xFF666666),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap code to copy',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFFAAB0C6) : const Color(0x73000000),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _shareCoupon,
                          icon: Icon(
                            Icons.share,
                            size: 20,
                            color: isDark ? const Color(0xFFAAB0C6) : const Color(0xFF666666),
                          ),
                          tooltip: 'Share coupon',
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              validUntilText,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFFAAB0C6) : const Color(0x73000000),
                                letterSpacing: -0.408,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _showTermsSheet,
                          icon: Icon(
                            Icons.info_outline,
                            size: 22,
                            color: isDark ? const Color(0xFFAAB0C6) : const Color(0xFF666666),
                          ),
                          tooltip: 'Terms & conditions',
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
    );
  }

  Widget _buildOfferHeadline(bool isDark, bool showDiscount) {
    final titleStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white : Colors.black,
      letterSpacing: -0.408,
    );
    final subtitleStyle = TextStyle(
      fontSize: 16,
      color: isDark ? const Color(0xFFAAB0C6) : const Color(0xB5000000),
      letterSpacing: -0.408,
    );

    if (!showDiscount) {
      return Text(
        widget.dealTitle,
        textAlign: TextAlign.center,
        style: titleStyle,
      );
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(text: widget.discount, style: titleStyle),
          TextSpan(text: '\n', style: titleStyle),
          TextSpan(text: widget.dealTitle, style: subtitleStyle),
        ],
      ),
    );
  }

  Widget _buildStoreLogo() {
    if (widget.storeLogoUrl.startsWith('assets/')) {
      return ClipOval(
        child: Image.asset(
          widget.storeLogoUrl,
          width: 106,
          height: 106,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitialsLogo(),
        ),
      );
    }
    return _buildInitialsLogo();
  }

  Widget _buildInitialsLogo() {
    final color = _storeColor(widget.dealStore);
    return Container(
      width: 106,
      height: 106,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(106, 106),
            painter: StarBadgePainter(color: color),
          ),
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

  Color _storeColor(String store) {
    final hash = store.hashCode.abs();
    const hues = [0xFF004D40, 0xFF1A3A52, 0xFF3F9EB2, 0xFF5222D0, 0xFFEE5F17];
    return Color(hues[hash % hues.length]);
  }

  String _getInitials(String text) {
    final parts = text.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.length >= 2
          ? parts.first.substring(0, 2).toUpperCase()
          : parts.first.toUpperCase();
    }
    return parts.take(2).map((p) => p.isNotEmpty ? p[0] : '').join().toUpperCase();
  }

  Widget _buildTermBullet(String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 20),
        Padding(
          padding: const EdgeInsets.only(top: 6, right: 12),
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white70 : Colors.black,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFFAAB0C6) : const Color(0xB5000000),
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

  Widget _buildQRCode(bool isDark) {
    return Container(
      width: 164,
      height: 164,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2D45) : Colors.grey.shade300,
        ),
      ),
      child: QrImageView(
        data: widget.couponCode,
        version: QrVersions.auto,
        size: 148,
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
      ),
    );
  }
}

class StarBadgePainter extends CustomPainter {
  StarBadgePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
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
  bool shouldRepaint(StarBadgePainter oldDelegate) => oldDelegate.color != color;
}
