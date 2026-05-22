import 'package:flutter/material.dart';
import 'package:fintech/services/topic_progress_service.dart';
import 'package:fintech/services/lesson_tts_service.dart';

class LessonContentScreen extends StatefulWidget {
  final String lessonTitle;
  final int lessonProgress;
  final String? topicId;

  const LessonContentScreen({
    super.key,
    required this.lessonTitle,
    required this.lessonProgress,
    this.topicId,
  });

  @override
  State<LessonContentScreen> createState() => _LessonContentScreenState();
}

class _LessonContentScreenState extends State<LessonContentScreen> {
  _LessonContent? _content;
  bool _showCards = false;
  bool _hasSwipedTopicIntro = false;
  bool _didPersistInitialStepProgress = false;
  int _topicIntroIndex = 0;
  final PageController _topicIntroController = PageController();
  final TextEditingController _challengeController = TextEditingController();

  final LessonTtsService _lessonTts = LessonTtsService.instance;
  bool _isSpeaking = false;

  static const Map<String, String> _lessonTitleAliases = {
    'debt is "renting" money': 'Understanding Debt: The Mechanics of Borrowing',
    'lesson 1 — understanding debt: the mechanics of borrowing': 'Understanding Debt: The Mechanics of Borrowing',
    'the "pay later" illusion': 'The "Pay Later" Illusion (Digital Debt)',
    'lesson 2 — the "pay later" illusion': 'The "Pay Later" Illusion (Digital Debt)',
    'the "minimum payment" trap': 'The Minimum Payment Trap',
    'lesson 3 — the minimum payment trap': 'The Minimum Payment Trap',
    'your financial "reputation" (credit score)': 'Your Financial "Grade" (The MCIB)',
    'lesson 4 — your financial "grade" (the mcib)': 'Your Financial "Grade" (The MCIB)',
    'how to get out of a debt hole': 'Escaping the Debt Hole: The Exit Strategy',
    'lesson 5 — escaping the debt hole: the exit strategy': 'Escaping the Debt Hole: The Exit Strategy',
    'lesson 1 — short-term vs. long-term goals': 'Short-Term vs. Long-Term Goals',
    'lesson 2 — estimating future costs & the 10% buffer': 'Estimating Future Costs & The 10% Buffer',
    'lesson 3 — creating a financial plan (s.m.a.r.t. goals)': 'Creating a Financial Plan (S.M.A.R.T. Goals)',
    'lesson 4 — tracking progress toward goals': 'Tracking Progress Toward Goals',
  };

  _LessonContent? _resolveContent() {
    final direct = _lessonContentByTitle[widget.lessonTitle];
    if (direct != null) return direct;

    final requestedKey = _normalizeLessonKey(widget.lessonTitle);
    for (final entry in _lessonContentByTitle.entries) {
      if (_normalizeLessonKey(entry.key) == requestedKey) return entry.value;
    }

    final canonicalTitle = _lessonTitleAliases[requestedKey];
    if (canonicalTitle != null) {
      final aliased = _lessonContentByTitle[canonicalTitle];
      if (aliased != null) return aliased;
    }

    return null;
  }

