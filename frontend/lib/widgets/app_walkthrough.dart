import 'package:flutter/material.dart';
import 'package:fintech/services/walkthrough_service.dart';

enum WalkthroughTooltipPosition { above, below }

class WalkthroughStep {
  const WalkthroughStep({
    required this.targetKey,
    required this.title,
    required this.message,
    this.position = WalkthroughTooltipPosition.below,
    this.beforeShow,
  });

  final GlobalKey targetKey;
  final String title;
  final String message;
  final WalkthroughTooltipPosition position;
  final Future<void> Function()? beforeShow;
}

class AppWalkthrough {
  AppWalkthrough._();

  static Future<void> show(
    BuildContext context, {
    required String tourId,
    required List<WalkthroughStep> steps,
  }) async {
    if (steps.isEmpty) return;
    if (await WalkthroughService.hasCompleted(tourId)) return;
    if (!context.mounted) return;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, __) {
        return _WalkthroughOverlay(
          tourId: tourId,
          steps: steps,
        );
      },
    );
  }
}

class _WalkthroughOverlay extends StatefulWidget {
  const _WalkthroughOverlay({
    required this.tourId,
    required this.steps,
  });

  final String tourId;
  final List<WalkthroughStep> steps;

  @override
  State<_WalkthroughOverlay> createState() => _WalkthroughOverlayState();
}

class _WalkthroughOverlayState extends State<_WalkthroughOverlay>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  Rect? _hole;
  bool _isBusy = false;
  bool _stepReady = false;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshHole());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  WalkthroughStep get _step => widget.steps[_index];

  Future<void> _refreshHole() async {
    final willTransition = _step.beforeShow != null;
    setState(() {
      _stepReady = false;
      if (willTransition) _hole = null;
    });

    if (willTransition) {
      await _step.beforeShow!();
      if (!mounted) return;
      await WidgetsBinding.instance.endOfFrame;
    }
    if (!mounted) return;

    final isNavStep = _step.position == WalkthroughTooltipPosition.above;
    if (!isNavStep) {
      final targetContext = _step.targetKey.currentContext;
      if (targetContext != null) {
        await Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: 0.2,
        );
        if (!mounted) return;
        await WidgetsBinding.instance.endOfFrame;
      }
    }

    Rect? rect;
    for (var attempt = 0; attempt < 4; attempt++) {
      rect = _targetRect(_step.targetKey);
      if (rect != null) break;
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    if (!mounted) return;
    setState(() {
      _hole = rect ?? _fallbackRect(context);
      _stepReady = true;
    });
  }

  Rect? _fallbackRect(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (_step.position == WalkthroughTooltipPosition.above) {
      return Rect.fromLTWH(
        size.width * 0.2,
        size.height - 120,
        size.width * 0.6,
        56,
      );
    }
    return Rect.fromLTWH(24, size.height * 0.28, size.width - 48, 120);
  }

  Rect? _targetRect(GlobalKey key) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    final offset = renderBox.localToGlobal(Offset.zero);
    return offset & renderBox.size;
  }

  Future<void> _next() async {
    if (_isBusy) return;
    _isBusy = true;
    try {
      if (_index >= widget.steps.length - 1) {
        await WalkthroughService.markCompleted(widget.tourId);
        if (mounted) Navigator.of(context).pop();
        return;
      }
      setState(() => _index++);
      await _refreshHole();
    } finally {
      _isBusy = false;
    }
  }

  Future<void> _skip() async {
    if (_isBusy) return;
    _isBusy = true;
    try {
      await WalkthroughService.markCompleted(widget.tourId);
      if (mounted) Navigator.of(context).pop();
    } finally {
      _isBusy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hole = _hole;
    final media = MediaQuery.of(context);
    final isLast = _index >= widget.steps.length - 1;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _SpotlightPainter(
                    hole: hole,
                    pulse: 0.5 + (_pulseController.value * 0.5),
                    dimColor: isDark
                        ? const Color(0xCC0F1020)
                        : const Color(0xB3000000),
                  ),
                );
              },
            ),
          ),
          if (hole != null)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              left: hole.left - 4,
              top: hole.top - 4,
              width: hole.width + 8,
              height: hole.height + 8,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF7EB6FF).withValues(
                            alpha: 0.35 + _pulseController.value * 0.45,
                          ),
                          width: 2.5,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            left: 20,
            right: 20,
            top: _tooltipTop(
              hole,
              screenHeight: media.size.height,
              safeTop: media.padding.top,
              safeBottom: media.padding.bottom,
            ),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: _stepReady ? 1 : 0,
              child: _CuteTooltipCard(
                title: _step.title,
                message: _step.message,
                stepIndex: _index,
                stepCount: widget.steps.length,
                isLast: isLast,
                isDark: isDark,
                isBusy: _isBusy,
                onSkip: _skip,
                onNext: _next,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _tooltipTop(
    Rect? hole, {
    required double screenHeight,
    required double safeTop,
    required double safeBottom,
  }) {
    if (hole == null) return screenHeight * 0.32;

    const cardHeight = 200.0;
    const gap = 16.0;
    const navReserve = 88.0;
    final minTop = safeTop + 12;
    final maxTop = screenHeight - cardHeight - navReserve - safeBottom;

    double clampTop(double value) => value.clamp(minTop, maxTop);

    if (_step.position == WalkthroughTooltipPosition.above) {
      return clampTop(hole.top - cardHeight - gap);
    }

    // Tall highlights: sit just under the top edge, not flush to screen top.
    if (hole.height > screenHeight * 0.38) {
      return clampTop(hole.top + gap);
    }

    final below = hole.bottom + gap;
    if (below <= maxTop) {
      return clampTop(below);
    }

    final above = hole.top - cardHeight - gap;
    if (above >= minTop) {
      return clampTop(above);
    }

    return clampTop(maxTop);
  }
}

