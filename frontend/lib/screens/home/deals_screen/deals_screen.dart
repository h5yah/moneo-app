import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:fintech/services/xp_service.dart';
import 'deal_detail_screen.dart';
import 'all_deals_screen.dart';
import 'my_coupons_screen.dart';
import 'spin_win_screen.dart';
import 'guess_win_screen.dart';
import 'shake_win_screen.dart';

class DealsScreen extends StatefulWidget {
  final Function(int)? onIndexChanged;

  const DealsScreen({
    super.key,
    this.onIndexChanged,
  });

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  int _selectedIndex = 3; // Deals tab
  static const int _maxXp = 200000;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: XpService.instance.xpStream(),
      builder: (context, snapshot) {
        final currentXp = snapshot.data ?? 0;

        return Container(
          color: const Color(0xFFF0F0F0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gradient Header with XP Circle
                _buildGradientHeader(currentXp),
                const SizedBox(height: 8),
                // Status Card
                _buildStatusCard(currentXp),
                const SizedBox(height: 32),
                // Rewards Section
                _buildRewardsSection(),
                const SizedBox(height: 32),
                // Exclusive Deals Section
                _buildExclusiveDealsSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradientHeader(int currentXp) {
    return Container(
      height: 319,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFEA9C1D),
            Color(0xFFFF2D84),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Header Title
          const Positioned(
            left: 35,
            top: 61,
            child: Text(
              'Rewards',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.408,
              ),
            ),
          ),
          // Notification Icon
          Positioned(
            right: 35,
            top: 61,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MyCouponsScreen(),
                  ),
                );
              },
              child: Stack(
                children: [
                  const Icon(
                    Icons.confirmation_number_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEA9C1D),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '1',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.408,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // XP Circle Progress
          Positioned(
            left: 0,
            right: 0,
            top: 95,
            child: Center(
              child: _buildXPCircle(currentXp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXPCircle(int currentXp) {
    final boundedXp = currentXp.clamp(0, _maxXp);
    final progress = boundedXp / _maxXp;

    return SizedBox(
      width: 340,
      height: 180,
      child: Stack(
        children: [
          // Progress Circle
          Positioned(
            left: 14,
            top: 10,
            child: CustomPaint(
              size: const Size(313, 160),
              painter: _CircleProgressPainter(progress),
            ),
          ),
          // Star Icon
          Positioned(
            left: 158,
            top: 44,
            child: Icon(
              Icons.star,
              color: Color(0xFFEA9C1D),
              size: 24,
            ),
          ),
          // Blue text
          Positioned(
            left: 14,
            right: 14,
            top: 79,
            child: Text(
              'Silver',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xBFFFFFFF),
                letterSpacing: -0.408,
              ),
            ),
          ),
          // XP Amount
          Positioned(
            left: 14,
            right: 14,
            top: 109,
            child: Text(
              '${_formatNumber(currentXp)} XP',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.408,
              ),
            ),
          ),
          // 0 label
          Positioned(
            left: 16,
            top: 166,
            child: Text(
              '0',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xADFFFFFF),
                letterSpacing: -0.408,
              ),
            ),
          ),
          // 200,000 label
          Positioned(
            left: 290,
            top: 166,
            child: Text(
              _formatNumber(_maxXp),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xADFFFFFF),
                letterSpacing: -0.408,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(int currentXp) {
    final remainingXp = math.max(0, _maxXp - currentXp);

    return Transform.translate(
      offset: const Offset(0, -25),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 35),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0x9C000000),
                    letterSpacing: -0.408,
                    height: 1.33,
                  ),
                  children: [
                    const TextSpan(text: "You're "),
                    TextSpan(
                      text: '${_formatNumber(remainingXp)} XP',
                      style: const TextStyle(
                        color: Color(0xFFEA9C1D),
                      ),
                    ),
                    const TextSpan(text: ' away from Silver status,\nkeep it up!'),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Transform.rotate(
              angle: math.pi,
              child: const Icon(
                Icons.arrow_back_ios,
                color: Colors.black,
                size: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  Widget _buildRewardsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rewards',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xB5000000),
              letterSpacing: -0.408,
            ),
          ),
          const SizedBox(height: 18),
          // Spin & Win Card
          _buildSpinWinCard(),
          const SizedBox(height: 12),
          // Guess & Win and Shake & Win Cards
          Row(
            children: [
              Expanded(
                child: _buildMiniGameCard(
                  'Guess & Win',
                  '1000 XP',
                  const Color(0xFF75C4EC),
                  'assets/guess.png',
                ),
              ),
              const SizedBox(width: 17),
              Expanded(
                child: _buildMiniGameCard(
                  'Shake & Win',
                  '1000 XP',
                  const Color(0xFFEC75AB),
                  'assets/shake_egg.png',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpinWinCard() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const SpinWinScreen(),
          ),
        );
      },
      child: Container(
        height: 173,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFEA9C1D),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
          // Left side content
          const Positioned(
            left: 20,
            top: 35,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spin & Win',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.408,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '1000 XP',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xD4FFFFFF),
                    letterSpacing: -0.408,
                  ),
                ),
              ],
            ),
          ),
          // Wheel illustration placeholder on right
          Positioned(
            right: 0,
            top: 13,
            child: SizedBox(
              width: 177,
              height: 147,
              child: Image.asset(
                'assets/fortune-wheel.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildMiniGameCard(
    String title,
    String xp,
    Color color,
    String iconAsset,
  ) {
    return GestureDetector(
      onTap: () {
        if (title == 'Guess & Win') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const GuessWinScreen(),
            ),
          );
        } else if (title == 'Shake & Win') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ShakeWinScreen(),
            ),
          );
        }
      },
      child: Container(
        height: 84,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          SizedBox(
            width: iconAsset == 'assets/shake_egg.png' ? 52 : 49,
            height: iconAsset == 'assets/shake_egg.png' ? 52 : 49,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Image.asset(
                iconAsset,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const Spacer(),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.408,
                  height: 1.29,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                xp,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xD4FFFFFF),
                  letterSpacing: -0.408,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
    ),
    );
  }

