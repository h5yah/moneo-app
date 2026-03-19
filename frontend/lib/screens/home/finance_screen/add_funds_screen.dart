import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_card_screen.dart';

class AddFundsScreen extends StatefulWidget {
  const AddFundsScreen({super.key});

  @override
  State<AddFundsScreen> createState() => _AddFundsScreenState();
}

class _AddFundsScreenState extends State<AddFundsScreen> {
  final TextEditingController _amountController = TextEditingController();

  String _selectedDestination = 'general';
  Map<String, String>? _savedCard;
  bool _isSubmitting = false;

  final List<int> _quickAmounts = [500, 1000, 5000];

  @override
  void initState() {
    super.initState();
    _fetchSavedCard();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchSavedCard() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'demo_user';

    final doc = await FirebaseFirestore.instance
        .collection('cards')
        .doc(userId)
        .get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null && mounted) {
        setState(() {
          _savedCard = {
            'last4': data['last4'] ?? '0000',
            'type': data['type'] ?? 'debit',
          };
        });
      }
    }
  }

  String _formatAmount(int amount) {
    if (amount >= 1000) {
      return '${amount ~/ 1000},${(amount % 1000).toString().padLeft(3, '0')}';
    }
    return amount.toString();
  }

  Future<void> _handleAddFunds() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'demo_user';

    if (amount <= 0) {
      _showMessage('Enter a valid amount.');
      return;
    }

    if (_savedCard == null) {
      _showMessage('Please link a card before adding funds.');
      return;
    }

    setState(() => _isSubmitting = true);

    final firestore = FirebaseFirestore.instance;

    try {
      if (_selectedDestination == 'general') {
        await _addFundsToGeneralWallet(amount);
      } else {
        final goalDoc = firestore.collection('goals').doc(_selectedDestination);

        await firestore.runTransaction((transaction) async {
          final goalSnapshot = await transaction.get(goalDoc);
          final current =
              (goalSnapshot.data()?['current'] as num?)?.toDouble() ?? 0.0;

          transaction.update(goalDoc, {
            'current': current + amount,
          });
        });

        await firestore.collection('transactions').add({
          'userId': userId,
          'type': 'add_funds',
          'category': 'goal',
          'expenseName': 'Goal Top-up',
          'amount': amount,
          'myShare': amount,
          'date': DateTime.now().toIso8601String(),
          'createdAt': FieldValue.serverTimestamp(),
          'metadata': {
            'source': 'card',
            'goalId': _selectedDestination,
          },
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Funds added successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Failed to add funds. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _addFundsToGeneralWallet(double amount) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'demo_user';
    final firestore = FirebaseFirestore.instance;
    final balanceRef = firestore.collection('balances').doc(userId);

    await firestore.runTransaction((transaction) async {
      final snap = await transaction.get(balanceRef);
      final data = snap.data() ?? <String, dynamic>{};

      final currentAvailable = (data['available'] as num?)?.toDouble() ?? 0.0;
      final currentIncome = (data['income'] as num?)?.toDouble() ?? 0.0;

      transaction.set(
        balanceRef,
        {
          'available': currentAvailable + amount,
          'income': currentIncome + amount,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    await firestore.collection('transactions').add({
      'userId': userId,
      'type': 'add_funds',
      'category': 'general',
      'expenseName': 'Funds Added',
      'amount': amount,
      'myShare': amount,
      'date': DateTime.now().toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
      'metadata': {
        'source': 'card',
      },
    });
  }

  Future<void> _navigateToAddCard() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddCardScreen(),
      ),
    );

    if (result != null && mounted) {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'demo_user';

      await FirebaseFirestore.instance.collection('cards').doc(userId).set({
        'last4': result['last4'] ?? '0000',
        'type': result['type'] ?? 'debit',
      }, SetOptions(merge: true));

      setState(() {
        _savedCard = result;
      });
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  IconData _iconFromString(String iconName) {
    switch (iconName) {
      case 'account_balance':
        return Icons.account_balance;
      case 'school_outlined':
        return Icons.school_outlined;
      case 'flight_takeoff':
        return Icons.flight_takeoff;
      case 'laptop_mac':
        return Icons.laptop_mac;
      case 'directions_car_outlined':
        return Icons.directions_car_outlined;
      case 'edit_note_rounded':
        return Icons.edit_note_rounded;
      case 'target':
        return Icons.track_changes;
      default:
        return Icons.account_balance_wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        title: const Text(
          'Add Funds',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 20),
                  _buildAmountCard(),
                  const SizedBox(height: 20),
                  _buildDestinationCard(),
                  const SizedBox(height: 20),
                  _buildPaymentMethodCard(),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D1B2A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isSubmitting ? null : _handleAddFunds,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Add Funds',
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF1B263B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Up Wallet',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add money securely to your wallet or savings goals',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Amount',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: const Text(
                  'Rs',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D1B2A),
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: const TextStyle(
                      color: Color(0xFFB8C1CC),
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Quick amount buttons removed
        ],
      ),
    );
  }

  Widget _buildDestinationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Destination',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 14),
          _buildDestinationOption(
            icon: Icons.account_balance_wallet,
            iconBgColor: const Color(0xFFE9F2FF),
            iconColor: const Color(0xFF2D4EFF),
            title: 'General Wallet',
            subtitle: 'Available for daily spending',
            value: 'general',
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('goals')
                .where(
                  'userId',
                  isEqualTo:
                      FirebaseAuth.instance.currentUser?.uid ?? 'demo_user',
                )
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox();
              }

              final docs = snapshot.data!.docs;

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildDestinationOption(
                      icon: _iconFromString(data['icon'] ?? 'account_balance'),
                      iconBgColor: const Color(0xFFEAF3FF),
                      iconColor: const Color(0xFF2D4EFF),
                      title: data['title'] ?? 'Goal',
                      subtitle: 'Goal: ${data['category'] ?? ''}',
                      value: doc.id,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationOption({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isSelected = _selectedDestination == value;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() {
          _selectedDestination = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF4F8FF)
              : const Color(0xFFF9FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2D4EFF)
                : const Color(0xFFE4E8EF),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2D4EFF)
                      : const Color(0xFFC9D1DC),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF2D4EFF),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0D1B2A),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 12,
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

  Widget _buildPaymentMethodCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 14),
          _savedCard != null ? _buildSavedCardView() : _buildNoCardView(),
        ],
      ),
    );
  }

  Widget _buildNoCardView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E8EF)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEAEFF5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.credit_card_outlined,
              color: Color(0xFF0D1B2A),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Card Linked',
                  style: TextStyle(
                    color: Color(0xFF0D1B2A),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Link a card to fund your wallet',
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _navigateToAddCard,
            child: const Text(
              'Add Card',
              style: TextStyle(
                color: Color(0xFF2D4EFF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedCardView() {
    final last4 = _savedCard!['last4'] ?? '0000';
    final type = _savedCard!['type'] ?? 'debit';
    final label = type == 'credit' ? 'Credit Card' : 'Debit/Credit Card';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E8EF)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.credit_card,
              color: Color(0xFF2D4EFF),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF0D1B2A),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '•••• $last4',
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _navigateToAddCard,
            child: const Text(
              'Change',
              style: TextStyle(
                color: Color(0xFF2D4EFF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}