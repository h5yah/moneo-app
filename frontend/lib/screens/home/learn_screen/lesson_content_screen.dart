import 'package:flutter/material.dart';
import 'package:fintech/services/topic_progress_service.dart';

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
    if (direct != null) {
      return direct;
    }

    final requestedKey = _normalizeLessonKey(widget.lessonTitle);
    for (final entry in _lessonContentByTitle.entries) {
      if (_normalizeLessonKey(entry.key) == requestedKey) {
        return entry.value;
      }
    }

    final canonicalTitle = _lessonTitleAliases[requestedKey];
    if (canonicalTitle != null) {
      final aliased = _lessonContentByTitle[canonicalTitle];
      if (aliased != null) {
        return aliased;
      }
    }

    // No fallback: return null if not found
    return null;
  }

  String _normalizeLessonKey(String value) {
    return value
        .toLowerCase()
        .replaceAll('’', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  void initState() {
    super.initState();
    _content = _resolveContent();
    _challengeController.text = '';
    _triggerCardEntrance();
  }

  @override
  void didUpdateWidget(covariant LessonContentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lessonTitle != widget.lessonTitle) {
      _content = _resolveContent();
      _topicIntroIndex = 0;
      _hasSwipedTopicIntro = false;
      _didPersistInitialStepProgress = false;
      if (_topicIntroController.hasClients) {
        _topicIntroController.jumpToPage(0);
      }
      _challengeController.text = '';
      _showCards = false;
      _triggerCardEntrance();
    }
  }

  void _triggerCardEntrance() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _showCards = true;
      });
    });
  }

  Future<void> _saveStepProgress({
    required int currentStep,
    required int totalSteps,
  }) async {
    final topicId = widget.topicId;
    if (topicId == null || topicId.isEmpty) {
      return;
    }

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
  void dispose() {
    _topicIntroController.dispose();
    _challengeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.lessonTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          // Lesson Progress Section
          _buildLessonProgressSection(),
          // Content Area
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

  BoxDecoration _premiumCardDecoration({
    Color backgroundColor = Colors.white,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: borderColor ?? const Color(0xFF007AFF).withValues(alpha: 0.10),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          offset: const Offset(0, 6),
          blurRadius: 14,
        ),
      ],
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 8),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Topic Progress',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Lesson $current of $totalLessons',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF007AFF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 10,
              backgroundColor: const Color(0xFFE8EEF7),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
            ),
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
          Container(
            width: 1,
            height: 120,
            color: Colors.grey[300],
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
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
            ] else
              const SizedBox(height: 24),
            _animateCard(_buildKeyTakeawayCard()),
            const SizedBox(height: 24),
          ],
        );
      case _LessonLayout.checklist:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _animateCard(_buildChecklistCard()),
            if (_content!.showDeepDive) ...[
              const SizedBox(height: 20),
              _animateCard(_buildDeepDiveCard()),
              const SizedBox(height: 20),
            ],
            _animateCard(_buildKeyTakeawayCard()),
            const SizedBox(height: 24),
          ],
        );
      case _LessonLayout.steps:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _animateCard(_buildStepsCard()),
            if (_content!.showDeepDive) ...[
              const SizedBox(height: 20),
              _animateCard(_buildDeepDiveCard()),
              const SizedBox(height: 20),
            ],
            _animateCard(_buildKeyTakeawayCard()),
            const SizedBox(height: 24),
          ],
        );
      case _LessonLayout.ruleSplit:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _animateCard(_buildRuleSplitCard()),
            if (_content!.showDeepDive) ...[
              const SizedBox(height: 20),
              _animateCard(_buildDeepDiveCard()),
              const SizedBox(height: 20),
            ],
            _animateCard(_buildKeyTakeawayCard()),
            const SizedBox(height: 24),
          ],
        );
      case _LessonLayout.tracker:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _animateCard(_buildTrackerCard()),
            if (_content!.showDeepDive) ...[
              const SizedBox(height: 20),
              _animateCard(_buildDeepDiveCard()),
              const SizedBox(height: 20),
            ],
            _animateCard(_buildKeyTakeawayCard()),
            const SizedBox(height: 24),
          ],
        );
      case _LessonLayout.tips:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _animateCard(_buildTipsCard()),
            if (_content!.showDeepDive) ...[
              const SizedBox(height: 20),
              _animateCard(_buildDeepDiveCard()),
              const SizedBox(height: 20),
            ],
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
                  if (index > 0) {
                    _hasSwipedTopicIntro = true;
                  }
                });
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        offset: const Offset(0, 6),
                        blurRadius: 14,
                      ),
                    ],
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
                            child: Text(
                              'Step ${index + 1} of ${steps.length}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        step.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      if (index == 0 && !_hasSwipedTopicIntro) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.swipe_rounded,
                              size: 14,
                              color: accentColor.withValues(alpha: 0.85),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Swipe to continue',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: accentColor.withValues(alpha: 0.9),
                              ),
                            ),
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
                                    border: Border.all(
                                      color: accentColor.withValues(alpha: 0.22),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        step.reflectionTitle!,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      if (step.reflectionPrompt != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          step.reflectionPrompt!,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF334155),
                                          ),
                                        ),
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
                                                  padding: EdgeInsets.only(top: 2),
                                                  child: Icon(
                                                    Icons.circle,
                                                    size: 7,
                                                    color: accentColor,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    bullet,
                                                    style: const TextStyle(
                                                      fontSize: 13.5,
                                                      height: 1.35,
                                                      color: Color(0xFF1F2937),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (step.reflectionNote != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          step.reflectionNote!,
                                          style: const TextStyle(
                                            fontSize: 12.8,
                                            height: 1.35,
                                            color: Color(0xFF475569),
                                          ),
                                        ),
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
                  color: _topicIntroIndex == i
                      ? const Color(0xFF007AFF)
                      : const Color(0xFFD0D5DD),
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
                if (!mounted) {
                  return;
                }
                await _saveStepProgress(currentStep: steps.length, totalSteps: steps.length);
                if (!mounted) {
                  return;
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
        cardColors: [
          Color(0xFFFFF4D9),
          Color(0xFFE8F8EF),
          Color(0xFFEAF0FF),
          Color(0xFFFFEBDD),
          Color(0xFFE7F7F3),
        ],
        accentColors: [
          Color(0xFF9A6700),
          Color(0xFF0F766E),
          Color(0xFF4338CA),
          Color(0xFFB45309),
          Color(0xFF0F766E),
        ],
      );
    }

    return const _TopicIntroPalette(
      cardColors: [
        Color(0xFFF1E3B0),
        Color(0xFFDDF1E8),
        Color(0xFFE5E9FF),
        Color(0xFFFFE8D6),
        Color(0xFFE7F5F4),
      ],
      accentColors: [
        Color(0xFF8A5B00),
        Color(0xFF0F766E),
        Color(0xFF4F46E5),
        Color(0xFFB45309),
        Color(0xFF0F766E),
      ],
    );
  }

  Widget _buildStepBodyText(String text, double fontSize) {
    final baseStyle = TextStyle(
      fontSize: fontSize,
      height: 1.48,
      color: const Color(0xFF1F2937),
    );

    final emphasisPattern = RegExp(r'(\*\*.*?\*\*)');
    final parts = text.split(emphasisPattern);
    final matches = emphasisPattern.allMatches(text).toList();

    final spans = <TextSpan>[];
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        spans.add(TextSpan(text: parts[i], style: baseStyle));
      }
      if (i < matches.length) {
        final boldRaw = matches[i].group(0)!;
        final boldText = boldRaw.substring(2, boldRaw.length - 2);
        spans.add(
          TextSpan(
            text: boldText,
            style: baseStyle.copyWith(fontWeight: FontWeight.w800),
          ),
        );
      }
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  List<_TopicIntroStep> _topicIntroStepsForTitle(String lessonTitle) {
    if (lessonTitle == 'Introduction to Budgeting') {
      return const [
        _TopicIntroStep(
          title: 'Question (Hook)',
          body:
              'Have you ever wondered where your money goes each month?\n\nMany people spend money throughout the week without clearly tracking it. Small purchases like snacks, transport, or online subscriptions can add up quickly.\n\nWithout a clear plan, it can be difficult to know how much money is available or whether spending is under control.\n\nBudgeting helps bring clarity to how money is used.',
        ),
        _TopicIntroStep(
          title: 'What Is a Budget?',
          body:
              'A budget is a simple plan for how you will use your money over a specific period, usually a week or a month.\n\nIt helps you organize your finances by identifying:\n\n• how much money you earn\n• how much money you spend\n• how much money remains after expenses\n\nInstead of reacting to expenses as they happen, a budget allows you to decide in advance how your money should be used.',
        ),
        _TopicIntroStep(
          title: 'How Budgeting Works',
          body:
              'Budgeting is based on a simple idea:\n\n**Income − Expenses = Balance**\n\n**Income** refers to the money you receive.\n**Expenses** refer to the money you spend.\n\nIf your income is higher than your expenses, you have money available to save or invest.\n\nIf your expenses are higher than your income, it means spending may need to be adjusted.',
        ),
        _TopicIntroStep(
          title: 'Example',
          body:
              'Imagine you receive **MUR 20,000** in a month.\n\nYou spend:\n\n**Rent:** MUR 8,000\n**Food and transport:** MUR 5,000\n**Other spending:** MUR 4,000\n\n**Total expenses = MUR 17,000**\n\n**Balance = MUR 3,000**\n\nThis remaining amount can be saved or used for future goals.',
        ),
        _TopicIntroStep(
          title: 'Key Takeaway',
          body:
              'Budgeting is not about restricting your spending.\nIt is about making intentional decisions about how money is used.\n\nA budget helps you:',
          reflectionTitle: 'Key Takeaway',
          reflectionBullets: [
            'understand where your money goes',
            'control spending habits',
            'plan for future goals',
          ],
          reflectionNote: 'A budget gives your money a clear purpose before you spend it.',
        ),
      ];
    }

    if (lessonTitle == 'Understanding Income') {
      return const [
        _TopicIntroStep(
          title: 'Question (Hook)',
          body:
              'Do you know the exact amount of money you actually receive each month?\n\nMany people think about their income as the total amount they earn, but this is not always the amount they can actually spend.\n\nSome deductions may reduce the final amount of money they receive.\n\nUnderstanding your real income is an important first step in managing money effectively.',
        ),
        _TopicIntroStep(
          title: 'Gross vs Net Income',
          body:
              'There are two important ways income is measured.\n\n**Gross Income**\nThis is the total amount of money you earn before any deductions.\n\n**Net Income**\nThis is the amount of money you actually receive after deductions, such as taxes or other contributions.\n\nWhen planning a budget, experts recommend using **net income**, because it represents the money that is truly available.',
        ),
        _TopicIntroStep(
          title: 'Example',
          body:
              'Imagine you earn **MUR 25,000** per month.\n\nHowever, some deductions apply:\n\n**Tax:** MUR 2,000\n**Other deductions:** MUR 1,000\n\nYour net income becomes:\n\n**25,000 − 3,000 = MUR 22,000**\n\nThis means you should plan your budget using **MUR 22,000**, not the full amount you earn.',
        ),
        _TopicIntroStep(
          title: 'Fixed vs Variable Income',
          body:
              'Income can also be fixed or variable.\n\n**Fixed income**\nMoney that arrives regularly and is usually the same amount each time.\nExample: a monthly salary.\n\n**Variable income**\nIncome that changes depending on the work completed.\nExamples: freelance work, commissions, or part-time jobs.\n\nIf income varies each month, financial educators recommend estimating an average income to build a more stable financial plan.',
        ),
        _TopicIntroStep(
          title: 'Key Takeaway',
          body: 'Understanding your income clearly helps you:',
          reflectionTitle: 'Key Takeaway',
          reflectionBullets: [
            'build a realistic budget',
            'control spending more effectively',
            'plan savings goals',
          ],
          reflectionNote:
              'Always build your financial plan using the money you actually receive, not just the money you expect to earn.',
        ),
      ];
    }

    if (lessonTitle == 'Classifying Expenses') {
      return const [
        _TopicIntroStep(
          title: 'Question (Hook)',
          body:
              'Do you know which of your expenses stay the same and which ones change?\n\nEvery time you spend money, it falls into a type of expense. Some expenses remain predictable each month, while others vary depending on how you spend.\n\nUnderstanding these differences helps you see where your money goes and where adjustments are possible.',
        ),
        _TopicIntroStep(
          title: 'What Are Expenses?',
          body:
              'An expense is any money you spend.\n\nExpenses can include regular payments as well as daily purchases.\n\nExamples include:\n\n• housing or rent\n• groceries\n• transportation\n• subscriptions\n• entertainment\n\nTo manage money effectively, expenses are usually grouped into categories.',
        ),
        _TopicIntroStep(
          title: 'Fixed vs Variable Expenses',
          body:
              'Expenses are commonly divided into two main types.\n\n**Fixed Expenses**\nThese costs usually stay the same each month and are difficult to change in the short term.\n\nExamples include:\n\n• rent or housing payments\n• tuition fees\n• loan repayments\n• monthly subscriptions\n\n**Variable Expenses**\nThese costs change depending on how much you spend.\n\nExamples include:\n\n• groceries\n• transport\n• eating out\n• entertainment',
        ),
        _TopicIntroStep(
          title: 'Example + Key Takeaway',
          body:
              'Example monthly expenses:\n\n**Fixed expenses**\n**Rent:** MUR 8,000\n**Internet:** MUR 1,000\n\n**Variable expenses**\n**Groceries:** MUR 4,000 – 5,000\n**Transport:** MUR 1,500\n\nBecause variable expenses can change, they are usually the easiest place to reduce spending when needed.',
          reflectionTitle: 'Key Takeaway',
          reflectionNote:
              'Understanding the difference between fixed and variable expenses helps you manage your budget more effectively.\n\nSome expenses are essential, while others are optional.\n\nIn the next lesson, we will explore the difference between needs and wants.',
        ),
      ];
    }

    if (lessonTitle == 'Needs vs Wants') {
      return const [
        _TopicIntroStep(
          title: 'Question (Hook)',
          body:
              'Is every purchase you make truly necessary?\n\nWhen managing money, it is important to understand the difference between things you need and things you want.\n\nThis helps you make better decisions when planning your spending.',
        ),
        _TopicIntroStep(
          title: 'What Are Needs?',
          body:
              'Needs are things that are essential for daily living or important responsibilities.\n\nThese are expenses that are difficult to avoid.\n\nExamples include:\n\n• food\n• housing or rent\n• transportation for work or university\n• basic utilities\n\nNeeds should usually be prioritized first in a budget.',
        ),
        _TopicIntroStep(
          title: 'What Are Wants?',
          body:
              'Wants are things that improve comfort or enjoyment but are not essential.\n\nThese purchases are usually optional and can often be reduced if necessary.\n\nExamples include:\n\n• dining out\n• gaming subscriptions\n• entertainment\n• luxury items or upgrades\n\nReducing wants can help free money for saving or important expenses.',
        ),
        _TopicIntroStep(
          title: 'Example + Key Takeaway',
          body:
              'Example situation:\n\n**Bus fare to university** → **Need**\n**Buying coffee every morning** → **Want**\n\nBoth may be enjoyable, but only one is essential.',
          reflectionTitle: 'Key Takeaway',
          reflectionNote:
              'Understanding the difference between needs and wants helps you prioritize spending and control your budget.',
        ),
      ];
    }

    if (lessonTitle == 'Developing a Budget Plan') {
      return const [
        _TopicIntroStep(
          title: 'Question (Hook)',
          body:
              'Now that you understand income and expenses, how do you actually create a budget?\n\nA budget plan helps organize your money so that essential expenses are covered and some money can be saved.\n\nCreating a budget does not need to be complicated. A simple step-by-step approach is often the most effective.',
        ),
        _TopicIntroStep(
          title: 'Step 1: Identify Your Income',
          body:
              'Start by calculating the money you actually receive (**net income**).',
        ),
        _TopicIntroStep(
          title: 'Step 2–4: Plan, Save, and Spend',
          body:
              '**Step 2 — Plan essential expenses**\nList necessary costs such as housing, food, and transport.\n\n**Step 3 — Allocate savings**\nSet aside an amount for savings before spending on non-essential items.\n\n**Step 4 — Plan remaining spending**\nUse the remaining money for flexible spending such as entertainment.',
        ),
        _TopicIntroStep(
          title: 'Example + Key Takeaway',
          body:
              'Example monthly budget:\n\n**Income:** MUR 20,000\n\n**Rent:** MUR 8,000\n**Food:** MUR 5,000\n**Transport:** MUR 2,000\n\n**Savings:** MUR 3,000\n\n**Entertainment:** MUR 2,000\n\nEvery amount has a purpose.',
          reflectionTitle: 'Key Takeaway',
          reflectionNote:
              'A strong budget plans for income, essential expenses, and savings before optional spending.',
        ),
      ];
    }

    if (lessonTitle == 'Monitoring & Tracking Spending') {
      return const [
        _TopicIntroStep(
          title: 'Question (Hook)',
          body:
              'How do you know if your budget is actually working?\n\nCreating a budget is an important first step, but it is equally important to monitor how money is spent.\n\nTracking spending helps you see whether your expenses match your planned budget.',
        ),
        _TopicIntroStep(
          title: 'What Is Spending Tracking?',
          body:
              'Tracking spending means recording the money you spend on a daily or weekly basis.\n\nThis can be done using:\n\n• a budgeting app\n• a notebook\n• a spreadsheet\n\nBy keeping track of expenses, you can clearly see where your money is going.',
        ),
        _TopicIntroStep(
          title: 'Example',
          body:
              'Example of daily spending:\n\n**Morning coffee:** MUR 80\n**Lunch:** MUR 150\n**Transport:** MUR 60\n\n**Total spent today: MUR 290**\n\nRecording these expenses helps you compare your actual spending with your planned budget.',
        ),
        _TopicIntroStep(
          title: 'Key Takeaway',
          body: 'Tracking spending helps you:',
          reflectionTitle: 'Key Takeaway',
          reflectionBullets: [
            'understand spending habits',
            'identify unnecessary expenses',
            'adjust your budget when needed',
          ],
          reflectionNote:
              'Even small purchases can add up over time, so regular tracking is important.\n\nTracking spending helps you stay in control of your financial plan.',
        ),
      ];
    }

    if (lessonTitle == 'The Habit: Paying Yourself First') {
      return const [
        _TopicIntroStep(
          title: 'Question (Hook)',
          body:
              'Do you save what’s left at the end of the month, only to find there’s nothing left?\n\nMost people spend first and hope to save later. This makes saving feel like a "punishment" or a struggle.',
        ),
        _TopicIntroStep(
          title: 'Flip the Script',
          body:
              'Financial experts recommend a strategy called **Paying Yourself First**.\n\nInstead of saving what is left over, you treat your savings like a mandatory bill that you owe to your future self.',
        ),
        _TopicIntroStep(
          title: 'How it Works',
          body:
              'The moment you receive any income (salary, allowance, or gift):\n\n• Decide on a percentage (e.g., 10%).\n• Move that money to a separate account immediately.\n• Live on the remaining 90%.',
        ),
        _TopicIntroStep(
          title: 'Key Takeaway',
          body:
              'If you don’t see the money in your daily account, you won’t spend it.',
          reflectionTitle: 'Key takeaway',
          reflectionNote:
              'Saving is a "set-and-forget" habit, not a monthly struggle.',
        ),
      ];
    }

    if (lessonTitle == 'The Shield: Emergency Funds') {
      return const [
        _TopicIntroStep(
          title: 'Question (Hook)',
          body:
              'What would happen if your phone broke today and you needed MUR 5,000 to fix it?\n\nWithout savings, you might have to borrow money or skip essentials. An emergency fund is your **financial shield**. It turns a disaster into a minor inconvenience.',
        ),
        _TopicIntroStep(
          title: 'Building the Shield (Two Levels)',
          body:
              'According to global standards, build your shield in two stages:\n\n**Level 1: The Starter Fund**\nAim for **MUR 5,000 – 10,000** for small, sudden "uh-oh" moments.\n\n**Level 2: The Full Fund**\nAim for **3 to 6 months** of essential expenses for major events, like losing a job.',
        ),
        _TopicIntroStep(
          title: 'When to Use It?',
          body:
              'An emergency is: **Unplanned, Necessary, and Urgent**.\n\nEmergency:\n• Urgent medical bill\n• Broken work laptop\n\nNOT an emergency:\n• A sale at your favorite store\n• A friend’s birthday party',
        ),
        _TopicIntroStep(
          title: 'Key Takeaway',
          body:
              'An emergency fund is like a spare tire; you hope you never need it, but you’re glad it’s there.',
          reflectionTitle: 'Key takeaway',
          reflectionNote:
              'A "Shield" prevents you from falling into debt when life happens.',
        ),
      ];
    }

    if (lessonTitle == 'The Tool: Savings Accounts') {
      return const [
        _TopicIntroStep(
          title: 'Question (Hook)',
          body:
              'Is a "piggy bank" under your bed the best place for your money?\n\nWhile it feels safe, money kept at home doesn’t grow, and it’s too easy to grab when you want a snack.',
        ),
        _TopicIntroStep(
          title: 'High-Yield Savings Accounts (HYSA)',
          body:
              'A savings account is a dedicated place for your money.\n\nBanks often offer High-Yield accounts that pay you more **interest** just for keeping your money there.',
        ),
        _TopicIntroStep(
          title: 'Why Use a Bank Account?',
          body:
              '• **Safety:** Your money is protected from theft or loss.\n• **Separation:** It keeps your "Shield" away from your "Spending" money.\n• **Growth:** You earn interest, making your money work for you.',
        ),
        _TopicIntroStep(
          title: 'Key Takeaway',
          body:
              'Your money should be in a place where it is **liquid** (easy to access in a day) but **separate** (not attached to your debit card).',
          reflectionTitle: 'Key takeaway',
          reflectionNote:
              'Choose the right "bucket" for your money to help it stay safe and grow.',
        ),
      ];
    }

    if (lessonTitle == 'The Growth: Compound Interest') {
      return const [
        _TopicIntroStep(
          title: 'Question (Hook)',
          body:
              'How can MUR 1,000 grow into MUR 10,000 without you adding more money?\n\nThe answer is **Compound Interest**. It is powerful for young people because you have the one thing money can’t buy: **Time**.',
        ),
        _TopicIntroStep(
          title: 'The "Snowball" Effect',
          body:
              '• You earn interest on your original deposit.\n• Next month, you earn interest on your deposit **plus** the interest already earned.\n• Your money starts earning its own money.',
        ),
        _TopicIntroStep(
          title: 'Example',
          body:
              'If you save MUR 500 a month starting at age 18, you will have significantly more by age 30 than someone who starts at age 25, even if they save double the amount.',
        ),
        _TopicIntroStep(
          title: 'Key Takeaway',
          body:
              'Compounding works best over long periods. Starting small today is better than starting big in five years.',
          reflectionTitle: 'Key takeaway',
          reflectionNote: 'Time is your greatest financial asset. Start now.',
        ),
      ];
    }

    if (lessonTitle == 'The Strategy: Automating Stability') {
      return const [
        _TopicIntroStep(
          title: 'Question (Hook)',
          body:
              'Can you save money without even thinking about it?\n\nRelying on willpower to save is a recipe for failure. The easiest way to save is to take yourself out of the equation.',
        ),
        _TopicIntroStep(
          title: 'What Is Automation?',
          body:
              'Most banking apps let you set up a **Standing Order** or **Scheduled Transfer**.\n\nThis automatically moves money from your income account to your savings account on payday.',
        ),
        _TopicIntroStep(
          title: 'The Benefits',
          body:
              '• **No discipline required:** You don’t have to decide every month.\n• **Consistency:** Your emergency fund grows every month.\n• **Less stress:** You don’t see the money, so you don’t feel like you are missing it.',
        ),
        _TopicIntroStep(
          title: 'Key Takeaway',
          body:
              'Technology is your best friend. Set up the transfer once, and let your wealth build in the background.',
          reflectionTitle: 'Key takeaway',
          reflectionNote: 'Automate your savings to make success inevitable.',
        ),
      ];
    }

    if (lessonTitle == 'Understanding Debt: The Mechanics of Borrowing') {
      return const [
        _TopicIntroStep(
          title: 'The Hook: Buying Your Own Future',
          body:
            'When you borrow money, you aren\'t actually "getting" money—you are pulling your future income into the present. Imagine you have a time machine. You go to yourself three years from now, take 1,000 MUR out of that version of yourself\'s wallet, and bring it back to today.\n\nThe catch? The bank is the one who owns the time machine, and they charge you a "usage fee" for that trip. If you borrow 1,000 MUR today, you aren\'t just paying back that 1,000 MUR later; you are promising to give away your time and work from next year to pay for a choice you made today. If you borrow too much, you are essentially making your "future self" a slave to your "current self\'s" desires.',
        ),
        _TopicIntroStep(
          title: 'The Technical Terms: Decoding the Bank\'s Language',
          body:
            'To win at the money game, you must speak the language of the people holding the cash. Most people only look at the "Monthly Payment," but that is how people stay stuck. Professionals look at:\n\n**The Principal:** This is the "clean" number—the actual amount of cash that hits your hand or pays for your item (e.g., 5,000 MUR).\n\n**The Interest Rate:** This is the "rent" on the money. It is usually shown as a percentage (e.g., 12%).\n\n**The APR (Annual Percentage Rate):** This is the King of all numbers. A loan might say "0% Interest," but then include a 50 MUR "Monthly Admin Fee" and a 200 MUR "Processing Fee." When you add all those up, that "0% loan" might actually be a 25% APR. The APR is the only number that tells you the Total, Honest Price Tag of a loan.',
        ),
        _TopicIntroStep(
          title: 'Detailed Example',
          body:
            'Imagine you take a "Quick Loan" for 10,000 MUR at a 30% APR to buy a new gadget. Over one year, you aren\'t just paying back the 10,000 MUR; you are paying back 13,000 MUR.\n\nThink about what that extra 3,000 MUR represents: That is roughly 60 fast-food meals or 10 months of a high-speed internet subscription. By borrowing, you have essentially "deleted" those 60 meals from your future self just to have a gadget today.',
        ),
        _TopicIntroStep(
          title: 'Expanded Key Takeaway',
          body:
            'Interest is a "tax" you choose to pay on your future income. Every time you borrow at a high interest rate, you are making your future self poorer.',
          reflectionTitle: 'Key Takeaway',
          reflectionNote:
            'Always compare the APR %, not the monthly payment. A "small" monthly payment is often a mask for a massive, wealth-draining cost.',
        ),
      ];
    }

    if (lessonTitle == 'The "Pay Later" Illusion (Digital Debt)') {
      return const [
        _TopicIntroStep(
          title: 'The Hook: The "Painless" Spending Trap',
          body:
            'Retailers know that humans feel "pain" when they part with money. If you have to count out twenty 100 MUR notes to buy a shirt, your brain screams, "Wait! That\'s a lot of work!"\n\nFintech apps use Psychological Decoupling to turn that scream into a whisper. By breaking a 2,000 MUR price tag into "4 easy payments of 500 MUR," they decouple the joy of getting the shirt from the pain of paying for it. You feel like you got a 2,000 MUR item for "free" today, but you\'ve actually just signed a legal contract to give away your next four paychecks.',
        ),
        _TopicIntroStep(
          title: 'The Stacking Danger: Death by a Thousand Cuts',
          body:
            'The danger of BNPL (Buy Now, Pay Later) isn\'t one small payment; it is the Accumulation Trap. Each payment on its own is invisible, but together they create a "debt wall."\n\nWhen you have one plan for a 300 MUR shirt, another for a 400 MUR dinner, and another for a 1,000 MUR phone, you reach a state called Overextension. This is the most common reason young people go broke: they don\'t have one big debt; they have ten tiny debts that eat 50% of their income. You end up working just to pay off things you bought months ago and probably don\'t even use anymore.',
        ),
        _TopicIntroStep(
          title: 'Detailed Example',
          body:
            'Imagine your monthly income is 15,000 MUR. You see a pair of sneakers for 6,000 MUR. The app says "Pay only 1,500 MUR for 4 months." It sounds tiny!\n\nBut then, you also buy a watch (1,000 MUR/mo) and a trip (2,000 MUR/mo). Suddenly, your "small" payments total 4,500 MUR per month. Before you even pay for food or transport, 30% of your income is already gone. If you lose your job, you are still legally trapped into those payments.',
        ),
        _TopicIntroStep(
          title: 'Expanded Key Takeaway',
          body:
            '"Pay Later" apps are designed to make you forget you are spending real money. They turn your future paycheck into a list of "IOUs" before you\'ve even earned it.',
          reflectionTitle: 'Key Takeaway',
          reflectionNote:
            'If you cannot afford to buy the item twice in cash right now, you cannot afford it on credit.',
        ),
      ];
    }

    if (lessonTitle == 'The Minimum Payment Trap') {
      return const [
        _TopicIntroStep(
          title: 'The Hook',
          body:
            'Why does the bank only ask for 250 MUR when you owe 5,000 MUR? It\'s a strategy to maximize their profit.',
        ),
        _TopicIntroStep(
          title: 'How it Works',
          body:
            'The "Minimum Payment" usually only covers the Interest and almost 0 MUR of the Principal (the actual debt).',
        ),
        _TopicIntroStep(
          title: 'Detailed Example',
          body:
            'You have a credit card debt of 10,000 MUR at 20% interest. The bank sets your "Minimum Payment" at 200 MUR.\n\nIn the first month, about 166 MUR of that payment goes straight to the bank as interest. Only 34 MUR actually lowers your debt. If you continue paying only the minimum, it will take you over 15 years to pay off that 10,000 MUR!',
        ),
        _TopicIntroStep(
          title: 'Expanded Key Takeaway',
          body:
            'The "Minimum Amount Due" is the minimum required to keep the bank from suing you. It is not for your benefit.',
          reflectionTitle: 'Key Takeaway',
          reflectionNote:
            'To achieve financial freedom, you must treat the Total Balance as the only real amount due.',
        ),
      ];
    }

    if (lessonTitle == 'Your Financial "Grade" (The MCIB)') {
      return const [
        _TopicIntroStep(
          title: 'The Hook',
          body:
            'How does a bank in Mauritius know if you are "trustworthy"? They check your Credit Score via the MCIB.',
        ),
        _TopicIntroStep(
          title: 'What is Recorded?',
          body:
            'Every loan, Hire Purchase (Courts, Galaxy), or postpaid mobile contract goes on your record.',
        ),
        _TopicIntroStep(
          title: 'Detailed Example',
          body:
            'Imagine you are 20 years old. You take a "Pay Later" deal for a 5,000 MUR jacket but forget to pay the last 1,000 MUR. Three years later, you want a car loan. The bank officer sees that "Unpaid/Late" flag from three years ago and rejects your application. That 1,000 MUR mistake just cost you your dream car.',
        ),
        _TopicIntroStep(
          title: 'Expanded Key Takeaway',
          body:
            'In the modern world, your Credit Score is your "Financial Passport." A single missed payment is a stain that takes 3 to 7 years to wash away.',
          reflectionTitle: 'Key Takeaway',
          reflectionNote:
            'Treat every bill as a sacred promise.',
        ),
      ];
    }

    if (lessonTitle == 'Escaping the Debt Hole: The Exit Strategy') {
      return const [
        _TopicIntroStep(
          title: 'Stop the Bleeding',
          body:
            'The first step is to Stop Digging.',
        ),
        _TopicIntroStep(
          title: 'The Avalanche Method',
          body:
            'Pay the debt with the Highest APR first.',
        ),
        _TopicIntroStep(
          title: 'Detailed Example',
          body:
            'You have three debts: A Credit Card (24% APR), a Store Loan (12% APR), and a Friend (0% interest). Using the Avalanche Method, you pay the minimum on the store loan and the friend, but you throw every extra cent at the Credit Card. Why? Because the 24% interest is the "fire" that is burning your money the fastest.',
        ),
        _TopicIntroStep(
          title: 'Expanded Key Takeaway',
          body:
            'Getting out of debt requires a warrior mindset. You must stop the flow of new debt completely and attack your balances one by one.',
          reflectionTitle: 'Key Takeaway',
          reflectionNote:
            'Pick the biggest fire (highest interest) and put it out first.',
        ),
      ];
    }

    if (lessonTitle == 'Short-Term vs. Long-Term Goals') {
      return const [
        _TopicIntroStep(
          title: 'The Hook: The "Job" of Money',
          body:
              'If you just "save money" without a goal, your brain sees that cash as a surplus and looks for ways to spend it on snacks, games, or airtime. Professionals give every rupee a job. By naming a fund (for example, "The Tokyo Trip Fund"), you create a psychological barrier. It is no longer just money; it is your future memory.',
        ),
        _TopicIntroStep(
          title: 'The Time Horizons',
          body:
              '**Short-Term (0–1 Year):** These are spending goals that keep you from using debt for daily life (for example, a new phone or emergency fund).\n\n**Medium-Term (1–5 Years):** These are lifestyle goals that require discipline (for example, a car deposit or a professional degree).\n\n**Long-Term (5+ Years):** These are freedom goals that require a set-and-forget strategy (for example, buying land or retirement).',
        ),
        _TopicIntroStep(
          title: 'Detailed Example',
          body:
              'Imagine you want a laptop (45,000 MUR) and a house (2,000,000 MUR). If you put all your savings into one big pile, you will feel rich at 50,000 MUR and be tempted to buy a laptop and a high-end watch.\n\nThe professional move: use a Fixed Deposit for the house (where you cannot easily touch it) and a regular Savings Account for the laptop, so your goals do not fight each other.',
        ),
        _TopicIntroStep(
          title: 'Expanded Key Takeaway',
          body:
              'Categorizing your goals is like sorting your clothes—it helps you find what you need when you need it.',
          reflectionTitle: 'Key Takeaway',
          reflectionNote:
              'By separating "Now" money from "Later" money, you protect your long-term dreams from short-term impulses.',
        ),
      ];
    }

    if (lessonTitle == 'Estimating Future Costs & The 10% Buffer') {
      return const [
        _TopicIntroStep(
          title: 'The Hook: The "Sticker Price" Lie',
          body:
              'Most people fail because they save exactly what the price tag says. In the real world, the sticker price is only the beginning. Professionals save for the Total Cost of Ownership (TCO). If you ignore hidden fees, you can reach your goal and still end up broke at the finish line.',
        ),
        _TopicIntroStep(
          title: 'The 10% Buffer (Your Safety Cushion)',
          body:
              'The 10% Buffer is extra money saved above the listed price. It covers:\n\n• Government fees (registration, transfer taxes, stamps)\n• Setup costs (insurance, accessories, fuel)\n• Inflation (prices rising over time)',
        ),
        _TopicIntroStep(
          title: 'Detailed Example: The Car Trap',
          body:
              'You want a second-hand car for 200,000 MUR.\n\n**Consumer path:** saves exactly 200,000 MUR, then discovers 8,000 MUR insurance and 4,000 MUR transfer fees, leaving 0 MUR and forcing a high-interest loan.\n\n**Professional path:** saves 220,000 MUR (price + 10% buffer), pays all costs in cash, and still has money left.',
        ),
        _TopicIntroStep(
          title: 'Expanded Key Takeaway',
          body:
              'A buffer is financial insurance for your mental health. It makes goal day a celebration, not a stress test.',
          reflectionTitle: 'Key Takeaway',
          reflectionNote:
              'If you do not use the buffer, you start the next goal with a head start.',
        ),
      ];
    }

    if (lessonTitle == 'Creating a Financial Plan (S.M.A.R.T. Goals)') {
      return const [
        _TopicIntroStep(
          title: 'The Hook: Dreams vs. Deadlines',
          body:
              'A dream is wanting a car. A plan is knowing you must save 4,166 MUR every month for 3 years to buy it. Without a plan, income evaporates.',
        ),
        _TopicIntroStep(
          title: 'The Framework',
          body:
              '**Specific:** What exactly are you buying?\n**Measurable:** Exactly how much does it cost?\n**Achievable:** Can you truly save that amount monthly?\n**Relevant:** Does this improve your life, or only your ego?\n**Time-bound:** What is the deadline?',
        ),
        _TopicIntroStep(
          title: 'Detailed Example',
          body:
              '**Bad Goal:** "I want to save for a trip."\n\n**S.M.A.R.T. Goal:** "I will save 44,000 MUR (40k price + 4k buffer) for a trip to Reunion Island by December 2026 by saving 2,000 MUR every month from my salary."',
        ),
        _TopicIntroStep(
          title: 'Expanded Key Takeaway',
          body:
              'The T (Time-bound) is the most powerful part. Once you set a date, the math becomes simple.',
          reflectionTitle: 'Key Takeaway',
          reflectionNote:
              'A deadline tells you exactly how much you can spend on fun today without ruining your goal tomorrow.',
        ),
      ];
    }

    if (lessonTitle == 'Tracking Progress Toward Goals') {
      return const [
        _TopicIntroStep(
          title: 'The Hook: The "Pilot" Mentality',
          body:
              'A pilot does not check instruments only at takeoff and landing—they check constantly. If you review savings once a year, you may drift off course without noticing.',
        ),
        _TopicIntroStep(
          title: 'The "Two-Account" Hack',
          body:
              'Professionals use mental accounting. Seeing all your money in one account makes you feel rich and spend more. Moving goal money into a separate account helps you stay disciplined and protect your target.',
        ),
        _TopicIntroStep(
          title: 'Detailed Example',
          body:
              'Use a visual tracker like a bar chart or savings thermometer. Every 1,000 MUR deposit fills another section. Watching progress rise gives motivation and makes saving feel like a game you are winning.',
        ),
        _TopicIntroStep(
          title: 'Expanded Key Takeaway',
          body:
              'Life is messy. Medical bills or repairs can slow you down—and that is okay.',
          reflectionTitle: 'Key Takeaway',
          reflectionNote:
              'Adjust the date when needed, but never delete the goal. Professionals adjust; consumers quit.',
        ),
      ];
    }

    return const [
      _TopicIntroStep(
        title: 'Why Budgeting Matters',
        body:
            'A surprising fact about money is that many people don’t know where most of their income goes each month.\n\nSmall everyday expenses — coffee, food delivery, subscriptions — can quietly consume a large portion of income.\n\n**Without a plan, spending becomes reactive instead of intentional.**\n\nBudgeting helps change that.',
      ),
      _TopicIntroStep(
        title: 'The Problem',
        body:
            'Have you ever reached the end of the month and wondered:\n\n**"Where did my money go?"**\n\nThis happens because money is often spent in many small decisions throughout the month.\n\nWhen spending is not planned, it becomes difficult to:\n\n• control expenses\n• save money consistently\n• avoid financial stress\n\nA budget helps bring clarity and awareness to your finances.',
      ),
      _TopicIntroStep(
        title: 'What Budgeting Is',
        body:
            'A budget is a plan for how you will use your money.\n\nIt shows:\n\n• how much money you earn (income)\n• how much you spend (expenses)\n• how much remains afterward\n\nThe basic idea is simple:\n\n**Income − Expenses = Balance**\n\nIf your balance is positive, you can save or invest.\nIf it is negative, you need to adjust spending.',
      ),
      _TopicIntroStep(
        title: 'Simple Example',
        body:
            'Imagine your monthly income is MUR 28,000.\n\nYou plan your spending in advance:\n\n**Housing:** MUR 12,000\n**Food & transport:** MUR 6,000\n**Savings:** MUR 4,000\n**Flexible spending:** MUR 6,000\n\nEach amount has a purpose.\n\nBudgeting is not about restricting yourself — it’s about deciding where your money should go before you spend it.',
      ),
      _TopicIntroStep(
        title: 'Reflection',
        body: 'Try this now.\n\n**Write down:**',
        reflectionTitle: 'Reflection',
        reflectionPrompt: 'Try this now.',
        reflectionBullets: [
          'your estimated monthly income',
          'your three biggest expenses',
        ],
        reflectionNote: 'This is the first step to building your budget.',
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
          Text(
            _content?.sectionLabel ?? '',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _content?.heading ?? '',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ...?_content?.paragraphs.map(
            (paragraph) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black.withValues(alpha: 0.8),
                  ),
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
        border: Border.all(
          color: const Color(0xFF007AFF).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Key Takeaway',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _content?.takeaway ?? '',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              // Show more details
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening more details...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Row(
              children: [
                Text(
                  _content?.ctaLabel ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF007AFF),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: Color(0xFF007AFF),
                ),
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
    if (funFact.isEmpty && miniChallenge.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _premiumCardDecoration(
        backgroundColor: const Color(0xFFFBFDFF),
        borderColor: const Color(0xFF007AFF).withValues(alpha: 0.12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  size: 18,
                  color: Color(0xFF007AFF),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Practice Prompt',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (funFact.isNotEmpty)
            Text(
              'Insight: $funFact',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Colors.black.withValues(alpha: 0.75),
              ),
            ),
          if (miniChallenge.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              miniChallenge,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: Colors.black.withValues(alpha: 0.86),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _challengeController,
              decoration: InputDecoration(
                hintText: 'Write your response...',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: const Color(0xFF007AFF).withValues(alpha: 0.18)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: const Color(0xFF007AFF).withValues(alpha: 0.18)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF007AFF), width: 1.2),
                ),
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
          ..._content!.checklist
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF34C759)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item, style: const TextStyle(fontSize: 14, color: Color(0xFF3A3A3C))),
                      ),
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
          ..._content!.steps
              .asMap()
              .entries
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Color(0xFF007AFF),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(entry.value, style: const TextStyle(fontSize: 14, color: Color(0xFF3A3A3C))),
                      ),
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
            children: _content != null
              ? _content!.ruleSplit
                .map(
                  (rule) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F6FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(rule, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                )
                  .toList()
                : [],
          ),
          const SizedBox(height: 12),
          ...?_content?.paragraphs.map(
            (paragraph) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black.withValues(alpha: 0.8),
                  ),
                  children: paragraph,
                ),
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
          ..._content!.trackerRows
              .map(
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
          ..._content!.tips
              .map(
                (tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.bolt_rounded, size: 18, color: Color(0xFFFF9500)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(tip, style: const TextStyle(fontSize: 14, color: Color(0xFF3A3A3C))),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  List<Widget> _buildParagraphWidgets() {
    if (_content == null || _content!.paragraphs.isEmpty) {
      return const [];
    }

    return [
      ..._content!.paragraphs.map(
        (paragraph) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black.withValues(alpha: 0.8),
              ),
              children: paragraph,
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
    ];
  }

  Widget _buildTrustedSourcesCard() {
    return const SizedBox.shrink();
  }

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
          const Text(
            'Deep Dive',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _buildDeepDiveRow(
            icon: Icons.calculate_outlined,
            label: 'Example',
            text: example,
          ),
          const SizedBox(height: 10),
          _buildDeepDiveRow(
            icon: Icons.error_outline,
            label: 'Common Mistake',
            text: mistake,
          ),
          const SizedBox(height: 10),
          _buildDeepDiveRow(
            icon: Icons.task_alt,
            label: 'Do This Today',
            text: action,
          ),
        ],
      ),
    );
  }

  Widget _buildDeepDiveRow({
    required IconData icon,
    required String label,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF007AFF)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Colors.black.withValues(alpha: 0.8),
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

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

  const _ConceptCardContent({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.note,
  });
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
            width: 49,
            height: 49,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(content.icon, color: accent, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            content.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            content.subtitle,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            content.note,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.black.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
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

  const _TopicIntroPalette({
    required this.cardColors,
    required this.accentColors,
  });
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, 6),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

final Map<String, _LessonContent> _lessonContentByTitle = {
  'Introduction to Budgeting': _LessonContent(
    sectionLabel: 'INTRODUCTION TO BUDGETING',
    heading: 'Introduction to Budgeting',
    paragraphs: [
      [
        const TextSpan(text: 'A budget is a simple plan for how you will use your money over a specific period — usually weekly or monthly.'),
      ],
      [
        const TextSpan(text: 'Instead of reacting to expenses, you decide in advance how your money should be used.'),
      ],
      [
        const TextSpan(text: 'Without a plan, money tends to disappear into small daily decisions.'),
      ],
      [
        const TextSpan(text: 'Budgeting gives you better control over spending, less financial stress, clear priorities, and the ability to save consistently.'),
      ],
      [
        const TextSpan(text: 'Core idea: '),
        const TextSpan(text: 'Income − Expenses = Balance', style: TextStyle(fontWeight: FontWeight.w700)),
      ],
      [
        const TextSpan(text: 'If your balance is positive, you can save or invest. If it is negative, adjustments are needed.'),
      ],
      [
        const TextSpan(text: 'Example (monthly income MUR 28,000): MUR 12,000 for housing, MUR 6,000 for food and transport, MUR 4,000 for savings, and MUR 6,000 for flexible spending. Every amount has a purpose before you spend it.'),
      ],
    ],
    cards: const [
      _ConceptCardContent(icon: Icons.account_balance_wallet_outlined, title: 'Plan', subtitle: 'Before spending', note: 'Give every amount a purpose'),
      _ConceptCardContent(icon: Icons.insights_outlined, title: 'Track', subtitle: 'Review regularly', note: 'Adjust and stay on course'),
    ],
    takeaway: 'Budgeting is not about saying no to everything. It is about deciding what matters — and making your money reflect that.',
    ctaLabel: 'Why this matters',
    layout: _LessonLayout.topicIntroPremium,
    checklist: const [
      'How much you earn',
      'Where your money goes',
      'What remains after spending',
      'Common mistake: Making a budget and never checking it again.',
      'Try this: Write your estimated monthly income and your 3 largest expenses.',
    ],
    showDeepDive: false,
    funFact: 'Small daily spending decisions can create big monthly differences over time.',
    miniChallenge: 'Write your monthly income and your 3 biggest expenses now.',
  ),
  'Understanding Income': _LessonContent(
    sectionLabel: 'FOUNDATION (OECD)',
    heading: 'Budgeting starts with knowing your real income',
    paragraphs: [
      [
        const TextSpan(text: 'Income is money you receive from work, support, or other sources. The best budgets are based on '),
        const TextSpan(text: 'net income', style: TextStyle(fontWeight: FontWeight.w600)),
        const TextSpan(text: ' (what you actually get to use).'),
      ],
      [
        const TextSpan(text: 'Some income is regular (salary/allowance) and some is irregular (freelance/bonus). If income changes, use an average to plan safely.'),
      ],
    ],
    cards: const [
      _ConceptCardContent(icon: Icons.payments_outlined, title: 'Regular', subtitle: 'Stable', note: 'Salary/allowance'),
      _ConceptCardContent(icon: Icons.bolt_outlined, title: 'Irregular', subtitle: 'Varies', note: 'Bonus/freelance'),
    ],
    takeaway: 'Use net income and plan conservatively if your income changes month to month.',
    ctaLabel: 'How to estimate income',
    layout: _LessonLayout.topicIntroPremium,
    showDeepDive: false,
    funFact: 'Planning from the highest month can cause overspending in lower months.',
    miniChallenge: 'Estimate your average monthly income using the last 3 months (or last 3 weeks).',
  ),
  'Classifying Expenses': _LessonContent(
    sectionLabel: 'CATEGORIES (CFPB)',
    heading: 'Group expenses so you know what you can control',
    paragraphs: [
      [
        const TextSpan(text: 'Expense categorization is a standard budgeting step. It helps you separate obligations from flexible spending.'),
      ],
      [
        const TextSpan(text: 'Common categories: '),
        const TextSpan(text: 'fixed', style: TextStyle(fontWeight: FontWeight.w600)),
        const TextSpan(text: ' (usually stable), '),
        const TextSpan(text: 'variable', style: TextStyle(fontWeight: FontWeight.w600)),
        const TextSpan(text: ' (changes), and '),
        const TextSpan(text: 'discretionary', style: TextStyle(fontWeight: FontWeight.w600)),
        const TextSpan(text: ' (optional).'),
      ],
    ],
    cards: const [
      _ConceptCardContent(icon: Icons.home_outlined, title: 'Fixed', subtitle: 'Obligations', note: 'Rent, tuition'),
      _ConceptCardContent(icon: Icons.shopping_cart_outlined, title: 'Variable', subtitle: 'Flexible', note: 'Food, transport'),
    ],
    takeaway: 'Pay fixed essentials first, then control variable/discretionary spending to stay within budget.',
    ctaLabel: 'Why categories help',
    layout: _LessonLayout.topicIntroPremium,
    checklist: const [
      'Fixed: rent, tuition, loan payments',
      'Variable: groceries, utilities, transport',
      'Discretionary: eating out, shopping, entertainment',
    ],
    showDeepDive: false,
    funFact: 'Budgets fail most often due to underestimated variable spending.',
    miniChallenge: 'List 2 fixed, 2 variable, and 2 discretionary expenses from your week.',
  ),
  'Needs vs Wants': _LessonContent(
    sectionLabel: 'DECISIONS (OECD)',
    heading: 'Prioritize essentials before lifestyle extras',
    paragraphs: [
      [
        const TextSpan(text: 'Needs are essential for basic functioning (food, transport to class/work, utilities). Wants improve comfort but are optional (treats, upgrades).'),
      ],
      [
        const TextSpan(text: 'A key decision skill is recognizing trade-offs: spending on one thing means less money for another goal.'),
      ],
    ],
    cards: const [
      _ConceptCardContent(icon: Icons.check_circle_outline, title: 'Needs', subtitle: 'Essentials', note: 'Must-pay items'),
      _ConceptCardContent(icon: Icons.star_outline, title: 'Wants', subtitle: 'Extras', note: 'Nice-to-haves'),
    ],
    takeaway: 'Labeling needs vs wants helps you make consistent choices when money is tight.',
    ctaLabel: 'Make better trade-offs',
    layout: _LessonLayout.topicIntroPremium,
    checklist: const [
      'Ask: “Will this affect my essentials if I buy it?”',
      'If income dropped, what would I cut first?',
      'Pause 10 seconds before buying a “want”.',
    ],
    showDeepDive: false,
    funFact: 'A short pause reduces impulse spending.',
    miniChallenge: 'Pick one “want” to postpone this week and write how much you saved.',
  ),
  'Developing a Budget Plan': _LessonContent(
    sectionLabel: 'SPENDING PLAN STEPS',
    heading: 'Build a simple plan you can actually follow',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.format_list_bulleted, title: 'List', subtitle: 'Essentials first', note: 'Start with fixed costs'),
      _ConceptCardContent(icon: Icons.savings_outlined, title: 'Save', subtitle: 'Pay yourself', note: 'Plan savings early'),
    ],
    takeaway: 'A good budget is realistic: it covers essentials, includes savings, and leaves room for flexible spending.',
    ctaLabel: 'Build your first plan',
    layout: _LessonLayout.topicIntroPremium,
    steps: const [
      'Start with net income (what you actually receive).',
      'Cover fixed essentials first (rent/tuition/bills).',
      'Set a savings amount (even small) before wants.',
      'Allocate the rest across variable categories.',
      'Keep a small buffer for unexpected costs.',
    ],
    showDeepDive: false,
    funFact: 'Even small planned savings builds the habit faster than “saving what’s left”.',
    miniChallenge: 'Create a 1-week budget with 3 categories: essentials, savings, and flexible spending.',
  ),
  'Monitoring & Tracking Spending': _LessonContent(
    sectionLabel: 'HABIT (WORLD BANK/CFPB)',
    heading: 'Tracking helps you notice patterns and adjust early',
    paragraphs: const [],
    cards: const [
      _ConceptCardContent(icon: Icons.edit_note_outlined, title: 'Track', subtitle: 'Daily', note: 'Capture every spend'),
      _ConceptCardContent(icon: Icons.insights_outlined, title: 'Review', subtitle: 'Weekly', note: 'Adjust before it’s late'),
    ],
    takeaway: 'Tracking turns your budget from a plan into real behavior—so you can improve it week by week.',
    ctaLabel: 'How to track',
    layout: _LessonLayout.topicIntroPremium,
    trackerRows: const [
      _TrackerRow(label: 'Coffee', amount: 'MUR 80'),
      _TrackerRow(label: 'Lunch', amount: 'MUR 150'),
      _TrackerRow(label: 'Transport', amount: 'MUR 60'),
      _TrackerRow(label: 'Snack', amount: 'MUR 40'),
    ],
    showDeepDive: false,
    funFact: 'Frequent tracking is linked to better budget adherence.',
    miniChallenge: 'Log every expense for 24 hours and tag each as need or want.',
  ),
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
  'Core Concepts': _LessonContent(
    sectionLabel: 'CORE CONCEPTS',
    heading: 'Use practical rules before advanced strategies',
    paragraphs: [
      [
        const TextSpan(text: 'Most core money decisions use the same sequence: '),
        const TextSpan(text: 'protect essentials, reduce high-cost debt, then grow savings/investments', style: TextStyle(fontWeight: FontWeight.w600)),
        const TextSpan(text: '.'),
      ],
      [
        const TextSpan(text: 'A common mistake is trying to optimize everything at once. Start with one lever: expense control, debt reduction, or automated saving.'),
      ],
      [
        const TextSpan(text: 'Example: Paying an expensive credit balance earlier can free monthly cash flow for future savings goals.'),
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
    funFact: 'Automation is one of the most reliable ways to improve money habits.',
    miniChallenge: 'Pick one recurring financial action to automate this week.',
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
      [
        const TextSpan(text: 'Higher potential return usually means higher volatility. Diversification and time discipline help reduce concentration risk.'),
      ],
      [
        const TextSpan(text: 'Example: Long-term goals may use growth-focused assets, while short-term goals should stay in safer, more liquid options.'),
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
    funFact: 'Consistency over time often matters more than timing the perfect entry.',
    miniChallenge: 'For one goal, write your horizon, risk level, and review frequency.',
  ),
};

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
    'mistake': 'Calling convenience spending a “need” without alternatives.',
    'action': 'Tag each expense today as Need or Want.',
  },
  'Developing a Budget Plan': const {
    'example': 'Weekly plan: essentials MUR 1,200 + savings MUR 300 + flexible MUR 500 (adjust to your income).',
    'mistake': 'Saving only what’s left after spending.',
    'action': 'Plan a small savings amount first, then build the rest of the budget around it.',
  },
  'Monitoring & Tracking Spending': const {
    'example': 'Daily log: coffee 80 + lunch 150 + transport 60 = 290. Seeing totals helps you adjust fast.',
    'mistake': 'Tracking only large purchases and ignoring small frequent spending.',
    'action': 'Track every expense for 24 hours and review the total at night.',
  },
};