  Widget _buildExclusiveDealsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Exclusive Deals',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xB5000000),
                  letterSpacing: -0.408,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AllDealsScreen(),
                    ),
                  );
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3F9EB2),
                    letterSpacing: -0.408,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Horizontal scrollable deals
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 35),
          child: Row(
            children: [
              _buildDealCard(
                category: 'DINING EXCLUSIVE',
                title: '15% Off at Ocean Basket',
                subtitle: 'Valid at all Mauritian locations',
                xpCost: 500,
                imageUrl: 'assets/ob.png',
                dealStore: 'Ocean Basket',
                description: 'Enjoy a 15% discount on your entire bill at Ocean Basket. Fresh seafood and Mediterranean cuisine await you.',
                validationPoints: const [
                  'Valid at all Ocean Basket locations in Mauritius',
                  'Not valid on public holidays',
                  'Cannot be combined with other promotions',
                ],
              ),
              const SizedBox(width: 23),
              _buildDealCard(
                category: 'SHOPPING',
                title: 'Rs 500 Discount',
                subtitle: 'Valid at all Mauritian locations',
                xpCost: 500,
                imageUrl: 'assets/espace_maison.png',
                dealStore: 'Espace Maison',
                description: 'Get Rs 500 off your purchase at Espace Maison. Upgrade your home with quality furniture and decor.',
                validationPoints: const [
                  'Minimum purchase of Rs 5000 required',
                  'Valid at all Espace Maison stores',
                  'Excludes sale items',
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDealCard({
    required String category,
    required String title,
    required String subtitle,
    required int xpCost,
    required String imageUrl,
    String? description,
    List<String>? validationPoints,
    String? dealStore,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DealDetailScreen(
              dealImage: imageUrl,
              dealCategory: category,
              dealTitle: title,
              dealStore: dealStore ?? _extractStore(title),
              discount: _getDiscountFromTitle(title),
              xpCost: xpCost,
              location: 'Islandwide',
              validity: 'Valid for 30 days',
              description: description ?? 'Enjoy a premium seafood experience at Mauritius’ favorite seafood destination. This exclusive offer gives you a 15% discount on your entire bill, including beverages and platters.',
              validationPoints: validationPoints ?? const [
                'Valid at all locations',
                'No minimum purchase required',
                'Cannot be combined with other offers',
              ],
              redeemSteps: const [
                'Claim this reward using your earned XP points.',
                'Find your unique digital coupon in the “My Coupons” section.',
                'Present your QR code to the staff when requesting your bill.',
              ],
            ),
          ),
        );
      },
      child: Container(
        width: 294,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Deal Image
            Stack(
              children: [
                Container(
                  height: 135,
                  width: 294,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: Image.asset(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.restaurant,
                          size: 60,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                ),
                // Category Badge
                Positioned(
                  left: 8,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xD4000000),
                        letterSpacing: -1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Deal Info
            Padding(
              padding: const EdgeInsets.all(19),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            letterSpacing: -0.408,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$xpCost',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2F80ED),
                              letterSpacing: -0.408,
                            ),
                          ),
                          const Text(
                            'XP COST',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                              letterSpacing: -0.408,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xE8000000),
                      letterSpacing: -0.408,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Claim Deal Button
                  Container(
                    width: double.infinity,
                    height: 35,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F80ED),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text(
                        'Claim Deal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
      ),
    );
  }

  String _extractStore(String title) {
    // Extract store name from title like "15% Off at Ocean Basket"
    if (title.contains('at ')) {
      return title.split('at ')[1];
    }
    return title;
  }

  String _getDiscountFromTitle(String title) {
    // Extract discount percentage from title
    if (title.contains('%')) {
      final parts = title.split('%');
      return '${parts[0]}%';
    }
    return '15%';
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          widget.onIndexChanged?.call(index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: const Color(0xFF007AFF),
        unselectedItemColor: const Color.fromRGBO(0, 0, 0, 0.55),
        selectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 24),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined, size: 24),
            label: 'Learn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_outlined, size: 24),
            label: 'Finance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard, size: 24),
            label: 'Deals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 24),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Custom painter for the circular progress indicator
class _CircleProgressPainter extends CustomPainter {
  final double progress;

  _CircleProgressPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 8);
    final radius = (size.width / 2) - 8;
    const startAngle = math.pi;
    final sweepAngle = math.pi * progress;

    // Background arc
    final backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      math.pi,
      false,
      backgroundPaint,
    );

    // Progress arc
    final progressPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
