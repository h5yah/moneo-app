import 'package:flutter/material.dart';
import 'package:fintech/services/xp_tier_service.dart';

class LoyaltyTierScreen extends StatelessWidget {
  const LoyaltyTierScreen({
    super.key,
    required this.totalXp,
  });

  final int totalXp;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tierMeta = XpTierService.metaFromTotalXp(totalXp);
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1020) : const Color(0xFFF0F0F0),
      body: Column(
        children: [
          _HeroHeader(
            tierMeta: tierMeta,
            totalXp: totalXp,
            topInset: topInset,
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -28),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F1020) : const Color(0xFFF0F0F0),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    _TierJourneyStrip(
                      totalXp: totalXp,
                      currentTier: tierMeta.currentTier,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Tier benefits',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Earn XP from lessons, quizzes, and reward games.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: isDark ? const Color(0xFFAAB0C6) : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final tier in LoyaltyTier.all)
                      _TierBenefitCard(
                        tier: tier,
                        isCurrent: tier.id == tierMeta.currentTier.id,
                        isUnlocked: totalXp >= tier.minXp,
                        isDark: isDark,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.tierMeta,
    required this.totalXp,
    required this.topInset,
  });

  final XpTierMeta tierMeta;
  final int totalXp;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF007AFF), Color(0xFF7C3AED)],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              const Expanded(
                child: Text(
                  'Loyalty Status',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            _formatXp(totalXp),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'XP',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xD9FFFFFF),
              letterSpacing: 1.2,
            ),
          ),
          if (!tierMeta.isMaxTier) ...[
            const SizedBox(height: 16),
            Text(
              '${_formatXp(tierMeta.xpToNextTier)} XP until ${_formatXp(tierMeta.nextTier!.minXp)}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatXp(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
  }
}

class _TierJourneyStrip extends StatelessWidget {
  const _TierJourneyStrip({
    required this.totalXp,
    required this.currentTier,
    required this.isDark,
  });

  final int totalXp;
  final LoyaltyTier currentTier;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1D33) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3148) : const Color(0xFFE8EAEF),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < LoyaltyTier.all.length; i++) ...[
            if (i > 0) Expanded(child: _ConnectorLine(
              filled: totalXp >= LoyaltyTier.all[i].minXp,
              isDark: isDark,
            )),
            Expanded(
              child: _JourneyNode(
                tier: LoyaltyTier.all[i],
                state: _nodeState(LoyaltyTier.all[i]),
                isDark: isDark,
              ),
            ),
          ],
        ],
      ),
    );
  }

  _NodeState _nodeState(LoyaltyTier tier) {
    if (tier.id == currentTier.id) return _NodeState.current;
    if (totalXp >= tier.minXp) return _NodeState.completed;
    return _NodeState.locked;
  }
}

enum _NodeState { completed, current, locked }

class _JourneyNode extends StatelessWidget {
  const _JourneyNode({
    required this.tier,
    required this.state,
    required this.isDark,
  });

  final LoyaltyTier tier;
  final _NodeState state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final accent = Color(tier.accentColor);
    final isActive = state != _NodeState.locked;

    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: state == _NodeState.current
                ? accent.withValues(alpha: 0.2)
                : (isActive
                    ? accent.withValues(alpha: 0.12)
                    : (isDark ? const Color(0xFF2A2D45) : const Color(0xFFF3F4F6))),
            border: Border.all(
              color: state == _NodeState.current
                  ? accent
                  : (isActive ? accent.withValues(alpha: 0.5) : const Color(0xFFD1D5DB)),
              width: state == _NodeState.current ? 2.5 : 1.5,
            ),
          ),
          child: Icon(
            state == _NodeState.locked
                ? Icons.lock_outline
                : state == _NodeState.completed
                    ? Icons.check_rounded
                    : Icons.star_rounded,
            size: 22,
            color: isActive ? accent : const Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tier.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: state == _NodeState.current ? FontWeight.w700 : FontWeight.w500,
            color: isActive
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          tier.maxXp == null ? '${_fmt(tier.minXp)}+' : _fmt(tier.minXp),
          style: TextStyle(
            fontSize: 10,
            color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  static String _fmt(int n) {
    if (n >= 1000) return '${n ~/ 1000}k';
    return '$n';
  }
}

class _ConnectorLine extends StatelessWidget {
  const _ConnectorLine({required this.filled, required this.isDark});

  final bool filled;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      margin: const EdgeInsets.only(bottom: 36),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: filled
            ? const Color(0xFF6366F1)
            : (isDark ? const Color(0xFF2E3148) : const Color(0xFFE5E7EB)),
      ),
    );
  }
}

class _TierBenefitCard extends StatelessWidget {
  const _TierBenefitCard({
    required this.tier,
    required this.isCurrent,
    required this.isUnlocked,
    required this.isDark,
  });

  final LoyaltyTier tier;
  final bool isCurrent;
  final bool isUnlocked;
  final bool isDark;

  String get _xpRange {
    if (tier.maxXp == null) return '${_format(tier.minXp)}+ lifetime XP';
    return '${_format(tier.minXp)} – ${_format(tier.maxXp!)} XP';
  }

  String _format(int n) =>
      n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

  List<String> get _perks {
    switch (tier.id) {
      case 'bronze':
        return [
          'Earn XP from lessons & quizzes',
          'Redeem partner deals with XP',
          'Daily Spin, Guess & Shake games',
        ];
      case 'silver':
        return [
          'All Bronze benefits',
          'Silver badge on Rewards',
          'Priority access to new deals',
        ];
      case 'gold':
        return [
          'All Silver benefits',
          'Gold badge - highest tier',
          'First access to premium rewards',
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Color(tier.accentColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1D33) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? accent
              : (isDark ? const Color(0xFF2E3148) : const Color(0xFFE8EAEF)),
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: isDark || !isUnlocked
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 4,
            color: isUnlocked ? accent : const Color(0xFFD1D5DB),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: isUnlocked ? 0.15 : 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isUnlocked ? Icons.star_rounded : Icons.lock_outline,
                        color: isUnlocked ? accent : const Color(0xFF9CA3AF),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tier.label,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: isUnlocked
                                  ? (isDark ? Colors.white : Colors.black)
                                  : (isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _xpRange,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFFAAB0C6) : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'You',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      )
                    else if (!isUnlocked)
                      Icon(Icons.lock, size: 16, color: Colors.grey.shade400),
                  ],
                ),
                const SizedBox(height: 14),
                ..._perks.map(
                  (perk) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: isUnlocked ? accent : const Color(0xFFD1D5DB),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            perk,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: isUnlocked
                                  ? (isDark ? const Color(0xFFCCD0DC) : const Color(0xFF374151))
                                  : (isDark ? const Color(0xFF4B5563) : const Color(0xFF9CA3AF)),
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
        ],
      ),
    );
  }
}
