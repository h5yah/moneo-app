import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_funds_screen.dart';
import 'pay_the_bill_screen.dart';
import 'goals_screen.dart';
import 'my_wallet_screen.dart';
import 'scan_to_pay_screen.dart';
import 'send_money_screen.dart';
import 'budget_planner_screen.dart';
import 'goal_icon_style.dart';

class FinanceScreen extends StatefulWidget {
  final Function(int)? onIndexChanged;
  final int? progressReplaySeed;

  const FinanceScreen({
    super.key,
    this.onIndexChanged,
    this.progressReplaySeed,
  });

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final bool _showBalance = true;
  double _availableBalance = 0.00;
  double _income = 0.00;
  double _spent = 0.00;

  final PageController _myGoalsPageController = PageController();

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? 'demo_user';

  @override
  void initState() {
    super.initState();
    _refreshFinanceStats();
  }

  @override
  void dispose() {
    _myGoalsPageController.dispose();
    super.dispose();
  }

  Future<void> _refreshFinanceStats() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('balances')
          .doc(_userId)
          .get();

      final data = snapshot.data() ?? <String, dynamic>{};

      if (!mounted) return;

      setState(() {
        _availableBalance = (data['available'] as num?)?.toDouble() ?? 0.0;
        _income = (data['income'] as num?)?.toDouble() ?? 0.0;
        _spent = (data['spent'] as num?)?.toDouble() ?? 0.0;
      });
    } catch (_) {}
  }

  Widget _buildAnimatedProgressBar({
    required double value,
    required Color color,
    required Color backgroundColor,
    required double minHeight,
    required Object replayKey,
  }) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(replayKey),
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return LinearProgressIndicator(
          value: animatedValue,
          minHeight: minHeight,
          backgroundColor: backgroundColor,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF0F1020) : const Color(0xFFF0F4FA),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildAvailableBalanceCard(context),
            const SizedBox(height: 32),
            _buildQuickActionsSection(context),
            const SizedBox(height: 32),
            _buildMyGoalsSection(context),
            const SizedBox(height: 24),
            _buildBudgetPlannerSection(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.fromLTRB(35, 18, 35, 0),
      child: Text(
        'Finance',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
          letterSpacing: -0.408,
        ),
      ),
    );
  }

  Widget _buildAvailableBalanceCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Column(
        children: [
          Container(
            height: 176,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E7BFF), Color(0xFF005BE0)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF005BE0).withOpacity(0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  Positioned(
                    top: -42,
                    right: -12,
                    child: Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: -20,
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.20),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -36,
                    left: -28,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Wallet Balance',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _showBalance
                              ? 'Rs ${_availableBalance.toStringAsFixed(2)}'
                              : '******',
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.8,
                            height: 1.0,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MyWalletScreen(
                                  availableBalance: _availableBalance,
                                ),
                              ),
                            );
                            await _refreshFinanceStats();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.35),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Text(
                                      'My Wallet',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.arrow_forward,
                                        size: 11,
                                        color: Color(0xFF007AFF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F6EF0), Color(0xFF0A5ED0)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0A5ED0).withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.arrow_downward,
                        size: 28,
                        color: Color(0xFF59D96E),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cash In',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFFEAF4FF),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Rs ${_income.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.25),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.arrow_upward,
                        size: 28,
                        color: Color(0xFFFF6464),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Spending',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFFEAF4FF),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Rs ${_spent.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 4),
                  child: _buildQuickActionButton(
                    icon: Icons.add_box_outlined,
                    label: 'Add Funds',
                    iconColor: const Color(0xFF34C759),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddFundsScreen(),
                        ),
                      );
                      await _refreshFinanceStats();
                    },
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildQuickActionButton(
                    icon: Icons.send_rounded,
                    label: 'Send Money',
                    iconColor: const Color(0xFFFF9500),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SendMoneyScreen(
                            availableBalance: _availableBalance,
                          ),
                        ),
                      );
                      await _refreshFinanceStats();
                    },
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildQuickActionButton(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Scan to Pay',
                    iconColor: const Color(0xFF007AFF),
                    onTap: () => _showScanToPayInfo(context),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, left: 4),
                  child: _buildQuickActionButton(
                    icon: Icons.receipt_long_outlined,
                    label: 'Pay\nBills',
                    iconColor: const Color(0xFFAF52DE),
                    onTap: () async {
                      final paid = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PayTheBillScreen(
                            availableBalance: _availableBalance,
                          ),
                        ),
                      );
                      if (!context.mounted) return;
                      if (paid == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bill paid successfully.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        await _refreshFinanceStats();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showScanToPayInfo(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScanToPayScreen(),
      ),
    );

    if (!context.mounted) return;
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _refreshFinanceStats();
    }
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1D33) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime? _parseGoalDate(String input) {
    final value = input.trim();
    if (value.isEmpty || value.toLowerCase() == 'no date') return null;

    final parts = value.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return DateTime.tryParse(value);
  }

  String _remainingTimeLabel(String dateText) {
    final parsedDate = _parseGoalDate(dateText);
    if (parsedDate == null) return 'No target date';

    final today = DateTime.now();
    final currentDate = DateTime(today.year, today.month, today.day);
    final targetDate =
        DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    final daysLeft = targetDate.difference(currentDate).inDays;
    if (daysLeft <= 0) return 'This month';

    final monthsApprox = daysLeft / 30.44;
    if (monthsApprox < 1) {
      return daysLeft == 1 ? '1 day left' : '$daysLeft days left';
    }

    final roundedMonths = monthsApprox.round();
    if (roundedMonths <= 1) return '1 month remaining';
    return '$roundedMonths months remaining';
  }

  Widget _financeGoalSheetField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9EBF2)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF2D4EFF), size: 20),
        ),
      ),
    );
  }

  Future<void> _showAdjustGoalSheet(DocumentSnapshot doc) async {
    final data = doc.data()! as Map<String, dynamic>;
    final titleController =
        TextEditingController(text: data['title']?.toString() ?? '');
    final targetController = TextEditingController(
      text: ((data['target'] as num?)?.toDouble() ?? 0).toStringAsFixed(0),
    );
    final dateController =
        TextEditingController(text: data['date']?.toString() ?? '');
    var isLoading = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                20 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1D1D6),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Adjust goal',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Rename your goal and update target or date.',
                    style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  _financeGoalSheetField(
                    controller: titleController,
                    label: 'Goal title',
                    icon: Icons.flag_outlined,
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 12),
                  _financeGoalSheetField(
                    controller: targetController,
                    label: 'Target amount',
                    icon: Icons.track_changes,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _financeGoalSheetField(
                    controller: dateController,
                    label: 'Date',
                    icon: Icons.calendar_today_outlined,
                    keyboardType: TextInputType.datetime,
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: modalContext,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        dateController.text =
                            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                        setSheetState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 18),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator()),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D4EFF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              final newTitle = titleController.text.trim();
                              final newTarget = double.tryParse(
                                    targetController.text.trim(),
                                  ) ??
                                  0;
                              final newDate = dateController.text.trim().isEmpty
                                  ? 'No date'
                                  : dateController.text.trim();
                              if (newTitle.isEmpty || newTarget <= 0) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please enter a goal title and valid target amount',
                                    ),
                                  ),
                                );
                                return;
                              }
                              setSheetState(() => isLoading = true);
                              try {
                                final timeLabel = _remainingTimeLabel(newDate);
                                await FirebaseFirestore.instance
                                    .collection('goals')
                                    .doc(doc.id)
                                    .update({
                                  'title': newTitle,
                                  'target': newTarget,
                                  'date': newDate,
                                  'timeRemaining': timeLabel,
                                  'remaining': timeLabel,
                                });
                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Goal updated successfully!'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setSheetState(() => isLoading = false);
                                if (sheetContext.mounted) {
                                  ScaffoldMessenger.of(sheetContext)
                                      .showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed:
                          isLoading ? null : () => Navigator.pop(sheetContext),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Color(0xFF8E8E93)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              setSheetState(() => isLoading = true);
                              try {
                                await FirebaseFirestore.instance
                                    .collection('goals')
                                    .doc(doc.id)
                                    .delete();
                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Goal deleted.'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setSheetState(() => isLoading = false);
                                if (sheetContext.mounted) {
                                  ScaffoldMessenger.of(sheetContext)
                                      .showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                      child: const Text(
                        'Delete Goal',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    titleController.dispose();
    targetController.dispose();
    dateController.dispose();
  }

  /// Single goal card for My Goals carousel on Finance.
  Widget _financeMyGoalCard(DocumentSnapshot doc, bool isDark) {
    final data = doc.data()! as Map<String, dynamic>;
    final title = data['title'] ?? '';
    final category = data['category'] ?? '';
    final target = (data['target'] as num?)?.toDouble() ?? 0;
    final current = (data['current'] as num?)?.toDouble() ?? 0;
    final remaining = _remainingTimeLabel(data['date']?.toString() ?? '');
    final percent = target > 0 ? ((current / target) * 100).round() : 0;
    final iconKey = data['icon']?.toString();
    final iconColors = goalIconAccent(iconKey, isDark: isDark);
    final accentPillBorder = Color.lerp(
      iconColors.foreground,
      iconColors.background,
      0.45,
    )!;
    final goalIconSize = iconKey == 'account_balance' ? 20.0 : 24.0;

    return Container(
      key: ValueKey(doc.id),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1D33) : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColors.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  goalIconFromKey(iconKey),
                  color: iconColors.foreground,
                  size: goalIconSize,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : null,
                      ),
                    ),
                    Text(
                      category.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8E8E93),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _showAdjustGoalSheet(doc),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEAF3FF),
                  foregroundColor: const Color(0xFF007AFF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Adjust',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: iconColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentPillBorder,
                  ),
                ),
                child: Text(
                  remaining,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: iconColors.foreground,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: iconColors.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _buildAnimatedProgressBar(
              value: target > 0 ? (current / target) : 0,
              minHeight: 9,
              backgroundColor: const Color(0xFFEBEBEB),
              color: iconColors.foreground,
              replayKey: 'goal-${doc.id}-${widget.progressReplaySeed}',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current: Rs $current',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8E8E93),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Target: Rs $target',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyGoalsSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Goals',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xC2000000),
                  letterSpacing: -0.408,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GoalsScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View Details',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('goals')
                .where('userId', isEqualTo: _userId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const SizedBox(
                  height: 170,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B1D33) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.flight_takeoff,
                        size: 44,
                        color: Color(0xFFBDBDBD),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No goals yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create a savings goal to start saving.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: 160,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D4EFF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const GoalsScreen(openCreateOnLaunch: true),
                              ),
                            );
                          },
                          child: const Text(
                            'Create Goal',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final goals = snapshot.data!.docs;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (goals.length == 1)
                    _financeMyGoalCard(goals.first, isDark)
                  else
                    SizedBox(
                      height: 170,
                      child: PageView.builder(
                        controller: _myGoalsPageController,
                        itemCount: goals.length,
                        itemBuilder: (context, index) {
                          final doc = goals[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              right: index < goals.length - 1 ? 12 : 0,
                            ),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: _financeMyGoalCard(doc, isDark),
                            ),
                          );
                        },
                      ),
                    ),
                  if (goals.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const GoalsScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: isDark
                                  ? Colors.white70
                                  : const Color(0xFF8E8E93),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              '...',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox(height: 8),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetPlannerSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'demo_user';
    final today = DateTime.now().toIso8601String().substring(0, 10);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget Planner',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xC2000000),
                  letterSpacing: -0.408,
                ),
              ),
              // Removed 'Go to Planner' button
            ],
          ),
          const SizedBox(height: 18),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('budgets')
                .doc(userId)
                .snapshots(),
            builder: (context, budgetSnapshot) {
              if (budgetSnapshot.connectionState == ConnectionState.waiting &&
                  !budgetSnapshot.hasData) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (!budgetSnapshot.hasData || !budgetSnapshot.data!.exists) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B1D33) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF1FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.pie_chart_outline_rounded,
                          color: Color(0xFF2D4EFF),
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No budget set yet',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Track your daily spending and stay in control.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8E8E93),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: 170,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D4EFF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const BudgetPlannerScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Open Planner',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final budgetData =
                  budgetSnapshot.data!.data() as Map<String, dynamic>;
              final dailyBudget =
                  (budgetData['dailyBudget'] as num?)?.toDouble();
              if (dailyBudget == null || dailyBudget == 0.0) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B1D33) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF1FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.pie_chart_outline_rounded,
                          color: Color(0xFF2D4EFF),
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No daily budget set',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please set your daily budget to start tracking your spending.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8E8E93),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: 170,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D4EFF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const BudgetPlannerScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Set Daily Budget',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('expenses')
                    .where('userId', isEqualTo: userId)
                    .where('date', isEqualTo: today)
                    .snapshots(),
                builder: (context, expenseSnapshot) {
                  if (expenseSnapshot.connectionState ==
                          ConnectionState.waiting &&
                      !expenseSnapshot.hasData) {
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  double spentToday = 0.0;

                  if (expenseSnapshot.hasData) {
                    for (final doc in expenseSnapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      spentToday += (data['amount'] as num?)?.toDouble() ?? 0.0;
                    }
                  }

                  final left = dailyBudget - spentToday;
                  final progress = dailyBudget > 0
                      ? (spentToday / dailyBudget).clamp(0.0, 1.0)
                      : 0.0;
                  final percent = dailyBudget > 0
                      ? ((spentToday / dailyBudget) * 100).round()
                      : 0;
                  final isOverBudget = spentToday > dailyBudget;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1B1D33) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF1FF),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.calendar_today_rounded,
                                color: Color(0xFF2D4EFF),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Today’s Budget',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1C1C1E),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isOverBudget ? 'Over budget' : 'In budget',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isOverBudget
                                          ? (isDark
                                              ? const Color(0xFFFF6961)
                                              : const Color(0xFFE53935))
                                          : (isDark
                                              ? const Color(0xFF4ADE80)
                                              : const Color(0xFF1E9E53)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isOverBudget
                                    ? const Color(0xFFFFEAEA)
                                    : const Color(0xFFEAF7EE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$percent%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isOverBudget
                                      ? const Color(0xFFFF3B30)
                                      : const Color(0xFF1E9E53),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: _buildAnimatedProgressBar(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: const Color(0xFFE9EDF5),
                            color: isOverBudget
                                ? const Color(0xFFFF3B30)
                                : const Color(0xFF2D4EFF),
                            replayKey:
                                'budget-$dailyBudget-$spentToday-${widget.progressReplaySeed}',
                          ),
                        ),
                        if (isOverBudget) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF3D2424)
                                  : const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFFFF453A)
                                        .withValues(alpha: 0.45)
                                    : const Color(0xFFFFCDD2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: isDark
                                      ? const Color(0xFFFF6961)
                                      : const Color(0xFFFF3B30),
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Over budget today by Rs ${(spentToday - dailyBudget).toStringAsFixed(0)}. Review spending in the planner.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      height: 1.35,
                                      color: isDark
                                          ? const Color(0xFFFFD0CC)
                                          : const Color(0xFFB71C1C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F9FC),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Budget',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF8E8E93),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Rs ${dailyBudget.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1C1C1E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F9FC),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isOverBudget
                                          ? 'Over Budget'
                                          : 'Left Today',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF8E8E93),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Rs ${left.abs().toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isOverBudget
                                            ? const Color(0xFFFF3B30)
                                            : const Color(0xFF1C1C1E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2D4EFF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const BudgetPlannerScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Open Planner',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // Bottom navigation is provided by HomeScreen; this screen only renders body content.
}
