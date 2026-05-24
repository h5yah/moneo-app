import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_funds_screen.dart';

class MyWalletScreen extends StatefulWidget {
  const MyWalletScreen({
    super.key,
    required this.availableBalance,
  });

  final double availableBalance;

  @override
  State<MyWalletScreen> createState() => _MyWalletScreenState();
}

class _MyWalletScreenState extends State<MyWalletScreen> {
  String _selectedFilter = 'all';

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? 'demo_user';

  Stream<List<Map<String, dynamic>>> _walletHistoryStream() {
    return FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: _userId)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        final transactionType = (data['type'] ?? '').toString().toLowerCase();
        final normalizedType = _isCashInType(transactionType) ? 'cash_in' : 'spending';
        final amount = (data['amount'] as num?)?.toDouble() ??
            (data['myShare'] as num?)?.toDouble() ??
            0.0;
        final category = (data['category'] ?? '').toString().toLowerCase();
        final metadata = (data['metadata'] is Map<String, dynamic>)
            ? (data['metadata'] as Map<String, dynamic>)
            : <String, dynamic>{};
        final source = (metadata['source'] ?? '').toString().toLowerCase();
        final visual = _resolveHistoryVisual(
          transactionType: transactionType,
          category: category,
          source: source,
          isCashIn: normalizedType == 'cash_in',
        );

        final createdAt = data['createdAt'];
        DateTime parsedDate;
        if (createdAt is Timestamp) {
          parsedDate = createdAt.toDate();
        } else {
          final fromDate = DateTime.tryParse((data['date'] ?? '').toString());
          parsedDate = fromDate ?? DateTime.now();
        }

        return {
          'type': normalizedType,
          'title': _resolveTitle(data, transactionType),
          'date': _formatHistoryDate(parsedDate),
          'amount': amount,
          'icon': visual['icon'],
          'iconBg': visual['iconBg'],
          'iconColor': visual['iconColor'],
          'sortAt': parsedDate,
        };
      }).toList();

      items.sort((a, b) =>
          (b['sortAt'] as DateTime).compareTo(a['sortAt'] as DateTime));

      return items;
    });
  }

  bool _isCashInType(String type) {
    return type == 'add_funds' || type == 'cash_in' || type == 'income';
  }

  Map<String, dynamic> _resolveHistoryVisual({
    required String transactionType,
    required String category,
    required String source,
    required bool isCashIn,
  }) {
    if (transactionType == 'add_funds') {
      return {
        'icon': Icons.add_card_rounded,
        'iconBg': const Color(0xFF34C759).withValues(alpha: 0.15),
        'iconColor': const Color(0xFF34C759),
      };
    }

    if (transactionType == 'expense' && source == 'manual') {
      final categoryIcon = _manualCategoryIcon(category);
      return {
        'icon': categoryIcon,
        'iconBg': const Color(0xFFFF3B30).withValues(alpha: 0.14),
        'iconColor': const Color(0xFFFF3B30),
      };
    }

    if (transactionType == 'scan_to_pay') {
      return {
        'icon': Icons.qr_code_scanner_rounded,
        'iconBg': const Color(0xFF007AFF).withValues(alpha: 0.14),
        'iconColor': const Color(0xFF007AFF),
      };
    }

    if (transactionType == 'bill_payment') {
      return {
        'icon': Icons.receipt_long_rounded,
        'iconBg': const Color(0xFFFF9500).withValues(alpha: 0.14),
        'iconColor': const Color(0xFFFF9500),
      };
    }

    return {
      'icon': isCashIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
      'iconBg': (isCashIn ? const Color(0xFF34C759) : const Color(0xFFFF3B30))
          .withValues(alpha: isCashIn ? 0.15 : 0.14),
      'iconColor': isCashIn ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
    };
  }

  IconData _manualCategoryIcon(String category) {
    switch (category) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'bills':
        return Icons.receipt_long;
      case 'shopping':
        return Icons.shopping_bag;
      case 'fun':
        return Icons.confirmation_number;
      default:
        return Icons.edit_note_rounded;
    }
  }

  String _resolveTitle(Map<String, dynamic> data, String type) {
    final expenseName = (data['expenseName'] ?? '').toString().trim();
    if (expenseName.isNotEmpty) return expenseName;

    if (type == 'scan_to_pay') {
      final merchant = (data['merchantName'] ?? '').toString().trim();
      if (merchant.isNotEmpty) return 'Payment to $merchant';
      return 'Scan to Pay';
    }
    if (type == 'bill_payment') {
      if (expenseName.isNotEmpty) return expenseName;
      return 'Bill Payment';
    }
    if (_isCashInType(type)) return 'Funds Added';
    return 'Expense';
  }

  String _formatHistoryDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final dayDiff = today.difference(target).inDays;

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    if (dayDiff == 0) return 'Today, $hour:$minute';
    if (dayDiff == 1) return 'Yesterday, $hour:$minute';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1020) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F1020) : const Color(0xFFF2F2F7),
        elevation: 0,
        titleSpacing: 0,
        title: Text(
          'My Wallet',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(context),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'Wallet History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                  ),
                ),
                const Spacer(),
                _buildFilterDropdown(),
              ],
            ),
            const SizedBox(height: 14),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _walletHistoryStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final allHistory = snapshot.data ?? const <Map<String, dynamic>>[];
                final filteredHistory = allHistory
                    .where((item) => _selectedFilter == 'all' || item['type'] == _selectedFilter)
                    .toList();

                if (filteredHistory.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1B1D33) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'No transactions found',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFAAB0C6) : const Color(0xFF8E8E93),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }

                return Column(
                  children: filteredHistory.map(_buildHistoryItem).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E7BFF), Color(0xFF005BE0)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF005BE0).withValues(alpha: 0.28),
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
              top: -44,
              right: -14,
              child: Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 42,
              right: -22,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
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
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Available Balance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Rs ${widget.availableBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 132,
                      height: 38,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddFundsScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF007AFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Add Funds',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
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

  Widget _buildFilterDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1D33) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF2A2D4A) : const Color(0xFFD1D1D6)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          dropdownColor: isDark ? const Color(0xFF1B1D33) : Colors.white,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: isDark ? Colors.white : null),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
          ),
          borderRadius: BorderRadius.circular(10),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All')),
            DropdownMenuItem(value: 'cash_in', child: Text('Cash In')),
            DropdownMenuItem(value: 'spending', child: Text('Spending')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedFilter = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCashIn = item['type'] == 'cash_in';
    final amount = item['amount'] as double;
    final icon = (item['icon'] as IconData?) ??
      (isCashIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded);
    final iconBg = (item['iconBg'] as Color?) ??
      (isCashIn
        ? const Color(0xFF34C759).withValues(alpha: 0.15)
        : const Color(0xFFFF3B30).withValues(alpha: 0.14));
    final iconColor = (item['iconColor'] as Color?) ??
      (isCashIn ? const Color(0xFF34C759) : const Color(0xFFFF3B30));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1D33) : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] as String,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['date'] as String,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFAAB0C6) : const Color(0xFF8E8E93),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isCashIn ? '+' : '-'}Rs ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: isCashIn ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
