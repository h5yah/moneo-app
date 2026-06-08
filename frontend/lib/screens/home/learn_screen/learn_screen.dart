import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'subtopic_detail_screen.dart';
import 'quiz_screen.dart';
import 'package:fintech/services/topic_progress_service.dart';
import 'package:fintech/services/xp_service.dart';
import 'survive_the_month.dart';
import 'emergency_fund_builder.dart';
import 'quick_scenario_screen.dart';
import 'package:fintech/services/topic_meta_service.dart';
import 'package:fintech/services/learn_content_service.dart';

enum LessonStatus { completed, current, locked, quiz }

class LessonItem {
  final String title;
  final String description;
  final LessonStatus status;
  final String? step;
  final String? duration;

  LessonItem({
    required this.title,
    required this.status,
    this.description = '',
    this.step,
    this.duration,
  });
}

class _InteractiveScenario {
  final String title;
  final String description;
  final int progress;
  final int totalLevels;
  final String duration;
  final int? xp;
  final VoidCallback onTap;

  const _InteractiveScenario({
    required this.title,
    required this.description,
    required this.progress,
    required this.totalLevels,
    required this.duration,
    required this.onTap,
    this.xp,
  });
}

class LearnScreen extends StatefulWidget {
  final Function(int)? onIndexChanged;
  final String? resumeTopicId;
  final bool autoOpenResumeTopic;
  final int? progressReplaySeed;
  final GlobalKey? walkthroughScenariosKey;
  final GlobalKey? walkthroughTopicsKey;

  const LearnScreen({
    super.key,
    this.onIndexChanged,
    this.resumeTopicId,
    this.autoOpenResumeTopic = false,
    this.progressReplaySeed,
    this.walkthroughScenariosKey,
    this.walkthroughTopicsKey,
  });

  @override
  State<LearnScreen> createState() => LearnScreenState();
}

class LearnScreenState extends State<LearnScreen> {
  int _budgetSimulatorProgress = 0;
  bool _didAutoResume = false;
  bool _topicMetaReady = false;
  bool _openingTopic = false;
  int _topicBarsReplay = 0;
  Map<String, Map<String, dynamic>> _progressByTopic = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _progressSub;
  StreamSubscription<Map<String, Map<String, dynamic>>>? _localProgressSub;
  Timer? _progressReloadDebounce;

  List<TopicMeta> get _topicsInOrder => [
        for (final id in TopicMetaService.instance.order)
          if (TopicMetaService.instance.byId[id] != null)
            TopicMetaService.instance.byId[id]!,
      ];

