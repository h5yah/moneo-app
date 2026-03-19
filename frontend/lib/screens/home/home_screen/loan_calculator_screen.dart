import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoanCalculatorScreen extends StatefulWidget {
  const LoanCalculatorScreen({super.key});

  @override
  State<LoanCalculatorScreen> createState() => _LoanCalculatorScreenState();
}

class _LoanCalculatorScreenState extends State<LoanCalculatorScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _loanController =
      TextEditingController(text: '0');
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _breakdownKey = GlobalKey();

  double _loanAmount = 0.00;
  double _annualRate = 0.5;
  int _termMonths = 6;
  bool _hasCalculated = false;

  late AnimationController _animController;
  late Animation<double> _donutAnimation;

  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color _bg = Color(0xFFF7F8FC);
  static const Color _white = Colors.white;
  static const Color _indigo = Color(0xFFFF6B35);
  static const Color _indigoDark = Color(0xFFE85520);
  static const Color _indigoLight = Color(0xFFFFF0EB);
  static const Color _pink = Color(0xFF0BB8A0);
  static const Color _pinkLight = Color(0xFFE6F9F7);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _surface = Color(0xFFF3F4F6);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _donutAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _loanController.dispose();
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ── Calculations ─────────────────────────────────────────────────────────
  double get _monthlyPayment {
    final r = _annualRate / 100 / 12;
    final n = _termMonths;
    if (n <= 0) return 0;
    if (r == 0) return _loanAmount / n;
    return _loanAmount * r * pow(1 + r, n) / (pow(1 + r, n) - 1);
  }

  double get _totalPayment => _monthlyPayment * _termMonths;
  double get _totalInterest => _totalPayment - _loanAmount;

  String _fmt(double v) =>
      'MUR ${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},')}';

  String _fmtWhole(double v) =>
      v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

  void _onCalculate() {
    final parsed = double.tryParse(_loanController.text.replaceAll(',', ''));
    if (parsed != null && parsed > 0) {
      setState(() {
        _loanAmount = parsed;
        _hasCalculated = true;
      });
    }

    _animController.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 120), () {
      final ctx = _breakdownKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────
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
          'Loan Calculator',
          style: TextStyle(
            color: _textDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Loan Amount Input ─────────────────────────────────────────
            _SectionLabel('Loan Amount'),
            const SizedBox(height: 8),
            _AmountInputField(controller: _loanController),
            const SizedBox(height: 28),

            // ── Loan Term Slider ──────────────────────────────────────────
            _SectionLabel('Loan Term'),
            const SizedBox(height: 4),
            _SliderField(
              value: _termMonths.toDouble(),
              min: 6,
              max: 360,
              divisions: 354,
              displayLabel: '$_termMonths Months',
              minLabel: '6 Months',
              maxLabel: '360 Months',
              onChanged: (v) => setState(() => _termMonths = v.round()),
            ),
            const SizedBox(height: 28),

            // ── Interest Rate Slider ──────────────────────────────────────
            _SectionLabel('Interest Rate'),
            const SizedBox(height: 4),
            _SliderField(
              value: _annualRate,
              min: 0.5,
              max: 30,
              divisions: 59,
              displayLabel: '${_annualRate.toStringAsFixed(1)}%',
              minLabel: '0.5%',
              maxLabel: '30%',
              onChanged: (v) {
                setState(() => _annualRate = (v * 2).round() / 2);
              },
            ),
            const SizedBox(height: 36),

            // ── Calculate Button ──────────────────────────────────────────
            _CalcButton(onPressed: _onCalculate),

            // ── Breakdown ─────────────────────────────────────────────────
            if (_hasCalculated) ...[
              const SizedBox(height: 44),
              _BreakdownSection(
                key: _breakdownKey,
                loanAmount: _loanAmount,
                totalInterest: _totalInterest,
                totalPayment: _totalPayment,
                monthlyPayment: _monthlyPayment,
                termMonths: _termMonths,
                annualRate: _annualRate,
                animation: _donutAnimation,
                fmt: _fmt,
                fmtWhole: _fmtWhole,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Section Label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Color(0xFF6B7280),
        letterSpacing: 0.2,
      ),
    );
  }
}

