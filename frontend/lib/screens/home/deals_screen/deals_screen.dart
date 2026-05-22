import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:fintech/services/coupon_service.dart';
import 'package:fintech/services/xp_service.dart';
import 'package:fintech/services/xp_tier_service.dart';
import 'deal_detail_screen.dart';
import 'all_deals_screen.dart';
import 'my_coupons_screen.dart';
import 'spin_win_screen.dart';
import 'guess_win_screen.dart';
import 'shake_win_screen.dart';
import 'loyalty_tier_screen.dart';

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
  bool _spinPlayedToday = false;
  bool _guessPlayedToday = false;
  bool _shakePlayedToday = false;

  @override
  void initState() {
    super.initState();
    _refreshDailyGameStatus();
  }

  Future<void> _refreshDailyGameStatus() async {
    final results = await Future.wait([
      XpService.instance.hasDailyReward(XpService.spinWinGame),
      XpService.instance.hasDailyReward(XpService.guessWinGame),
      XpService.instance.hasDailyReward(XpService.shakeWinGame),
    ]);
    if (!mounted) return;
    setState(() {
      _spinPlayedToday = results[0];
      _guessPlayedToday = results[1];
      _shakePlayedToday = results[2];
    });
  }

  Future<void> _openMiniGame(Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
    await _refreshDailyGameStatus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<int>(
      stream: XpService.instance.xpStream(),
      builder: (context, snapshot) {
        final currentXp = snapshot.data ?? 0;

        return Container(
          color: isDark ? const Color(0xFF0F1020) : const Color(0xFFF0F0F0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gradient Header with XP Circle
                _buildGradientHeader(currentXp),
                _buildStatusCard(currentXp),
                // Rewards Section
                Transform.translate(
                  offset: const Offset(0, 0),
                  child: _buildRewardsSection(),
                ),
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
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      height: 319 + topInset,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF007AFF),
            Color(0xFF7C3AED),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Header Title
          Positioned(
            left: 35,
            top: 18 + topInset,
            child: const Text(
              'Rewards',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.408,
              ),
            ),
          ),
          // My Coupons icon
          Positioned(
            right: 35,
            top: 18 + topInset,
            child: StreamBuilder<int>(
              stream: CouponService.instance.activeCouponCountStream(),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MyCouponsScreen(),
                      ),
                    );
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.confirmation_number_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                      if (count > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 13,
                              minHeight: 13,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: const BoxDecoration(
                              color: Color(0xFF6366F1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                count > 9 ? '9+' : '$count',
                                style: const TextStyle(
                                  fontSize: 9,
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
                );
              },
            ),
          ),
          // XP Circle Progress
          Positioned(
            left: 0,
            right: 0,
            top: 95 + topInset,
            child: Center(
              child: _buildXPCircle(currentXp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXPCircle(int currentXp) {
    final tierMeta = XpTierService.metaFromTotalXp(currentXp);
    final progress = tierMeta.progressInTier;
    final rangeStart = tierMeta.tierRangeStart;
    final rangeEnd = tierMeta.tierRangeEnd;

    return SizedBox(
      width: 340,
      height: 180,
      child: Stack(
        children: [
          // Progress Circle (animated 0 → current)
          Positioned(
            left: 14,
            top: 10,
            child: _AnimatedArcProgress(targetProgress: progress),
          ),
          // Star Icon
          Positioned(
            left: 158,
            top: 44,
            child: Icon(
              Icons.star,
              color: Color(tierMeta.currentTier.accentColor),
              size: 24,
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            top: 79,
            child: Text(
              tierMeta.currentTier.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
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
          Positioned(
            left: 16,
            top: 166,
            child: Text(
              _formatNumber(rangeStart),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xADFFFFFF),
                letterSpacing: -0.408,
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 166,
            child: Text(
              tierMeta.isMaxTier ? 'Max' : _formatNumber(rangeEnd),
              style: const TextStyle(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tierMeta = XpTierService.metaFromTotalXp(currentXp);
    final highlightXp = tierMeta.isMaxTier
        ? _formatNumber(tierMeta.totalXp)
        : _formatNumber(tierMeta.xpToNextTier);

    return Transform.translate(
      offset: const Offset(0, -25),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 325),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openLoyaltyTiers(currentXp),
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B1D33) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
              child: tierMeta.isMaxTier
                  ? Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: isDark ? const Color(0xFFAAB0C6) : const Color(0x9C000000),
                          letterSpacing: -0.408,
                          height: 1.33,
                        ),
                        children: [
                          const TextSpan(text: "You're at "),
                          TextSpan(
                            text: '${tierMeta.currentTier.label} status',
                            style: TextStyle(
                              color: Color(tierMeta.currentTier.accentColor),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(text: ' — $highlightXp total XP!'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  : Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: isDark ? const Color(0xFFAAB0C6) : const Color(0x9C000000),
                          letterSpacing: -0.408,
                          height: 1.33,
                        ),
                        children: [
                          const TextSpan(text: "You're "),
                          TextSpan(
                            text: '$highlightXp XP',
                            style: const TextStyle(
                              color: Color(0xFF6366F1),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: ' away from ${tierMeta.nextTier!.label} status,\nkeep it up!',
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: isDark ? Colors.white70 : Colors.black54,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openLoyaltyTiers(int currentXp) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LoyaltyTierScreen(totalXp: currentXp),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rewards',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xB5000000),
              letterSpacing: -0.408,
            ),
          ),
          const SizedBox(height: 18),
          // Spin & Win Card
          _buildSpinWinCard(playedToday: _spinPlayedToday),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMiniGameCard(
                  title: 'Guess & Win',
                  xp: '1000 XP',
                  color: const Color(0xFF75C4EC),
                  iconAsset: 'assets/guess.png',
                  playedToday: _guessPlayedToday,
                  onTap: () => _openMiniGame(const GuessWinScreen()),
                ),
              ),
              const SizedBox(width: 17),
              Expanded(
                child: _buildMiniGameCard(
                  title: 'Shake & Win',
                  xp: '1000 XP',
                  color: const Color(0xFF8B5CF6),
                  iconAsset: 'assets/shake_egg.png',
                  playedToday: _shakePlayedToday,
                  onTap: () => _openMiniGame(const ShakeWinScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpinWinCard({required bool playedToday}) {
    return GestureDetector(
      onTap: () => _openMiniGame(const SpinWinScreen()),
      child: Opacity(
        opacity: playedToday ? 0.72 : 1,
        child: Container(
          height: 173,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
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
              if (playedToday)
                Positioned(
                  right: 12,
                  top: 12,
                  child: _playedTodayBadge(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniGameCard({
    required String title,
    required String xp,
    required Color color,
    required String iconAsset,
    required bool playedToday,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: playedToday ? 0.72 : 1,
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(10),
          child: Stack(
            children: [
              Row(
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
              if (playedToday)
                Positioned(
                  left: 8,
                  top: 8,
                  child: _playedTodayBadge(compact: true),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _playedTodayBadge({bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Played today',
        style: TextStyle(
          fontSize: compact ? 9 : 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildExclusiveDealsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exclusive Deals',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xB5000000),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          color: isDark ? const Color(0xFF1B1D33) : Colors.white,
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
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
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
                          Text(
                            'XP COST',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFFAAB0C6) : Colors.black,
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
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFFAAB0C6) : const Color(0xE8000000),
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

class _AnimatedArcProgress extends StatefulWidget {
  const _AnimatedArcProgress({required this.targetProgress});

  final double targetProgress;

  @override
  State<_AnimatedArcProgress> createState() => _AnimatedArcProgressState();
}

class _AnimatedArcProgressState extends State<_AnimatedArcProgress>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 1400);

  late final AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _progressAnimation = _buildTween(0, widget.targetProgress);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedArcProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetProgress != widget.targetProgress) {
      final from = _progressAnimation.value.clamp(0.0, 1.0);
      _progressAnimation = _buildTween(from, widget.targetProgress);
      _controller
        ..reset()
        ..forward();
    }
  }

  Animation<double> _buildTween(double begin, double end) {
    return Tween<double>(
      begin: begin.clamp(0.0, 1.0),
      end: end.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, _) {
        return CustomPaint(
          size: const Size(313, 160),
          painter: _CircleProgressPainter(_progressAnimation.value),
        );
      },
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
