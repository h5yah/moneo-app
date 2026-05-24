import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fintech/services/wallet_card_service.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  String _selectedCardType = 'debit'; // 'debit' or 'credit'
  bool _saveForFuture = true;
  bool _isSaving = false;

  Future<void> _persistCard(Map<String, String> cardData) async {
    await WalletCardService.saveCard(
      last4: cardData['last4']!,
      type: cardData['type']!,
      holder: cardData['holder'] ?? '',
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xF0FFFFFF),
      body: SafeArea(
        child: Column(
          children: [
            // Custom header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        'Add Card',
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
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 28),
                      // Card preview
                      _buildCardPreview(),
                      const SizedBox(height: 32),
                      // Card type selector
                      const Text(
                        'CARD TYPE',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildCardTypeChip('Debit Card', 'debit'),
                          const SizedBox(width: 12),
                          _buildCardTypeChip('Credit Card', 'credit'),
                        ],
                      ),
                      const SizedBox(height: 28),
                      // Card Number
                      const Text(
                        'CARD NUMBER',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        controller: _cardNumberController,
                        hintText: '0000  0000  0000  0000',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(16),
                          _CardNumberFormatter(),
                        ],
                        prefixIcon: Icons.credit_card,
                      ),
                      const SizedBox(height: 24),
                      // Cardholder Name
                      const Text(
                        'CARDHOLDER NAME',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        controller: _cardHolderController,
                        hintText: 'Full name on card',
                        keyboardType: TextInputType.name,
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 24),
                      // Expiry & CVV
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'EXPIRY DATE',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildTextField(
                                  controller: _expiryController,
                                  hintText: 'MM / YY',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                    _ExpiryDateFormatter(),
                                  ],
                                  prefixIcon: Icons.calendar_today_outlined,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CVV',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildTextField(
                                  controller: _cvvController,
                                  hintText: '•••',
                                  keyboardType: TextInputType.number,
                                  obscureText: true,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(3),
                                  ],
                                  prefixIcon: Icons.lock_outline,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Save for future toggle
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _saveForFuture = !_saveForFuture;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _saveForFuture
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                color: _saveForFuture
                                    ? const Color(0xFF007AFF)
                                    : const Color(0xFFB2B8C6),
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Save card for future transactions',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'You won\'t need to enter details again',
                                      style: TextStyle(
                                        color: Color(0xFF9E9E9E),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D1B2A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isSaving
                          ? null
                          : () async {
                              final cardNum = _cardNumberController.text
                                  .replaceAll(RegExp(r'\D'), '');
                              if (cardNum.length < 4) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Enter a valid card number.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              final cardData = <String, String>{
                                'last4': cardNum.substring(cardNum.length - 4),
                                'type': _selectedCardType,
                                'holder': _cardHolderController.text.trim(),
                              };

                              if (!_saveForFuture) {
                                if (!mounted) return;
                                Navigator.pop(context, cardData);
                                return;
                              }

                              setState(() => _isSaving = true);
                              try {
                                await _persistCard(cardData);
                                if (!mounted) return;
                                Navigator.pop(context, cardData);
                              } on StateError catch (e) {
                                if (!mounted) return;
                                final message = e.message == 'not_signed_in'
                                    ? 'Sign in to save a card.'
                                    : 'Could not save card. Try again.';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(message),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } catch (_) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not save card. Check your connection and try again.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _isSaving = false);
                                }
                              }
                            },
                      child: const Text(
                        'Add Card',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: Color(0xFFB2B8C6),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'YOUR CARD INFO IS ENCRYPTED & SECURE',
                        style: TextStyle(
                          color: Color(0xFFB2B8C6),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
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
    );
  }

  Widget _buildCardPreview() {
    final cardNum = _cardNumberController.text.isEmpty
        ? '••••  ••••  ••••  ••••'
        : _formatDisplayNumber(_cardNumberController.text);
    final holderName = _cardHolderController.text.isEmpty
        ? 'YOUR NAME'
        : _cardHolderController.text.toUpperCase();
    final expiry =
        _expiryController.text.isEmpty ? 'MM/YY' : _expiryController.text;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D1B2A),
            Color(0xFF1B3A5C),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D1B2A).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedCardType == 'debit' ? 'DEBIT' : 'CREDIT',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              _buildCardBrandIcon(),
            ],
          ),
          const SizedBox(height: 28),
          // Chip icon
          Container(
            width: 45,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Icon(
                Icons.memory,
                color: Color(0xFFB8960C),
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            cardNum,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CARD HOLDER',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    holderName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EXPIRES',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    expiry,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardBrandIcon() {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
        ),
        Transform.translate(
          offset: const Offset(-10, 0),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardTypeChip(String label, String value) {
    final isSelected = _selectedCardType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCardType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D1B2A) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D1B2A) : const Color(0xFFE0E0E0),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0D1B2A).withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required TextInputType keyboardType,
    required IconData prefixIcon,
    bool obscureText = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        inputFormatters: inputFormatters,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFFB2B8C6),
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: const Color(0xFFB2B8C6),
            size: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  String _formatDisplayNumber(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write('  ');
      buffer.write(digits[i]);
    }
    // Pad remaining with dots
    final remaining = 16 - digits.length;
    if (remaining > 0) {
      for (int i = 0; i < remaining; i++) {
        if ((digits.length + i) > 0 && (digits.length + i) % 4 == 0) {
          buffer.write('  ');
        }
        buffer.write('•');
      }
    }
    return buffer.toString();
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write('  ');
      buffer.write(digits[i]);
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2) buffer.write(' / ');
      buffer.write(digits[i]);
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