// ── Back Button ──────────────────────────────────────────────────────────────
class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: GestureDetector(
        onTap: () => Navigator.maybePop(context),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 14,
            color: Color(0xFF111827),
          ),
        ),
      ),
    );
  }
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

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focused ? const Color(0xFFFF6B35) : const Color(0xFFE5E7EB),
          width: _focused ? 1.5 : 1,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: const Text(
              'MUR',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF6B35),
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(
            child: Focus(
              onFocusChange: (f) => setState(() => _focused = f),
              child: TextField(
                controller: widget.controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                  letterSpacing: -0.5,
                ),
                decoration: const InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(
                    color: Color(0xFFD1D5DB),
                    fontWeight: FontWeight.w500,
                  ),
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

// ── Slider Field ──────────────────────────────────────────────────────────────
class _SliderField extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayLabel;
  final String minLabel;
  final String maxLabel;
  final ValueChanged<double> onChanged;

  const _SliderField({
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayLabel,
    required this.minLabel,
    required this.maxLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayLabel,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: const Color(0xFFFF6B35),
              inactiveTrackColor: const Color(0xFFE5E7EB),
              thumbColor: Colors.white,
              thumbShape: const _CustomThumb(),
              overlayColor: const Color(0xFFFF6B35).withOpacity(0.1),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 18),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(minLabel,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF9CA3AF))),
              Text(maxLabel,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF9CA3AF))),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomThumb extends SliderComponentShape {
  const _CustomThumb();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(22, 22);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(
      center,
      11,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      center,
      11,
      Paint()
        ..color = const Color(0xFFFF6B35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      center,
      5,
      Paint()..color = const Color(0xFFFF6B35),
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
          backgroundColor: const Color(0xFFFF6B35),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
        child: const Text('Calculate'),
      ),
    );
  }
}

// ── Breakdown Section ─────────────────────────────────────────────────────────
class _BreakdownSection extends StatelessWidget {
  final double loanAmount;
  final double totalInterest;
  final double totalPayment;
  final double monthlyPayment;
  final int termMonths;
  final double annualRate;
  final Animation<double> animation;
  final String Function(double) fmt;
  final String Function(double) fmtWhole;

  const _BreakdownSection({
    super.key,
    required this.loanAmount,
    required this.totalInterest,
    required this.totalPayment,
    required this.monthlyPayment,
    required this.termMonths,
    required this.annualRate,
    required this.animation,
    required this.fmt,
    required this.fmtWhole,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Breakdown',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
                letterSpacing: -0.5,
              ),
            ),

          ],
        ),
        const SizedBox(height: 24),

        // Donut
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: animation,
                builder: (_, __) => CustomPaint(
                  size: const Size(200, 200),
                  painter: _DonutPainter(
                    principal: loanAmount,
                    interest: totalInterest,
                    progress: animation.value,
                  ),
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Total Payable',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fmtWhole(totalPayment),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendItem(
                    color: const Color(0xFFFF6B35),
                    label: 'Loan Amount',
                    value: fmtWhole(loanAmount),
                  ),
                  const SizedBox(width: 24),
                  _LegendItem(
                    color: const Color(0xFF0BB8A0),
                    label: 'Total Interest',
                    value: fmtWhole(totalInterest),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Summary grid
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
                child: _SummaryRow(
                  items: [
                    _SummaryItem(
                        label: 'Loan Amount',
                        value: 'MUR ${fmtWhole(loanAmount)}'),
                    _SummaryItem(
                        label: 'Loan Term',
                        value: '$termMonths Months'),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: _SummaryRow(
                  items: [
                    _SummaryItem(
                        label: 'Interest Rate',
                        value: '${annualRate.toStringAsFixed(1)}%'),
                    _SummaryItem(
                        label: 'Monthly Payment',
                        value: fmt(monthlyPayment)),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: _SummaryRow(
                  items: [
                    _SummaryItem(
                        label: 'Total Interest',
                        value: 'MUR ${fmtWhole(totalInterest)}'),
                    _SummaryItem(
                        label: 'Loan Payable',
                        value: 'MUR ${fmtWhole(totalPayment)}'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Disclaimer
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
              Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF9CA3AF)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Estimate only. Final loan terms, fees, and rates are subject to lender assessment.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Donut Painter ─────────────────────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  final double principal;
  final double interest;
  final double progress;

  _DonutPainter({
    required this.principal,
    required this.interest,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 18;
    const strokeWidth = 20.0;
    final rect =
        Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    const startAngle = -pi / 2;
    const fullCircle = 2 * pi;

    final total = principal + interest;
    final principalSweep = (principal / total) * fullCircle * progress;
    final interestSweep = (interest / total) * fullCircle * progress;

    // Track
    canvas.drawArc(
      rect,
      0,
      fullCircle,
      false,
      Paint()
        ..color = const Color(0xFFEEEEEE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Principal arc
    canvas.drawArc(
      rect,
      startAngle,
      principalSweep,
      false,
      Paint()
        ..color = const Color(0xFFFF6B35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Interest arc
    canvas.drawArc(
      rect,
      startAngle + principalSweep,
      interestSweep,
      false,
      Paint()
        ..color = const Color(0xFF0BB8A0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress ||
      old.principal != principal ||
      old.interest != interest;
}

// ── Legend Item ───────────────────────────────────────────────────────────────
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11.5, color: Color(0xFF9CA3AF))),
            Text(value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                )),
          ],
        ),
      ],
    );
  }
}

// ── Summary Row ───────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final List<_SummaryItem> items;
  const _SummaryRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items
          .map((item) => Expanded(child: item))
          .toList(),
    );
  }
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
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF9CA3AF))),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
              letterSpacing: -0.4,
            )),
      ],
    );
  }
}