  String _normalizeLessonKey(String value) {
    return value
        .toLowerCase()
        .replaceAll('\u2019', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  void initState() {
    super.initState();
    _content = _resolveContent();
    _challengeController.text = '';
    _triggerCardEntrance();
    _initTts();
  }

  @override
  void didUpdateWidget(covariant LessonContentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lessonTitle != widget.lessonTitle) {
      _content = _resolveContent();
      _topicIntroIndex = 0;
      _hasSwipedTopicIntro = false;
      _didPersistInitialStepProgress = false;
      _stopTts();
      if (_topicIntroController.hasClients) {
        _topicIntroController.jumpToPage(0);
      }
      _challengeController.text = '';
      _showCards = false;
      _triggerCardEntrance();
    }
  }

  Future<void> _initTts() async {
    _lessonTts.bindHandlers(
      onStart: () {
        if (!mounted) return;
        setState(() => _isSpeaking = true);
      },
      onStop: () {
        if (!mounted) return;
        setState(() => _isSpeaking = false);
      },
      onError: (message) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not play audio: $message')),
        );
      },
    );
    await _lessonTts.ensureReady();
    if (mounted) setState(() {});
  }

  Future<void> _stopTts() async {
    await _lessonTts.stop();
    if (mounted) setState(() => _isSpeaking = false);
  }

  String _plainTextForTts(String text) {
    return text.replaceAll('**', '').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _ttsTextForTopicStep(_TopicIntroStep step) {
    final buf = StringBuffer();
    buf.writeln(_plainTextForTts(step.title));
    buf.writeln();
    buf.writeln(step.body.replaceAll('**', ''));
    if ((step.reflectionTitle ?? '').trim().isNotEmpty) {
      buf.writeln();
      buf.writeln(step.reflectionTitle!.trim());
    }
    if ((step.reflectionPrompt ?? '').trim().isNotEmpty) {
      buf.writeln(step.reflectionPrompt!.trim());
    }
    for (final b in step.reflectionBullets) {
      final t = b.trim();
      if (t.isNotEmpty) buf.writeln('- $t');
    }
    if ((step.reflectionNote ?? '').trim().isNotEmpty) {
      buf.writeln();
      buf.writeln(step.reflectionNote!.trim());
    }
    return buf.toString().trim();
  }

  Future<void> _toggleSpeakTopicStep(_TopicIntroStep step) async {
    if (_isSpeaking || _lessonTts.isSpeaking) {
      await _stopTts();
      return;
    }

    final text = _ttsTextForTopicStep(step);
    final error = await _lessonTts.speak(text);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.contains('Check')
                ? error
                : '$error\n\nTip: Turn up volume and turn off Silent mode (iPhone).',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _lessonTts.stop();
    _topicIntroController.dispose();
    _challengeController.dispose();
    super.dispose();
  }

  void _triggerCardEntrance() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _showCards = true);
    });
  }

  Future<void> _saveStepProgress({
    required int currentStep,
    required int totalSteps,
  }) async {
    final topicId = widget.topicId;
    if (topicId == null || topicId.isEmpty) return;
    await TopicProgressService.instance.saveLessonStepProgress(
      topicId: topicId,
      lessonNumber: widget.lessonProgress,
      currentStep: currentStep,
      totalSteps: totalSteps,
    );
  }

  Widget _animateCard(Widget child) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      offset: _showCards ? Offset.zero : const Offset(0, 0.02),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        opacity: _showCards ? 1 : 0,
        child: child,
      ),
    );
  }

  @override
  void reassemble() {
    super.reassemble();
    _content = _resolveContent();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1020) : const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF17192B) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.lessonTitle,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black),
        ),
      ),
      body: Column(
        children: [
          _buildLessonProgressSection(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLessonBody(),
                  _buildTrustedSourcesCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _premiumCardDecoration({Color backgroundColor = Colors.white, Color? borderColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? const Color(0xFF1B1D33) : backgroundColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark ? const Color(0xFF2A2D4A) : (borderColor ?? const Color(0xFF007AFF).withValues(alpha: 0.10)),
        width: 1,
      ),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), offset: const Offset(0, 6), blurRadius: 14)],
    );
  }

  Widget _buildLessonProgressSection() {
    const int totalLessons = 6;
    final int current = widget.lessonProgress.clamp(1, totalLessons);
    final double value = current / totalLessons;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF007AFF).withValues(alpha: 0.12)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), offset: const Offset(0, 8), blurRadius: 18)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Topic Progress', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFF007AFF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
                child: Text('Lesson $current of $totalLessons', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF007AFF))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: value, minHeight: 10, backgroundColor: const Color(0xFFE8EEF7), valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF007AFF))),
          ),
        ],
      ),
    );
  }

  Widget _buildConceptCards() {
    if (_content == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _premiumCardDecoration(),
      child: Row(
        children: [
          _ConceptCard(content: _content!.cards[0], accent: const Color(0xFF007AFF)),
          Container(width: 1, height: 120, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 16)),
          _ConceptCard(content: _content!.cards[1], accent: const Color(0xFFFF6B35)),
        ],
      ),
    );
  }

  Widget _buildLessonBody() {
    if (_content == null) return const SizedBox.shrink();
    switch (_content!.layout ?? _LessonLayout.cardsComparison) {
      case _LessonLayout.topicIntroPremium:
        return _buildTopicIntroPremiumBody();
      case _LessonLayout.cardsComparison:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _animateCard(_buildConceptCards()),
            const SizedBox(height: 24),
            _animateCard(_buildConceptComparison()),
            if (_content!.showDeepDive) ...[
              const SizedBox(height: 20),
              _animateCard(_buildDeepDiveCard()),
              const SizedBox(height: 32),
            ] else const SizedBox(height: 24),
            _animateCard(_buildKeyTakeawayCard()),
            const SizedBox(height: 24),
          ],
        );
      case _LessonLayout.checklist:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _animateCard(_buildChecklistCard()),
            if (_content!.showDeepDive) ...[const SizedBox(height: 20), _animateCard(_buildDeepDiveCard()), const SizedBox(height: 20)],
            _animateCard(_buildKeyTakeawayCard()),
            const SizedBox(height: 24),
          ],
        );
      case _LessonLayout.steps:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _animateCard(_buildStepsCard()),
            if (_content!.showDeepDive) ...[const SizedBox(height: 20), _animateCard(_buildDeepDiveCard()), const SizedBox(height: 20)],
            _animateCard(_buildKeyTakeawayCard()),
            const SizedBox(height: 24),
          ],
        );
      case _LessonLayout.ruleSplit:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _animateCard(_buildRuleSplitCard()),
            if (_content!.showDeepDive) ...[const SizedBox(height: 20), _animateCard(_buildDeepDiveCard()), const SizedBox(height: 20)],
            _animateCard(_buildKeyTakeawayCard()),
            const SizedBox(height: 24),
          ],
        );
      case _LessonLayout.tracker:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _animateCard(_buildTrackerCard()),
            if (_content!.showDeepDive) ...[const SizedBox(height: 20), _animateCard(_buildDeepDiveCard()), const SizedBox(height: 20)],
            _animateCard(_buildKeyTakeawayCard()),
            const SizedBox(height: 24),
          ],
        );
      case _LessonLayout.tips:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _animateCard(_buildTipsCard()),
            if (_content!.showDeepDive) ...[const SizedBox(height: 20), _animateCard(_buildDeepDiveCard()), const SizedBox(height: 20)],
            _animateCard(_buildKeyTakeawayCard()),
            const SizedBox(height: 24),
          ],
        );
    }
  }

  Widget _buildTopicIntroPremiumBody() {
    final width = MediaQuery.sizeOf(context).width;
    final isNarrowPhone = width < 380;
    final bodyFontSize = isNarrowPhone ? 15.8 : 17.0;

    final steps = _topicIntroStepsForTitle(_content?.heading ?? '');
    final palette = _topicIntroPaletteForTitle(_content?.heading ?? '');

    if (!_didPersistInitialStepProgress) {
      _didPersistInitialStepProgress = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _saveStepProgress(currentStep: _topicIntroIndex + 1, totalSteps: steps.length);
      });
    }

    final isLastStep = _topicIntroIndex == steps.length - 1;
    final stepCardColors = palette.cardColors;
    final stepAccentColors = palette.accentColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _animateCard(
          SizedBox(
            height: 560,
            child: PageView.builder(
              controller: _topicIntroController,
              itemCount: steps.length,
              onPageChanged: (index) {
                setState(() {
                  _topicIntroIndex = index;
                  if (index > 0) _hasSwipedTopicIntro = true;
                });
                _stopTts();
                _saveStepProgress(currentStep: index + 1, totalSteps: steps.length);
              },
              itemBuilder: (context, index) {
                final step = steps[index];
                final cardColor = stepCardColors[index % stepCardColors.length];
                final accentColor = stepAccentColors[index % stepAccentColors.length];
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), offset: const Offset(0, 6), blurRadius: 14)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: accentColor.withValues(alpha: 0.28)),
                            ),
                            child: Text('Step ${index + 1} of ${steps.length}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: accentColor)),
                          ),
                          IconButton(
                            tooltip: _isSpeaking ? 'Stop' : 'Listen',
                            onPressed: () => _toggleSpeakTopicStep(step),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.7),
                              foregroundColor: accentColor,
                              padding: const EdgeInsets.all(10),
                            ),
                            icon: Icon(
                              _isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(step.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                      if (index == 0 && !_hasSwipedTopicIntro) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.swipe_rounded, size: 14, color: accentColor.withValues(alpha: 0.85)),
                            const SizedBox(width: 6),
                            Text('Swipe to continue', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: accentColor.withValues(alpha: 0.9))),
                          ],
                        ),
                      ],
                      const SizedBox(height: 18),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStepBodyText(step.body, bodyFontSize),
                              if (step.reflectionTitle != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: accentColor.withValues(alpha: 0.22)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(step.reflectionTitle!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                                      if (step.reflectionPrompt != null) ...[
                                        const SizedBox(height: 8),
                                        Text(step.reflectionPrompt!, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                                      ],
                                      if (step.reflectionBullets.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        ...step.reflectionBullets.map(
                                          (bullet) => Padding(
                                            padding: const EdgeInsets.only(bottom: 6),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 2),
                                                  child: Icon(Icons.circle, size: 7, color: accentColor),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(child: Text(bullet, style: const TextStyle(fontSize: 13.5, height: 1.35, color: Color(0xFF1F2937)))),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (step.reflectionNote != null) ...[
                                        const SizedBox(height: 6),
                                        Text(step.reflectionNote!, style: const TextStyle(fontSize: 12.8, height: 1.35, color: Color(0xFF475569))),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < steps.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _topicIntroIndex == i ? 18 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _topicIntroIndex == i ? const Color(0xFF007AFF) : const Color(0xFFD0D5DD),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
          ],
        ),
        if (isLastStep) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (!mounted) return;
                await _saveStepProgress(currentStep: steps.length, totalSteps: steps.length);
                if (!mounted) return;
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Done', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
        const SizedBox(height: 18),
      ],
    );
  }

  _TopicIntroPalette _topicIntroPaletteForTitle(String lessonTitle) {
    if (lessonTitle == 'Understanding Income') {
      return const _TopicIntroPalette(
        cardColors: [Color(0xFFFFF4D9), Color(0xFFE8F8EF), Color(0xFFEAF0FF), Color(0xFFFFEBDD), Color(0xFFE7F7F3)],
        accentColors: [Color(0xFF9A6700), Color(0xFF0F766E), Color(0xFF4338CA), Color(0xFFB45309), Color(0xFF0F766E)],
      );
    }
    if (lessonTitle == 'Introduction to Investing') {
      return const _TopicIntroPalette(
        cardColors: [Color(0xFFEAF0FF), Color(0xFFE8F8EF), Color(0xFFFFF4D9), Color(0xFFFFEBDD), Color(0xFFEAF0FF), Color(0xFFE8F8EF)],
        accentColors: [Color(0xFF4338CA), Color(0xFF0F766E), Color(0xFF9A6700), Color(0xFFB45309), Color(0xFF4338CA), Color(0xFF0F766E)],
      );
    }
    if (lessonTitle == 'Introduction to Taxes') {
      return const _TopicIntroPalette(
        cardColors: [Color(0xFFFFF4D9), Color(0xFFEAF0FF), Color(0xFFE8F8EF), Color(0xFFFFEBDD), Color(0xFFEAF0FF), Color(0xFFFFF4D9)],
        accentColors: [Color(0xFF9A6700), Color(0xFF4338CA), Color(0xFF0F766E), Color(0xFFB45309), Color(0xFF4338CA), Color(0xFF9A6700)],
      );
    }
    if (lessonTitle == 'Introduction to Retirement Planning') {
      return const _TopicIntroPalette(
        cardColors: [Color(0xFFE8F8EF), Color(0xFFEAF0FF), Color(0xFFFFF4D9), Color(0xFFFFEBDD), Color(0xFFE8F8EF), Color(0xFFEAF0FF)],
        accentColors: [Color(0xFF0F766E), Color(0xFF4338CA), Color(0xFF9A6700), Color(0xFFB45309), Color(0xFF0F766E), Color(0xFF4338CA)],
      );
    }
    if (lessonTitle == 'Protecting from Fraud & Scams') {
      return const _TopicIntroPalette(
        cardColors: [Color(0xFFFFEBDD), Color(0xFFFFF4D9), Color(0xFFEAF0FF), Color(0xFFE8F8EF), Color(0xFFFFEBDD), Color(0xFFFFF4D9)],
        accentColors: [Color(0xFFB45309), Color(0xFF9A6700), Color(0xFF4338CA), Color(0xFF0F766E), Color(0xFFB45309), Color(0xFF9A6700)],
      );
    }
    return const _TopicIntroPalette(
      cardColors: [Color(0xFFF1E3B0), Color(0xFFDDF1E8), Color(0xFFE5E9FF), Color(0xFFFFE8D6), Color(0xFFE7F5F4)],
      accentColors: [Color(0xFF8A5B00), Color(0xFF0F766E), Color(0xFF4F46E5), Color(0xFFB45309), Color(0xFF0F766E)],
    );
  }

  Widget _buildStepBodyText(String text, double fontSize) {
    final baseStyle = TextStyle(fontSize: fontSize, height: 1.48, color: const Color(0xFF1F2937));
    final emphasisPattern = RegExp(r'(\*\*.*?\*\*)');
    final parts = text.split(emphasisPattern);
    final matches = emphasisPattern.allMatches(text).toList();
    final spans = <TextSpan>[];
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) spans.add(TextSpan(text: parts[i], style: baseStyle));
      if (i < matches.length) {
        final boldRaw = matches[i].group(0)!;
        final boldText = boldRaw.substring(2, boldRaw.length - 2);
        spans.add(TextSpan(text: boldText, style: baseStyle.copyWith(fontWeight: FontWeight.w800)));
      }
    }
    return RichText(text: TextSpan(children: spans));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ALL TOPIC INTRO STEPS
  // ─────────────────────────────────────────────────────────────────────────
  List<_TopicIntroStep> _topicIntroStepsForTitle(String lessonTitle) {

    // ── BUDGETING & EXPENSE TRACKING ──────────────────────────────────────

    if (lessonTitle == 'Introduction to Budgeting') {
      return const [
        _TopicIntroStep(
          title: 'Where does the money go?',
          body: 'Ask most people where their money went last month and they genuinely cannot tell you. Not because they were careless but because spending happens in small decisions, spread across the whole month, and no single one feels significant enough to remember.\n\nA budget fixes that. It is simply a plan you make before you spend, so you are not guessing at the end of the month.',
        ),
        _TopicIntroStep(
          title: 'What a budget actually is',
          body: 'A budget is not a punishment. It is not a list of things you cannot buy.\n\nIt is just a decision you make once at the start of the month about where your money is going. Housing gets this much. Food gets this much. Savings gets this much. What is left over is yours to enjoy without guilt.\n\nThe goal is not restriction. The goal is intention.',
        ),
        _TopicIntroStep(
          title: 'A simple way to split your money',
          body: 'One of the most practical starting points is the 50/30/20 split.\n\nHalf your income covers the things you have to pay: rent, food, transport, bills. Thirty percent goes to the things you enjoy: eating out, hobbies, subscriptions. Twenty percent goes to savings and paying off any debt.\n\nIt is not a rule set in stone. But it gives you a starting shape to work from.',
        ),
        _TopicIntroStep(
          title: 'What this looks like in real life',
          body: 'Say you take home MUR 22,000 a month.\n\nUsing 50/30/20, about MUR 11,000 goes to the essentials, i.e, rent, groceries, transport. Around MUR 6,600 is yours to spend on things you enjoy. And MUR 4,400 goes straight to savings before you touch the rest.\n\nEvery rupee has somewhere to go. Nothing is left to disappear on its own.',
        ),
        _TopicIntroStep(
          title: 'The one thing to remember',
          body: 'A budget you never look at does not help you. The point is not to create a perfect spreadsheet, it is to check in regularly and see if your actual spending matches your plan.\n\nWeekly is better than monthly. Ten minutes on a Sunday is enough.',
          reflectionTitle: 'Quick reminder',
          reflectionBullets: [
            'Always work from your net income - what actually arrives in your account',
            'Cover essentials first, savings second, enjoyment third',
            'Check your budget at least once a week',
          ],
          reflectionNote: 'People who plan their spending tend to save more and stress less, even on the same income.',
        ),
      ];
    }

    if (lessonTitle == 'Understanding Income') {
      return const [
        _TopicIntroStep(
          title: 'You earn more than you think you receive',
          body: 'Your salary and your income are not the same number.\n\nYour salary is what your employer agreed to pay you. Your income is what actually arrives in your account — after tax, NPF, NSF, and any other deductions. For most people in Mauritius, those deductions take between 10 and 20 percent off the top.\n\nIf you build your budget from the salary figure, you will overspend every single month without knowing why.',
        ),
        _TopicIntroStep(
          title: 'Gross vs net — the one that matters',
          body: 'Gross income is the big number on your contract. Net income is the smaller number that hits your bank account.\n\nWhen you sit down to plan your finances, only net income is real. The gross figure is irrelevant until you are negotiating a raise.\n\nCheck your payslip. Find the number after all deductions. That is your starting point for every financial decision you make.',
        ),
        _TopicIntroStep(
          title: 'What if your income changes every month?',
          body: 'If you freelance, work on commission, or have multiple income sources, your monthly income will not be the same each time.\n\nThe safest thing to do is build your budget around the lowest amount you reliably earn — not your best month, not your average, but the floor. That way, a slow month does not break you. A good month becomes a bonus.',
        ),
        _TopicIntroStep(
          title: 'An example that makes it concrete',
          body: 'Gross salary: MUR 30,000.\n\nAfter income tax, NPF, and NSF deductions, the amount that lands in your account is closer to MUR 27,750.\n\nIf you plan your life around MUR 30,000, you will be short MUR 2,250 every single month. That gap does not disappear — it quietly becomes debt.',
        ),
        _TopicIntroStep(
          title: 'The habit that changes everything',
          body: 'Look at your payslip every month. Not just the total — the breakdown. Know what was taken, why, and what you actually have to work with.\n\nMost people skip this step. That is exactly why most people are confused about where their money went.',
          reflectionTitle: 'Key point',
          reflectionBullets: [
            'Net income only — never plan from gross',
            'If your income varies, use the lowest amount you reliably earn',
            'Your payslip is the most important document you receive each month',
          ],
          reflectionNote: 'One small habit: read your payslip the same day you receive it.',
        ),
      ];
    }

    if (lessonTitle == 'Classifying Expenses') {
      return const [
        _TopicIntroStep(
          title: 'Not all spending is the same',
          body: 'Some of your expenses are fixed — they show up at the same amount every month no matter what you do. Others change depending on your choices. And some are completely optional.\n\nKnowing which category each expense falls into tells you something important: where you have control and where you do not.',
        ),
        _TopicIntroStep(
          title: 'The expenses you cannot easily change',
          body: 'Fixed expenses are the commitments you have already made. Rent. Loan repayments. Insurance. Your internet plan. Tuition.\n\nThese come out first, before you make any other financial decision. You cannot easily reduce them in the short term, so they need to be respected in your budget — not estimated, not guessed. Written down and planned for.',
        ),
        _TopicIntroStep(
          title: 'Where most of your control actually lives',
          body: 'Variable expenses change based on how you behave. Your grocery bill, transport costs, electricity — all of these respond to your choices.\n\nThen there are discretionary expenses, which are fully optional. Dining out. Subscriptions you barely use. Online shopping. Entertainment.\n\nThis is where budgets are won or lost. Not because these things are bad — but because people consistently underestimate how much they are actually spending here.',
        ),
        _TopicIntroStep(
          title: 'What categorising actually reveals',
          body: 'Imagine you think you spend MUR 15,000 a month on living expenses.\n\nWhen you break it down: rent is MUR 8,000, groceries MUR 3,200, transport MUR 1,400, three forgotten subscriptions MUR 600, takeaway and dining MUR 2,100.\n\nSuddenly the MUR 600 in subscriptions and MUR 2,100 in food delivery are visible. You did not decide to spend that — it just happened. Now you can decide.',
        ),
        _TopicIntroStep(
          title: 'The simple takeaway',
          body: 'You cannot control what you cannot see. Putting your spending into categories takes maybe twenty minutes — and it will show you something about your money you did not know.',
          reflectionTitle: 'How to categorise',
          reflectionBullets: [
            'Fixed: rent, loans, insurance — list these first, always',
            'Variable: groceries, transport — set a weekly limit',
            'Discretionary: dining, shopping — choose these consciously',
          ],
          reflectionNote: 'Most people find 10 to 15 percent of spending they never consciously chose — once they look.',
        ),
      ];
    }

    if (lessonTitle == 'Needs vs Wants') {
      return const [
        _TopicIntroStep(
          title: 'One question that changes how you spend',
          body: 'Before you buy something that is not planned, ask yourself one thing: do I actually need this, or do I just want it right now?\n\nIt sounds simple. But most people skip this step entirely — and that is why money disappears faster than expected.',
        ),
        _TopicIntroStep(
          title: 'What a need actually is',
          body: 'A need is whatever you genuinely require to function — for work, for health, for daily life.\n\nFood is a need. But a meal delivery order every night is not. Transport to work is a need. A taxi when the bus runs fine is not. The distinction is not about what is comfortable — it is about what is necessary at its most basic level.',
        ),
        _TopicIntroStep(
          title: 'Wants are not the enemy',
          body: 'Wants are not bad things. Enjoying your money is part of living a good life.\n\nThe problem is not spending on wants — it is spending on them automatically, without noticing, and then wondering why there is nothing left. A want that you chose consciously and planned for is fine. A want that silently consumed three months of savings is the issue.\n\nMost people underestimate their want spending significantly. Not because they are irresponsible — because small purchases do not feel like spending until you add them up.',
        ),
        _TopicIntroStep(
          title: 'The 24-hour rule',
          body: 'Here is a practical trick that works surprisingly well.\n\nWhen you want to buy something unplanned, wait 24 hours. Do not talk yourself out of it — just wait. If you still want it the next day and it fits your budget, buy it without guilt.\n\nThe urgency almost always fades. Most unplanned purchases never happen once you sleep on them.',
        ),
        _TopicIntroStep(
          title: 'Why this matters',
          body: 'Every rupee you redirect from something you did not really want goes somewhere that actually matters — savings, goals, debt repayment.\n\nNot because you are being strict with yourself. Because you made a real decision instead of a reflex one.',
          reflectionTitle: 'Remember',
          reflectionBullets: [
            'A need is the functional minimum — not the nicest version of it',
            'Wants are fine when they are chosen, not just automatic',
            'The 24-hour pause is the simplest way to filter impulse spending',
          ],
          reflectionNote: 'People who can distinguish needs from wants consistently save more over time — on identical incomes.',
        ),
      ];
    }

    if (lessonTitle == 'Developing a Budget Plan') {
      return const [
        _TopicIntroStep(
          title: 'Why most budgets fail before they start',
          body: 'Most budgets fail not because people lack willpower — but because the plan was built on numbers that were not true.\n\nThey use their gross salary instead of net. They underestimate their fixed costs. They assume variable spending will somehow be less than it always is.\n\nA budget built on optimistic numbers collapses within the first week of the month.',
        ),
        _TopicIntroStep(
          title: 'Start with what is real',
          body: 'Step one: write down exactly what lands in your bank account after all deductions. Not your salary — your actual net income.\n\nStep two: list every fixed commitment — rent, loan repayments, insurance, subscriptions. These leave first, before you make any other decision.\n\nWhat remains is your working money for the rest of the month.',
        ),
        _TopicIntroStep(
          title: 'Savings come before enjoyment',
          body: 'Once you know what is left after fixed costs, do not spend any of it yet.\n\nMove your savings amount first — whatever percentage you have committed to. Even MUR 1,000 counts. Transfer it before you touch anything else.\n\nThen set weekly limits for your variable categories: groceries, transport, dining, entertainment. Weekly limits are easier to track than monthly totals — you notice when you are going over before it is too late.',
        ),
        _TopicIntroStep(
          title: 'A complete example',
          body: 'Net income: MUR 22,000\n\nFixed costs: rent MUR 7,500, loan repayment MUR 1,500, internet MUR 500.\nSavings: emergency fund MUR 2,000, goal savings MUR 1,500.\nEssentials: groceries MUR 3,000, transport MUR 1,500.\nFlexible spending: dining and entertainment MUR 4,000, buffer MUR 500.\n\nTotal: MUR 22,000. Everything has somewhere to go.',
        ),
        _TopicIntroStep(
          title: 'The goal is zero unassigned money',
          body: 'The most effective budgets give every single rupee a purpose before the month starts. Not because you cannot be spontaneous — but because if you do not decide where money goes, it disappears into small decisions you will not remember.\n\nAssign it yourself. Then you are in control.',
          reflectionTitle: 'Build it in this order',
          reflectionBullets: [
            'Net income first — always from what actually arrives',
            'Fixed costs out, then savings, then everything else',
            'Set weekly limits, not just monthly totals',
          ],
          reflectionNote: 'Budgeting, goal-setting, and financial knowledge are the three foundations of long-term financial well-being.',
        ),
      ];
    }

    if (lessonTitle == 'Monitoring & Tracking Spending') {
      return const [
        _TopicIntroStep(
          title: 'A plan without tracking is just a guess',
          body: 'You can build the best budget in the world — and if you never check how your actual spending compares to it, nothing changes.\n\nTracking is not complicated. It is just the habit of recording what you spend, so you can see the truth instead of guessing at it.',
        ),
        _TopicIntroStep(
          title: 'The method that actually works',
          body: 'The best tracking method is the one you will actually do. A note in your phone. A simple spreadsheet. A budgeting app. The FinLit wallet.\n\nThe one habit that matters more than the tool: record each expense at the moment it happens. Not that evening. Not at the weekend. Right when you spend.\n\nMemory is unreliable. Small purchases — the ones that add up the fastest — are the easiest to forget.',
        ),
        _TopicIntroStep(
          title: 'Check in once a week',
          body: 'Once a week — ten minutes is enough — look at what you actually spent versus what you planned.\n\nAsk yourself three questions. Which category did I go over in? Was it a one-off situation or is this a pattern? What do I adjust for next week?\n\nWeekly check-ins catch problems early. Monthly reviews often find them too late to fix.',
        ),
        _TopicIntroStep(
          title: 'What tracking actually reveals',
          body: 'Most people estimate they spend around MUR 3,000 a month on food.\n\nOne week of honest tracking often looks like this: groceries MUR 850, delivery apps MUR 620, snacks and cafeteria MUR 390, dining out MUR 1,100.\n\nThat is almost MUR 3,000 in a single week — nearly MUR 12,000 a month. The estimate was off by four times. Tracking does not judge you for this. It just shows you the truth so you can make a real decision.',
        ),
        _TopicIntroStep(
          title: 'You cannot fix what you cannot see',
          body: 'Tracking your spending is not about restriction or punishment. It is just information — the same way checking your phone battery tells you when to charge it.\n\nOnce you know where the money actually goes, you can decide if that is where you want it to go.',
          reflectionTitle: 'The habits that matter',
          reflectionBullets: [
            'Log expenses at the moment of purchase — not later',
            'Do a 10-minute review once a week',
            'One over-budget week is normal — a pattern is a signal to act',
          ],
          reflectionNote: 'People who track spending consistently save more than those who rely on memory — even when their incomes are the same.',
        ),
      ];
    }

    // ── SAVING & EMERGENCY FUNDS ──────────────────────────────────────────

    if (lessonTitle == 'The Habit: Paying Yourself First') {
      return const [
        _TopicIntroStep(
          title: 'Why saving last never works',
          body: 'Most people plan to save whatever is left at the end of the month.\n\nThe problem is that nothing is ever left. Spending quietly expands to fill every rupee available. This is not a discipline problem — it is just how money behaves when there is no prior commitment on it.\n\nThe fix is not trying harder. It is changing the order.',
        ),
        _TopicIntroStep(
          title: 'Save first, spend what remains',
          body: 'Paying yourself first means your savings move out of your account before you spend a single rupee.\n\nThe moment income arrives, a fixed amount transfers to a separate savings account. Not at the end of the month. Not when you remember. Immediately.\n\nThen you live on what is left. After a few weeks, your brain adjusts to the smaller number and you stop noticing what was moved.',
        ),
        _TopicIntroStep(
          title: 'How much should you move?',
          body: 'Start with what is realistic, even if it feels small. Five percent is a real start. Ten percent is a solid habit. Fifteen to twenty percent is where you start building real momentum.\n\nFor someone taking home MUR 20,000, ten percent is MUR 2,000 a month. By the end of the year, that is MUR 24,000 sitting in savings — without any extra effort after the first setup.\n\nEvery time your salary increases, increase the percentage before you increase your spending.',
        ),
        _TopicIntroStep(
          title: 'The key insight',
          body: 'The difference between people who save consistently and people who never quite manage it is almost never income.\n\nIt is almost always sequence. The people who save do it first. The people who struggle do it last.',
          reflectionTitle: 'The three steps',
          reflectionBullets: [
            'Decide your percentage — even 5% is a real start',
            'Set up a transfer that moves on payday automatically',
            'Increase it with every salary raise, before anything else',
          ],
          reflectionNote: 'Saving automatically is more reliable than any approach that depends on remembering to do it.',
        ),
      ];
    }

    if (lessonTitle == 'The Shield: Emergency Funds') {
      return const [
        _TopicIntroStep(
          title: 'What happens when life breaks your plan',
          body: 'At some point, something will go wrong. A phone screen. A medical bill. A car that will not start. A job that ends without warning.\n\nWithout savings, any of these forces you to borrow money — often at high interest — just to get through it. With savings, the same event is an inconvenience. Not a crisis.',
        ),
        _TopicIntroStep(
          title: 'Build it in two stages',
          body: 'You do not need to save six months of expenses before this fund starts protecting you.\n\nStart with MUR 5,000 to MUR 10,000 — enough to handle the most common emergencies: a broken device, an unexpected medical visit, an urgent transport cost. This alone prevents most people from reaching for a credit card.\n\nOnce you have that, build toward three to six months of essential expenses. That is the level that protects you even if you lose your income entirely.',
        ),
        _TopicIntroStep(
          title: 'Not every crisis counts',
          body: "An emergency fund is for things that are unplanned, necessary, and urgent — all three at once.\n\nA sale at your favourite store is not an emergency. A concert ticket is not an emergency. A friend's birthday dinner is not an emergency.\n\nA broken water heater in monsoon season is. A hospital visit is. Protecting this fund from non-emergencies is half the discipline.",
        ),
        _TopicIntroStep(
          title: 'Where to keep it',
          body: 'Your emergency fund needs to be two things: easy to access within a day or two, and completely separate from your daily spending account.\n\nA standard savings account at your bank works well — as long as you are not using that account for anything else. Do not put it in a fixed deposit where you would lose access in a real crisis.',
        ),
        _TopicIntroStep(
          title: 'Why this changes more than your bank balance',
          body: 'Having an emergency fund does not just protect your money. It changes how you make decisions every day.\n\nWhen you know you can handle a sudden expense, you stop making financial decisions from a place of fear. That calm is worth more than the number in the account.',
          reflectionTitle: 'Build it in order',
          reflectionBullets: [
            'First target: MUR 5,000 to MUR 10,000',
            'Final target: 3 to 6 months of essential expenses',
            'Keep it liquid and in a separate account',
          ],
          reflectionNote: 'Even a small emergency fund dramatically reduces financial stress — and the likelihood of falling into debt when something goes wrong.',
        ),
      ];
    }

    if (lessonTitle == 'The Tool: Savings Accounts') {
      return const [
        _TopicIntroStep(
          title: 'Where money lives changes how it behaves',
          body: 'Money sitting in your daily current account does two things: it earns nothing, and it is available every time you open your banking app.\n\nThat combination is the enemy of savings. The more visible and accessible your savings are, the more likely you are to spend them — even without realising it.',
        ),
        _TopicIntroStep(
          title: 'The accounts worth knowing about',
          body: 'A standard savings account earns a little interest and stays accessible. Good for your emergency fund.\n\nA high-yield savings account earns more while staying liquid. Better if your bank offers one.\n\nA fixed deposit locks your money for a set period in exchange for a higher rate. Good for medium-term goals — but do not use it for your emergency fund. If something goes wrong, you cannot get to the money without a penalty.',
        ),
        _TopicIntroStep(
          title: 'Use separate accounts for separate goals',
          body: 'One of the most practical things you can do is open multiple savings accounts and name each one after its purpose.\n\nOne account for your emergency fund — untouchable. One for a specific goal like a laptop or travel. One for something further out like a car deposit.\n\nWhen they are separate, goal money cannot accidentally become spending money. And seeing each balance grow makes the goal feel more real.',
        ),
        _TopicIntroStep(
          title: 'The simple rule',
          body: 'Emergency fund: a separate savings account, accessible within a day, never linked to your debit card.\n\nShort-term goals: a high-yield savings account if your bank offers one.\n\nMedium-term goals: a fixed deposit — only if you are confident you will not need the money before it matures.',
          reflectionTitle: 'What to do now',
          reflectionBullets: [
            'Open a savings account separate from your daily account',
            'Name it after its purpose',
            'Never put emergency savings in a fixed deposit',
          ],
          reflectionNote: 'Naming an account after its goal is one of the simplest and most effective ways to protect that money from being spent.',
        ),
      ];
    }

    if (lessonTitle == 'The Growth: Compound Interest') {
      return const [
        _TopicIntroStep(
          title: 'Money that earns money on its own earnings',
          body: 'When you earn interest on savings, that interest gets added to your balance. Next month, you earn interest on the larger balance — including the interest from before.\n\nThis is compounding. The longer it runs, the faster it grows — not in a straight line, but in a curve that gets steeper the further you go.',
        ),
        _TopicIntroStep(
          title: 'The snowball on a hill',
          body: 'Think of a small snowball rolling down a long hill. At first it barely picks up anything. But as it gets bigger, each rotation collects more snow. Eventually it is rolling so fast and growing so large that nothing can slow it down.\n\nThat is what happens to savings over time. Year one looks boring. Year ten looks interesting. Year twenty looks dramatic. Year thirty looks like a completely different number than you started with.',
        ),
        _TopicIntroStep(
          title: 'Why starting early beats saving more later',
          body: 'Two people save MUR 1,500 a month. Person A starts at 20 and stops at 30 — ten years total. Person B starts at 30 and saves until 60 — thirty years total.\n\nPerson B contributes three times more money over their lifetime. But Person A, because of that ten-year head start, ends up with more wealth at 60.\n\nTime in the system matters more than the amount going in.',
        ),
        _TopicIntroStep(
          title: 'The Rule of 72',
          body: 'Here is a quick way to understand compounding: divide 72 by your interest rate to find how many years it takes to double your money.\n\nAt 4% interest, your money doubles in 18 years. At 6%, in 12 years. At 8%, in 9 years.\n\nMUR 10,000 saved at 22 at 8% becomes MUR 20,000 by 31, MUR 40,000 by 40, MUR 80,000 by 49 — without adding anything after the first deposit.',
        ),
        _TopicIntroStep(
          title: 'The one thing you cannot buy back',
          body: 'You can always earn more money. You can always save a larger percentage. But you cannot go back in time and start earlier.\n\nEvery year you wait costs you a doubling cycle. Starting small now is worth far more than starting big later.',
          reflectionTitle: 'What this means for you',
          reflectionBullets: [
            'Never withdraw savings early — you reset the clock',
            'Reinvest any interest rather than spending it',
            'Use the Rule of 72 to see how fast your money actually grows',
          ],
          reflectionNote: 'The impact of starting early is genuinely difficult to feel until you see the numbers — because growth is exponential, not linear.',
        ),
      ];
    }

    if (lessonTitle == 'The Strategy: Automating Stability') {
      return const [
        _TopicIntroStep(
          title: 'Willpower is a bad financial strategy',
          body: 'Every month, deciding whether to save requires willpower. And willpower is unreliable — it gets used up, it weakens under stress, and it loses to any enjoyable thing competing with it.\n\nThe people who save most consistently are not more disciplined than anyone else. They just set things up so the decision does not have to be made every month.',
        ),
        _TopicIntroStep(
          title: 'How automation actually works',
          body: 'Most banks let you set up a standing order — an automatic transfer that moves a fixed amount from your main account to a savings account on a date you choose.\n\nSet the date for the day after payday. Set the amount to your savings target. Then leave it alone.\n\nFrom that point forward, savings happen every month without you deciding anything.',
        ),
        _TopicIntroStep(
          title: 'Why it works psychologically',
          body: 'When money moves before you see it, your brain treats what remains as your total income. You adjust your spending to the smaller number — and after a few weeks, you genuinely stop noticing.\n\nThis is exactly how pension deductions work. The money is gone before the payslip arrives, so you never build a lifestyle around it. Automation applies the same logic to your own savings.',
        ),
        _TopicIntroStep(
          title: 'Layer it up over time',
          body: 'Start with one automatic transfer — your emergency fund. Once that reaches its target, either keep the transfer going for a different goal, or add a second one.\n\nOver time you can have a transfer for your emergency fund, one for a specific goal, one toward investments. Each one runs without you making a decision every month.\n\nYour financial progress becomes something that just happens in the background.',
        ),
        _TopicIntroStep(
          title: 'The simplest financial system',
          body: 'The best financial system is one that requires the least ongoing effort from you. Set it up once. Review it every six months. Increase the amounts when your income goes up.\n\nThat is it.',
          reflectionTitle: 'How to set it up',
          reflectionBullets: [
            'Create a standing order on the day after payday',
            'Start with one transfer for your emergency fund',
            'Add more layers as your savings habits settle',
          ],
          reflectionNote: 'Savings that happen automatically are far more consistent than savings that depend on remembering to do them.',
        ),
      ];
    }

    // ── DEBT MANAGEMENT ───────────────────────────────────────────────────

    if (lessonTitle == 'Understanding Debt: The Mechanics of Borrowing') {
      return const [
        _TopicIntroStep(
          title: 'Borrowing is not getting money — it is promising future money',
          body: 'When you take a loan, you are not receiving a gift. You are making a legal agreement to hand over a portion of your future income — plus a fee for the service.\n\nEvery loan is a claim on your future self. The question is whether the thing you are buying today is worth what your future self will give up to pay for it.',
        ),
        _TopicIntroStep(
          title: 'The three numbers that tell the real story',
          body: 'The principal is the amount you actually borrowed. The interest rate is the annual cost of borrowing it. And the APR — Annual Percentage Rate — is the number that tells you the complete, honest price.\n\nA loan might advertise zero percent interest, then add a monthly admin fee that turns it into a sixty percent APR when you do the maths. The APR is the only figure worth comparing between different loans.',
        ),
        _TopicIntroStep(
          title: 'Simple interest vs compound interest on debt',
          body: 'With simple interest, you pay a fixed amount on the original loan. With compound interest — which most credit cards and personal loans use — the interest gets added to your balance, and then you pay interest on that too.\n\nLeft unpaid, a MUR 10,000 debt at twelve percent compound interest becomes roughly MUR 14,000 after three years — without borrowing another rupee.',
        ),
        _TopicIntroStep(
          title: 'What a real loan actually costs',
          body: 'A personal loan of MUR 50,000 at eighteen percent APR over three years costs about MUR 1,808 per month to repay.\n\nBy the time it is paid off, you will have handed back MUR 65,088. The extra MUR 15,088 is just the price of having that money early.\n\nThat is roughly three months of salary for many workers — paid entirely to the bank.',
        ),
        _TopicIntroStep(
          title: 'The one question to ask before any loan',
          body: 'Before you sign anything: what is the APR, and what is the total amount I will repay?\n\nNot the monthly payment. Not the interest rate alone. The total you will hand back by the end.\n\nIf that number is worth whatever you are buying, borrow. If it is not, do not.',
          reflectionTitle: 'Always check',
          reflectionBullets: [
            'Ask for the APR — not just the interest rate',
            'Calculate monthly payment multiplied by number of months',
            'Compare that total against the real value of what you are buying',
          ],
          reflectionNote: 'Understanding the true cost of borrowing is one of the most financially valuable skills you can develop.',
        ),
      ];
    }

    if (lessonTitle == 'The "Pay Later" Illusion (Digital Debt)') {
      return const [
        _TopicIntroStep(
          title: 'Why small payments feel like not spending',
          body: 'When you hand over MUR 2,000 in cash, your brain notices. When you tap "four payments of MUR 500," it barely registers.\n\nThe total is identical. But your brain experiences them completely differently. Buy Now Pay Later platforms are designed around this exact effect — they make spending feel smaller so you do more of it.',
        ),
        _TopicIntroStep(
          title: 'The problem is not one plan — it is all of them together',
          body: "One BNPL plan for MUR 500 a month feels manageable. But add a second for MUR 800, a third for MUR 1,200, a fourth for MUR 600 — and suddenly you have committed MUR 3,100 of next month's income before the month has even started.\n\nAnd you probably could not list all of them without checking your phone first. That is the design. Each plan is forgettable on its own.",
        ),
        _TopicIntroStep(
          title: 'A real example of how it adds up',
          body: 'Your take-home income is MUR 15,000. You sign up for three BNPL plans — shoes, a watch, a trip — totalling MUR 4,600 per month.\n\nBefore you pay rent, buy groceries, or cover transport, nearly a third of your income is already gone. And those are legal obligations — you cannot simply choose not to pay them.',
        ),
        _TopicIntroStep(
          title: 'The test to run before any BNPL purchase',
          body: 'Before accepting a Pay Later offer, ask yourself one question: could I afford to buy this item twice in cash, right now?\n\nIf yes — the instalments are just convenience. If no — you are taking out a loan for something your current income cannot actually support.',
        ),
        _TopicIntroStep(
          title: 'BNPL is credit with better marketing',
          body: 'There is nothing wrong with using Pay Later products occasionally for things you could afford anyway. The danger is treating them as a way to buy things you cannot yet afford.\n\nEvery instalment plan is a legal claim on your future income. Name it what it is.',
          reflectionTitle: 'Before the next plan',
          reflectionBullets: [
            'Add up all your current BNPL commitments — total monthly amount',
            'Run the "twice in cash" test before any new plan',
            'If BNPL exceeds 10% of your net income, pause everything new',
          ],
          reflectionNote: 'People with multiple BNPL plans are significantly more likely to struggle with debt elsewhere — because the commitments are invisible until they collide.',
        ),
      ];
    }

    if (lessonTitle == 'The Minimum Payment Trap') {
      return const [
        _TopicIntroStep(
          title: 'Why banks only ask for a little',
          body: 'When you owe MUR 10,000 on a credit card and the bank asks for MUR 200, that is not generosity. That is a business decision.\n\nThe less you pay each month, the longer you carry a balance. The longer you carry a balance, the more interest you pay. The minimum payment keeps you in debt as long as possible — which is profitable for the bank and expensive for you.',
        ),
        _TopicIntroStep(
          title: 'What the minimum actually does to your debt',
          body: 'On a MUR 10,000 credit card balance at 24% annual interest, with a minimum payment of MUR 200, almost all of that MUR 200 goes straight to interest. Barely anything reduces the balance.\n\nAt that rate, it takes roughly ten years to clear MUR 10,000 — and you end up paying back close to MUR 20,000 in total.',
        ),
        _TopicIntroStep(
          title: 'What paying more actually does',
          body: 'Same debt. Same rate. But paying MUR 500 a month instead of MUR 200 clears it in about two years and saves you thousands in interest.\n\nPaying MUR 1,000 a month clears it in under a year. The difference between paying the minimum and paying aggressively is not small — it is years of your life and a significant amount of money.',
        ),
        _TopicIntroStep(
          title: 'The minimum is not a target — it is a floor',
          body: 'The minimum payment is the lowest amount the bank will accept before they take action against you. It is not a recommendation. It is not calculated with your interests in mind.\n\nTreat the full balance as the amount you owe. Anything less is just paying rent on the debt.',
          reflectionTitle: 'What to do',
          reflectionBullets: [
            'Always pay more than the minimum — even MUR 100 extra helps',
            'Use any loan calculator to see how long your debt will actually last',
            'Think of the total balance as the real number due',
          ],
          reflectionNote: 'People who consistently pay only the minimum on credit often end up paying two to three times the original amount by the time the debt is cleared.',
        ),
      ];
    }

    if (lessonTitle == 'Your Financial "Grade" (The MCIB)') {
      return const [
        _TopicIntroStep(
          title: 'Someone is keeping score',
          body: 'In Mauritius, every time you borrow money — through a bank loan, a hire purchase agreement, or even a postpaid phone contract — that arrangement is reported to the Mauritius Credit Information Bureau.\n\nThe MCIB keeps a record of every credit facility you have held, whether you paid on time, and whether anything was left unpaid. Banks check this before deciding whether to lend to you.',
        ),
        _TopicIntroStep(
          title: 'What a good record opens up for you',
          body: 'A clean credit record means banks see you as reliable. That translates into lower interest rates on loans, higher amounts approved, better terms on a mortgage, and sometimes lower insurance premiums.\n\nA damaged record does the opposite — for three to seven years.',
        ),
        _TopicIntroStep(
          title: 'What damages it',
          body: 'Late payments are flagged. Partial payments when the full amount was due are flagged. Defaults are flagged. And the MCIB does not distinguish between a large missed payment and a small one.\n\nA forgotten balance on a MUR 1,000 phone plan can show up three years later and block you from a car loan or a mortgage. The amount does not matter — only whether you paid.',
        ),
        _TopicIntroStep(
          title: 'Building a good record takes time — and paying on time',
          body: 'You build a strong credit record by borrowing and repaying consistently. Not by avoiding credit entirely.\n\nPay every bill on time. Pay the full agreed amount. Keep hire purchase agreements current. And check your own MCIB record once a year — errors happen, and you are entitled to see it.',
        ),
        _TopicIntroStep(
          title: 'Every payment is a data point',
          body: 'Your credit record is not built in a moment — it is built across years of small decisions. Every on-time payment adds to it. Every missed payment leaves a mark.\n\nTreat every financial commitment as a promise. Not because someone is watching — because you will need that record to work in your favour one day.',
          reflectionTitle: 'Protect it',
          reflectionBullets: [
            'Pay every bill on time, every time',
            'Late is almost as damaging as not paying at all',
            'Request your MCIB report once a year to check for errors',
          ],
          reflectionNote: 'Your credit history affects your interest rates, your loan eligibility, and in some cases your employment — for years.',
        ),
      ];
    }

    if (lessonTitle == 'Escaping the Debt Hole: The Exit Strategy') {
      return const [
        _TopicIntroStep(
          title: 'First: stop making it worse',
          body: 'The most important step in clearing debt is one most people skip.\n\nBefore any strategy, before any method, you need to stop adding new debt. Trying to pay off what you owe while still borrowing is like bailing water from a boat with a hole in the bottom.\n\nFreeze all new credit. No exceptions until the existing debt is gone.',
        ),
        _TopicIntroStep(
          title: 'The Avalanche — the mathematically correct approach',
          body: 'List every debt you have, with its interest rate. Pay the minimum on all of them. Then put every extra rupee you can find toward the one with the highest rate.\n\nOnce that is cleared, take everything that was going toward it and redirect it to the next highest rate. Repeat until you are done.\n\nThis approach costs you the least in total interest over time.',
        ),
        _TopicIntroStep(
          title: 'The Snowball — when you need motivation more than maths',
          body: 'The Snowball method works differently: you target the smallest balance first, regardless of interest rate. You pay it off quickly, get a genuine win, then roll that energy and that freed-up payment toward the next smallest.\n\nIt costs slightly more in interest than the Avalanche. But for people who need visible progress to stay motivated, it works better in practice.\n\nBoth methods beat minimum payments by an enormous margin. Pick the one you will actually stick to.',
        ),
        _TopicIntroStep(
          title: 'A real example',
          body: 'Three debts: a credit card at 24%, a store loan at 12%, a personal loan at 9%.\n\nUsing the Avalanche, you throw everything extra at the credit card first. It clears in roughly seven months. Then all that money shifts to the store loan. Then the personal loan.\n\nCompared to paying only minimums, this saves around MUR 4,200 in interest — and years of repayment.',
        ),
        _TopicIntroStep(
          title: 'Debt has a finish line',
          body: 'One of the most powerful things you can do is calculate your debt-free date. Work out how long each debt will take at your current extra payment rate. Write it down.\n\nWhen you know there is an end, the sacrifice feels different. It is not forever — it is until a specific month.',
          reflectionTitle: 'The plan',
          reflectionBullets: [
            'Stop all new debt first — nothing else matters until this is done',
            'Avalanche for minimum interest paid, Snowball for motivation',
            'Calculate your debt-free date and keep it visible',
          ],
          reflectionNote: 'Structured repayment with a clear end date is far more likely to succeed than open-ended minimum payments.',
        ),
      ];
    }

    // ── FINANCIAL PLANNING FOR BIG GOALS ─────────────────────────────────

    if (lessonTitle == 'Short-Term vs. Long-Term Goals') {
      return const [
        _TopicIntroStep(
          title: 'Money without a name gets spent',
          body: 'When your savings sit in one unnamed account, they feel like a surplus. And surplus money gets spent — on a holiday, on something you did not plan, on nothing in particular.\n\nThe moment you name a savings goal, the money changes character. It stops being available. It becomes something you are protecting.',
        ),
        _TopicIntroStep(
          title: 'Three different timelines, three different strategies',
          body: "Short-term goals are things you want within the next year — an emergency fund, a new device, a trip. These need to be kept in a liquid savings account so you can access them easily.\n\nMedium-term goals — a car deposit, further education, a home deposit — need one to five years. A fixed deposit or higher-yield account makes sense here.\n\nLong-term goals are five years or more away: a home, retirement, your children's education. These need to grow, which means investing, not just saving.",
        ),
        _TopicIntroStep(
          title: 'Why mixing goals breaks both of them',
          body: 'When all your savings are in one pot, your house deposit and your laptop fund compete with each other.\n\nYou see MUR 80,000 in an account, feel financially comfortable, and spend MUR 20,000 on a holiday. You tell yourself you will replace it. You usually do not.\n\nSeparate accounts make the cost of that decision visible. It is no longer "taking from savings." It is taking from the house fund, specifically.',
        ),
        _TopicIntroStep(
          title: 'An example that shows it working',
          body: 'Take-home income: MUR 25,000.\n\nThree goals, three accounts: emergency fund getting MUR 2,500 a month, laptop fund getting MUR 3,000, car deposit getting MUR 2,800 in a fixed deposit.\n\nEach goal has a separate account, a clear target, and a monthly contribution. Progress is visible. Goals do not compete.',
        ),
        _TopicIntroStep(
          title: 'A goal without an account is just a wish',
          body: 'Having a goal in your head is not a plan. Having a named savings account with a monthly transfer going into it is a plan.\n\nThe difference between people who reach their goals and people who perpetually almost reach them is usually this one step.',
          reflectionTitle: 'Do this for every goal',
          reflectionBullets: [
            'Give every goal its own account with its own name',
            'Separate short, medium, and long-term savings physically',
            'Review goal timelines quarterly — adjust the amount, never drop the goal',
          ],
          reflectionNote: 'Goal-based saving with defined timelines is one of the most reliable predictors of long-term financial well-being.',
        ),
      ];
    }

    if (lessonTitle == 'Estimating Future Costs & The 10% Buffer') {
      return const [
        _TopicIntroStep(
          title: 'The sticker price is never the real price',
          body: 'Most people save for the number on the price tag and are surprised when it is not enough.\n\nEvery significant purchase comes with additional costs that are not in the headline figure: registration fees, transfer taxes, insurance, delivery, setup costs. If you only saved for the sticker price, you arrive at your goal and discover you are still short.',
        ),
        _TopicIntroStep(
          title: 'Add ten percent on top of everything',
          body: 'A ten percent buffer on top of your true total cost covers the things you did not think of: a fee you did not know existed, a price that went up while you were saving, a small repair that was needed on day one.\n\nIf you use every rupee of the buffer — no problem, you planned for it. If you do not — you start your next goal with a head start.',
        ),
        _TopicIntroStep(
          title: 'What this looks like with a real purchase',
          body: 'You want a second-hand car with a sticker price of MUR 180,000.\n\nOnce you add registration transfer, first-year insurance, road tax, and a minor repair discovered at inspection, the actual total is closer to MUR 201,000.\n\nSomeone who saved exactly MUR 180,000 is short and has to borrow. Someone who saved MUR 198,000 — price plus ten percent — gets through with almost no gap.',
        ),
        _TopicIntroStep(
          title: 'For goals more than a year away, add inflation too',
          body: 'Prices do not stay the same. Inflation in Mauritius has averaged three to six percent in recent years.\n\nA goal that costs MUR 50,000 today might cost MUR 53,000 in a year. If you save exactly MUR 50,000, you finish short through no fault of your own.\n\nFor goals more than twelve months away, add an inflation adjustment on top of the ten percent buffer.',
        ),
        _TopicIntroStep(
          title: 'Save for what it actually costs',
          body: 'The gap between what something appears to cost and what it actually costs is where most goal failures happen. Not from lack of effort — from incomplete research.',
          reflectionTitle: 'The habit',
          reflectionBullets: [
            'Research all costs — not just the headline price',
            'Add 10% buffer on top of the real total',
            'For goals over 12 months, also add an inflation adjustment',
          ],
          reflectionNote: 'Always plan for the complete cost. A buffer is cheaper than borrowing to close the gap at the finish line.',
        ),
      ];
    }

    if (lessonTitle == 'Creating a Financial Plan (S.M.A.R.T. Goals)') {
      return const [
        _TopicIntroStep(
          title: 'The difference between a wish and a plan',
          body: '"I want to save for a trip" is a wish.\n\n"I will save MUR 44,000 for a trip to Réunion by December 2026, by setting aside MUR 2,445 every month starting now" is a plan.\n\nThe difference is not motivation. It is specificity. A wish leaves every decision open. A plan closes them.',
        ),
        _TopicIntroStep(
          title: 'What S.M.A.R.T. actually means in practice',
          body: 'Specific: what exactly are you saving for?\nMeasurable: what is the exact amount you need?\nAchievable: can you realistically save that much each month?\nRelevant: does this goal actually improve your life?\nTime-bound: what is the deadline?\n\nEvery question you cannot answer is a gap that will let the goal slip through.',
        ),
        _TopicIntroStep(
          title: 'Reverse-engineer the monthly number',
          body: 'Once you have a clear goal with a clear deadline, the maths is simple.\n\nTotal amount needed, divided by months until the deadline, equals your monthly savings target.\n\nMUR 44,000 divided by 18 months is MUR 2,445 per month. Can you do that? If yes, set up the transfer. If no, extend the deadline or adjust the goal.',
        ),
        _TopicIntroStep(
          title: 'What to do when life gets in the way',
          body: 'Things will happen. A month where you could not contribute, an unexpected expense that set you back.\n\nWhen this happens, the right response is to adjust the deadline — not to abandon the goal. Work out how many months you missed. Push the end date by that amount.\n\nThe goal survives. The timeline just shifts.',
        ),
        _TopicIntroStep(
          title: 'A deadline is not pressure — it is clarity',
          body: 'Knowing you need to save MUR 2,445 this month tells you exactly how much you can spend on everything else. Without a deadline, every month is just "saving something."\n\nWith one, every decision has context.',
          reflectionTitle: 'How to build it',
          reflectionBullets: [
            'Write every goal with all five S.M.A.R.T. elements',
            'Calculate the monthly target — if it is impossible, extend the deadline',
            'Review every three months and update if needed',
          ],
          reflectionNote: 'Goal-setting combined with regular review is one of the most reliable ways to actually reach what you are working toward.',
        ),
      ];
    }

    if (lessonTitle == 'Tracking Progress Toward Goals') {
      return const [
        _TopicIntroStep(
          title: 'Goals die without check-ins',
          body: 'Setting a goal and never looking at it again is one of the most common reasons people fail to reach them. Not because they gave up dramatically — but because they drifted gradually and never noticed.\n\nRegular progress reviews are not a formality. They are the mechanism that keeps the goal alive.',
        ),
        _TopicIntroStep(
          title: 'Why separate accounts work as a tracking tool',
          body: 'When your goal savings are in a separate, named account, you can see progress at a glance — the balance grows, and you can feel it working.\n\nWhen they are mixed with your daily money, the number changes for all kinds of reasons and progress is invisible.\n\nSeparate accounts do not just protect savings. They make the goal feel real and tangible in a way that one combined balance never does.',
        ),
        _TopicIntroStep(
          title: 'Five minutes, once a month',
          body: 'A monthly review does not need to be long. Ask three things: am I on track? If not, was it a one-off or a pattern? What do I adjust?\n\nIf it was a one-off — a medical bill, an unexpected expense — just resume next month. If it is a pattern — spending consistently more than planned — either increase contributions or extend the deadline.',
        ),
        _TopicIntroStep(
          title: 'Make progress visible',
          body: 'Something happens psychologically when you can see progress building. Motivation increases the closer you get to a visible goal.\n\nA savings thermometer drawn on paper. A bar in a spreadsheet. The goal tracker in FinLit. It does not matter what the tool is — just that you can see the balance moving toward a target.',
        ),
        _TopicIntroStep(
          title: 'Adjust, but never delete',
          body: 'Life will interrupt your savings. The professional response is to adjust the timeline — not to abandon the goal.\n\nThe goal is not the money. The goal is what the money makes possible. Keep that in view.',
          reflectionTitle: 'The habits',
          reflectionBullets: [
            'Check goal progress once a month — five minutes is enough',
            'Use separate named accounts so progress is always visible',
            'When life disrupts — adjust the date, keep the goal',
          ],
          reflectionNote: 'Regular review is more important than income level when it comes to actually reaching financial goals.',
        ),
      ];
    }

    // ── INVESTING BASICS ──────────────────────────────────────────────────

    if (lessonTitle == 'Introduction to Investing') {
      return const [
        _TopicIntroStep(
          title: 'Saving keeps your money. Investing grows it.',
          body: 'A savings account protects your money and earns a small amount of interest. That is valuable — but it is not enough on its own.\n\nInflation quietly reduces what your money can buy each year. If your savings earn two percent but inflation is five percent, you are losing ground in real terms. Investing is how you stay ahead of that.',
        ),
        _TopicIntroStep(
          title: 'What investing actually means',
          body: 'Investing means putting money into something — a business, a government bond, a fund — with the expectation that it will grow over time.\n\nUnlike a savings account, investments can lose value in the short term. That is the trade-off. More potential growth comes with more uncertainty. How much of that uncertainty you take on is a decision you get to make.',
        ),
        _TopicIntroStep(
          title: 'Get your foundation right first',
          body: 'Before investing anything, two things need to be in place.\n\nFirst, a fully funded emergency fund — because if something goes wrong and you have no savings, you might have to sell investments at a loss just to cover the cost.\n\nSecond, freedom from high-interest debt — because paying twenty percent interest on credit card debt while earning eight percent on investments is a losing trade.',
        ),
        _TopicIntroStep(
          title: 'Why it matters more than most people realise',
          body: 'MUR 500 per month invested from age 22, at eight percent annual return, becomes over MUR 1.6 million by age 60.\n\nThe same MUR 500 sitting in a zero-interest account becomes MUR 228,000.\n\nThe difference is not luck or salary. It is the decision to invest, and the patience to leave it alone.',
          reflectionTitle: 'The order matters',
          reflectionBullets: [
            'Emergency fund first — fully funded before investing',
            'Clear high-interest debt before anything else',
            'Then invest consistently, for as long as possible',
          ],
          reflectionNote: 'Investing is how ordinary people build significant wealth over time — but only when the financial foundation is solid first.',
        ),
      ];
    }

    if (lessonTitle == 'Risk and Return') {
      return const [
        _TopicIntroStep(
          title: 'More potential return always means more risk',
          body: 'This is the one law of investing that never changes.\n\nIf something offers very high returns with no risk, it is either a lie or something you do not fully understand yet. Real investments offer a trade-off: accept more uncertainty, and you get access to more potential growth.',
        ),
        _TopicIntroStep(
          title: 'What kinds of risk actually exist',
          body: 'Market risk is the most obvious: the value of your investment can fall when economic conditions shift.\n\nInflation risk is subtler: your returns might not keep pace with rising prices. Liquidity risk means you might not be able to sell quickly when you need cash. Concentration risk comes from putting too much into one thing.\n\nUnderstanding which risks you are exposed to is more useful than trying to avoid risk entirely.',
        ),
        _TopicIntroStep(
          title: 'How much risk makes sense for you',
          body: 'Three things shape your risk tolerance.\n\nTime horizon: the longer until you need the money, the more short-term volatility you can absorb. Income stability: a reliable salary means you can invest aggressively without worrying about needing the money unexpectedly. Financial cushion: a solid emergency fund means a bad investment year does not become a personal crisis.\n\nA 22-year-old with stable income and a full emergency fund can take considerably more risk than a 55-year-old approaching retirement.',
        ),
        _TopicIntroStep(
          title: 'Risk is not the enemy',
          body: 'Avoiding all risk means your money barely grows. Taking on appropriate risk for your situation is how wealth is built.\n\nThe skill is not finding zero-risk options — it is understanding the risks you are taking and making sure they match your timeline and your life.',
          reflectionTitle: 'Questions to ask yourself',
          reflectionBullets: [
            'How many years until I need this money?',
            'How would I feel if this investment dropped 30% in one year?',
            'Do I have an emergency fund so I would not need to sell in a crisis?',
          ],
          reflectionNote: 'Match your investment risk level to your timeline and personal circumstances — not to what anyone else is doing.',
        ),
      ];
    }

    if (lessonTitle == 'Types of Investments (Stocks, Bonds, Funds)') {
      return const [
        _TopicIntroStep(
          title: 'Stocks: owning a piece of a business',
          body: 'When you buy a stock, you become a part-owner of that company. If the company grows and becomes more valuable, your share is worth more. If it struggles, your share loses value.\n\nStocks offer the highest potential return over long periods — but also the most volatility in the short term.',
        ),
        _TopicIntroStep(
          title: 'Bonds: lending your money for interest',
          body: 'When you buy a bond, you lend money to a government or company. They agree to pay you a fixed interest rate over a set period, then return your original amount at the end.\n\nBonds are generally safer than stocks but grow more slowly. They are most useful for protecting capital or balancing out a riskier portfolio.',
        ),
        _TopicIntroStep(
          title: 'Funds: investing in many things at once',
          body: 'A fund pools money from many investors and buys a collection of stocks, bonds, or other assets.\n\nAn index fund tracks a market index — for example, the five hundred largest companies in a given market — at very low cost. You get broad exposure without picking individual companies.\n\nFor most people starting out, a low-cost index fund is the most sensible place to begin.',
        ),
        _TopicIntroStep(
          title: 'How to think about them together',
          body: 'Stocks for growth over the long term. Bonds for stability and income. Funds for broad diversification without needing to pick individual investments.\n\nMost practical investment strategies use a combination of all three, adjusted based on how many years you have and how much volatility you can tolerate.',
          reflectionTitle: 'A simple starting point',
          reflectionBullets: [
            'Stocks: highest growth potential, most volatility',
            'Bonds: lower growth, more stable, good for balance',
            'Index funds: broad diversification at low cost — a good starting point',
          ],
          reflectionNote: 'Most beginners are well served by a low-cost index fund before exploring individual stocks or bonds.',
        ),
      ];
    }

    if (lessonTitle == 'Diversification') {
      return const [
        _TopicIntroStep(
          title: 'Do not put everything in one place',
          body: 'Diversification means spreading your investments across different assets, sectors, and regions.\n\nThe goal is straightforward: when one investment falls in value, others may hold steady or rise — so the damage to your overall portfolio is limited.',
        ),
        _TopicIntroStep(
          title: 'What happens without it',
          body: 'Imagine you put all your savings into one airline company.\n\nA global event grounds all flights. That investment drops eighty percent.\n\nBut if your money was spread across airlines, technology, healthcare, and bonds — the airline falls eighty percent, but other parts of the portfolio behave differently, and your overall loss is far smaller.',
        ),
        _TopicIntroStep(
          title: 'How to actually diversify',
          body: 'Invest across different sectors — not just technology, not just one industry. Invest across different countries — not just your home market. Mix asset types — some stocks, some bonds.\n\nAnd avoid holding more than ten percent of your portfolio in any single company. No matter how confident you feel about it.\n\nIndex funds do all of this automatically. That is one of the main reasons they are so widely recommended.',
        ),
        _TopicIntroStep(
          title: 'What diversification does and does not do',
          body: 'Diversification does not eliminate risk. If the entire global economy contracts, almost everything falls together.\n\nWhat it does is protect you from the risk of any one investment collapsing and taking everything with it.',
          reflectionTitle: 'The principle',
          reflectionBullets: [
            'Spread across sectors, countries, and asset types',
            'Never put more than 10% in a single company',
            'Index funds provide automatic diversification at low cost',
          ],
          reflectionNote: 'A diversified portfolio gives you the best chance of steady long-term growth while protecting against catastrophic loss from a single bad investment.',
        ),
      ];
    }

    if (lessonTitle == 'The Power of Long-Term Investing') {
      return const [
        _TopicIntroStep(
          title: 'The best time to invest is as early as possible',
          body: 'Many people wait for the right moment to invest. The market seems high. There is uncertainty. They will start when things feel more stable.\n\nThe problem is that time spent waiting is time spent not compounding. Every year of delay costs you growth you cannot recover.',
        ),
        _TopicIntroStep(
          title: 'Markets fall. They also recover.',
          body: "In the short term, markets go up and down constantly. A drop in value looks alarming — but it is only a loss if you sell.\n\nInvestors who held through the 2008 financial crisis and the 2020 pandemic crash saw both recoveries — and both eventually reached new highs.\n\nThe long-term investor's job is not to predict the market. It is to stay invested while it does what it has always done over time.",
        ),
        _TopicIntroStep(
          title: 'Starting early matters more than the amount',
          body: 'Person A invests MUR 2,000 per month from age 22 to 32 and then stops. Person B invests MUR 2,000 per month from age 32 to 62 and never stops.\n\nPerson A invests for ten years. Person B invests for thirty. At a standard long-term return rate, Person A ends up with more wealth at 60.\n\nThe ten-year head start did more than thirty years of consistent contributions could overcome.',
        ),
        _TopicIntroStep(
          title: 'The strategy that works is the one you stick to',
          body: 'The most sophisticated investment strategy in the world fails if you panic and sell during a downturn. The simplest strategy — invest regularly, leave it alone, do not react to short-term noise — succeeds if you actually follow it.\n\nConsistency over decades is what builds wealth. Not timing, not picking the right stock, not watching the market daily.',
          reflectionTitle: 'What to do',
          reflectionBullets: [
            'Start investing as early as possible, even with small amounts',
            'Do not check your portfolio daily — it will make you anxious without helping',
            'Stay invested through downturns — selling at a loss locks in the loss',
          ],
          reflectionNote: 'Time in the market consistently outperforms trying to time the market.',
        ),
      ];
    }

    if (lessonTitle == 'Common Investment Mistakes') {
      return const [
        _TopicIntroStep(
          title: 'Selling when the market drops',
          body: 'When investments fall in value, the emotional response is to sell before things get worse.\n\nThis is almost always the wrong decision. Selling during a downturn turns a temporary paper loss into a permanent real one — and means you are often out of the market when the recovery happens.\n\nThe investors who come out ahead are usually the ones who did nothing during the crash.',
        ),
        _TopicIntroStep(
          title: 'Chasing what everyone is talking about',
          body: 'By the time a stock or investment becomes popular news, the people who benefit most have already bought in.\n\nInvesting in something because it is trending on social media or because a friend mentioned it is not a strategy — it is speculation. Most people who follow trends into investments lose money.',
        ),
        _TopicIntroStep(
          title: 'Ignoring fees',
          body: 'Two funds. One charges two percent per year in fees. The other charges 0.1 percent. They track the same index.\n\nOver thirty years, the fee difference alone can cost you nearly forty percent of your final wealth through lost compounding. A small annual percentage does not feel significant until you calculate what it compounds to over decades.\n\nAlways check the expense ratio before investing in any fund.',
        ),
        _TopicIntroStep(
          title: 'The biggest mistakes are emotional, not analytical',
          body: 'Most investment errors come from reacting to fear or excitement rather than following a plan.\n\nA boring, consistent, low-cost investment strategy held for decades outperforms almost everything else — including active strategies run by professionals.',
          reflectionTitle: 'Avoid these',
          reflectionBullets: [
            'Stay calm in downturns — do not sell into a falling market',
            'Ignore tips and trends — stick to your plan',
            'Always check the annual fee before buying any fund',
          ],
          reflectionNote: 'A simple, consistent, low-cost approach to investing beats excitement almost every time.',
        ),
      ];
    }

    // ── FRAUD & SCAMS ─────────────────────────────────────────────────────

    if (lessonTitle == 'Protecting from Fraud & Scams') {
      return const [
        _TopicIntroStep(
          title: 'Scams are not obvious — that is the point',
          body: 'Financial scams are not designed to fool foolish people. They are designed by skilled professionals to fool anyone.\n\nThey use legitimate-looking websites, real bank names, convincing voices, and carefully crafted urgency. Anyone can be targeted. The only protection is knowing how they work.',
        ),
        _TopicIntroStep(
          title: 'The rule that protects you from almost everything',
          body: 'Legitimate organisations — banks, government agencies, employers — never contact you out of nowhere to demand urgent action, ask for your PIN or password, or request upfront payment to release money you are owed.\n\nIf any of these happen, stop. Do not act. Verify through an official number you find yourself — not one provided in the message.',
        ),
        _TopicIntroStep(
          title: 'Who gets targeted',
          body: 'Scammers look for people who are expecting money, people under financial stress, people unfamiliar with digital payments, and anyone reachable online.\n\nThat covers most people at some point in their lives. Awareness is not a guarantee — but it dramatically reduces the chance of being caught.',
        ),
        _TopicIntroStep(
          title: 'The habit that works',
          body: 'Before any financial action triggered by an unexpected contact — a call, a message, an email — pause.\n\nStop. Think. Verify independently. Then decide.\n\nScams depend on you acting before you think. The pause is the protection.',
          reflectionTitle: 'Remember',
          reflectionBullets: [
            'No legitimate organisation asks for your PIN or OTP',
            'No real prize or payment requires an upfront fee',
            'When in doubt — stop and verify through official channels',
          ],
          reflectionNote: 'Your best protection is a habit of pausing before any unexpected financial action.',
        ),
      ];
    }

    if (lessonTitle == 'Common Types of Financial Scams') {
      return const [
        _TopicIntroStep(
          title: 'Phishing: pretending to be someone you trust',
          body: 'Phishing is when a scammer impersonates a trusted organisation — your bank, a government agency, a company — to steal your login details or personal information.\n\nIt usually arrives by email or SMS with a link to a fake website that looks identical to the real one. You enter your credentials. The scammer now has them.',
        ),
        _TopicIntroStep(
          title: 'Investment scams: guaranteed returns that are not real',
          body: 'Investment scams promise extraordinary returns with no risk. They take several forms.\n\nPonzi schemes pay early investors using money from new investors — until the scheme collapses. Pump and dump schemes inflate the price of a worthless asset, then sell it to people who bought the hype. Crypto scams show you fake profits in a fake platform and never let you withdraw.\n\nThe constant: if returns sound extraordinary, they are not real.',
        ),
        _TopicIntroStep(
          title: 'Impersonation scams: creating fear to demand money',
          body: 'A voice on the phone claims to be a police officer, a tax official, or a bank employee. They say you owe money, or that your account has been compromised, or that someone used your identity.\n\nThey create urgency and fear — demanding immediate action, threatening arrest or account closure.\n\nNo legitimate authority works this way. Real agencies send official correspondence. They do not demand wire transfers over the phone.',
        ),
        _TopicIntroStep(
          title: 'The pattern behind every scam',
          body: 'Every scam uses one of three emotions to make you act before you think.\n\nGreed: this is a rare opportunity you will miss if you hesitate. Fear: something bad will happen if you do not act immediately. Urgency: you have minutes, not days.\n\nRecognise the emotion being triggered. Then pause.',
          reflectionTitle: 'The three triggers',
          reflectionBullets: [
            'Greed: too-good-to-be-true opportunity',
            'Fear: threat of arrest, account closure, legal action',
            'Urgency: act now or lose everything',
          ],
          reflectionNote: 'Recognise the trigger — and walk away.',
        ),
      ];
    }

    if (lessonTitle == 'Online Payment and Banking Security') {
      return const [
        _TopicIntroStep(
          title: 'Your banking login is worth more than your wallet',
          body: 'A stolen wallet loses whatever cash was in it. A stolen banking password loses everything in your account.\n\nOnline banking is enormously convenient — and it creates risks that did not exist with physical cash. Simple security habits dramatically reduce those risks.',
        ),
        _TopicIntroStep(
          title: 'The habits that actually protect you',
          body: 'Use a strong, unique password for every financial account — not the same one you use elsewhere. Enable two-factor authentication on all banking apps.\n\nNever do banking on public WiFi. Never click a link in an SMS or email asking you to verify your account. Log out of banking apps after each session.\n\nThese take a few minutes to set up and they prevent most attacks.',
        ),
        _TopicIntroStep(
          title: 'Verify before you pay',
          body: "Fraudsters send fake payment requests that look identical to real ones from suppliers, employers, or landlords.\n\nBefore any payment: verify the recipient's account details through a phone number you already have on record — not a number in the payment request. Be suspicious of any last-minute change to payment details. Check that any website asking for card details starts with https.",
        ),
        _TopicIntroStep(
          title: 'Slow down before every payment',
          body: "Most financial fraud online happens because someone acted quickly on something that felt legitimate.\n\nA thirty-second pause to verify can save your account. Speed is the scammer's advantage. Caution is yours.",
          reflectionTitle: 'Practical steps',
          reflectionBullets: [
            'Unique strong password for every financial account',
            'Two-factor authentication on all banking apps',
            'Never verify payment details using a number from the payment request',
          ],
          reflectionNote: 'Online security is not about technology — it is about habits. Simple ones, done consistently.',
        ),
      ];
    }

    if (lessonTitle == 'Protecting Personal Information') {
      return const [
        _TopicIntroStep(
          title: 'Your personal data is worth money to criminals',
          body: 'Your name, ID number, date of birth, and bank details are enough for a scammer to open accounts in your name, take out loans you never applied for, and damage your credit record — sometimes before you even notice anything is wrong.',
        ),
        _TopicIntroStep(
          title: 'What you should never share',
          body: "Your National ID or passport number. Your full bank account details. Your card's CVV number. Your PIN. Your one-time password. Your security question answers.\n\nNo bank and no government agency will ever ask for your PIN or OTP. If someone does — regardless of how official they sound — it is a scam.",
        ),
        _TopicIntroStep(
          title: 'How to know if your identity has been misused',
          body: 'Watch for transactions on your bank statement you do not recognise. Watch for loan or credit applications you never made. Watch for bills arriving for accounts that are not yours. Watch for being denied credit for no reason you can identify.\n\nIf any of these happen, contact your bank and check your MCIB record immediately.',
        ),
        _TopicIntroStep(
          title: 'Be careful with what you share, and where',
          body: 'Be careful about what personal information you share online — on social media, in forms, in response to unsolicited messages.\n\nScammers use small pieces of information gathered over time to build a profile convincing enough to impersonate you or to manipulate you.',
          reflectionTitle: 'Protect this',
          reflectionBullets: [
            'Never share your PIN, OTP, or CVV with anyone',
            'Check your bank statement regularly for unfamiliar transactions',
            'Be selective about what personal data you share online',
          ],
          reflectionNote: 'Protecting your personal information is as important as protecting your cash.',
        ),
      ];
    }

    if (lessonTitle == 'Recognizing Warning Signs of Fraud') {
      return const [
        _TopicIntroStep(
          title: 'Red flag one: pressure to act immediately',
          body: '"You have thirty minutes to claim this or it expires." "Act now before someone else takes your spot." "This offer ends at midnight."\n\nLegitimate opportunities do not expire in minutes. Real financial situations allow time to verify, to think, to ask someone else. Any genuine pressure to act immediately is a warning sign.',
        ),
        _TopicIntroStep(
          title: 'Red flag two: upfront payment required to receive money',
          body: '"Pay a small processing fee to release your prize." "Transfer a deposit to unlock your loan." "Send the tax amount before we can send your inheritance."\n\nNo legitimate prize, loan, or inheritance requires an upfront fee. Once you pay the first fee, another reason for another fee will appear. This is the structure of the scam.',
        ),
        _TopicIntroStep(
          title: 'Red flag three: guaranteed returns that are extraordinary',
          body: '"Earn fifty percent per month — guaranteed." "Double your money in sixty days." "Risk-free investment with fifteen percent weekly returns."\n\nNo legitimate investment offers guaranteed high returns. The word "guaranteed" combined with an extraordinary rate is not a feature — it is the lie.',
        ),
        _TopicIntroStep(
          title: 'Why smart people get caught',
          body: 'Scams work not because people are gullible — but because scammers are skilled at triggering emotions that override rational thinking.\n\nExcitement, fear, and urgency all reduce your ability to think clearly. The scam counts on that window.\n\nThe pause is the defence. One moment of deliberate calm is enough to break the effect.',
          reflectionTitle: 'Remember these',
          reflectionBullets: [
            'Urgency is a red flag, not a reason to act faster',
            'Upfront fees to receive money are always a scam',
            'Guaranteed extraordinary returns do not exist',
          ],
          reflectionNote: 'When emotions spike, pause. That pause is what separates the people who get caught from the people who do not.',
        ),
      ];
    }

    if (lessonTitle == 'What To Do If You Are Scammed') {
      return const [
        _TopicIntroStep(
          title: 'Act as fast as possible',
          body: 'The speed of your response makes a real difference.\n\nCall your bank immediately. Explain what happened and ask them to freeze the account or attempt to reverse the transaction. Change the passwords for all financial accounts that could be compromised. Enable two-factor authentication on anything that does not already have it.',
        ),
        _TopicIntroStep(
          title: 'Report it',
          body: "Report the fraud to your bank's fraud team first — they are best placed to act quickly.\n\nThen report to the Mauritius Police Force Economic Crime Office. If it involved an investment, report to the Financial Services Commission. If it involved a SIM swap, contact your mobile operator.\n\nReporting does not guarantee recovery — but it helps authorities identify patterns and protects other people.",
        ),
        _TopicIntroStep(
          title: 'Watch for the follow-up scam',
          body: 'After someone is scammed, they often receive another approach — this time from a "recovery agent" or "fraud investigator" who claims to be able to retrieve the lost money for a fee.\n\nThis is a second scam. There are no legitimate recovery agents who cold-contact scam victims. Anyone offering this service is taking advantage of people who are already distressed.',
        ),
        _TopicIntroStep(
          title: 'Protect yourself going forward',
          body: 'Check your MCIB credit record for any accounts or loans that appeared without your knowledge. Review your bank statements weekly for a period after the incident. Let family members know — scammers sometimes use information from one victim to target people connected to them.',
          reflectionTitle: 'The steps',
          reflectionBullets: [
            'Call your bank immediately — ask to freeze and reverse',
            'Report to police and relevant regulators',
            'Ignore any recovery agent who contacts you — it is another scam',
          ],
          reflectionNote: 'Being scammed is not a personal failure. These are professional criminals. Act fast and protect yourself from what comes next.',
        ),
      ];
    }

    // ── TAXES & TAX PLANNING ──────────────────────────────────────────────

    if (lessonTitle == 'Introduction to Taxes') {
      return const [
        _TopicIntroStep(
          title: 'What a tax actually is',
          body: 'A tax is a mandatory contribution to the government — not optional, not negotiable, and built into most financial transactions you make as an adult.\n\nIn Mauritius, taxes are collected by the Mauritius Revenue Authority. They fund everything from public hospitals and schools to roads, police, and social services.',
        ),
        _TopicIntroStep(
          title: 'How taxes show up in your life',
          body: 'Income tax is deducted from your salary before you receive it — through a system called PAYE, Pay As You Earn. Your employer handles this on your behalf.\n\nVAT — Value Added Tax — is added to most goods and services you buy. When you purchase a phone or pay for a meal at a restaurant, a portion of that price is VAT.\n\nThere are also taxes on property, on imported goods, and mandatory contributions like NPF and NSF.',
        ),
        _TopicIntroStep(
          title: 'Why it matters to understand them',
          body: 'Taxes affect your real income, the true price of purchases, and the cost of financial decisions like buying property or running a business.\n\nUnderstanding how they work helps you plan more accurately, claim what you are entitled to, and avoid mistakes that can be costly.',
        ),
        _TopicIntroStep(
          title: 'Taxes are your financial starting point',
          body: 'Every financial plan starts with the money actually available after tax. Understanding what comes out — and why — is the foundation of every other financial decision.',
          reflectionTitle: 'The basics',
          reflectionBullets: [
            'Income tax is deducted at source through PAYE',
            'VAT is added to most purchases — 15% in Mauritius',
            'NPF and NSF contributions are also mandatory deductions',
          ],
          reflectionNote: 'Understanding your tax obligations helps you plan, comply, and avoid costly mistakes.',
        ),
      ];
    }

    if (lessonTitle == 'Why Governments Collect Taxes') {
      return const [
        _TopicIntroStep(
          title: 'The things no individual could afford alone',
          body: 'A public hospital. A national road network. A school system. A police force.\n\nNo individual could fund any of these. Taxes pool contributions from everyone so that services everyone depends on can actually exist.',
        ),
        _TopicIntroStep(
          title: 'Taxes do more than pay for services',
          body: 'Taxes also shape behaviour and balance economic gaps.\n\nHigher earners contribute more, which funds support for those who earn less. Tax breaks encourage things governments want more of — investment in renewable energy, for example. Higher taxes on cigarettes and alcohol reduce harmful consumption.\n\nTax policy is one of the main levers governments use to shape how an economy functions.',
        ),
        _TopicIntroStep(
          title: 'What happens when taxes are not paid',
          body: 'When individuals or businesses avoid paying taxes illegally, public services are underfunded, honest taxpayers carry a heavier share, and governments may raise rates to compensate.\n\nTax evasion — deliberately hiding income or making false claims — is a criminal offence. Tax planning — legally using allowances and deductions to reduce your bill — is entirely different, and entirely within your rights.',
        ),
        _TopicIntroStep(
          title: 'A different way to think about it',
          body: 'Taxes are not just money leaving your account. They are your share of the infrastructure, services, and protections that make daily life possible.\n\nUnderstanding why they exist makes it easier to think about them clearly — and to engage with tax planning without resentment.',
          reflectionTitle: 'The distinction',
          reflectionBullets: [
            'Tax evasion: hiding income illegally — a criminal offence',
            'Tax avoidance: using legal allowances — entirely your right',
            'Tax compliance: filing accurately and on time — a legal requirement',
          ],
          reflectionNote: 'Understanding why taxes exist helps you see them as an investment in shared infrastructure — not just a cost.',
        ),
      ];
    }

    if (lessonTitle == 'Common Types of Taxes Individuals Pay') {
      return const [
        _TopicIntroStep(
          title: 'Income tax',
          body: 'Income tax is charged on what you earn. In Mauritius, it is deducted from your salary before you receive it — through PAYE — so most employees never actually handle the payment.\n\nThe rate is fifteen percent on chargeable income, which is your income after personal exemptions are subtracted.',
        ),
        _TopicIntroStep(
          title: 'VAT',
          body: 'Value Added Tax is charged on most goods and services at fifteen percent.\n\nWhen you buy something for MUR 1,150, MUR 150 of that is VAT going to the government. You pay it without thinking about it because it is built into the price.\n\nBusinesses collect it on behalf of the government — you are the one bearing the cost.',
        ),
        _TopicIntroStep(
          title: 'Other contributions you may not have noticed',
          body: 'Beyond income tax and VAT, there are several other mandatory contributions.\n\nNPF — National Pension Fund — is deducted from your salary and goes toward your retirement. NSF — National Savings Fund — is another mandatory deduction. If you own property, there is land tax. Buying or selling property involves registration duties.',
        ),
        _TopicIntroStep(
          title: 'Taxes are everywhere in a financial life',
          body: 'Almost every significant financial transaction has a tax dimension — employment, purchases, property, savings, inheritance.\n\nKnowing which ones apply to your situation lets you plan accurately and avoid surprises.',
          reflectionTitle: 'The main ones',
          reflectionBullets: [
            'Income tax: 15% on chargeable income, deducted through PAYE',
            'VAT: 15% on most goods and services you buy',
            'NPF and NSF: mandatory salary deductions for pension and savings',
          ],
          reflectionNote: 'Taxes affect almost every financial transaction in your life — knowing which apply to you helps you budget accurately.',
        ),
      ];
    }

    if (lessonTitle == 'Understanding Income Tax') {
      return const [
        _TopicIntroStep(
          title: 'How your income tax is calculated',
          body: 'In Mauritius, income tax is calculated on your chargeable income — which is your gross income minus your personal exemption threshold.\n\nThe exemption threshold is a tax-free allowance based on your household situation: single, married, with dependents, and so on. If your income is below the threshold, you pay no income tax.',
        ),
        _TopicIntroStep(
          title: 'The flat rate',
          body: 'Mauritius uses a flat income tax rate of fifteen percent on everything above the exemption threshold.\n\nThis means if your income is below the threshold, you pay nothing. If it is above, everything over that threshold is taxed at fifteen percent — regardless of how far above it you are.',
        ),
        _TopicIntroStep(
          title: 'A concrete example',
          body: 'Annual income: MUR 300,000.\nPersonal exemption threshold for a single person: approximately MUR 325,000.\n\nChargeable income: MUR 0. Tax due: MUR 0.\n\nIf income were MUR 400,000: chargeable income is MUR 75,000. Tax at 15%: MUR 11,250.\n\nYour employer deducts this monthly through PAYE — but knowing the calculation helps you verify it is correct.',
        ),
        _TopicIntroStep(
          title: 'Why you should check your payslip',
          body: 'Most people never look at the deductions section of their payslip. But errors happen — incorrect tax codes, wrong exemption categories, miscalculated deductions.\n\nChecking your payslip monthly takes two minutes and ensures you are not overpaying — or underpaying and building a tax liability without knowing it.',
          reflectionTitle: 'The essentials',
          reflectionBullets: [
            'Chargeable income = gross income minus personal exemption threshold',
            'Income tax rate: 15% on everything above the threshold',
            'PAYE means your employer handles the deduction monthly',
          ],
          reflectionNote: 'Understanding the calculation means you can verify your payslip is correct — and plan your finances more accurately.',
        ),
      ];
    }

    if (lessonTitle == 'Basic Tax Planning Concepts') {
      return const [
        _TopicIntroStep(
          title: 'Tax planning versus tax evasion',
          body: 'Tax evasion is hiding income, falsifying records, or deliberately not filing returns. It is illegal.\n\nTax planning is using the allowances, deductions, and reliefs that the government has built into the tax system to reduce your bill. It is completely legal — and it is exactly what the government intended when it created those allowances.',
        ),
        _TopicIntroStep(
          title: 'Allowances you may be entitled to',
          body: 'In Mauritius, you can reduce your taxable income through your personal exemption threshold based on family situation. You may be able to deduct interest paid on a housing loan. Medical insurance contributions may be deductible up to certain limits. Supporting dependent relatives may qualify for an additional allowance.\n\nMost people claim only the basic personal exemption and miss everything else.',
        ),
        _TopicIntroStep(
          title: 'Timing can matter',
          body: 'Some tax decisions benefit from being made before the end of the tax year.\n\nContributing to an approved pension scheme before the year ends. Declaring certain income in the most tax-efficient year. Timing the sale of property to minimise registration duties.\n\nNone of this requires complex strategies — just awareness of the deadlines.',
        ),
        _TopicIntroStep(
          title: 'You are allowed to pay less than the maximum',
          body: 'There is nothing morally complex about using legal allowances to reduce your tax bill. The government created them intentionally. Using them is not a loophole — it is the system working as designed.',
          reflectionTitle: 'The basic approach',
          reflectionBullets: [
            'Know every allowance and exemption you qualify for',
            'Check before year-end whether any contributions could reduce your tax',
            'File on time — the penalties for late filing outweigh any small saving',
          ],
          reflectionNote: 'Tax planning is not about avoiding responsibility — it is about not paying more than the law requires.',
        ),
      ];
    }

    if (lessonTitle == 'Avoiding Common Tax Mistakes') {
      return const [
        _TopicIntroStep(
          title: 'Not filing because you think you owe nothing',
          body: 'Some people assume that if they do not owe any tax, there is no reason to file a return.\n\nIn Mauritius, you may be legally required to file regardless of whether you owe anything — depending on your income level and circumstances. Missing the deadline brings penalties and interest, even if the tax due is zero.',
        ),
        _TopicIntroStep(
          title: 'Not claiming everything you are entitled to',
          body: 'Dependent relative allowances. Housing loan interest relief. Medical insurance deductions.\n\nMany people pay more tax than they need to simply because they never checked what they were entitled to claim. Reviewing your full entitlement once a year — before you file — can make a real difference.',
        ),
        _TopicIntroStep(
          title: 'Not declaring side income',
          body: 'Income from freelance work, selling goods online, renting out a room, or any other source is taxable — even if you did not receive a formal payslip.\n\nMany people assume small amounts do not need to be declared. The law does not make this distinction. Undeclared income can result in back taxes, interest, and penalties.',
        ),
        _TopicIntroStep(
          title: 'The good news',
          body: 'All of these mistakes are completely avoidable with about an hour of attention once a year.\n\nFile on time. Claim everything you are entitled to. Declare all income sources. When in doubt, the MRA website has guidance — or consult a qualified tax professional.',
          reflectionTitle: 'The three mistakes to avoid',
          reflectionBullets: [
            'Not filing — even if you think you owe nothing, you may still need to file',
            'Missing deductions — review your full entitlement before submitting',
            'Not declaring side income — all income sources are taxable',
          ],
          reflectionNote: 'A small amount of attention each year prevents the most common and costly tax mistakes.',
        ),
      ];
    }

    // ── RETIREMENT PLANNING ───────────────────────────────────────────────

    if (lessonTitle == 'Introduction to Retirement Planning') {
      return const [
        _TopicIntroStep(
          title: 'What retirement actually means financially',
          body: 'Retirement is the period of your life when you stop working for income — and everything you need to live on comes from what you built beforehand.\n\nFor most people, that period lasts twenty to thirty years. That is a long time to fund without a salary.',
        ),
        _TopicIntroStep(
          title: 'Why the state pension alone is not enough',
          body: 'In Mauritius, the Basic Retirement Pension provides a foundation — but it is designed as a safety net, not a living wage.\n\nIf your goal is to maintain anything close to your pre-retirement lifestyle, you need personal savings and investments alongside whatever the government provides.',
        ),
        _TopicIntroStep(
          title: 'The three layers of retirement income',
          body: 'The most secure retirements are built on three layers.\n\nThe first is the state pension — what the government provides to everyone. The second is an occupational or employer pension scheme, if you have access to one. The third is what you build personally — your own savings and investments.\n\nMost financially secure retirees have all three. Most people in difficulty have only the first.',
        ),
        _TopicIntroStep(
          title: 'The earlier you start, the easier it becomes',
          body: 'Retirement planning is not something you do at fifty-five. Every year you delay means you need to contribute significantly more each month to reach the same outcome.\n\nThe people who have the most comfortable retirements are almost always the ones who started thinking about it early — not because they were particularly wealthy, but because time did the work for them.',
          reflectionTitle: 'The foundation',
          reflectionBullets: [
            'State pension: a starting point, not a full solution',
            'Build personal savings alongside any employer scheme',
            'Start as early as possible — time is the most valuable resource',
          ],
          reflectionNote: 'Every year of delay in retirement planning costs you compounding growth that can never be fully recovered.',
        ),
      ];
    }

    if (lessonTitle == 'Why Retirement Planning Matters') {
      return const [
        _TopicIntroStep(
          title: 'The retirement gap',
          body: 'Even with a pension, most people face a gap between what they receive and what they need to live comfortably.\n\nState pensions typically replace around thirty to fifty percent of pre-retirement income. If you were living on MUR 30,000 a month, a pension covering half of that leaves you short — for potentially twenty-five years.',
        ),
        _TopicIntroStep(
          title: 'People are living longer',
          body: 'Life expectancy has increased significantly. Someone retiring at sixty today may live another twenty-five to thirty-five years.\n\nThat means retirement savings need to last much longer than previous generations planned for — and healthcare costs, which typically rise with age, need to be factored in.',
        ),
        _TopicIntroStep(
          title: 'What waiting costs you',
          body: 'If you need MUR 5,000,000 to retire comfortably, and you start at twenty-five, you might need to save around MUR 3,800 per month.\n\nStart at thirty-five and that rises to around MUR 9,200 per month. Start at forty-five and it becomes MUR 26,000 per month.\n\nWaiting ten years does not make the problem ten years harder. It makes it roughly two to three times harder.',
        ),
        _TopicIntroStep(
          title: 'It is preventable — with time',
          body: 'Financial difficulty in retirement is one of the few financial problems that is almost entirely preventable if you start early enough.\n\nThe income you need does not appear automatically. It has to be built — and the earlier the building starts, the less effort each individual contribution requires.',
          reflectionTitle: 'The numbers that matter',
          reflectionBullets: [
            'Start at 25: around MUR 3,800/month needed',
            'Start at 35: around MUR 9,200/month needed',
            'Start at 45: around MUR 26,000/month needed',
          ],
          reflectionNote: 'Retirement poverty is real — and almost entirely preventable with early, consistent action.',
        ),
      ];
    }

    if (lessonTitle == 'Pension Systems and Retirement Funds') {
      return const [
        _TopicIntroStep(
          title: 'How the Mauritius pension system works',
          body: 'Mauritius has two main pension layers built into the system.\n\nThe Basic Retirement Pension is a universal payment available to all citizens at retirement age — regardless of employment history. The National Pension Fund is a contributory scheme where you and your employer both contribute a percentage of your salary throughout your working life.',
        ),
        _TopicIntroStep(
          title: 'What NPF actually provides',
          body: 'The NPF builds up over your working years through mandatory contributions. At retirement, it pays you a monthly income based on your contribution history.\n\nFor most people, the NPF and BRP together cover the basics — housing costs, food, essential utilities. They rarely cover the lifestyle most people expect to maintain into retirement.',
        ),
        _TopicIntroStep(
          title: 'Building your own layer on top',
          body: 'Beyond the state system, you can build personal retirement wealth through several paths.\n\nApproved private pension schemes offer tax-deductible contributions. Long-term savings and investment accounts grow independently. Property can generate rental income in retirement. A diversified investment portfolio can be drawn down gradually.\n\nThe more sources you have, the more resilient your retirement becomes.',
        ),
        _TopicIntroStep(
          title: 'Do not rely on one source',
          body: 'The state system protects everyone from the worst outcomes. But a comfortable retirement requires more than the minimum.\n\nEvery contribution you make to your own pension or investments during your working years reduces the gap between what the state provides and what you actually need.',
          reflectionTitle: 'The structure',
          reflectionBullets: [
            'BRP: universal state pension — available to all at retirement age',
            'NPF: contributory scheme — builds with your salary deductions',
            'Personal savings: your own layer — needs to be built deliberately',
          ],
          reflectionNote: 'Do not rely solely on the state pension. Build your own retirement fund alongside the mandatory contributions.',
        ),
      ];
    }

    if (lessonTitle == 'The Power of Starting Early') {
      return const [
        _TopicIntroStep(
          title: 'The most powerful financial decision you can make',
          body: 'Of all the factors that determine how much wealth you retire with — income, savings rate, investment choices — time is the most powerful by a significant margin.\n\nA person who starts saving at twenty-two and stops at thirty-two can accumulate more than someone who saves from thirty-two to sixty-two — even though the second person contributes three times as much money.',
        ),
        _TopicIntroStep(
          title: 'Why the numbers work this way',
          body: 'Compounding means that returns are reinvested, and then earn returns themselves. Over decades, the growth becomes exponential rather than linear.\n\nIn the early years, it looks slow. In the middle years, it looks steady. In the later years, it accelerates dramatically. The ten-year head start captures the most powerful part of that curve.',
        ),
        _TopicIntroStep(
          title: 'What small amounts actually become',
          body: 'MUR 500 per month from age twenty-two, invested at eight percent annual return.\n\nBy forty: approximately MUR 290,000. By fifty: approximately MUR 700,000. By sixty: approximately MUR 1,600,000.\n\nMUR 500 a month is the price of a few meals out. Over forty years, it becomes over a million and a half rupees.',
        ),
        _TopicIntroStep(
          title: 'You cannot buy back time',
          body: 'You can always earn more. You can always save a higher percentage. You can always find a slightly better investment.\n\nBut you cannot go back in time and start earlier. Every year of delay costs you a compounding cycle you cannot recover.',
          reflectionTitle: 'The message',
          reflectionBullets: [
            'Starting at 22 vs 32 matters more than doubling your savings rate',
            'Even MUR 300 to 500 a month, started early, becomes significant',
            'The best time to start was earlier. The second best time is now.',
          ],
          reflectionNote: 'Starting early is the single most powerful retirement decision available to you.',
        ),
      ];
    }

    if (lessonTitle == 'Estimating Retirement Needs') {
      return const [
        _TopicIntroStep(
          title: 'How much will you actually need?',
          body: 'A common estimate is that most people need around seventy to eighty percent of their pre-retirement income to maintain their lifestyle in retirement.\n\nWork expenses disappear. Mortgage payments may be finished. But healthcare typically increases. Leisure spending often stays. The overall number is lower than your working income — but not dramatically so.',
        ),
        _TopicIntroStep(
          title: 'How to calculate your personal target',
          body: 'Start with your desired monthly retirement income. Subtract whatever you expect to receive from the state pension. The gap that remains is what your personal savings need to cover.\n\nMultiply that annual gap by twenty-five. That is your savings target — based on the principle that withdrawing four percent of a well-invested portfolio per year is sustainable over a long retirement.',
        ),
        _TopicIntroStep(
          title: 'A worked example',
          body: 'You want MUR 30,000 a month in retirement. Your expected pension covers MUR 10,000.\n\nPersonal savings need to cover MUR 20,000 a month — MUR 240,000 a year.\n\nMUR 240,000 multiplied by twenty-five: your savings target is MUR 6,000,000.\n\nDivide that by the number of years until retirement to find your annual contribution target. Then divide by twelve to get the monthly amount.',
        ),
        _TopicIntroStep(
          title: 'The number is less scary when it is broken down',
          body: 'MUR 6,000,000 feels enormous. But MUR 4,000 a month for thirty-five years, at reasonable investment returns, gets you there — and that is before factoring in employer contributions or any additional savings.\n\nThe goal is not to save MUR 6,000,000 at once. It is to build toward it, one month at a time.',
          reflectionTitle: 'How to find your number',
          reflectionBullets: [
            'Desired monthly income minus expected pension = monthly gap',
            'Multiply annual gap by 25 to find total savings target',
            'Divide by years remaining to get your monthly contribution target',
          ],
          reflectionNote: 'Calculate your number. Then build a plan around it — starting as early as possible.',
        ),
      ];
    }

    if (lessonTitle == 'Building Long-Term Financial Security') {
      return const [
        _TopicIntroStep(
          title: 'Security is built in layers, in order',
          body: 'Long-term financial security is not the result of one good decision. It is the result of many consistent decisions, made in the right order over many years.\n\nThe order matters. Trying to invest before you have an emergency fund means one bad month forces you to sell investments. Paying for lifestyle upgrades before clearing high-interest debt costs you years.',
        ),
        _TopicIntroStep(
          title: 'The order that works',
          body: 'Phase one: build the emergency fund and clear high-interest debt. These protect you from the financial shocks that derail everything else.\n\nPhase two: maximise pension and retirement contributions. Time is still on your side here — every year you contribute earlier compounds significantly.\n\nPhase three: build an investment portfolio beyond retirement. Diversify across assets.\n\nPhase four: protect everything you have built with appropriate insurance.',
        ),
        _TopicIntroStep(
          title: 'The quiet threat: lifestyle inflation',
          body: 'As income grows, there is a natural pull to spend more. A bigger flat. A newer car. More dining out. More subscriptions.\n\nNone of this is wrong — but doing it automatically, without intention, is how people earn significantly more than they used to and still feel like they are not getting ahead.\n\nThe habit that changes this: every time your income increases, direct at least half of the increase to savings or investments before adjusting your lifestyle.',
        ),
        _TopicIntroStep(
          title: 'What consistent decisions actually produce',
          body: 'Thirty years of modest, consistent decisions — saving a percentage every month, investing regularly, avoiding high-interest debt, maintaining insurance — produce outcomes that feel extraordinary to people who never started.\n\nNot because they required sacrifice every day. Because they compounded quietly in the background while life went on.',
          reflectionTitle: 'The long-term habits',
          reflectionBullets: [
            'Protect first: emergency fund and insurance before everything else',
            'Grow consistently: invest every month regardless of amount',
            'Resist lifestyle inflation: save half of every raise before spending it',
          ],
          reflectionNote: 'Small, consistent decisions over thirty years produce outcomes that look dramatic — because compounding is exponential.',
        ),
      ];
    }

    // Default fallback
    return const [
      _TopicIntroStep(
        title: 'Why this topic matters',
        body: 'This lesson covers financial knowledge that directly affects your daily decisions and long-term outcomes.\n\nSwipe through to explore the key concepts.',
      ),
    ];
  }


  Widget _buildConceptComparison() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _premiumCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_content?.sectionLabel ?? '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[600], letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Text(_content?.heading ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
          const SizedBox(height: 16),
          ...?_content?.paragraphs.map(
            (paragraph) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black.withValues(alpha: 0.8)),
                  children: paragraph,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyTakeawayCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF007AFF).withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(color: const Color(0xFF007AFF), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.lightbulb, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Key Takeaway', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
            ],
          ),
          const SizedBox(height: 16),
          Text(_content?.takeaway ?? '', style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black.withValues(alpha: 0.8))),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening more details...'), duration: Duration(seconds: 1)));
            },
            child: Row(
              children: [
                Text(_content?.ctaLabel ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF007AFF))),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF007AFF)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFunCard() {
    final funFact = _content != null ? _content!.funFact ?? '' : '';
    final miniChallenge = _content != null ? _content!.miniChallenge ?? '' : '';
    if (funFact.isEmpty && miniChallenge.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _premiumCardDecoration(backgroundColor: const Color(0xFFFBFDFF), borderColor: const Color(0xFF007AFF).withValues(alpha: 0.12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(color: const Color(0xFF007AFF).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFF007AFF)),
              ),
              const SizedBox(width: 10),
              const Expanded(child: Text('Practice Prompt', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black))),
            ],
          ),
          const SizedBox(height: 12),
          if (funFact.isNotEmpty)
            Text('Insight: $funFact', style: TextStyle(fontSize: 13, height: 1.45, color: Colors.black.withValues(alpha: 0.75))),
          if (miniChallenge.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(miniChallenge, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.4, color: Colors.black.withValues(alpha: 0.86))),
            const SizedBox(height: 12),
            TextField(
              controller: _challengeController,
              decoration: InputDecoration(
                hintText: 'Write your response...',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: const Color(0xFF007AFF).withValues(alpha: 0.18))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: const Color(0xFF007AFF).withValues(alpha: 0.18))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF007AFF), width: 1.2)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChecklistCard() {
    if (_content == null) return const SizedBox.shrink();
    return _InfoCard(
      title: _content!.heading,
      label: _content!.sectionLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._buildParagraphWidgets(),
          ..._content!.checklist.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF34C759)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item, style: const TextStyle(fontSize: 14, color: Color(0xFF3A3A3C)))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsCard() {
    if (_content == null) return const SizedBox.shrink();
    return _InfoCard(
      title: _content!.heading,
      label: _content!.sectionLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._buildParagraphWidgets(),
          ..._content!.steps.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26, height: 26,
                    decoration: const BoxDecoration(color: Color(0xFF007AFF), shape: BoxShape.circle),
                    child: Center(child: Text('${entry.key + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(entry.value, style: const TextStyle(fontSize: 14, color: Color(0xFF3A3A3C)))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleSplitCard() {
    if (_content == null) return const SizedBox.shrink();
    return _InfoCard(
      title: _content!.heading,
      label: _content!.sectionLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _content!.ruleSplit.map(
              (rule) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFF2F6FF), borderRadius: BorderRadius.circular(20)),
                child: Text(rule, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ).toList(),
          ),
          const SizedBox(height: 12),
          ...?_content?.paragraphs.map(
            (paragraph) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RichText(
                text: TextSpan(style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black.withValues(alpha: 0.8)), children: paragraph),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerCard() {
    if (_content == null) return const SizedBox.shrink();
    return _InfoCard(
      title: _content!.heading,
      label: _content!.sectionLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._buildParagraphWidgets(),
          ..._content!.trackerRows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(row.label, style: const TextStyle(fontSize: 13, color: Color(0xFF3A3A3C))),
                  Text(row.amount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    if (_content == null) return const SizedBox.shrink();
    return _InfoCard(
      title: _content!.heading,
      label: _content!.sectionLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._buildParagraphWidgets(),
          ..._content!.tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.bolt_rounded, size: 18, color: Color(0xFFFF9500)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(tip, style: const TextStyle(fontSize: 14, color: Color(0xFF3A3A3C)))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildParagraphWidgets() {
    if (_content == null || _content!.paragraphs.isEmpty) return const [];
    return [
      ..._content!.paragraphs.map(
        (paragraph) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: RichText(
            text: TextSpan(style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black.withValues(alpha: 0.8)), children: paragraph),
          ),
        ),
      ),
      const SizedBox(height: 8),
    ];
  }

  Widget _buildTrustedSourcesCard() => const SizedBox.shrink();

  Widget _buildDeepDiveCard() {
    final example = _detailByTitle[widget.lessonTitle]?['example'] ?? _defaultDetails['example']!;
    final mistake = _detailByTitle[widget.lessonTitle]?['mistake'] ?? _defaultDetails['mistake']!;
    final action = _detailByTitle[widget.lessonTitle]?['action'] ?? _defaultDetails['action']!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _premiumCardDecoration(backgroundColor: const Color(0xFFF4F8FF)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Deep Dive', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
          const SizedBox(height: 12),
          _buildDeepDiveRow(icon: Icons.calculate_outlined, label: 'Example', text: example),
          const SizedBox(height: 10),
          _buildDeepDiveRow(icon: Icons.error_outline, label: 'Common Mistake', text: mistake),
          const SizedBox(height: 10),
          _buildDeepDiveRow(icon: Icons.task_alt, label: 'Do This Today', text: action),
        ],
      ),
    );
  }

  Widget _buildDeepDiveRow({required IconData icon, required String label, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF007AFF)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 13, height: 1.45, color: Colors.black.withValues(alpha: 0.8)),
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black)),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

class _LessonContent {
  final String sectionLabel;
  final String heading;
  final List<List<TextSpan>> paragraphs;
  final List<_ConceptCardContent> cards;
  final String takeaway;
  final String ctaLabel;
  final _LessonLayout? layout;
  final List<String> checklist;
  final List<String> steps;
  final List<String> ruleSplit;
  final List<_TrackerRow> trackerRows;
  final List<String> tips;
  final bool showDeepDive;
  final String? funFact;
  final String? miniChallenge;

  const _LessonContent({
    required this.sectionLabel,
    required this.heading,
    required this.paragraphs,
    required this.cards,
    required this.takeaway,
    required this.ctaLabel,
    this.layout,
    this.checklist = const [],
    this.steps = const [],
    this.trackerRows = const [],
    this.tips = const [],
    this.showDeepDive = true,
    this.funFact,
    this.miniChallenge,
  }) : ruleSplit = const [];
}

class _ConceptCardContent {
  final IconData icon;
  final String title;
  final String subtitle;
  final String note;

  const _ConceptCardContent({required this.icon, required this.title, required this.subtitle, required this.note});
}

class _ConceptCard extends StatelessWidget {
  final _ConceptCardContent content;
  final Color accent;

  const _ConceptCard({required this.content, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 49, height: 49,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(content.icon, color: accent, size: 28),
          ),
          const SizedBox(height: 8),
          Text(content.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(content.subtitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(content.note, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.black.withValues(alpha: 0.6), fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}

class _TrackerRow {
  final String label;
  final String amount;
  const _TrackerRow({required this.label, required this.amount});
}

class _TopicIntroStep {
  final String title;
  final String body;
  final String? reflectionTitle;
  final String? reflectionPrompt;
  final List<String> reflectionBullets;
  final String? reflectionNote;

  const _TopicIntroStep({
    required this.title,
    required this.body,
    this.reflectionTitle,
    this.reflectionPrompt,
    this.reflectionBullets = const [],
    this.reflectionNote,
  });
}

class _TopicIntroPalette {
  final List<Color> cardColors;
  final List<Color> accentColors;
  const _TopicIntroPalette({required this.cardColors, required this.accentColors});
}

enum _LessonLayout { cardsComparison, checklist, steps, ruleSplit, tracker, tips, topicIntroPremium }

class _InfoCard extends StatelessWidget {
  final String label;
  final String title;
  final Widget child;

  const _InfoCard({required this.label, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF007AFF).withValues(alpha: 0.10)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), offset: const Offset(0, 6), blurRadius: 14)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[600], letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LESSON CONTENT MAP — all 8 topics
// ─────────────────────────────────────────────────────────────────────────────

final Map<String, _LessonContent> _lessonContentByTitle = {

  // ── BUDGETING ────────────────────────────────────────────────────────────
  'Introduction to Budgeting': _LessonContent(
    sectionLabel: 'INTRODUCTION TO BUDGETING',
    heading: 'Introduction to Budgeting',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.account_balance_wallet_outlined, title: 'Plan', subtitle: 'Before spending', note: 'Give every amount a purpose'),
      _ConceptCardContent(icon: Icons.insights_outlined, title: 'Track', subtitle: 'Review regularly', note: 'Adjust and stay on course'),
    ],
    takeaway: 'Budgeting is not about saying no to everything. It is about deciding what matters — and making your money reflect that.',
    ctaLabel: 'Why this matters',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'Understanding Income': _LessonContent(
    sectionLabel: 'FOUNDATION',
    heading: 'Understanding Income',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.payments_outlined, title: 'Regular', subtitle: 'Stable', note: 'Salary/allowance'),
      _ConceptCardContent(icon: Icons.bolt_outlined, title: 'Irregular', subtitle: 'Varies', note: 'Bonus/freelance'),
    ],
    takeaway: 'Use net income and plan conservatively if your income changes month to month.',
    ctaLabel: 'How to estimate income',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'Classifying Expenses': _LessonContent(
    sectionLabel: 'CATEGORIES',
    heading: 'Classifying Expenses',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.home_outlined, title: 'Fixed', subtitle: 'Obligations', note: 'Rent, tuition'),
      _ConceptCardContent(icon: Icons.shopping_cart_outlined, title: 'Variable', subtitle: 'Flexible', note: 'Food, transport'),
    ],
    takeaway: 'Pay fixed essentials first, then control variable and discretionary spending to stay within budget.',
    ctaLabel: 'Why categories help',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'Needs vs Wants': _LessonContent(
    sectionLabel: 'DECISIONS',
    heading: 'Needs vs Wants',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.check_circle_outline, title: 'Needs', subtitle: 'Essentials', note: 'Must-pay items'),
      _ConceptCardContent(icon: Icons.star_outline, title: 'Wants', subtitle: 'Extras', note: 'Nice-to-haves'),
    ],
    takeaway: 'Labeling needs vs wants helps you make consistent choices when money is tight.',
    ctaLabel: 'Make better trade-offs',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'Developing a Budget Plan': _LessonContent(
    sectionLabel: 'SPENDING PLAN',
    heading: 'Developing a Budget Plan',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.format_list_bulleted, title: 'List', subtitle: 'Essentials first', note: 'Start with fixed costs'),
      _ConceptCardContent(icon: Icons.savings_outlined, title: 'Save', subtitle: 'Pay yourself', note: 'Plan savings early'),
    ],
    takeaway: 'A good budget is realistic: it covers essentials, includes savings, and leaves room for flexible spending.',
    ctaLabel: 'Build your first plan',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'Monitoring & Tracking Spending': _LessonContent(
    sectionLabel: 'HABIT',
    heading: 'Monitoring & Tracking Spending',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.edit_note_outlined, title: 'Track', subtitle: 'Daily', note: 'Capture every spend'),
      _ConceptCardContent(icon: Icons.insights_outlined, title: 'Review', subtitle: 'Weekly', note: 'Adjust before it\'s late'),
    ],
    takeaway: 'Tracking turns your budget from a plan into real behavior — so you can improve it week by week.',
    ctaLabel: 'How to track',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),

  // ── SAVING ───────────────────────────────────────────────────────────────
  'The Habit: Paying Yourself First': _LessonContent(
    sectionLabel: 'THE HABIT',
    heading: 'The Habit: Paying Yourself First',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.savings_outlined, title: 'Pay First', subtitle: 'Save immediately', note: 'Before spending'),
      _ConceptCardContent(icon: Icons.repeat_outlined, title: 'Repeat', subtitle: 'Every income', note: 'Build consistency'),
    ],
    takeaway: 'Saving first transforms progress from guesswork to habit.',
    ctaLabel: 'Build the habit',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'The Shield: Emergency Funds': _LessonContent(
    sectionLabel: 'THE SHIELD',
    heading: 'The Shield: Emergency Funds',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.shield_outlined, title: 'Protect', subtitle: 'Unexpected costs', note: 'Avoid debt shocks'),
      _ConceptCardContent(icon: Icons.home_repair_service_outlined, title: 'Prepare', subtitle: 'Real-life events', note: 'Use only for emergencies'),
    ],
    takeaway: 'A strong emergency fund protects your stability when life is unpredictable.',
    ctaLabel: 'Build your shield',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'The Tool: Savings Accounts': _LessonContent(
    sectionLabel: 'THE TOOL',
    heading: 'The Tool: Savings Accounts',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.account_balance_outlined, title: 'Safe', subtitle: 'Protected', note: 'Better than cash at home'),
      _ConceptCardContent(icon: Icons.trending_up_outlined, title: 'Grow', subtitle: 'Earn interest', note: 'Let money work'),
    ],
    takeaway: 'The right account keeps your emergency money safe, separate, and growing.',
    ctaLabel: 'Choose the bucket',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'The Growth: Compound Interest': _LessonContent(
    sectionLabel: 'THE GROWTH',
    heading: 'The Growth: Compound Interest',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.auto_graph_outlined, title: 'Snowball', subtitle: 'Interest on interest', note: 'Growth accelerates'),
      _ConceptCardContent(icon: Icons.schedule_outlined, title: 'Time', subtitle: 'Start early', note: 'Big advantage'),
    ],
    takeaway: 'Starting early beats starting big later because time multiplies your growth.',
    ctaLabel: 'Use time well',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'The Strategy: Automating Stability': _LessonContent(
    sectionLabel: 'THE STRATEGY',
    heading: 'The Strategy: Automating Stability',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.sync_alt_outlined, title: 'Automate', subtitle: 'Set once', note: 'Transfer on payday'),
      _ConceptCardContent(icon: Icons.psychology_alt_outlined, title: 'Less friction', subtitle: 'No willpower needed', note: 'Consistency wins'),
    ],
    takeaway: 'Automating savings removes friction and makes steady progress automatic.',
    ctaLabel: 'Make it automatic',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),

  // ── DEBT ─────────────────────────────────────────────────────────────────
  'Understanding Debt: The Mechanics of Borrowing': _LessonContent(
    sectionLabel: 'DEBT BASICS',
    heading: 'Understanding Debt: The Mechanics of Borrowing',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.payments_outlined, title: 'Principal', subtitle: 'Borrowed amount', note: 'Base debt value'),
      _ConceptCardContent(icon: Icons.percent_outlined, title: 'Interest/APR', subtitle: 'Cost of borrowing', note: 'The rent on money'),
    ],
    takeaway: 'Debt is never free: always calculate the full borrowing cost before saying yes.',
    ctaLabel: 'Know the cost',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'The "Pay Later" Illusion (Digital Debt)': _LessonContent(
    sectionLabel: 'BNPL RISKS',
    heading: 'The "Pay Later" Illusion (Digital Debt)',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.shopping_bag_outlined, title: 'Small installments', subtitle: 'Looks easy', note: 'Can hide total cost'),
      _ConceptCardContent(icon: Icons.warning_amber_rounded, title: 'Overextension', subtitle: 'Too many plans', note: 'Monthly burden spikes'),
    ],
    takeaway: 'Pay Later feels smaller, but total obligations still hit your monthly cash flow.',
    ctaLabel: 'See total commitment',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'The Minimum Payment Trap': _LessonContent(
    sectionLabel: 'PAYMENT TRAP',
    heading: 'The Minimum Payment Trap',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.trending_flat_outlined, title: 'Slow progress', subtitle: 'Debt barely moves', note: 'Interest consumes payment'),
      _ConceptCardContent(icon: Icons.hourglass_bottom_outlined, title: 'Time loss', subtitle: 'Years of repayment', note: 'Costs snowball'),
    ],
    takeaway: 'Minimum payment extends debt life and increases total cost paid.',
    ctaLabel: 'Pay faster',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'Your Financial "Grade" (The MCIB)': _LessonContent(
    sectionLabel: 'CREDIT PROFILE',
    heading: 'Your Financial "Grade" (The MCIB)',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.verified_user_outlined, title: 'Trust signal', subtitle: 'Payment behavior', note: 'Built over time'),
      _ConceptCardContent(icon: Icons.account_balance_outlined, title: 'Future access', subtitle: 'Loans and terms', note: 'Better score, better options'),
    ],
    takeaway: 'On-time payments build long-term credibility and better borrowing opportunities.',
    ctaLabel: 'Protect your score',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'Escaping the Debt Hole: The Exit Strategy': _LessonContent(
    sectionLabel: 'EXIT STRATEGY',
    heading: 'Escaping the Debt Hole: The Exit Strategy',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.block_outlined, title: 'Stop borrowing', subtitle: 'No new debt', note: 'Stabilize first'),
      _ConceptCardContent(icon: Icons.north_east_outlined, title: 'Avalanche', subtitle: 'Highest APR first', note: 'Save most interest'),
    ],
    takeaway: 'Focus and sequence matter: stop new debt, then eliminate highest-cost debt first.',
    ctaLabel: 'Start debt exit plan',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),

  // ── FINANCIAL GOALS ───────────────────────────────────────────────────────
  'Short-Term vs. Long-Term Goals': _LessonContent(
    sectionLabel: 'GOAL HORIZONS',
    heading: 'Short-Term vs. Long-Term Goals',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.schedule_outlined, title: 'Time horizon', subtitle: 'Now vs later', note: 'Match strategy to timeline'),
      _ConceptCardContent(icon: Icons.work_outline, title: 'Money job', subtitle: 'Purpose-driven saving', note: 'Named funds reduce impulse'),
    ],
    takeaway: 'Separate short, medium, and long goals so today\'s wants do not consume tomorrow\'s freedom.',
    ctaLabel: 'Sort your goals',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'Estimating Future Costs & The 10% Buffer': _LessonContent(
    sectionLabel: 'COST PLANNING',
    heading: 'Estimating Future Costs & The 10% Buffer',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.receipt_long_outlined, title: 'Total cost', subtitle: 'Beyond sticker price', note: 'Include hidden fees'),
      _ConceptCardContent(icon: Icons.shield_outlined, title: '10% buffer', subtitle: 'Safety cushion', note: 'Protects from surprises'),
    ],
    takeaway: 'Save price plus buffer so reaching your goal does not create new debt.',
    ctaLabel: 'Plan full cost',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'Creating a Financial Plan (S.M.A.R.T. Goals)': _LessonContent(
    sectionLabel: 'SMART PLANNING',
    heading: 'Creating a Financial Plan (S.M.A.R.T. Goals)',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.rule_folder_outlined, title: 'SMART', subtitle: 'Clear framework', note: 'Specific to time-bound'),
      _ConceptCardContent(icon: Icons.calculate_outlined, title: 'Monthly target', subtitle: 'Actionable math', note: 'Deadline drives amount'),
    ],
    takeaway: 'A deadline turns dreams into math, and math turns intention into action.',
    ctaLabel: 'Make it SMART',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'Tracking Progress Toward Goals': _LessonContent(
    sectionLabel: 'PROGRESS SYSTEM',
    heading: 'Tracking Progress Toward Goals',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.account_balance_wallet_outlined, title: 'Two-account hack', subtitle: 'Separate goal money', note: 'Prevents accidental spending'),
      _ConceptCardContent(icon: Icons.bar_chart_outlined, title: 'Visual tracker', subtitle: 'See momentum', note: 'Consistency gets easier'),
    ],
    takeaway: 'Track often, adjust timelines when needed, and keep the goal alive.',
    ctaLabel: 'Track your bar',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),

  // ── INVESTING ─────────────────────────────────────────────────────────────
  'Introduction to Investing': _LessonContent(
    sectionLabel: 'INVESTING BASICS',
    heading: 'Introduction to Investing',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.trending_up_outlined, title: 'Growth', subtitle: 'Beat inflation', note: 'Money works for you'),
      _ConceptCardContent(icon: Icons.foundation_outlined, title: 'Foundation first', subtitle: 'Emergency fund first', note: 'Invest safely'),
    ],
    takeaway: 'Investing is how ordinary people build extraordinary wealth — but only when the financial foundation is solid first.',
    ctaLabel: 'Start here',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'Risk and Return': _LessonContent(
    sectionLabel: 'RISK & RETURN',
    heading: 'Risk and Return',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.balance_outlined, title: 'Trade-off', subtitle: 'Higher return = higher risk', note: 'No free lunch'),
      _ConceptCardContent(icon: Icons.person_outline, title: 'Tolerance', subtitle: 'Know your limits', note: 'Match your timeline'),
    ],
    takeaway: 'Risk is not something to avoid — it is something to understand, measure, and manage.',
    ctaLabel: 'Assess your risk',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'Types of Investments (Stocks, Bonds, Funds)': _LessonContent(
    sectionLabel: 'INVESTMENT TYPES',
    heading: 'Types of Investments (Stocks, Bonds, Funds)',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.show_chart_outlined, title: 'Stocks', subtitle: 'Own a business', note: 'High return, high risk'),
      _ConceptCardContent(icon: Icons.account_balance_outlined, title: 'Bonds & Funds', subtitle: 'Lend or diversify', note: 'Lower risk options'),
    ],
    takeaway: 'Stocks for growth. Bonds for stability. Funds for diversification at low cost.',
    ctaLabel: 'Compare options',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'Diversification': _LessonContent(
    sectionLabel: 'DIVERSIFICATION',
    heading: 'Diversification',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.pie_chart_outline, title: 'Spread risk', subtitle: 'Multiple assets', note: 'Reduces impact of any one loss'),
      _ConceptCardContent(icon: Icons.language_outlined, title: 'Go wide', subtitle: 'Sectors & regions', note: 'Global exposure helps'),
    ],
    takeaway: 'Diversification does not eliminate risk — it manages it.',
    ctaLabel: 'Build your mix',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'The Power of Long-Term Investing': _LessonContent(
    sectionLabel: 'LONG-TERM MINDSET',
    heading: 'The Power of Long-Term Investing',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.hourglass_top_outlined, title: 'Stay invested', subtitle: 'Time in market', note: 'Beats timing the market'),
      _ConceptCardContent(icon: Icons.auto_graph_outlined, title: 'Compound', subtitle: 'Growth on growth', note: 'Accelerates over decades'),
    ],
    takeaway: 'The best investment strategy is the one you can stick to consistently for decades.',
    ctaLabel: 'Think long term',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'Common Investment Mistakes': _LessonContent(
    sectionLabel: 'AVOID THESE',
    heading: 'Common Investment Mistakes',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.sentiment_very_dissatisfied_outlined, title: 'Emotion', subtitle: 'Panic selling', note: 'Locks in losses'),
      _ConceptCardContent(icon: Icons.receipt_outlined, title: 'Fees', subtitle: 'Hidden cost drain', note: 'Check expense ratios'),
    ],
    takeaway: 'The biggest investment mistakes are emotional, not analytical.',
    ctaLabel: 'Stay disciplined',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),

  // ── FRAUD & SCAMS ─────────────────────────────────────────────────────────
  'Protecting from Fraud & Scams': _LessonContent(
    sectionLabel: 'FRAUD AWARENESS',
    heading: 'Protecting from Fraud & Scams',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.visibility_outlined, title: 'Awareness', subtitle: 'Know the tactics', note: 'Recognition is protection'),
      _ConceptCardContent(icon: Icons.pause_circle_outline, title: 'Pause', subtitle: 'Stop and verify', note: 'Never act under pressure'),
    ],
    takeaway: 'Your best protection is a habit of skepticism before any financial action.',
    ctaLabel: 'Stay protected',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'Common Types of Financial Scams': _LessonContent(
    sectionLabel: 'SCAM TYPES',
    heading: 'Common Types of Financial Scams',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.phishing_outlined, title: 'Phishing', subtitle: 'Fake identity', note: 'Steals your credentials'),
      _ConceptCardContent(icon: Icons.trending_up_outlined, title: 'Investment fraud', subtitle: 'Too-good returns', note: 'No risk = scam flag'),
    ],
    takeaway: 'Every scam uses greed, fear, or urgency. Recognize the trigger — and walk away.',
    ctaLabel: 'Spot the pattern',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'Online Payment and Banking Security': _LessonContent(
    sectionLabel: 'DIGITAL SECURITY',
    heading: 'Online Payment and Banking Security',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.lock_outlined, title: 'Strong habits', subtitle: 'Passwords + 2FA', note: 'First line of defense'),
      _ConceptCardContent(icon: Icons.verified_outlined, title: 'Verify', subtitle: 'Before paying', note: 'Check every detail'),
    ],
    takeaway: 'Online security is not about technology — it\'s about habits.',
    ctaLabel: 'Secure your accounts',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'Protecting Personal Information': _LessonContent(
    sectionLabel: 'PERSONAL DATA',
    heading: 'Protecting Personal Information',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.badge_outlined, title: 'Guard your ID', subtitle: 'Never share details', note: 'NID, PIN, OTP'),
      _ConceptCardContent(icon: Icons.search_outlined, title: 'Monitor', subtitle: 'Watch for theft', note: 'Check statements regularly'),
    ],
    takeaway: 'Protecting your personal information is as important as protecting your cash.',
    ctaLabel: 'Be stingy with data',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'Recognizing Warning Signs of Fraud': _LessonContent(
    sectionLabel: 'RED FLAGS',
    heading: 'Recognizing Warning Signs of Fraud',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.timer_outlined, title: 'Urgency', subtitle: 'Act now pressure', note: 'Legitimate offers wait'),
      _ConceptCardContent(icon: Icons.money_off_outlined, title: 'Upfront fees', subtitle: 'Pay to receive', note: 'Always a scam'),
    ],
    takeaway: 'When emotions spike, pause. Scammers count on you not pausing.',
    ctaLabel: 'Know the red flags',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'What To Do If You Are Scammed': _LessonContent(
    sectionLabel: 'RECOVERY STEPS',
    heading: 'What To Do If You Are Scammed',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.flash_on_outlined, title: 'Act fast', subtitle: 'Call bank first', note: 'Speed matters'),
      _ConceptCardContent(icon: Icons.report_outlined, title: 'Report', subtitle: 'Police + FSC', note: 'Helps stop others'),
    ],
    takeaway: 'Act fast, report fully, and protect yourself from follow-up fraud.',
    ctaLabel: 'Recovery steps',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),

  // ── TAXES ─────────────────────────────────────────────────────────────────
  'Introduction to Taxes': _LessonContent(
    sectionLabel: 'TAX BASICS',
    heading: 'Introduction to Taxes',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.account_balance_outlined, title: 'Mandatory', subtitle: 'Legal obligation', note: 'Funds public services'),
      _ConceptCardContent(icon: Icons.people_outline, title: 'Shared', subtitle: 'Civic responsibility', note: 'Everyone contributes'),
    ],
    takeaway: 'Understanding your tax obligations helps you plan, comply, and avoid costly mistakes.',
    ctaLabel: 'Understand taxes',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'Why Governments Collect Taxes': _LessonContent(
    sectionLabel: 'TAX PURPOSE',
    heading: 'Why Governments Collect Taxes',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.local_hospital_outlined, title: 'Public services', subtitle: 'Health, roads, schools', note: 'Shared by all'),
      _ConceptCardContent(icon: Icons.swap_horiz_outlined, title: 'Redistribution', subtitle: 'Support lower incomes', note: 'Social protection'),
    ],
    takeaway: 'Taxes fund the systems that make modern society function.',
    ctaLabel: 'Why it matters',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'Common Types of Taxes Individuals Pay': _LessonContent(
    sectionLabel: 'TAX TYPES',
    heading: 'Common Types of Taxes Individuals Pay',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.work_outline, title: 'Income tax', subtitle: 'On what you earn', note: 'PAYE deducted monthly'),
      _ConceptCardContent(icon: Icons.shopping_basket_outlined, title: 'VAT', subtitle: 'On what you buy', note: '15% in Mauritius'),
    ],
    takeaway: 'Taxes touch almost every financial transaction — know which ones apply to you.',
    ctaLabel: 'Know your taxes',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'Understanding Income Tax': _LessonContent(
    sectionLabel: 'INCOME TAX',
    heading: 'Understanding Income Tax',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.calculate_outlined, title: 'Calculation', subtitle: 'Gross minus allowances', note: 'Chargeable income'),
      _ConceptCardContent(icon: Icons.percent_outlined, title: 'Flat rate', subtitle: '15% in Mauritius', note: 'After exemption threshold'),
    ],
    takeaway: 'Your employer deducts income tax via PAYE — but understanding the calculation helps you plan and verify.',
    ctaLabel: 'Check your payslip',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'Basic Tax Planning Concepts': _LessonContent(
    sectionLabel: 'TAX PLANNING',
    heading: 'Basic Tax Planning Concepts',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.check_circle_outline, title: 'Legal', subtitle: 'Tax planning', note: 'Use all allowances'),
      _ConceptCardContent(icon: Icons.block_outlined, title: 'Illegal', subtitle: 'Tax evasion', note: 'Criminal offence'),
    ],
    takeaway: 'Tax planning is not about avoiding responsibility — it\'s about not paying more than the law requires.',
    ctaLabel: 'Plan your taxes',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'Avoiding Common Tax Mistakes': _LessonContent(
    sectionLabel: 'TAX MISTAKES',
    heading: 'Avoiding Common Tax Mistakes',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.event_outlined, title: 'File on time', subtitle: 'Meet deadlines', note: 'Penalties are avoidable'),
      _ConceptCardContent(icon: Icons.receipt_long_outlined, title: 'Claim all', subtitle: 'Use deductions', note: 'Don\'t overpay'),
    ],
    takeaway: 'Taxes do not manage themselves. An hour of planning each year saves significant money and stress.',
    ctaLabel: 'Avoid these errors',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),

  // ── RETIREMENT ────────────────────────────────────────────────────────────
  'Introduction to Retirement Planning': _LessonContent(
    sectionLabel: 'RETIREMENT BASICS',
    heading: 'Introduction to Retirement Planning',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.beach_access_outlined, title: 'Freedom', subtitle: 'Choice in later life', note: 'Built over decades'),
      _ConceptCardContent(icon: Icons.layers_outlined, title: 'Three pillars', subtitle: 'State + employer + personal', note: 'Build all three'),
    ],
    takeaway: 'Retirement planning is not something you do at 55 — it starts the moment you earn your first income.',
    ctaLabel: 'Start planning',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'Why Retirement Planning Matters': _LessonContent(
    sectionLabel: 'WHY IT MATTERS',
    heading: 'Why Retirement Planning Matters',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.hourglass_empty_outlined, title: 'Living longer', subtitle: '20–30 year retirement', note: 'Savings must last'),
      _ConceptCardContent(icon: Icons.trending_down_outlined, title: 'Cost of delay', subtitle: 'Doubles monthly saving', note: 'Every year counts'),
    ],
    takeaway: 'Retirement poverty is real — and entirely preventable with early, consistent action.',
    ctaLabel: 'Calculate the gap',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'Pension Systems and Retirement Funds': _LessonContent(
    sectionLabel: 'PENSION SYSTEMS',
    heading: 'Pension Systems and Retirement Funds',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.account_balance_outlined, title: 'NPF', subtitle: 'Contributory scheme', note: 'Employer + employee'),
      _ConceptCardContent(icon: Icons.add_circle_outline, title: 'Personal fund', subtitle: 'Your own savings', note: 'Beyond the state pension'),
    ],
    takeaway: 'Do not rely solely on the government pension. Build your own retirement fund alongside mandatory contributions.',
    ctaLabel: 'Build your pension',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'The Power of Starting Early': _LessonContent(
    sectionLabel: 'START EARLY',
    heading: 'The Power of Starting Early',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.rocket_launch_outlined, title: 'Head start', subtitle: '10 years = massive edge', note: 'Compounding accelerates'),
      _ConceptCardContent(icon: Icons.grain_outlined, title: 'Small amounts', subtitle: 'MUR 300–500/month', note: 'Adds up to millions'),
    ],
    takeaway: 'Starting early is the single most powerful retirement decision you can make.',
    ctaLabel: 'Start today',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'Estimating Retirement Needs': _LessonContent(
    sectionLabel: 'RETIREMENT TARGET',
    heading: 'Estimating Retirement Needs',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.calculate_outlined, title: '70–80% rule', subtitle: 'Of pre-retirement income', note: 'Common benchmark'),
      _ConceptCardContent(icon: Icons.savings_outlined, title: '25x rule', subtitle: 'Total savings target', note: '4% withdrawal rate'),
    ],
    takeaway: 'A retirement target feels overwhelming until you break it into a monthly savings goal — then it becomes manageable.',
    ctaLabel: 'Calculate your number',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),
  'Building Long-Term Financial Security': _LessonContent(
    sectionLabel: 'LONG-TERM SECURITY',
    heading: 'Building Long-Term Financial Security',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.foundation_outlined, title: 'Build in order', subtitle: 'Phase by phase', note: 'Each phase strengthens next'),
      _ConceptCardContent(icon: Icons.trending_flat_outlined, title: 'Resist inflation', subtitle: 'Lifestyle creep', note: 'Save every raise'),
    ],
    takeaway: 'Financial security is a decades-long project, not a single moment.',
    ctaLabel: 'Build for the long run',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
  ),

  // ── LEGACY ENTRIES ────────────────────────────────────────────────────────
  'Core Concepts': _LessonContent(
    sectionLabel: 'CORE CONCEPTS',
    heading: 'Use practical rules before advanced strategies',
    paragraphs: [
      [
        const TextSpan(text: 'Most core money decisions use the same sequence: '),
        const TextSpan(text: 'protect essentials, reduce high-cost debt, then grow savings/investments', style: TextStyle(fontWeight: FontWeight.w600)),
        const TextSpan(text: '.'),
      ],
    ],
    cards: const [
      _ConceptCardContent(icon: Icons.shield_outlined, title: 'Protect', subtitle: 'Essentials first', note: 'Stability before growth'),
      _ConceptCardContent(icon: Icons.trending_up, title: 'Grow', subtitle: 'Savings next', note: 'Step-by-step progress'),
    ],
    takeaway: 'Core concepts help you make better decisions under real-life constraints.',
    ctaLabel: 'Why this matters',
    layout: _LessonLayout.steps,
    steps: const [
      'List current commitments (housing, bills, debt, savings).',
      'Prioritize by impact: costly debt and unstable expenses first.',
      'Automate one positive habit this week (save, repay, or track).',
    ],
    showDeepDive: false,
  ),
  'Advanced Topics': _LessonContent(
    sectionLabel: 'ADVANCED STRATEGY',
    heading: 'Manage risk while aiming for growth',
    paragraphs: [
      [
        const TextSpan(text: 'Advanced planning focuses on balancing '),
        const TextSpan(text: 'return, risk, liquidity, and time horizon', style: TextStyle(fontWeight: FontWeight.w600)),
        const TextSpan(text: ' for each goal.'),
      ],
    ],
    cards: const [
      _ConceptCardContent(icon: Icons.balance_outlined, title: 'Risk', subtitle: 'Know limits', note: 'Match tolerance'),
      _ConceptCardContent(icon: Icons.account_balance_wallet_outlined, title: 'Liquidity', subtitle: 'Stay flexible', note: 'Access when needed'),
    ],
    takeaway: 'Advanced decisions work best when they still follow your fundamentals and risk boundaries.',
    ctaLabel: 'Why this matters',
    layout: _LessonLayout.tips,
    tips: const [
      'Define goal horizon: short-term, medium-term, long-term.',
      'Choose strategy based on risk tolerance and cash-flow needs.',
      'Review allocation periodically instead of reacting to daily noise.',
    ],
    showDeepDive: false,
  ),
};

