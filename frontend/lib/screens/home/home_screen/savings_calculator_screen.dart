import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SavingsCalculatorScreen extends StatefulWidget {
  const SavingsCalculatorScreen({super.key});

  @override
  State<SavingsCalculatorScreen> createState() => _SavingsCalculatorScreenState();
}

class _SavingsCalculatorScreenState extends State<SavingsCalculatorScreen> {
  final TextEditingController _goalController    = TextEditingController(text: '0');
  final TextEditingController _monthlyController = TextEditingController(text: '0');
  final ScrollController      _scrollController  = ScrollController();
  final GlobalKey             _breakdownKey       = GlobalKey();

  double _goalAmount    = 0.0;
  double _monthlySaving = 0.0;
  bool   _hasCalculated = false;

  // ── Palette ────────────────────────────────────────────────────────────────
  static const Color _bg       = Color(0xFFF7F8FC);
  static const Color _purple   = Color(0xFF5B3FE8);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF9CA3AF);
  static const Color _border   = Color(0xFFE5E7EB);
  static const Color _surface  = Color(0xFFF3F4F6);

  @override
  void dispose() {
    _goalController.dispose();
    _monthlyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Calculations ───────────────────────────────────────────────────────────
  int get _months {
    if (_monthlySaving <= 0 || _goalAmount <= 0) return 0;
    return (_goalAmount / _monthlySaving).ceil();
  }

  String get _timeLabel {
    final m = _months;
    if (m <= 0) return '—';
    final y   = m ~/ 12;
    final rem = m % 12;
    if (y == 0)   return '$m month${m == 1 ? '' : 's'}';
    if (rem == 0) return '$y year${y == 1 ? '' : 's'}';
    return '$y yr $rem mo';
  }

  String get _completionDate {
    if (_months <= 0) return '—';
    const names = ['Jan','Feb','Mar','Apr','May','Jun',
                   'Jul','Aug','Sep','Oct','Nov','Dec'];
    final t = DateTime(DateTime.now().year, DateTime.now().month + _months);
    return '${names[t.month - 1]} ${t.year}';
  }

  String _fmt(double v) =>
      'Rs ${v.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},')}';

  String _fmtWhole(double v) =>
      v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

  void _onCalculate() {
    final goal    = double.tryParse(_goalController.text.replaceAll(',', ''));
    final monthly = double.tryParse(_monthlyController.text.replaceAll(',', ''));
    if (goal != null && goal > 0 && monthly != null && monthly > 0) {
      setState(() {
        _goalAmount    = goal;
        _monthlySaving = monthly;
        _hasCalculated = true;
      });
      Future.delayed(const Duration(milliseconds: 120), () {
        final ctx = _breakdownKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutCubic);
        }
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: _BackButton(),
        title: const Text(
          'Savings Calculator',
          style: TextStyle(color: _textDark, fontSize: 18,
              fontWeight: FontWeight.w600, letterSpacing: -0.3),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Savings Goal ─────────────────────────────────────────────
              const _SectionLabel('Savings Goal'),
              const _SectionHint('How much do you want to save up?'),
              const SizedBox(height: 8),
              _AmountInputField(controller: _goalController),
              const SizedBox(height: 28),

              // ── Monthly Savings ──────────────────────────────────────────
              const _SectionLabel('Monthly Savings'),
              const _SectionHint('How much can you set aside each month?'),
              const SizedBox(height: 8),
              _AmountInputField(controller: _monthlyController),
              const SizedBox(height: 36),

              // ── Calculate Button ─────────────────────────────────────────
              _CalcButton(onPressed: _onCalculate),

              // ── Breakdown ────────────────────────────────────────────────
              if (_hasCalculated) ...[
                const SizedBox(height: 44),
                _BreakdownSection(
                  key: _breakdownKey,
                  goalAmount:     _goalAmount,
                  monthlySaving:  _monthlySaving,
                  timeLabel:      _timeLabel,
                  completionDate: _completionDate,
                  fmt:            _fmt,
                  fmtWhole:       _fmtWhole,
                ),
              ],

            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Label / Hint ──────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: Color(0xFF111827), letterSpacing: 0.1));
}

class _SectionHint extends StatelessWidget {
  final String text;
  const _SectionHint(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 2, bottom: 2),
    child: Text(text,
        style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
  );
}

// ── Back Button ───────────────────────────────────────────────────────────────
class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 12),
    child: GestureDetector(
      onTap: () => Navigator.maybePop(context),
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white, shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 14, color: Color(0xFF111827)),
      ),
    ),
  );
}

// ── Amount Input Field ────────────────────────────────────────────────────────
class _AmountInputField extends StatefulWidget {
  final TextEditingController controller;
  const _AmountInputField({required this.controller});
  @override
  State<_AmountInputField> createState() => _AmountInputFieldState();
}

class _AmountInputFieldState extends State<_AmountInputField> {
  bool _focused = false;
  static const _purple = Color(0xFF5B3FE8);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focused ? _purple : const Color(0xFFE5E7EB),
          width: _focused ? 1.5 : 1,
        ),
        boxShadow: _focused
            ? [BoxShadow(color: _purple.withOpacity(0.08),
                blurRadius: 12, offset: const Offset(0, 4))]
            : [],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
            decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Color(0xFFE5E7EB)))),
            child: const Text('Rs',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                    color: _purple, letterSpacing: 0.3)),
          ),
          Expanded(
            child: Focus(
              onFocusChange: (f) => setState(() => _focused = f),
              child: TextField(
                controller: widget.controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))
                ],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                    color: Color(0xFF111827), letterSpacing: -0.5),
                decoration: const InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(
                      color: Color(0xFFD1D5DB), fontWeight: FontWeight.w500),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 17),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Calculate Button ──────────────────────────────────────────────────────────
class _CalcButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CalcButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF5B3FE8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16,
              fontWeight: FontWeight.w600, letterSpacing: 0.1),
        ),
        child: const Text('Calculate'),
      ),
    );
  }
}

// ── Breakdown Section ─────────────────────────────────────────────────────────
class _BreakdownSection extends StatelessWidget {
  final double goalAmount;
  final double monthlySaving;
  final String timeLabel;
  final String completionDate;
  final String Function(double) fmt;
  final String Function(double) fmtWhole;

  const _BreakdownSection({
    super.key,
    required this.goalAmount,
    required this.monthlySaving,
    required this.timeLabel,
    required this.completionDate,
    required this.fmt,
    required this.fmtWhole,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your savings plan',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
              color: Color(0xFF111827), letterSpacing: -0.5),
        ),
        const SizedBox(height: 16),

        // ── Summary grid ───────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: _SummaryRow(items: [
                  _SummaryItem(label: 'Savings Goal',
                      value: 'Rs ${fmtWhole(goalAmount)}'),
                  _SummaryItem(label: 'Time to reach it',
                      value: timeLabel),
                ]),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: _SummaryRow(items: [
                  _SummaryItem(label: 'Monthly savings',
                      value: fmt(monthlySaving)),
                  _SummaryItem(label: 'Goal reached by',
                      value: completionDate),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Note ───────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 16, color: Color(0xFF9CA3AF)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Based on saving the same amount every month with no interest. Actual progress may vary.',
                  style: TextStyle(fontSize: 12,
                      color: Color(0xFF9CA3AF), height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Summary Row / Item ────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final List<_SummaryItem> items;
  const _SummaryRow({required this.items});
  @override
  Widget build(BuildContext context) =>
      Row(children: items.map((e) => Expanded(child: e)).toList());
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                color: Color(0xFF111827), letterSpacing: -0.4)),
      ],
    );
  }
}