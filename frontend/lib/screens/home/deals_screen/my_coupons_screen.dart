import 'package:flutter/material.dart';
import 'package:fintech/services/coupon_service.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'coupon_claimed_screen.dart';
import 'used_coupon_screen.dart';
import 'expired_coupon_screen.dart';

class MyCouponsScreen extends StatefulWidget {
  const MyCouponsScreen({super.key});

  @override
  State<MyCouponsScreen> createState() => _MyCouponsScreenState();
}

class _MyCouponsScreenState extends State<MyCouponsScreen> {
  bool _showInactive = false;

  static final _dateFormat = DateFormat('d MMMM yyyy');
  static final _shortDateFormat = DateFormat('d MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1020) : const Color(0xFFF0F0F0),
      body: SafeArea(
        child: StreamBuilder<List<UserCoupon>>(
          stream: CouponService.instance.couponsStream(),
          builder: (context, snapshot) {
            final coupons = snapshot.data ?? [];
            final active = coupons
                .where((c) => c.effectiveStatus == CouponStatus.active)
                .toList();
            final inactive = coupons
                .where((c) => c.effectiveStatus != CouponStatus.active)
                .toList();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Icon(
                            Icons.arrow_back_ios,
                            size: 20,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          'My Coupons',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                            letterSpacing: -0.408,
                          ),
                        ),
                        const SizedBox(width: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData)
                    const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (active.isEmpty && inactive.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 43),
                      child: Text(
                        'No coupons yet. Claim a deal from Rewards to see it here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? const Color(0xFFAAB0C6) : const Color(0x91000000),
                          height: 1.4,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (active.isNotEmpty) ...[
                            Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFAAB0C6) : const Color(0x73000000),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          for (var i = 0; i < active.length; i++) ...[
                            if (i > 0) const SizedBox(height: 14),
                            _buildCouponCard(context, active[i], isDark),
                          ],
                          if (_showInactive && inactive.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text(
                              'Used or expired',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFAAB0C6) : const Color(0x73000000),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (_showInactive)
                            for (var i = 0; i < inactive.length; i++) ...[
                              if (i > 0) const SizedBox(height: 14),
                              _buildCouponCard(context, inactive[i], isDark),
                            ],
                        ],
                      ),
                    ),
                  if (inactive.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 103),
                      child: GestureDetector(
                        onTap: () => setState(() => _showInactive = !_showInactive),
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
                              Text(
                                _showInactive
                                    ? 'Hide used or expired coupons'
                                    : 'Show used or expired my Coupons',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF3F9EB2),
                                  letterSpacing: -0.408,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _showInactive
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
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCouponCard(BuildContext context, UserCoupon coupon, bool isDark) {
    final status = coupon.effectiveStatus;
    final validity = _validityLabel(coupon, status);
    final isInactive = status != CouponStatus.active;
    final borderColor = isDark ? const Color(0xFF2E3148) : const Color(0xFFE2E4EA);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openCoupon(context, coupon, status),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1D33) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Opacity(
            opacity: isInactive ? 0.72 : 1,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                    child: _buildStoreBadge(coupon, size: 72),
                  ),
                  SizedBox(
                    width: 20,
                    child: _CouponPerforation(isDark: isDark),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 14, 8, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  coupon.dealStore.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.4,
                                    color: isDark
                                        ? const Color(0xFFAAB0C6)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                              if (status == CouponStatus.active)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Active',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                )
                              else if (status == CouponStatus.used)
                                _statusChip('Used', const Color(0xFF6B7280))
                              else
                                _statusChip('Expired', const Color(0xFFEF4444)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            coupon.dealTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              color: isDark ? Colors.white : Colors.black,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                status == CouponStatus.expired
                                    ? Icons.event_busy_outlined
                                    : status == CouponStatus.used
                                        ? Icons.check_circle_outline
                                        : Icons.schedule_outlined,
                                size: 14,
                                color: isDark
                                    ? const Color(0xFFAAB0C6)
                                    : const Color(0xFF9CA3AF),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  validity,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: isDark
                                        ? const Color(0xFFAAB0C6)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.chevron_right,
                      size: 22,
                      color: isDark ? const Color(0xFF6B7280) : const Color(0xFFD1D5DB),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStoreBadge(UserCoupon coupon, {double size = 78}) {
    final color = _storeColor(coupon.dealStore);
    final initials = _initials(coupon.dealStore);

    if (coupon.storeLogoUrl.startsWith('assets/')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1.5,
          ),
        ),
        child: ClipOval(
          child: Image.asset(
            coupon.storeLogoUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initialsBadge(initials, color, size: size),
          ),
        ),
      );
    }

    return _initialsBadge(initials, color, size: size);
  }

  Widget _initialsBadge(String initials, Color color, {double size = 78}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: StarBadgePainter(color: color),
          ),
          Text(
            initials,
            style: TextStyle(
              fontSize: size * 0.36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _validityLabel(UserCoupon coupon, CouponStatus status) {
    switch (status) {
      case CouponStatus.expired:
        return 'Expired ${_shortDateFormat.format(coupon.validUntil)}';
      case CouponStatus.used:
        return 'Used on ${_shortDateFormat.format(coupon.claimedAt)}';
      case CouponStatus.active:
        return 'Valid until ${_dateFormat.format(coupon.validUntil)}';
    }
  }

  void _openCoupon(BuildContext context, UserCoupon coupon, CouponStatus status) {
    switch (status) {
      case CouponStatus.active:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CouponClaimedScreen(
              dealStore: coupon.dealStore,
              dealTitle: coupon.dealTitle,
              discount: coupon.discount,
              description: coupon.description,
              location: coupon.location,
              couponCode: coupon.couponCode,
              validUntil: coupon.validUntil,
              storeLogoUrl: coupon.storeLogoUrl,
              validationPoints: coupon.validationPoints,
            ),
          ),
        );
      case CouponStatus.expired:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ExpiredCouponScreen(
              storeName: coupon.dealStore,
              dealTitle: coupon.dealTitle,
              dealDescription: coupon.description,
              location: coupon.location,
              expiredDate: _shortDateFormat.format(coupon.validUntil),
              storeLogoUrl: coupon.storeLogoUrl,
            ),
          ),
        );
      case CouponStatus.used:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => UsedCouponScreen(
              storeName: coupon.dealStore,
              dealTitle: coupon.dealTitle,
              dealDescription: coupon.description,
              location: coupon.location,
              redeemedDate: _shortDateFormat.format(coupon.claimedAt),
              redeemedTime: DateFormat('HH:mm').format(coupon.claimedAt),
              storeLogoUrl: coupon.storeLogoUrl,
            ),
          ),
        );
    }
  }

  String _initials(String text) {
    final parts = text.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.length >= 2
          ? parts.first.substring(0, 2).toUpperCase()
          : parts.first.toUpperCase();
    }
    return parts.take(2).map((p) => p.isNotEmpty ? p[0] : '').join().toUpperCase();
  }

  Color _storeColor(String store) {
    final hash = store.hashCode.abs();
    final hues = [0xFF1A3A52, 0xFF004D40, 0xFF3F9EB2, 0xFF5222D0, 0xFFEE5F17];
    return Color(hues[hash % hues.length]);
  }
}

class _CouponPerforation extends StatelessWidget {
  const _CouponPerforation({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PerforationPainter(
        lineColor: isDark ? const Color(0xFF3A3D55) : const Color(0xFFD1D5DB),
      ),
      child: const SizedBox(width: 16),
    );
  }
}

class _PerforationPainter extends CustomPainter {
  _PerforationPainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    const dashHeight = 5.0;
    const gap = 4.0;
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.2;

    var y = 14.0;
    while (y < size.height - 14) {
      canvas.drawLine(Offset(centerX, y), Offset(centerX, y + dashHeight), paint);
      y += dashHeight + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _PerforationPainter oldDelegate) => false;
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
