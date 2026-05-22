import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TipSplitterScreen extends StatefulWidget {
  const TipSplitterScreen({super.key});

  @override
  State<TipSplitterScreen> createState() => _TipSplitterScreenState();
}

class _TipSplitterScreenState extends State<TipSplitterScreen> {
  /// App currency label (always shown; not tied to device locale).
  static const String _currencyPrefix = 'Rs ';

  final TextEditingController _billController = TextEditingController();

  double _tipPercent = 0;
  int _people = 1;

  double get _bill => double.tryParse(_billController.text.trim()) ?? 0;
  double get _tipAmount => _bill * _tipPercent / 100;
  double get _total => _bill + _tipAmount;
  double get _perPerson => _people > 0 ? _total / _people : 0;

  final List<int> _tipOptions = [0, 5, 10, 15, 20, 25];

  String _rs(double amount) => '$_currencyPrefix${amount.toStringAsFixed(2)}';

  @override
  void dispose() {
    _billController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1020) : const Color(0xFFF5F7FB);
    final textDark = isDark ? Colors.white : const Color(0xFF111827);
    final textMuted = isDark ? const Color(0xFFAAB0C6) : const Color(0xFF6B7280);
    final border = isDark ? const Color(0xFF2A2D4A) : const Color(0xFFE9ECF4);
    final card = isDark ? const Color(0xFF1B1D33) : Colors.white;

    const orange = Color(0xFFFF7A00);
    const orangeLight = Color(0xFFFFA64D);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Bill Splitter",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            /// RESULT CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  colors: [orange, orangeLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: orange.withOpacity(0.35),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Text(
                      "Per Person",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    _rs(_perPerson),
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _miniSummary(
                          "Tip",
                          _rs(_tipAmount),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _miniSummary(
                          "Total",
                          _rs(_total),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// INPUT CARD
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.04),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    "Bill Amount",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _currencyPrefix,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: textMuted,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _billController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => setState(() {}),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                          ),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: textMuted.withValues(alpha: 0.45),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 28),

                  /// TIP SELECTOR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Tip %",
                        style: TextStyle(color: textMuted),
                      ),
                      Text(
                        "${_tipPercent.toInt()}%",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _tipOptions.map((p) {
                      final selected = _tipPercent == p.toDouble();

                      return GestureDetector(
                        onTap: () => setState(() => _tipPercent = p.toDouble()),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? orange
                                : (isDark ? const Color(0xFF242742) : const Color(0xFFF5F7FB)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected ? orange : border,
                            ),
                          ),
                          child: Text(
                            "$p%",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : textDark,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  /// PEOPLE
                  Text(
                    "Split Between",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FB),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        _counterButton(Icons.remove, () {
                          if (_people > 1) setState(() => _people--);
                        }),

                        Expanded(
                          child: Center(
                            child: Text(
                              "$_people",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: textDark,
                              ),
                            ),
                          ),
                        ),

                        _counterButton(Icons.add, () {
                          setState(() => _people++);
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// BREAKDOWN
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: border),
              ),
              child: Column(
                children: [
                  _row("Bill", _rs(_bill)),
                  const SizedBox(height: 12),
                  _row("Tip", _rs(_tipAmount)),
                  const Divider(height: 26),
                  _row(
                    "Total",
                    _rs(_total),
                    bold: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniSummary(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _counterButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE9ECF4)),
        ),
        child: Icon(icon, color: const Color(0xFF111827)),
      ),
    );
  }

  Widget _row(String title, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(
              fontSize: 14,
              color: bold ? Colors.black : const Color(0xFF6B7280),
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            )),
        Text(value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: bold ? const Color(0xFFFF7A00) : Colors.black,
            )),
      ],
    );
  }
}