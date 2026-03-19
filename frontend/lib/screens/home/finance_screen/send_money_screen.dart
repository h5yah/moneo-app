import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SendMoneyScreen extends StatefulWidget {
  final double availableBalance;

  const SendMoneyScreen({
    super.key,
    required this.availableBalance,
  });

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String? _selectedUserId;
  List<Map<String, dynamic>> _userList = [];
  bool _loadingUsers = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  double get _availableBalance => widget.availableBalance;

  double get _enteredAmount {
    return double.tryParse(_amountController.text.trim()) ?? 0;
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _loadingUsers = true;
    });

    final snapshot = await FirebaseFirestore.instance
        .collection('wallet_users')
        .orderBy('name')
        .get();

    _userList = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': (data['name'] ?? data['fullName'] ?? '').toString(),
        'phone': (data['phone'] ?? '').toString(),
      };
    }).toList();

    debugPrint('Fetched users: ${_userList.length}');
    debugPrint(_userList.toString());

    if (!mounted) return;

    setState(() {
      _loadingUsers = false;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _recipientController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handleSendMoney() {
    final amount = _enteredAmount;
    final phone = _recipientController.text.trim();

    if (phone.isEmpty) {
      _showMessage('Please enter a phone number.');
      return;
    }

    final phonePattern = RegExp(r'^5\d{7}$');
    if (!phonePattern.hasMatch(phone)) {
      _showMessage('Phone number must start with 5 and contain 8 digits.');
      return;
    }

    _validatePhoneAndProceed(phone, amount);
  }

  Future<void> _validatePhoneAndProceed(String phone, double amount) async {
    if (_amountController.text.trim().isEmpty) {
      _showMessage('Please enter an amount.');
      return;
    }

    if (amount <= 0) {
      _showMessage('Amount must be greater than 0.');
      return;
    }

    if (amount > _availableBalance) {
      _showMessage('Insufficient wallet balance.');
      return;
    }

    final query = await FirebaseFirestore.instance
        .collection('wallet_users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();

    String recipient;
    if (query.docs.isEmpty) {
      recipient = phone;
      _selectedUserId = null;
    } else {
      final doc = query.docs.first;
      final user = doc.data();
      final name = (user['name'] ?? user['fullName'] ?? '').toString().trim();
      final foundPhone = (user['phone'] ?? '').toString().trim();

      _selectedUserId = doc.id;
      recipient = name.isNotEmpty ? '$name ($foundPhone)' : foundPhone;
    }

    _showConfirmationDialog(recipient, amount);
  }

  void _showConfirmationDialog(String recipient, double amount) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Confirm Transfer',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recipient: $recipient'),
              const SizedBox(height: 8),
              Text('Amount: Rs ${amount.toStringAsFixed(2)}'),
              if (_noteController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Note: ${_noteController.text.trim()}'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D1B2A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);

                try {
                  await _deductBalanceAndSaveTransaction(recipient, amount);

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Rs ${amount.toStringAsFixed(2)} sent successfully to $recipient',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );

                  _amountController.clear();
                  _recipientController.clear();
                  _noteController.clear();

                  setState(() {
                    _selectedUserId = null;
                  });

                  Navigator.of(context).pop();
                } catch (e) {
                  if (!mounted) return;
                  _showMessage('Failed to send money. Please try again.');
                }
              },
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deductBalanceAndSaveTransaction(
    String recipient,
    double amount,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      throw Exception('No logged-in user found.');
    }

    final senderId = currentUser.uid;
    final balanceRef =
        FirebaseFirestore.instance.collection('balances').doc(senderId);
    final txRef = FirebaseFirestore.instance.collection('transactions').doc();

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

      final now = DateTime.now();
      final dateString = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Save to transactions
      tx.set(txRef, {
        'expenseName': 'Money Sent',
        'myShare': -amount,
        'recipient': recipient,
        'userId': senderId,
        'type': 'send_money',
        'date': now.toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
        'note': _noteController.text.trim(),
      });

      // Save to expenses
      final expenseRef = FirebaseFirestore.instance.collection('expenses').doc();
      tx.set(expenseRef, {
        'expenseName': 'Money Sent',
        'amount': amount,
        'recipient': recipient,
        'userId': senderId,
        'type': 'send_money',
        'date': dateString,
        'createdAt': FieldValue.serverTimestamp(),
        'note': _noteController.text.trim(),
      });
    });
  }

  void _openRecipientPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        if (_loadingUsers) {
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (_userList.isEmpty) {
          return const SizedBox(
            height: 220,
            child: Center(
              child: Text(
                'No contacts found',
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Recipient',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _userList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = _userList[index];
                      final name = (user['name'] ?? '').toString().trim();
                      final phone = (user['phone'] ?? '').toString().trim();

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF0D1B2A),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          name.isNotEmpty ? name : 'Unknown User',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(phone),
                        onTap: () {
                          _recipientController.text = phone;
                          _selectedUserId = user['id'];
                          Navigator.pop(bottomSheetContext);
                          setState(() {});
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _getSelectedRecipientName() {
    final phone = _recipientController.text.trim();

    for (final user in _userList) {
      if ((user['phone'] ?? '').toString().trim() == phone) {
        final name = (user['name'] ?? '').toString().trim();
        return name.isNotEmpty ? name : null;
      }
    }
    return null;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        title: const Text(
          'Send Money',
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBalanceCard(),
              const SizedBox(height: 20),
              _buildFormCard(),
              const SizedBox(height: 28),
              SizedBox(
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
                  onPressed: _handleSendMoney,
                  child: const Text(
                    'Send Money',
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
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rs ${_availableBalance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
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
            'Mobile Number',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _recipientController,
            keyboardType: TextInputType.phone,
            onChanged: (_) {
              setState(() {
                _selectedUserId = null;
              });
            },
            decoration: InputDecoration(
              hintText: 'Enter mobile number',
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
              suffixIcon: IconButton(
                onPressed: _openRecipientPicker,
                icon: const Icon(
                  Icons.contacts_rounded,
                  color: Color(0xFF0D1B2A),
                ),
              ),
            ),
          ),
          if (_getSelectedRecipientName() != null) ...[
            const SizedBox(height: 10),
            Text(
              'Recipient: ${_getSelectedRecipientName()}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D1B2A),
              ),
            ),
          ],
          const SizedBox(height: 18),
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
          const SizedBox(height: 18),
          const Text(
            'Note (Optional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              hintText: 'Add a short note',
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
        ],
      ),
    );
  }
}