import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LogExpenseScreen extends StatefulWidget {
  const LogExpenseScreen({super.key});

  @override
  State<LogExpenseScreen> createState() => _LogExpenseScreenState();
}

class _LogExpenseScreenState extends State<LogExpenseScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  int _selectedCategoryIndex = 1;
  bool? _isPlanned = true;
  bool _isSaving = false;

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  final List<_ExpenseCategory> _categories = const [
    _ExpenseCategory(
      label: 'Food',
      icon: Icons.restaurant,
      background: Color(0x2FEE5F17),
      iconColor: Color(0xFFEE5F17),
    ),
    _ExpenseCategory(
      label: 'Transport',
      icon: Icons.directions_car,
      background: Color(0x2F0088FF),
      iconColor: Color(0xFF0088FF),
    ),
    _ExpenseCategory(
      label: 'Bills',
      icon: Icons.receipt_long,
      background: Color(0x2F34C459),
      iconColor: Color(0xFF34C459),
    ),
    _ExpenseCategory(
      label: 'Shopping',
      icon: Icons.shopping_bag,
      background: Color(0x2F5222D0),
      iconColor: Color(0xFF5222D0),
    ),
    _ExpenseCategory(
      label: 'Fun',
      icon: Icons.confirmation_number,
      background: Color(0x2FFF0000),
      iconColor: Color(0xFFFF0000),
    ),
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xF0FFFFFF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 10, 32, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        'Log Expense',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  'ENTER AMOUNT',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0x73000000),
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Rs',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Color(0x73000000),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 180,
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w600,
                        color: Color(0x31000000),
                        letterSpacing: -0.4,
                      ),
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w600,
                          color: Color(0x31000000),
                          letterSpacing: -0.4,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const SizedBox(height: 22),
              const Center(
                child: Text(
                  'WHAT IS THIS FOR?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0x73000000),
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _noteController,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0x31000000),
                  letterSpacing: -0.4,
                ),
                decoration: const InputDecoration(
                  hintText: 'e.g., McDonald’s, Tuition Fee, Grocery, or Metro',
                  hintStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0x31000000),
                    letterSpacing: -0.4,
                  ),
                  border: InputBorder.none,
                ),
              ),
              Divider(color: Colors.black.withValues(alpha: 0.12), height: 1),
              const SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xC2000000),
                      letterSpacing: -0.4,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('See all categories')),
                      );
                    },
                    child: const Text(
                      'See All',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0088FF),
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 110,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(
                      _categories.length,
                      (index) => Padding(
                        padding: EdgeInsets.only(right: index == _categories.length - 1 ? 0 : 16),
                        child: _buildCategoryItem(_categories[index], index),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE6E6E6)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEAF1FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.psychology_rounded, color: Color(0xFF0B4C9E), size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Impulse Control Check',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0B4C9E),
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Was this a planned purchase?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8C8C8C),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _ImpulseOption(
                          label: 'Yes, planned',
                          selected: _isPlanned == true,
                          onTap: () => setState(() => _isPlanned = true),
                        ),
                        _ImpulseOption(
                          label: 'No, impulse',
                          selected: _isPlanned == false,
                          onTap: () => setState(() => _isPlanned = false),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Select date & time')),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Color(0x99000000), size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'DATE & TIME',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0x61000000),
                              letterSpacing: -0.4,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Today, 12:45 PM',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xD6000000),
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0x80000000)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSaveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B1B3C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Expense',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSaveExpense() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    final selectedCategory = _categories[_selectedCategoryIndex].label;
    final note = _noteController.text.trim();
    final expenseName = note.isEmpty ? selectedCategory : note;

    setState(() {
      _isSaving = true;
    });

    try {
      final callable = _functions.httpsCallable('logExpense');
      await callable.call({
        'amount': amount,
        'expenseName': expenseName,
        'category': selectedCategory.toLowerCase(),
        'note': note,
        'source': 'manual',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense saved.')),
      );
      Navigator.pop(context, true);
    } on FirebaseFunctionsException catch (e) {
      final canFallback =
          e.code == 'not-found' ||
          e.code == 'unavailable' ||
          e.code == 'unimplemented';

      if (canFallback) {
        try {
          await _logExpenseViaFirestore(
            amount: amount,
            expenseName: expenseName,
            category: selectedCategory,
            note: note,
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense saved.')),
          );
          Navigator.pop(context, true);
          return;
        } catch (_) {}
      }

      if (!mounted) return;
      final message = (e.message ?? 'Unable to save expense right now.').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message.isEmpty ? 'Unable to save expense right now.' : message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save expense right now.')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _logExpenseViaFirestore({
    required double amount,
    required String expenseName,
    required String category,
    required String note,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'demo_user';
    final firestore = FirebaseFirestore.instance;
    final balanceRef = firestore.collection('balances').doc(userId);

    await firestore.runTransaction((transaction) async {
      final snap = await transaction.get(balanceRef);
      final data = snap.data() ?? <String, dynamic>{};
      final currentAvailable = (data['available'] as num?)?.toDouble() ?? 0.0;
      final currentSpent = (data['spent'] as num?)?.toDouble() ?? 0.0;

      if (currentAvailable < amount) {
        throw StateError('insufficient_balance');
      }

      transaction.set(
        balanceRef,
        {
          'available': currentAvailable - amount,
          'spent': currentSpent + amount,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    await firestore.collection('transactions').add({
      'userId': userId,
      'type': 'expense',
      'category': category.toLowerCase(),
      'expenseName': expenseName,
      'amount': amount,
      'myShare': amount,
      'note': note,
      'date': DateTime.now().toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
      'metadata': {
        'source': 'manual',
      },
    });
  }

  Widget _buildCategoryItem(_ExpenseCategory category, int index) {
    final bool selected = index == _selectedCategoryIndex;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryIndex = index),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 72,
            decoration: BoxDecoration(
              color: selected ? category.iconColor.withValues(alpha: 0.18) : category.background,
              borderRadius: BorderRadius.circular(20),
              border: selected ? Border.all(color: category.iconColor.withValues(alpha: 0.35)) : null,
            ),
            child: Icon(category.icon, color: category.iconColor, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            category.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? category.iconColor : Colors.black,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseCategory {
  final String label;
  final IconData icon;
  final Color background;
  final Color iconColor;

  const _ExpenseCategory({
    required this.label,
    required this.icon,
    required this.background,
    required this.iconColor,
  });
}

class _ImpulseOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _ImpulseOption({required this.label, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isPlanned = label.toLowerCase().contains('planned');
    final Color bg = isPlanned ? const Color(0xFF0B1B3C) : const Color(0xFFF1F1F1);
    final Color fg = isPlanned ? Colors.white : const Color(0xFF1A1A1A);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isPlanned ? Colors.transparent : const Color(0xFFE0E0E0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: fg,
            letterSpacing: -0.4,
          ),
        ),
      ),
    );
  }
}
