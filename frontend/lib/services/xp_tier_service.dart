/// Lifetime XP loyalty tiers: Bronze → Silver → Gold.
class LoyaltyTier {
  const LoyaltyTier({
    required this.id,
    required this.label,
    required this.minXp,
    this.maxXp,
    required this.accentColor,
  });

  final String id;
  final String label;
  final int minXp;

  /// Inclusive upper bound; `null` means top tier (no cap).
  final int? maxXp;
  final int accentColor;

  static const bronze = LoyaltyTier(
    id: 'bronze',
    label: 'Bronze',
    minXp: 0,
    maxXp: 4999,
    accentColor: 0xFFCD7F32,
  );

  static const silver = LoyaltyTier(
    id: 'silver',
    label: 'Silver',
    minXp: 5000,
    maxXp: 19999,
    accentColor: 0xFF94A3B8,
  );

  static const gold = LoyaltyTier(
    id: 'gold',
    label: 'Gold',
    minXp: 20000,
    maxXp: null,
    accentColor: 0xFFF59E0B,
  );

  static const List<LoyaltyTier> all = [bronze, silver, gold];
}

class XpTierMeta {
  const XpTierMeta({
    required this.totalXp,
    required this.currentTier,
    required this.nextTier,
    required this.xpIntoTier,
    required this.xpSpanForTier,
    required this.xpToNextTier,
  });

  final int totalXp;
  final LoyaltyTier currentTier;
  final LoyaltyTier? nextTier;
  final int xpIntoTier;
  final int xpSpanForTier;
  final int xpToNextTier;

  bool get isMaxTier => nextTier == null;

  double get progressInTier =>
      xpSpanForTier <= 0 ? 1 : (xpIntoTier / xpSpanForTier).clamp(0.0, 1.0);

  int get tierRangeStart => currentTier.minXp;

  int get tierRangeEnd =>
      nextTier?.minXp ?? (currentTier.maxXp != null ? currentTier.maxXp! + 1 : currentTier.minXp + 1);
}

class XpTierService {
  XpTierService._();

  static XpTierMeta metaFromTotalXp(int totalXp) {
    final xp = totalXp < 0 ? 0 : totalXp;
    final current = _tierForXp(xp);
    final next = _nextTier(current);

    final spanEnd = next?.minXp ?? (current.maxXp != null ? current.maxXp! + 1 : current.minXp + 1);
    final span = spanEnd - current.minXp;
    final into = xp - current.minXp;

    return XpTierMeta(
      totalXp: xp,
      currentTier: current,
      nextTier: next,
      xpIntoTier: into,
      xpSpanForTier: span,
      xpToNextTier: next == null ? 0 : mathMax(0, next.minXp - xp),
    );
  }

  static String statusMessage(XpTierMeta meta) {
    if (meta.isMaxTier) {
      return "You're at ${meta.currentTier.label} status —\nkeep earning XP!";
    }
    final next = meta.nextTier!;
    return "You're ${_formatXp(meta.xpToNextTier)} XP away from\n${next.label} status, keep it up!";
  }

  static String _formatXp(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
  }

  static LoyaltyTier _tierForXp(int xp) {
    if (xp >= LoyaltyTier.gold.minXp) return LoyaltyTier.gold;
    if (xp >= LoyaltyTier.silver.minXp) return LoyaltyTier.silver;
    return LoyaltyTier.bronze;
  }

  static LoyaltyTier? _nextTier(LoyaltyTier current) {
    final index = LoyaltyTier.all.indexWhere((t) => t.id == current.id);
    if (index < 0 || index >= LoyaltyTier.all.length - 1) return null;
    return LoyaltyTier.all[index + 1];
  }

  static int mathMax(int a, int b) => a > b ? a : b;
}