// ─────────────────────────────────────────────────────────────────────────────
// DEEP DIVE DETAILS
// ─────────────────────────────────────────────────────────────────────────────

const Map<String, String> _defaultDetails = {
  'example': 'If your monthly income is MUR 30,000, assign specific amounts to essentials, savings, and flexible spending before the month starts.',
  'mistake': 'Trying to change every financial habit at once usually leads to inconsistency.',
  'action': 'Choose one measurable money action this week and track it for 7 days.',
};

final Map<String, Map<String, String>> _detailByTitle = {
  'Introduction to Budgeting': const {
    'example': 'Monthly income MUR 28,000: MUR 12,000 housing, MUR 6,000 food/transport, MUR 4,000 savings, MUR 6,000 flexible spending.',
    'mistake': 'Creating a budget once and never reviewing it again.',
    'action': 'Write your estimated monthly income and your 3 largest expenses today.',
  },
  'Understanding Income': const {
    'example': 'If your income varies, take an average of recent months and budget from that safer number.',
    'mistake': 'Planning based on your highest earning month.',
    'action': 'Estimate your net income and write it as your budgeting starting point.',
  },
  'Classifying Expenses': const {
    'example': 'Fixed: rent MUR 10,000. Variable: groceries MUR 4,500–6,000. Discretionary: dining out MUR 1,500.',
    'mistake': 'Treating variable spending like it cannot be reduced.',
    'action': 'Choose one variable category and set a weekly cap for it.',
  },
  'Needs vs Wants': const {
    'example': 'Need: transport to university. Want: extra snacks daily. If tight, keep transport, reduce snacks.',
    'mistake': 'Calling convenience spending a "need" without alternatives.',
    'action': 'Tag each expense today as Need or Want.',
  },
  'Developing a Budget Plan': const {
    'example': 'Weekly plan: essentials MUR 1,200 + savings MUR 300 + flexible MUR 500 (adjust to your income).',
    'mistake': 'Saving only what\'s left after spending.',
    'action': 'Plan a small savings amount first, then build the rest of the budget around it.',
  },
  'Monitoring & Tracking Spending': const {
    'example': 'Daily log: coffee 80 + lunch 150 + transport 60 = 290. Seeing totals helps you adjust fast.',
    'mistake': 'Tracking only large purchases and ignoring small frequent spending.',
    'action': 'Track every expense for 24 hours and review the total at night.',
  },
  'Introduction to Investing': const {
    'example': 'MUR 500/month invested at 8% annual return from age 22 grows to over MUR 1.6 million by age 60.',
    'mistake': 'Trying to invest before building an emergency fund — one bad month forces selling at a loss.',
    'action': 'Check if your emergency fund is fully funded before making your first investment.',
  },
  'Risk and Return': const {
    'example': 'A 22-year-old with 40 years until retirement can hold 80% stocks. A 55-year-old should hold far more bonds.',
    'mistake': 'Taking on more risk than your timeline and income can absorb.',
    'action': 'Write your investment goal, timeline, and one sentence on how you would feel if the value dropped 30%.',
  },
  'Types of Investments (Stocks, Bonds, Funds)': const {
    'example': 'A global index fund holds thousands of companies across many countries — diversified by design at very low cost.',
    'mistake': 'Buying individual stocks based on tips before understanding the business.',
    'action': 'Research one low-cost index fund and note its expense ratio.',
  },
  'Diversification': const {
    'example': 'Portfolio split: 60% global stocks fund, 30% bonds fund, 10% cash — simple and well-diversified.',
    'mistake': 'Holding 90% in one company or one country because it "feels safe."',
    'action': 'List every investment you currently hold and check if any single asset exceeds 20% of your total.',
  },
  'The Power of Long-Term Investing': const {
    'example': 'Staying invested through the 2008 crash and 2020 crash — both recovered to new highs within years.',
    'mistake': 'Selling everything during a market drop to "protect" savings — locking in the loss permanently.',
    'action': 'Set your investments to auto-invest monthly and do not check the price more than once a month.',
  },
  'Common Investment Mistakes': const {
    'example': 'A fund with 2% annual fees vs 0.1% — over 30 years the difference can equal 40% of your total wealth.',
    'mistake': 'Chasing this year\'s best-performing fund — it almost always underperforms next year.',
    'action': 'Check the expense ratio of any fund you currently hold or are considering.',
  },
  'Protecting from Fraud & Scams': const {
    'example': 'A scammer sends an SMS pretending to be your bank — the link looks identical to the real site but steals your login.',
    'mistake': 'Acting on urgency without verifying the sender through an official channel.',
    'action': 'Save your bank\'s official number and always call it directly instead of clicking any link.',
  },
  'Introduction to Taxes': const {
    'example': 'VAT of 15% on a MUR 1,000 grocery bill means MUR 130 of that bill goes directly to the government.',
    'mistake': 'Assuming you don\'t need to think about taxes until you earn a high salary.',
    'action': 'Check your payslip and identify how much income tax and NPF are deducted monthly.',
  },
  'Introduction to Retirement Planning': const {
    'example': 'Starting MUR 500/month at 22 vs MUR 1,500/month at 42 — the early starter wins despite contributing far less total.',
    'mistake': 'Assuming the government pension will be enough to maintain your lifestyle.',
    'action': 'Estimate what monthly income you would need at retirement and write it down.',
  },
  'Estimating Retirement Needs': const {
    'example': 'Target: MUR 30,000/month in retirement. Pension covers MUR 10,000. Personal savings must cover MUR 240,000/year → target MUR 6,000,000.',
    'mistake': 'Planning retirement income without accounting for inflation and healthcare cost growth.',
    'action': 'Calculate your retirement income gap (desired minus expected pension) and multiply by 25 to get your savings target.',
  },
};