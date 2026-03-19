import 'package:flutter/material.dart';
import 'package:fintech/services/xp_service.dart';
import 'coupon_claimed_screen.dart';

class DealDetailScreen extends StatefulWidget {
  final String dealImage;
  final String dealCategory;
  final String dealTitle;
  final String dealStore;
  final String discount;
  final int xpCost;
  final String location;
  final String validity;
  final String description;
  final List<String> validationPoints;
  final List<String> redeemSteps;

  const DealDetailScreen({
    super.key,
    required this.dealImage,
    required this.dealCategory,
    required this.dealTitle,
    required this.dealStore,
    required this.discount,
    required this.xpCost,
    required this.location,
    required this.validity,
    required this.description,
    required this.validationPoints,
    required this.redeemSteps,
  });

  @override
  State<DealDetailScreen> createState() => _DealDetailScreenState();
}

class _DealDetailScreenState extends State<DealDetailScreen> {
  bool _isClaiming = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image header with back button
            _buildImageHeader(),
            // Deal info container with overlap effect
            Transform.translate(
              offset: const Offset(0, -20),
              child: _buildDealInfoContainer(),
            ),
            const SizedBox(height: 16),
            // About this deal
            _buildAboutSection(),
            // How to redeem
            _buildRedeemSection(),
            const SizedBox(height: 32),
            // Claim button
            _buildClaimButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHeader() {
    return Stack(
      children: [
        // Image
        Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            color: Colors.grey[300],
          ),
          child: widget.dealImage.startsWith('assets/')
              ? Image.asset(
                  widget.dealImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 100),
                    );
                  },
                )
              : Image.network(
                  widget.dealImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 100),
                    );
                  },
                ),
        ),
        // Back button
        Positioned(
          top: 16,
          left: 16,
          child: SafeArea(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.black,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDealInfoContainer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFF00897B), width: 1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        widget.dealCategory.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00897B),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Deal title
                    Text(
                      widget.dealTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Store name
                    Text(
                      widget.dealStore,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // XP cost badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      '${widget.xpCost}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF00897B),
                      ),
                    ),
                    Text(
                      'XP COST',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Location and validity chips
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: Color(0xFF00897B)),
                    const SizedBox(width: 6),
                    Text(
                      widget.location,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_outlined,
                        size: 14, color: Color(0xFF00897B)),
                    const SizedBox(width: 6),
                    Text(
                      widget.validity,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ABOUT THIS DEAL',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.black.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          // Validation points
          for (int i = 0; i < widget.validationPoints.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 18, color: Color(0xFF00897B)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.validationPoints[i],
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
            if (i < widget.validationPoints.length - 1)
              const SizedBox(height: 12),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRedeemSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'HOW TO REDEEM',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 20),
            for (int i = 0; i < widget.redeemSteps.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00897B),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.redeemSteps[i],
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.black.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (i < widget.redeemSteps.length - 1)
                const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClaimButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton(
        onPressed: _isClaiming ? null : _claimDeal,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00897B),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
        ),
        child: _isClaiming
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Claim for',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.xpCost} XP',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.star, size: 20),
                ],
              ),
      ),
    );
  }

  Future<void> _claimDeal() async {
    setState(() {
      _isClaiming = true;
    });

    try {
      await XpService.instance.spendXp(
        amount: widget.xpCost,
        source: 'deal_claim',
      );

      if (!mounted) {
        return;
      }

      _showClaimConfirmation();
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = error.toString().contains('failed-precondition') ||
              error.toString().contains('Not enough XP')
          ? 'Not enough XP to claim this deal.'
          : 'Could not claim deal right now. Please try again.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isClaiming = false;
        });
      }
    }
  }

  void _showClaimConfirmation() {
    final couponCode = _generateCouponCode();
    final validUntil = DateTime.now().add(const Duration(days: 18));

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CouponClaimedScreen(
          dealStore: widget.dealStore,
          dealTitle: widget.dealTitle,
          discount: widget.discount,
          description: widget.description,
          location: widget.location,
          couponCode: couponCode,
          validUntil: validUntil,
          storeLogoUrl: widget.dealImage,
        ),
      ),
    );
  }

  String _generateCouponCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().microsecond;
    final code = List.generate(8, (index) {
      return chars[(random + index) % chars.length];
    }).join();
    return code;
  }
}
