import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fintech/utils/icon_accent_style.dart';

class _MerchantOption {
  const _MerchantOption({
    required this.id,
    required this.name,
    required this.account,
  });

  final String id;
  final String name;
  final String account;
}

class ScanToPayScreen extends StatefulWidget {
  const ScanToPayScreen({super.key});

  @override
  State<ScanToPayScreen> createState() => _ScanToPayScreenState();
}

class _ScanToPayScreenState extends State<ScanToPayScreen> {
  final TextEditingController _amountController = TextEditingController();

  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: [BarcodeFormat.qrCode],
  );

  bool _hasScanned = false;
  bool _isHandlingScan = false;
  bool _flashOn = false;
  bool _isPaying = false;

  String _merchantName = 'Unknown Merchant';
  String _merchantId = 'Not available';
  String _merchantAccount = 'Not available';
  String _rawPayload = '';

  String get _userId {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? 'demo_user';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPay =
        _hasScanned && _amountController.text.trim().isNotEmpty && !_isPaying;

    return Scaffold(
      backgroundColor: _hasScanned ? const Color(0xFFF2F2F7) : Colors.black,
      appBar: AppBar(
        backgroundColor: _hasScanned ? const Color(0xFFF2F2F7) : Colors.black,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12, top: 2),
          child: GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              decoration: BoxDecoration(
                color: _hasScanned ? const Color(0xFFF2F2F7) : Colors.black,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color:
                    _hasScanned ? const Color(0xFF007AFF) : Colors.yellowAccent,
              ),
            ),
          ),
        ),
        title: Text(
          'Scan to Pay',
          style: TextStyle(
            color: _hasScanned ? const Color(0xFF1C1C1E) : Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (!_hasScanned)
            IconButton(
              onPressed: () async {
                await _scannerController.toggleTorch();
                if (!mounted) return;
                setState(() {
                  _flashOn = !_flashOn;
                });
              },
              icon: Icon(
                _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: Colors.white,
              ),
            ),
        ],
      ),
      body: _hasScanned ? _buildPaymentForm(canPay) : _buildScannerView(),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: _onDetect,
        ),
        Container(color: Colors.black.withValues(alpha: 0.24)),
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 40,
          child: Column(
            children: [
              const Text(
                'Scan merchant QR code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'After scan, enter amount and confirm payment',
                style: TextStyle(
                  color: Color(0xFFE5E7EB),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _showMerchantPicker,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC143C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Select from merchant list',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentForm(bool canPay) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Merchant Details',
                  style: TextStyle(
                    color: Color(0xFF1C1C1E),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _buildDetailRow('Name', _merchantName),
                const SizedBox(height: 6),
                _buildDetailRow('Merchant ID', _merchantId),
                const SizedBox(height: 6),
                _buildDetailRow('Account', _merchantAccount),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _resetScanner,
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
              label: const Text('Rescan QR'),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Amount',
            style: TextStyle(
              color: Color(0xFF1C1C1E),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Enter amount in Rs',
              filled: true,
              fillColor: Colors.white,
              prefixText: 'Rs ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD1D1D6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD1D1D6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF007AFF), width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'QR Payload: $_rawPayload',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: canPay ? _handlePayNow : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFB9D7FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isPaying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Pay Now',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1C1C1E),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String? _firstNonEmptyString(
    Map<String, dynamic> data,
    List<String> fieldNames,
  ) {
    final normalizedFields = {
      for (final fieldName in fieldNames) _normalizeFieldName(fieldName),
    };

    for (final fieldName in fieldNames) {
      final value = data[fieldName]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }

    for (final entry in data.entries) {
      if (!normalizedFields.contains(_normalizeFieldName(entry.key))) {
        continue;
      }
      final value = entry.value?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }

    return null;
  }

  String? _guessMerchantName(Map<String, dynamic> data, String merchantId) {
    final directMatch = _firstNonEmptyString(data, const [
      'merchantName',
      'merchant name',
      'merchant_name',
      'name',
      'Name',
      'businessName',
      'business name',
      'business_name',
      'displayName',
      'display name',
      'shopName',
      'shop name',
      'title',
    ]);
    if (directMatch != null) return directMatch;

    for (final entry in data.entries) {
      final key = _normalizeFieldName(entry.key);
      if (key.contains('id') ||
          key.contains('account') ||
          key.contains('active') ||
          key.contains('created') ||
          key.contains('updated')) {
        continue;
      }

      final value = entry.value;
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty && trimmed != merchantId) return trimmed;
      }

      if (value is Map) {
        final nested = _guessMerchantName(
          Map<String, dynamic>.from(value),
          merchantId,
        );
        if (nested != null) return nested;
      }
    }

    return null;
  }

  Map<String, dynamic> _expandedMerchantData(Map<String, dynamic> data) {
    final expanded = Map<String, dynamic>.from(data);

    for (final entry in data.entries) {
      final decodedKey = _tryDecodeJsonMap(entry.key);
      if (decodedKey != null) expanded.addAll(decodedKey);

      final value = entry.value;
      if (value is String) {
        final decodedValue = _tryDecodeJsonMap(value);
        if (decodedValue != null) expanded.addAll(decodedValue);
      } else if (value is Map) {
        expanded.addAll(Map<String, dynamic>.from(value));
      }
    }

    return expanded;
  }

  Map<String, dynamic>? _tryDecodeJsonMap(String value) {
    final trimmed = value.trim();
    if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) return null;

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  String _normalizeFieldName(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
  }

  String? _merchantIdFromData(Map<String, dynamic> data) {
    return _firstNonEmptyString(data, const [
      'merchantId',
      'merchant id',
      'merchant_id',
      'id',
    ]);
  }

  String? _merchantAccountFromData(Map<String, dynamic> data) {
    return _firstNonEmptyString(data, const [
      'account',
      'accountNumber',
      'account number',
      'account_number',
      'walletAccount',
      'wallet account',
      'wallet_account',
      'merchantAccount',
      'merchant account',
    ]);
  }

  _MerchantOption _merchantOptionFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = _expandedMerchantData(doc.data());
    final id = _merchantIdFromData(data) ?? doc.id;
    final name = _guessMerchantName(data, id) ?? 'Unknown Merchant';
    final account = _merchantAccountFromData(data) ?? 'Not available';
    return _MerchantOption(id: id, name: name, account: account);
  }

  Future<void> _showMerchantPicker() async {
    setState(() => _isHandlingScan = true);
    await _scannerController.stop();

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('merchants').get();
      if (!mounted) return;

      final merchants = snapshot.docs
          .where((doc) {
            final data = _expandedMerchantData(doc.data());
            return data['isActive'] as bool? ?? true;
          })
          .map(_merchantOptionFromDoc)
          .where((merchant) => merchant.name != 'Unknown Merchant')
          .toList();

      if (merchants.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active merchants found.')),
        );
        await _scannerController.start();
        setState(() => _isHandlingScan = false);
        return;
      }

      final selected = await showModalBottomSheet<_MerchantOption>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) {
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
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
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Select Merchant',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose a merchant if you do not want to scan a QR code.',
                    style: TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: merchants.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final merchant = merchants[index];
                        final isDark =
                            Theme.of(context).brightness == Brightness.dark;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: iconAccentBackground(
                                accentColor: const Color(0xFF007AFF),
                                isDark: isDark,
                                lightBackground: const Color(0xFFEAF3FF),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: Color(0xFF007AFF),
                            ),
                          ),
                          title: Text(
                            merchant.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.pop(sheetContext, merchant),
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

      if (!mounted) return;
      if (selected == null) {
        await _scannerController.start();
        setState(() => _isHandlingScan = false);
        return;
      }

      setState(() {
        _merchantId = selected.id;
        _merchantName = selected.name;
        _merchantAccount = selected.account;
        _rawPayload = selected.id;
        _hasScanned = true;
        _isHandlingScan = false;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load merchants.')),
      );
      await _scannerController.start();
      setState(() => _isHandlingScan = false);
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isHandlingScan || _hasScanned) return;

    final firstCode =
        capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;

    if (firstCode == null || firstCode.trim().isEmpty) return;

    _isHandlingScan = true;

    final merchantId = firstCode.trim();
    await _fetchMerchant(merchantId);

    _isHandlingScan = false;
  }

  Future<void> _fetchMerchant(String merchantId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('merchants')
          .doc(merchantId)
          .get();

      if (!doc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Merchant not found.')),
        );
        return;
      }

      final data = _expandedMerchantData(doc.data()!);
      final isActive = data['isActive'] as bool? ?? true;

      if (!isActive) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This merchant is inactive.')),
        );
        return;
      }

      final merchantName = _guessMerchantName(data, merchantId);
      final merchantAccount = _merchantAccountFromData(data);

      await _scannerController.stop();

      if (!mounted) return;
      setState(() {
        _merchantId = merchantId;
        _merchantName = merchantName ?? 'Unknown Merchant';
        _merchantAccount = merchantAccount ?? 'Not available';
        _rawPayload = merchantId;
        _hasScanned = true;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load merchant details.')),
      );
    }
  }

  void _resetScanner() {
    setState(() {
      _hasScanned = false;
      _isHandlingScan = false;
      _merchantName = 'Unknown Merchant';
      _merchantId = 'Not available';
      _merchantAccount = 'Not available';
      _rawPayload = '';
      _amountController.clear();
    });
    _scannerController.start();
  }

  Future<void> _handlePayNow() async {
    final rawAmount = _amountController.text.trim();
    final amount = double.tryParse(rawAmount);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Payment'),
          content: Text(
            'Pay Rs ${amount.toStringAsFixed(2)} to $_merchantName?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _isPaying = true;
    });

    final firestore = FirebaseFirestore.instance;
    final balanceRef = firestore.collection('balances').doc(_userId);
    final transactionRef = firestore.collection('transactions').doc();
    final expenseRef = firestore.collection('expenses').doc();
    final now = DateTime.now();
    final dateString =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    try {
      await firestore.runTransaction((transaction) async {
        final balanceSnap = await transaction.get(balanceRef);
        final balanceData = balanceSnap.data() ?? <String, dynamic>{};

        final currentAvailable =
            (balanceData['available'] as num?)?.toDouble() ?? 0.0;

        if (currentAvailable < amount) {
          throw StateError('insufficient_balance');
        }

        final currentSpent = (balanceData['spent'] as num?)?.toDouble() ?? 0.0;
        final newAvailable = currentAvailable - amount;

        transaction.set(
          balanceRef,
          {
            'available': newAvailable,
            'spent': currentSpent + amount,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        transaction.set(
          transactionRef,
          {
            'userId': _userId,
            'merchantId': _merchantId,
            'merchantName': _merchantName,
            'merchantAccount': _merchantAccount,
            'qrPayload': _rawPayload,
            'amount': amount,
            'expenseName': 'QR Payment - $_merchantName',
            'type': 'scan_to_pay',
            'category': 'qr_payment',
            'status': 'success',
            'paymentMethod': 'wallet',
            'date': now.toIso8601String(),
            'createdAt': FieldValue.serverTimestamp(),
          },
        );

        transaction.set(
          expenseRef,
          {
            'userId': _userId,
            'merchantId': _merchantId,
            'merchantName': _merchantName,
            'amount': amount,
            'expenseName': 'QR Payment - $_merchantName',
            'type': 'scan_to_pay',
            'category': 'qr_payment',
            'paymentMethod': 'wallet',
            'date': dateString,
            'createdAt': FieldValue.serverTimestamp(),
          },
        );
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } on StateError catch (error) {
      if (!mounted) return;
      final message = error.message == 'insufficient_balance'
          ? 'Insufficient wallet balance.'
          : 'Payment failed. Please try again.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      setState(() {
        _isPaying = false;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment failed. Please try again.')),
      );
      setState(() {
        _isPaying = false;
      });
    }
  }
}
