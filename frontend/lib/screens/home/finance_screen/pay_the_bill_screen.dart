import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PayTheBillScreen extends StatefulWidget {
  const PayTheBillScreen({
    super.key,
    required this.availableBalance,
  });

  final double availableBalance;

  @override
  State<PayTheBillScreen> createState() => _PayTheBillScreenState();
}

class _PayTheBillScreenState extends State<PayTheBillScreen> {
  String get _userId =>
      FirebaseAuth.instance.currentUser?.uid ?? 'demo_user';

  double get _availableBalance => widget.availableBalance;

  static const List<Map<String, dynamic>> _bills = [
    {
      'id': 'electric',
      'title': 'Electric bill',
      'subtitle': 'Pay electric bill this month',
      'color': Color(0xFFFAF6FF),
      'accent': Color(0xFF6C4EF2),
    },
    {
      'id': 'water',
      'title': 'Water bill',
      'subtitle': 'Pay water bill this month',
      'color': Color(0xFFEAF6FF),
      'accent': Color(0xFF4EC6F2),
    },
    {
      'id': 'internet',
      'title': 'Internet bill',
      'subtitle': 'Pay internet bill this month',
      'color': Color(0xFFFFF6E9),
      'accent': Color(0xFFF2A54E),
    },
  ];

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openBillPaymentSheet(Map<String, dynamic> bill) async {
    final payload = await showModalBottomSheet<_BillPaymentPayload>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return _BillPaymentSheet(
          bill: bill,
          availableBalance: _availableBalance,
        );
      },
    );

    if (!mounted || payload == null) return;

    await _confirmAndPay(bill, payload.accountNumber, payload.amount);
  }

  Future<void> _confirmAndPay(
    Map<String, dynamic> bill,
    String accountNumber,
    double amount,
  ) async {
    final title = bill['title'] as String;

    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Confirm payment',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bill: $title'),
              const SizedBox(height: 8),
              Text('Account: $accountNumber'),
              const SizedBox(height: 8),
              Text('Amount: Rs ${amount.toStringAsFixed(2)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: bill['accent'] as Color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await _deductBalanceAndSaveTransaction(bill, accountNumber, amount);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Payment failed. Please try again.');
    }
  }

  Future<void> _deductBalanceAndSaveTransaction(
    Map<String, dynamic> bill,
    String accountNumber,
    double amount,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No logged-in user found.');
    }

    final senderId = user.uid;
    final billId = bill['id'] as String;
    final title = bill['title'] as String;
    final balanceRef =
        FirebaseFirestore.instance.collection('balances').doc(senderId);
    final txRef = FirebaseFirestore.instance.collection('transactions').doc();
    final expenseRef =
        FirebaseFirestore.instance.collection('expenses').doc();
    final now = DateTime.now();
    final dateString =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final balanceSnap = await tx.get(balanceRef);

      if (!balanceSnap.exists) {
        throw Exception('Balance document not found');
      }

      final data = balanceSnap.data()!;
      final currentBalance = (data['available'] as num).toDouble();

      if (currentBalance < amount) {
        throw Exception('Insufficient balance');
      }

      final newBalance = currentBalance - amount;
      final currentSpent = ((data['spent'] ?? 0) as num).toDouble();

      tx.update(balanceRef, {
        'available': newBalance,
        'spent': currentSpent + amount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.set(txRef, {
        'userId': senderId,
        'type': 'bill_payment',
        'category': 'bills',
        'billType': billId,
        'expenseName': title,
        'amount': amount,
        'myShare': -amount,
        'accountNumber': accountNumber,
        'status': 'success',
        'paymentMethod': 'wallet',
        'date': now.toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.set(expenseRef, {
        'expenseName': title,
        'amount': amount,
        'accountNumber': accountNumber,
        'billType': billId,
        'userId': senderId,
        'type': 'bill_payment',
        'category': 'bills',
        'date': dateString,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  void _openPaymentHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _BillPaymentHistoryScreen(userId: _userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Pay the bill',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C4EF2), Color(0xFF8C6EF8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Wallet balance',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Rs ${_availableBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ..._bills.map(
                (bill) => GestureDetector(
                  onTap: () => _openBillPaymentSheet(bill),
                  child: _billTile(
                    title: bill['title'] as String,
                    subtitle: bill['subtitle'] as String,
                    color: bill['color'] as Color,
                    accent: bill['accent'] as Color,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: InkWell(
                  onTap: _openPaymentHistory,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.history, color: Color(0xFF6C4EF2), size: 22),
                        SizedBox(width: 12),
                        Text(
                          'Check payment history',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6C4EF2),
                            fontSize: 16,
                          ),
                        ),
                        Spacer(),
                        Icon(
                          Icons.chevron_right,
                          color: Color(0xFF6C4EF2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _billTile({
    required String title,
    required String subtitle,
    required Color color,
    required Color accent,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: accent,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 15,
                        color: accent.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.payment, color: accent, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BillPaymentPayload {
  const _BillPaymentPayload({
    required this.accountNumber,
    required this.amount,
  });

  final String accountNumber;
  final double amount;
}

class _BillPaymentSheet extends StatefulWidget {
  const _BillPaymentSheet({
    required this.bill,
    required this.availableBalance,
  });

  final Map<String, dynamic> bill;
  final double availableBalance;

  @override
  State<_BillPaymentSheet> createState() => _BillPaymentSheetState();
}

class _BillPaymentSheetState extends State<_BillPaymentSheet> {
  final _accountController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _accountController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final account = _accountController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;

    if (account.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an account number.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (amount > widget.availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient wallet balance.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      _BillPaymentPayload(accountNumber: account, amount: amount),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.bill['accent'] as Color;
    final title = widget.bill['title'] as String;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Available: Rs ${widget.availableBalance.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Account / reference number',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _accountController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              hintText: 'Enter account number',
              filled: true,
              fillColor: const Color(0xFFF5F5F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Amount',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              prefixText: 'Rs ',
              hintText: 'Enter amount',
              filled: true,
              fillColor: const Color(0xFFF5F5F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 12,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: _submit,
              child: const Text(
                'Pay bill',
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillPaymentHistoryScreen extends StatelessWidget {
  const _BillPaymentHistoryScreen({required this.userId});

  final String userId;

  String _formatDate(dynamic createdAt, String? dateStr) {
    DateTime parsed;
    if (createdAt is Timestamp) {
      parsed = createdAt.toDate();
    } else {
      parsed = DateTime.tryParse(dateStr ?? '') ?? DateTime.now();
    }
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '${parsed.day}/${parsed.month}/${parsed.year}, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bill payment history',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('userId', isEqualTo: userId)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load payment history.'),
            );
          }

          final docs = (snapshot.data?.docs ?? [])
              .where((doc) {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                final type =
                    (data['type'] ?? '').toString().toLowerCase();
                return type == 'bill_payment';
              })
              .toList();
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No bill payments yet.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF8E8E93),
                ),
              ),
            );
          }

          final sorted = List.of(docs);
          sorted.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['createdAt'];
            final bTime = bData['createdAt'];
            if (aTime is Timestamp && bTime is Timestamp) {
              return bTime.compareTo(aTime);
            }
            return 0;
          });

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final data = sorted[index].data() as Map<String, dynamic>;
              final title =
                  (data['expenseName'] ?? 'Bill payment').toString();
              final amount = (data['amount'] as num?)?.toDouble() ?? 0;
              final account =
                  (data['accountNumber'] ?? '').toString().trim();

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9500).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Color(0xFFFF9500),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          if (account.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Acct: $account',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(
                              data['createdAt'],
                              data['date']?.toString(),
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '-Rs ${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF3B30),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