class _CuteTooltipCard extends StatelessWidget {
  const _CuteTooltipCard({
    required this.title,
    required this.message,
    required this.stepIndex,
    required this.stepCount,
    required this.isLast,
    required this.isDark,
    required this.isBusy,
    required this.onSkip,
    required this.onNext,
  });

  final String title;
  final String message;
  final int stepIndex;
  final int stepCount;
  final bool isLast;
  final bool isDark;
  final bool isBusy;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1D33) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF2F3358) : const Color(0xFFE8EEFF),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22007AFF),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF111827),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: isDark ? const Color(0xFFAAB0C6) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < stepCount; i++)
                Container(
                  width: i == stepIndex ? 18 : 7,
                  height: 7,
                  margin: EdgeInsets.only(right: i == stepCount - 1 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: i == stepIndex
                        ? const Color(0xFF007AFF)
                        : const Color(0xFF007AFF).withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              const Spacer(),
              TextButton(
                onPressed: isBusy ? null : onSkip,
                style: TextButton.styleFrom(
                  foregroundColor:
                      isDark ? const Color(0xFF939BB6) : const Color(0xFF9CA3AF),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text('Skip'),
              ),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: isBusy ? null : onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(isLast ? 'Got it' : 'Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.hole,
    required this.pulse,
    required this.dimColor,
  });

  final Rect? hole;
  final double pulse;
  final Color dimColor;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Path()..addRect(Offset.zero & size);

    if (hole != null) {
      final expanded = hole!.inflate(6 * pulse);
      final roundedHole = RRect.fromRectAndRadius(
        expanded,
        const Radius.circular(18),
      );
      overlay.addRRect(roundedHole);
      overlay.fillType = PathFillType.evenOdd;
    }

    canvas.drawPath(overlay, Paint()..color = dimColor);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.hole != hole ||
        oldDelegate.pulse != pulse ||
        oldDelegate.dimColor != dimColor;
  }
}