  @override
  void initState() {
    super.initState();
    _topicMetaReady = TopicMetaService.instance.isLoaded &&
        LearnContentService.instance.isLoaded;
    _initLearnScreen();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeAutoResumeTopic();
    });
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    _localProgressSub?.cancel();
    _progressReloadDebounce?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(LearnScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoOpenResumeTopic &&
        widget.resumeTopicId != null &&
        (oldWidget.resumeTopicId != widget.resumeTopicId ||
            !oldWidget.autoOpenResumeTopic)) {
      _didAutoResume = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeAutoResumeTopic();
      });
    }

    if (oldWidget.progressReplaySeed != widget.progressReplaySeed) {
      _replayTopicBars();
    }
  }

  Widget _wrapWalkthroughTarget(GlobalKey? key, Widget child) {
    if (key == null) return child;
    return KeyedSubtree(key: key, child: child);
  }

  Future<void> _initLearnScreen() async {
    await TopicMetaService.instance.ensureLoaded();
    if (!mounted) return;
    setState(() => _topicMetaReady = true);

    await LearnContentService.instance.ensureLoaded();
    await _loadBudgetSimulatorProgress();
    await _bootstrapTopicProgress();
  }

  Future<void> _bootstrapTopicProgress() async {
    await TopicMetaService.instance.ensureLoaded();

    final local = await TopicProgressService.instance.loadLocalProgress();
    if (mounted && local.isNotEmpty) {
      _applyProgressMap(local);
    }

    final merged = await TopicProgressService.instance.loadAllProgress();
    if (!mounted) return;
    _applyProgressMap(merged);

    _progressSub?.cancel();
    _progressSub =
        TopicProgressService.instance.watchAllTopicProgressSnapshots().listen(
              (_) => _scheduleProgressReload(),
            );

    _localProgressSub?.cancel();
    _localProgressSub =
        TopicProgressService.instance.progressUpdates.listen((map) {
      if (!mounted) return;
      _applyProgressMap(map);
    });
  }

  void _scheduleProgressReload() {
    _progressReloadDebounce?.cancel();
    _progressReloadDebounce =
        Timer(const Duration(milliseconds: 250), () async {
      if (!mounted) return;
      final next = await TopicProgressService.instance.loadAllProgress();
      if (!mounted) return;
      _applyProgressMap(next);
    });
  }

  Future<void> refreshTopicProgress() async {
    await _reloadTopicProgressFromServer();
    _replayTopicBars();
  }

  void replayTopicBars() => _replayTopicBars();

  void _replayTopicBars() {
    if (!mounted) return;
    setState(() => _topicBarsReplay++);
  }

  void _applyProgressMap(Map<String, Map<String, dynamic>> next) {
    if (_progressMapsEqual(_progressByTopic, next)) return;
    setState(() => _progressByTopic = next);
  }

  bool _progressMapsEqual(
    Map<String, Map<String, dynamic>> a,
    Map<String, Map<String, dynamic>> b,
  ) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final other = b[entry.key];
      if (other == null) return false;
      final lessonsA = (entry.value['lessonsCompleted'] as num?)?.toInt() ?? 0;
      final lessonsB = (other['lessonsCompleted'] as num?)?.toInt() ?? 0;
      if (lessonsA != lessonsB) return false;
      if (entry.value['topicCompleted'] != other['topicCompleted']) {
        return false;
      }
      if (entry.value['allLessonsCompleted'] != other['allLessonsCompleted']) {
        return false;
      }
    }
    for (final id in b.keys) {
      if (!a.containsKey(id)) return false;
    }
    return true;
  }

  Future<void> _reloadTopicProgressFromServer() async {
    final merged = await TopicProgressService.instance.loadAllProgress();
    if (!mounted) return;
    _applyProgressMap(merged);
  }

  Widget _buildLessonProgressBar({
    required double value,
    required Color color,
    Color backgroundColor = const Color(0xFFEBEBEB),
    String? replayKey,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: TweenAnimationBuilder<double>(
        key: replayKey == null ? null : ValueKey(replayKey),
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 850),
        curve: Curves.easeOutCubic,
        builder: (context, animatedValue, _) {
          return LinearProgressIndicator(
            value: animatedValue,
            minHeight: 7,
            backgroundColor: backgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          );
        },
      ),
    );
  }

  bool _isTopicComplete(Map<String, dynamic>? data, TopicMeta meta) {
    if (data == null) return false;
    if (data['topicCompleted'] == true) return true;
    if (data['allLessonsCompleted'] == true) return true;
    final lessons = (data['lessonsCompleted'] as num?)?.toInt() ?? 0;
    return lessons >= meta.totalLessons;
  }

  bool _isTopicUnlocked(TopicMeta meta) {
    if (!meta.enabled) return false;
    final prereqId = meta.prerequisiteTopicId;
    if (prereqId == null || prereqId.isEmpty) return true;
    final prereqMeta = TopicMetaService.instance.byId[prereqId];
    if (prereqMeta == null) return false;
    return _isTopicComplete(_progressByTopic[prereqId], prereqMeta);
  }

  String? _prerequisiteTitle(TopicMeta meta) {
    final prereqId = meta.prerequisiteTopicId;
    if (prereqId == null || prereqId.isEmpty) return null;
    return TopicMetaService.instance.byId[prereqId]?.title;
  }

  int _lessonsCompletedForTopic(TopicMeta meta) {
    return TopicProgressService.lessonsCompletedFrom(
      _progressByTopic[meta.id],
      meta.totalLessons,
    );
  }

  void _maybeAutoResumeTopic() {
    if (!mounted ||
        _didAutoResume ||
        !widget.autoOpenResumeTopic ||
        widget.resumeTopicId == null) {
      return;
    }

    _didAutoResume = true;
    final topicId = widget.resumeTopicId!;
    final meta = TopicMetaService.instance.byId[topicId];
    if (meta == null) return;
    _startTopicFlow(topicId: meta.id);
  }

  Future<void> _openTopic(String topicId) async {
    if (_openingTopic) return;
    setState(() => _openingTopic = true);
    try {
      await _startTopicFlow(topicId: topicId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_topicOpenErrorMessage(e)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _openingTopic = false);
        await refreshTopicProgress();
      }
    }
  }

  String _topicOpenErrorMessage(Object error) {
    if (error is StateError) {
      return error.message;
    }
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'Progress could not be saved. Deploy Firestore rules from the backend folder.';
      }
      return error.message ?? 'Could not open this topic.';
    }
    return 'Could not open this topic. Please try again.';
  }

  Future<void> _startTopicFlow({
    required String topicId,
  }) async {
    final meta = TopicMetaService.instance.byId[topicId];
    if (meta == null) {
      throw StateError('Topic not found.');
    }

    if (FirebaseAuth.instance.currentUser == null) {
      throw StateError('Please sign in to start this topic.');
    }

    await LearnContentService.instance.ensureLoaded();

    var progressData = _progressByTopic[topicId];
    progressData ??=
        await TopicProgressService.instance.getTopicProgress(topicId);
    progressData ??= <String, dynamic>{};

    var preQuizDone = progressData['preQuizCompleted'] == true;
    var shouldAutoStartFlow = false;

    if (!mounted) return;

    final preQuizQuestions = _getPreQuizQuestionsForTopic(topicId);
    final preQuizTotal = (progressData['preQuizTotal'] as num?)?.toInt() ?? -1;

    if (preQuizDone && preQuizTotal == 0 && preQuizQuestions.isNotEmpty) {
      preQuizDone = false;
    }

    if (!preQuizDone && preQuizQuestions.isNotEmpty) {
      final quizResult = await Navigator.push<Map<String, dynamic>?>(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(
            quizTitle: 'Before You Start Quiz',
            questions: preQuizQuestions,
            awardXp: false,
            showCompletionFlow: false,
            revealAnswerFeedback: false,
            onQuizFinished: (score, totalQuestions) {
              return TopicProgressService.instance.savePreQuizResult(
                topicId: topicId,
                score: score,
                totalQuestions: totalQuestions,
              );
            },
          ),
        ),
      );

      if (quizResult == null) return;

      preQuizDone = true;
      shouldAutoStartFlow = true;
      progressData = {
        ...progressData,
        'preQuizCompleted': true,
        'preQuizScore': quizResult['score'],
        'preQuizTotal': quizResult['totalQuestions'],
      };

      unawaited(
        XpService.instance
            .earnXpOnce(
          amount: 25,
          source: 'pre_quiz_completion',
          awardKey: 'pre_quiz:$topicId',
        )
            .catchError((Object error) {
          debugPrint('Pre-quiz XP award failed: $error');
          return const XpEarnResult(xp: 0, awarded: false);
        }),
      );
    } else if (!preQuizDone && preQuizQuestions.isEmpty) {
      await TopicProgressService.instance.savePreQuizResult(
        topicId: topicId,
        score: 0,
        totalQuestions: 0,
      );
      preQuizDone = true;
      shouldAutoStartFlow = true;
    }

    if (!mounted) return;

    final persistedLessonsCompleted = TopicProgressService.lessonsCompletedFrom(
      progressData,
      meta.totalLessons,
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubtopicDetailScreen(
          topicId: topicId,
          preQuizCompleted: preQuizDone,
          autoStartFlow: shouldAutoStartFlow,
          topicTitle: meta.title,
          currentLesson: persistedLessonsCompleted,
          totalLessons: meta.totalLessons,
          lessons: _getLessonsForTopic(topicId),
        ),
      ),
    );

    try {
      await _reloadTopicProgressFromServer();
    } catch (_) {
    }
  }

  Future<void> _loadBudgetSimulatorProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _budgetSimulatorProgress =
          prefs.getInt('budget_simulator_completed_level') ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF0F1020) : const Color(0xFFFFFFFF),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _wrapWalkthroughTarget(
              widget.walkthroughScenariosKey,
              _buildInteractiveScenariosSection(),
            ),
            const SizedBox(height: 32),
            _buildAllTopicsSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(35, 18, 35, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learn',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -0.408,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Short lessons to improve your financial knowledge',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: isDark
                  ? const Color(0xFFAAB0C6)
                  : const Color.fromRGBO(0, 0, 0, 0.6),
              letterSpacing: -0.408,
            ),
          ),
        ],
      ),
    );
  }

  List<_InteractiveScenario> _interactiveScenarios() {
    return [
      _InteractiveScenario(
        title: 'Budget Simulator',
        description:
            'Practice managing a monthly budget and track expenses in a realistic scenario.',
        progress: _budgetSimulatorProgress,
        totalLevels: 3,
        duration: '5 min',
        xp: 100,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SurviveTheMonthScreen(),
            ),
          );
          _loadBudgetSimulatorProgress();
        },
      ),
      _InteractiveScenario(
        title: 'Emergency Fund',
        description:
            'Handle unexpected expenses and build a starter emergency fund.',
        progress: 2,
        totalLevels: 4,
        duration: '7 min',
        xp: 100,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const EmergencyFundBuilderScreen(),
            ),
          );
        },
      ),
      _InteractiveScenario(
        title: 'Needs vs Wants',
        description:
            'Make quick spending choices and learn what should come first.',
        progress: 0,
        totalLevels: 3,
        duration: '4 min',
        xp: 75,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const QuickScenarioScreen(
                title: 'Needs vs Wants',
                subtitle: 'Choose what to prioritize when money is limited.',
                completionMessage:
                    'Nice work. You practiced separating important spending from nice-to-have purchases.',
                xpAward: 75,
                xpAwardKey: 'scenario:needs_vs_wants',
                steps: [
                  QuickScenarioStep(
                    prompt:
                        'Your bus pass for the week costs Rs 200, but you also want new earbuds. What comes first?',
                    options: [
                      'Top up the bus pass because you need transport',
                      'Buy the earbuds and figure out transport later',
                      'Use all your savings for both',
                    ],
                    bestOptionIndex: 0,
                    feedback:
                        'Transport is a need when it gets you to school, work, or errands. Earbuds can wait.',
                  ),
                  QuickScenarioStep(
                    prompt:
                        'You have Rs 500 left for the week in Mauritius. Which plan is strongest?',
                    options: [
                      'Food and mobile data first, then decide on snacks',
                      'Buy cafe drinks now and worry later',
                      'Spend half on games and hope the rest is enough',
                    ],
                    bestOptionIndex: 0,
                    feedback:
                        'Cover essentials first. Wants are easier to enjoy when your basics are already protected.',
                  ),
                  QuickScenarioStep(
                    prompt:
                        'A Port Louis sale makes you feel rushed. What should you do?',
                    options: [
                      'Pause and check if it matches your budget',
                      'Buy now because the discount might disappear',
                      'Use credit so it does not affect today',
                    ],
                    bestOptionIndex: 0,
                    feedback:
                        'A quick pause helps you avoid impulse spending, even when a sale looks exciting.',
                  ),
                ],
              ),
            ),
          );
        },
      ),
      _InteractiveScenario(
        title: 'Debt Decision',
        description:
            'Compare loan, BNPL, and cash options before making a purchase.',
        progress: 0,
        totalLevels: 3,
        duration: '6 min',
        xp: 100,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const QuickScenarioScreen(
                title: 'Debt Decision',
                subtitle:
                    'Think through repayment before choosing borrowed money.',
                completionMessage:
                    'You reviewed how debt choices affect your future budget.',
                xpAward: 100,
                xpAwardKey: 'scenario:debt_decision',
                steps: [
                  QuickScenarioStep(
                    prompt:
                        'A Rs 8,000 phone can be paid now or split into monthly payments. What should you check first?',
                    options: [
                      'Total cost, fees, and whether repayments fit your budget',
                      'Only the monthly payment amount',
                      'Whether your friends think it is worth it',
                    ],
                    bestOptionIndex: 0,
                    feedback:
                        'Small payments can hide fees. The total cost and repayment fit matter most.',
                  ),
                  QuickScenarioStep(
                    prompt:
                        'Your budget is already tight after transport and groceries. What is the safest choice?',
                    options: [
                      'Delay the purchase until you can afford it',
                      'Borrow and hope next month is easier',
                      'Take a second payment plan to cover it',
                    ],
                    bestOptionIndex: 0,
                    feedback:
                        'Delaying protects you from stacking payments when your budget is already stretched.',
                  ),
                  QuickScenarioStep(
                    prompt: 'Which sign means a debt option may be risky?',
                    options: [
                      'You do not understand the late fees',
                      'The repayment date matches payday',
                      'The seller explains the total cost clearly',
                    ],
                    bestOptionIndex: 0,
                    feedback:
                        'If fees or penalties are unclear, pause before agreeing to the debt.',
                  ),
                ],
              ),
            ),
          );
        },
      ),
      _InteractiveScenario(
        title: 'Savings Goal Sprint',
        description:
            'Choose a goal, adjust monthly savings, and beat the deadline.',
        progress: 0,
        totalLevels: 3,
        duration: '5 min',
        xp: 100,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const QuickScenarioScreen(
                title: 'Savings Goal Sprint',
                subtitle: 'Build a simple plan for reaching a savings target.',
                completionMessage:
                    'Great job. You practiced turning a goal into a realistic monthly plan.',
                xpAward: 100,
                xpAwardKey: 'scenario:savings_goal_sprint',
                steps: [
                  QuickScenarioStep(
                    prompt:
                        'You want to save Rs 6,000 in 3 months for a laptop repair. What is the clearest target?',
                    options: [
                      'Save Rs 2,000 each month',
                      'Save whatever is left over',
                      'Wait until the final month and try harder',
                    ],
                    bestOptionIndex: 0,
                    feedback:
                        'A monthly target makes the goal easier to track and less stressful.',
                  ),
                  QuickScenarioStep(
                    prompt:
                        'You missed one week of saving. What should you do next?',
                    options: [
                      'Adjust the next few weeks slightly and keep going',
                      'Give up because the plan is ruined',
                      'Spend the savings since the goal is delayed',
                    ],
                    bestOptionIndex: 0,
                    feedback:
                        'A good plan can flex. Small adjustments help you recover without quitting.',
                  ),
                  QuickScenarioStep(
                    prompt: 'What makes a savings goal stronger?',
                    options: [
                      'A clear amount, deadline, and reason',
                      'A vague wish to save more',
                      'A target based only on social media trends',
                    ],
                    bestOptionIndex: 0,
                    feedback:
                        'Specific goals are easier to measure, motivate, and complete.',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ];
  }

  Future<void> _openAllScenarios() async {
    final scenarios = _interactiveScenarios();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryText = isDark ? Colors.white : Colors.black;
        final iconColor =
            isDark ? Colors.white70 : Colors.black.withValues(alpha: 0.55);

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F1020) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Interactive Scenarios',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: primaryText,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: Icon(Icons.close, color: iconColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: scenarios.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final scenario = scenarios[index];
                      return SizedBox(
                        height: 144,
                        child: _buildScenarioCard(
                          title: scenario.title,
                          description: scenario.description,
                          progress: scenario.progress,
                          totalLevels: scenario.totalLevels,
                          duration: scenario.duration,
                          xp: scenario.xp,
                          onTap: () {
                            Navigator.pop(sheetContext);
                            scenario.onTap();
                          },
                        ),
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

  Widget _buildInteractiveScenariosSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scenarios = _interactiveScenarios();
    final featuredScenarios = scenarios.take(2).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 38),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Interactive Scenarios',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.408,
                ),
              ),
              GestureDetector(
                onTap: _openAllScenarios,
                child: const Text(
                  'Browse All',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF007AFF),
                    letterSpacing: -0.408,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 38),
          child: Row(
            children: [
              for (int i = 0; i < featuredScenarios.length; i++) ...[
                SizedBox(
                  width: 240,
                  height: 140,
                  child: _buildScenarioCard(
                    title: featuredScenarios[i].title,
                    description: featuredScenarios[i].description,
                    progress: featuredScenarios[i].progress,
                    totalLevels: featuredScenarios[i].totalLevels,
                    duration: featuredScenarios[i].duration,
                    xp: featuredScenarios[i].xp,
                    onTap: featuredScenarios[i].onTap,
                  ),
                ),
                if (i < featuredScenarios.length - 1) const SizedBox(width: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScenarioCard({
    required String title,
    required String description,
    required int progress,
    required int totalLevels,
    required String duration,
    int? xp,
    String? imageAsset,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1D33) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isDark ? const Color(0xFF2A2D4A) : Colors.grey[300]!),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageAsset != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      imageAsset,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        duration,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color.fromRGBO(0, 0, 0, 0.55),
                          letterSpacing: -0.408,
                        ),
                      ),
                    ),
                    if (xp != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                size: 13, color: Colors.blue),
                            const SizedBox(width: 3),
                            Text(
                              '$xp XP',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                                letterSpacing: -0.408,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.408,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? const Color(0xFFAAB0C6)
                        : const Color.fromRGBO(0, 0, 0, 0.6),
                    letterSpacing: -0.408,
                    height: 1.27,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllTopicsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 38),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _wrapWalkthroughTarget(
            widget.walkthroughTopicsKey,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Topics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.408,
                  ),
                ),
                const SizedBox(height: 16),
                if (!_topicMetaReady)
                  const SizedBox(
                    height: 88,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_topicsInOrder.isNotEmpty)
                  _buildTopicCard(meta: _topicsInOrder.first),
              ],
            ),
          ),
          if (_topicMetaReady && _topicsInOrder.length > 1) ...[
            const SizedBox(height: 12),
            for (int i = 1; i < _topicsInOrder.length; i++) ...[
              _buildTopicCard(meta: _topicsInOrder[i]),
              if (i < _topicsInOrder.length - 1) const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTopicCard({required TopicMeta meta}) {
    final locked = !_isTopicUnlocked(meta);
    final displayProgress = _lessonsCompletedForTopic(meta);
    final displayProgressValue = displayProgress.toDouble();

    if (locked) {
      return _buildLockedTopicCard(meta: meta);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openingTopic ? null : () => _openTopic(meta.id),
      child: SizedBox(
        width: double.infinity,
        child: _buildUnlockedTopicCard(
          meta: meta,
          displayProgress: displayProgress,
          displayProgressValue: displayProgressValue,
        ),
      ),
    );
  }

  Widget _buildLockedTopicCard({required TopicMeta meta}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prereqTitle = _prerequisiteTitle(meta);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          final message = prereqTitle != null
              ? 'Finish "$prereqTitle" to unlock this topic.'
              : 'Complete the previous topic to unlock this one.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1D33) : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isDark ? const Color(0xFF2A2D4A) : Colors.grey[300]!,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: meta.iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    meta.icon,
                    color: meta.iconColor.withValues(alpha: 0.6),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFAAB0C6)
                            : Colors.black.withValues(alpha: 0.65),
                        letterSpacing: -0.408,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Locked',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                            letterSpacing: -0.408,
                          ),
                        ),
                        Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildLessonProgressBar(
                      value: 0,
                      color: Colors.grey,
                      replayKey: 'locked-${meta.id}-$_topicBarsReplay',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnlockedTopicCard({
    required TopicMeta meta,
    required int displayProgress,
    required double displayProgressValue,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1D33) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
            color: isDark ? const Color(0xFF2A2D4A) : Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: meta.iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(meta.icon, color: meta.iconColor, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.408,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$displayProgress/${meta.totalLessons} lessons completed',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF007AFF),
                        letterSpacing: -0.408,
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 8),
                _buildLessonProgressBar(
                  value: meta.totalLessons > 0
                      ? displayProgressValue / meta.totalLessons
                      : 0,
                  color: meta.progressColor,
                  replayKey: '${meta.id}-$_topicBarsReplay',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<LessonItem> _getLessonsForTopic(String topicId) {
    final lessonData = LearnContentService.instance.lessonsForTopic(topicId);
    final coreLessons = lessonData
        .map(
          (l) => LessonItem(
            step: l.step,
            title: l.title,
            duration: l.duration,
            status: LessonStatus.current,
          ),
        )
        .toList(growable: false);

    return [
      LessonItem(
        step: 'PRE-QUIZ',
        title: 'Before You Start Quiz',
        duration: '5 min',
        status: LessonStatus.quiz,
      ),
      ...coreLessons,
      LessonItem(
        step: 'FINAL QUIZ',
        title: 'Final Quiz',
        duration: '5 min',
        status: LessonStatus.quiz,
      ),
    ];
  }

  List<QuizQuestion> _getPreQuizQuestionsForTopic(String topicId) {
    return LearnContentService.instance.preQuizQuestionsForTopic(topicId);
  }
}
