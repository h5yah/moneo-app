import 'package:flutter/material.dart';
import 'package:fintech/services/xp_service.dart';

class QuickScenarioStep {
  final String prompt;
  final List<String> options;
  final int bestOptionIndex;
  final String feedback;

  const QuickScenarioStep({
    required this.prompt,
    required this.options,
    required this.bestOptionIndex,
    required this.feedback,
  });
}

class QuickScenarioScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<QuickScenarioStep> steps;
  final String completionMessage;
  final int xpAward;
  final String xpAwardKey;
  final String xpSource;
  final Color accentColor;

  const QuickScenarioScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.steps,
    required this.completionMessage,
    required this.xpAward,
    required this.xpAwardKey,
    this.xpSource = 'interactive_scenario',
    this.accentColor = const Color(0xFF2563EB),
  });

  @override
  State<QuickScenarioScreen> createState() => _QuickScenarioScreenState();
}

class _QuickScenarioScreenState extends State<QuickScenarioScreen> {
  int _stepIndex = 0;
  int _score = 0;
  int? _selectedIndex;
  bool _xpAwardPending = false;
  bool _xpAwardAttempted = false;
  XpEarnResult? _xpResult;
  String? _xpError;

  QuickScenarioStep get _currentStep => widget.steps[_stepIndex];
  bool get _isLastStep => _stepIndex == widget.steps.length - 1;

  void _selectOption(int index) {
    if (_selectedIndex != null) return;
    setState(() {
      _selectedIndex = index;
      if (index == _currentStep.bestOptionIndex) {
        _score++;
      }
    });
  }

  Future<void> _continue() async {
    if (_selectedIndex == null) return;
    if (_isLastStep) {
      setState(() => _stepIndex = widget.steps.length);
      await _awardCompletionXp();
      return;
    }
    setState(() {
      _stepIndex++;
      _selectedIndex = null;
    });
  }

  Future<void> _awardCompletionXp() async {
    if (_xpAwardAttempted || widget.xpAward <= 0) return;
    setState(() {
      _xpAwardAttempted = true;
      _xpAwardPending = true;
      _xpError = null;
    });

    try {
      final result = await XpService.instance.earnXpOnce(
        amount: widget.xpAward,
        source: widget.xpSource,
        awardKey: widget.xpAwardKey,
      );
      if (!mounted) return;
      setState(() {
        _xpResult = result;
        _xpAwardPending = false;
      });
    } catch (error) {
      debugPrint('Quick scenario XP award failed: $error');
      if (!mounted) return;
      setState(() {
        _xpError = 'XP could not be added right now.';
        _xpAwardPending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completed = _stepIndex >= widget.steps.length;
    final progress = completed
        ? 1.0
        : ((_stepIndex + (_selectedIndex == null ? 0 : 1)) /
                widget.steps.length)
            .clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1020) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: isDark
                      ? const Color(0xFF272A45)
                      : const Color(0xFFE8EEF8),
                  valueColor: AlwaysStoppedAnimation<Color>(widget.accentColor),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: completed
                    ? _buildCompletionState(isDark)
                    : _buildQuestionState(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionState(bool isDark) {
    final step = _currentStep;
    final mutedText =
        isDark ? const Color(0xFFAAB0C6) : Colors.black.withValues(alpha: 0.62);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step ${_stepIndex + 1} of ${widget.steps.length}',
          style: TextStyle(
            color: widget.accentColor,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          step.prompt,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 25,
            fontWeight: FontWeight.w800,
            height: 1.12,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.subtitle,
          style: TextStyle(
            color: mutedText,
            fontSize: 15,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 24),
        for (int i = 0; i < step.options.length; i++) ...[
          _buildOptionCard(
            label: step.options[i],
            index: i,
            isDark: isDark,
          ),
          if (i < step.options.length - 1) const SizedBox(height: 12),
        ],
        const Spacer(),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _selectedIndex == null
              ? const SizedBox.shrink()
              : _buildFeedbackPanel(isDark),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _selectedIndex == null ? null : _continue,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.accentColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  isDark ? const Color(0xFF2A2D4A) : const Color(0xFFE2E8F0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              _isLastStep ? 'See result' : 'Continue',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required String label,
    required int index,
    required bool isDark,
  }) {
    final selected = _selectedIndex == index;
    final answered = _selectedIndex != null;
    final isBest = index == _currentStep.bestOptionIndex;
    final borderColor = selected
        ? widget.accentColor
        : isDark
            ? const Color(0xFF2A2D4A)
            : const Color(0xFFE2E8F0);
    final fillColor = selected
        ? widget.accentColor.withValues(alpha: isDark ? 0.2 : 0.1)
        : isDark
            ? const Color(0xFF1B1D33)
            : Colors.white;

    return InkWell(
      onTap: () => _selectOption(index),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: selected ? 1.6 : 1),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.24,
                ),
              ),
            ),
            if (answered && isBest)
              Icon(Icons.check_circle_rounded, color: widget.accentColor)
            else
              Icon(
                Icons.chevron_right_rounded,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.45)
                    : Colors.black.withValues(alpha: 0.32),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackPanel(bool isDark) {
    final selectedBest = _selectedIndex == _currentStep.bestOptionIndex;
    return Container(
      key: ValueKey(_stepIndex),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selectedBest
            ? widget.accentColor.withValues(alpha: isDark ? 0.22 : 0.1)
            : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selectedBest
              ? widget.accentColor.withValues(alpha: 0.35)
              : const Color(0xFFFBBF24).withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        _currentStep.feedback,
        style: TextStyle(
          color: selectedBest
              ? (isDark ? Colors.white : const Color(0xFF1E3A8A))
              : const Color(0xFF92400E),
          fontSize: 14,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCompletionState(bool isDark) {
    final scorePercent = (_score / widget.steps.length * 100).round();
    final textColor = isDark ? Colors.white : Colors.black;
    final mutedText =
        isDark ? const Color(0xFFAAB0C6) : Colors.black.withValues(alpha: 0.62);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: widget.accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              color: widget.accentColor,
              size: 46,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Scenario Complete',
            style: TextStyle(
              color: textColor,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.completionMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: mutedText,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '$scorePercent% smart choices',
            style: TextStyle(
              color: widget.accentColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (widget.xpAward > 0) ...[
            const SizedBox(height: 8),
            Text(
              _xpStatusText,
              style: TextStyle(
                color: _xpError == null
                    ? widget.accentColor
                    : const Color(0xFFDC2626),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _xpStatusText {
    if (_xpAwardPending) return 'Adding ${widget.xpAward} XP...';
    if (_xpError != null) return _xpError!;
    if (_xpResult?.awarded == true) return '+${widget.xpAward} XP added';
    if (_xpResult?.awarded == false) return 'XP already claimed';
    return '${widget.xpAward} XP reward';
  }
}
