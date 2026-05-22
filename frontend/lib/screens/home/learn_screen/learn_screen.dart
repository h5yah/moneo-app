import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'subtopic_detail_screen.dart';
import 'quiz_screen.dart';
import 'package:fintech/services/topic_progress_service.dart';
import 'package:fintech/services/xp_service.dart';
import 'survive_the_month.dart';
import 'emergency_fund_builder.dart';
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

class LearnScreen extends StatefulWidget {
  final Function(int)? onIndexChanged;
  final String? resumeTopicId;
  final bool autoOpenResumeTopic;

  const LearnScreen({
    super.key,
    this.onIndexChanged,
    this.resumeTopicId,
    this.autoOpenResumeTopic = false,
  });

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  int _selectedIndex = 1;
  int _budgetSimulatorProgress = 0;
  bool _didAutoResume = false;

  static const String _topicResetFlagKey = 'learn_topic_progress_reset_v2';
  static const String _budgetTopicResetFlagKey = 'learn_budget_topic_reset_v4';
  static const String _savingTopicResetFlagKey = 'learn_saving_topic_reset_v1';
  static const String _debtTopicResetFlagKey = 'learn_debt_topic_reset_v1';
  static const String _planningTopicResetFlagKey = 'learn_planning_topic_reset_v1';

  List<TopicMeta> get _topicsInOrder => [
        for (final id in TopicMetaService.instance.order)
          if (TopicMetaService.instance.byId[id] != null)
            TopicMetaService.instance.byId[id]!,
      ];

  @override
  void initState() {
    super.initState();
    TopicMetaService.instance.ensureLoaded();
    LearnContentService.instance.ensureLoaded();
    _resetTopicProgressOnce();
    _resetBudgetingTopicProgressOnce();
    _resetSavingTopicProgressOnce();
    _resetDebtTopicProgressOnce();
    _resetPlanningTopicProgressOnce();
    _loadBudgetSimulatorProgress();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeAutoResumeTopic();
    });
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

  Future<void> _startTopicFlow({
    required String topicId,
  }) async {
    final meta = TopicMetaService.instance.byId[topicId];
    if (meta == null) return;

    await LearnContentService.instance.ensureLoaded();

    var progressData =
        await TopicProgressService.instance.getTopicProgress(topicId);
    var preQuizDone = progressData?['preQuizCompleted'] == true;
    var shouldAutoStartFlow = false;

    if (!context.mounted) return;

    final preQuizQuestions = _getPreQuizQuestionsForTopic(topicId);
    final preQuizTotal = (progressData?['preQuizTotal'] as num?)?.toInt() ?? -1;

    // If this topic previously had no pre-quiz, we auto-marked it as completed
    // with a 0/0 result. Now that questions exist, show the pre-quiz again.
    if (preQuizDone && preQuizTotal == 0 && preQuizQuestions.isNotEmpty) {
      preQuizDone = false;
    }

    if (!preQuizDone && preQuizQuestions.isNotEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(
            quizTitle: 'Before You Start Quiz',
            questions: preQuizQuestions,
            awardXp: false,
            showCompletionFlow: false,
            revealAnswerFeedback: false,
            onQuizFinished: (score, totalQuestions) {
              return TopicProgressService.instance
                  .savePreQuizResult(
                    topicId: topicId,
                    score: score,
                    totalQuestions: totalQuestions,
                  )
                  .then((_) async {
                await XpService.instance.earnXpOnce(
                  amount: 25,
                  source: 'pre_quiz_completion',
                  awardKey: 'pre_quiz:$topicId',
                );
              });
            },
          ),
        ),
      );

      progressData =
          await TopicProgressService.instance.getTopicProgress(topicId);
      preQuizDone = progressData?['preQuizCompleted'] == true;

      if (!preQuizDone) return;
      shouldAutoStartFlow = true;
    } else if (!preQuizDone && preQuizQuestions.isEmpty) {
      // Topics with no pre-quiz should not block the learning flow.
      await TopicProgressService.instance.savePreQuizResult(
        topicId: topicId,
        score: 0,
        totalQuestions: 0,
      );
      preQuizDone = true;
      shouldAutoStartFlow = true;
    }

    if (!context.mounted) return;

    final persistedLessonsCompleted =
        (progressData?['lessonsCompleted'] as int?)?.clamp(0, meta.totalLessons) ?? 0;

    Navigator.push(
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
  }

  Future<void> _resetTopicProgressOnce() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyReset = prefs.getBool(_topicResetFlagKey) ?? false;
    if (alreadyReset) return;
    final resetSucceeded = await TopicProgressService.instance.clearAllTopicProgress();
    if (!resetSucceeded) return;
    await prefs.setBool(_topicResetFlagKey, true);
  }

  Future<void> _resetBudgetingTopicProgressOnce() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyReset = prefs.getBool(_budgetTopicResetFlagKey) ?? false;
    if (alreadyReset) return;
    await TopicMetaService.instance.ensureLoaded();
    final resetSucceeded = await TopicProgressService.instance
        .clearTopicProgress(TopicMetaService.instance.byId['budgeting_and_expense_tracking']!.id);
    if (!resetSucceeded) return;
    await prefs.setBool(_budgetTopicResetFlagKey, true);
  }

  Future<void> _resetSavingTopicProgressOnce() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyReset = prefs.getBool(_savingTopicResetFlagKey) ?? false;
    if (alreadyReset) return;
    await TopicMetaService.instance.ensureLoaded();
    final resetSucceeded = await TopicProgressService.instance
        .clearTopicProgress(TopicMetaService.instance.byId['saving_and_emergency_funds']!.id);
    if (!resetSucceeded) return;
    await prefs.setBool(_savingTopicResetFlagKey, true);
  }

  Future<void> _resetDebtTopicProgressOnce() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyReset = prefs.getBool(_debtTopicResetFlagKey) ?? false;
    if (alreadyReset) return;
    await TopicMetaService.instance.ensureLoaded();
    final resetSucceeded = await TopicProgressService.instance
        .clearTopicProgress(TopicMetaService.instance.byId['debt_management']!.id);
    if (!resetSucceeded) return;
    await prefs.setBool(_debtTopicResetFlagKey, true);
  }

  Future<void> _resetPlanningTopicProgressOnce() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyReset = prefs.getBool(_planningTopicResetFlagKey) ?? false;
    if (alreadyReset) return;
    await TopicMetaService.instance.ensureLoaded();
    final resetSucceeded = await TopicProgressService.instance.clearTopicProgress(
        TopicMetaService.instance.byId['financial_planning_for_big_goals']!.id);
    if (!resetSucceeded) return;
    await prefs.setBool(_planningTopicResetFlagKey, true);
  }

  Future<void> _loadBudgetSimulatorProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _budgetSimulatorProgress = prefs.getInt('budget_simulator_completed_level') ?? 0;
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
            _buildInteractiveScenariosSection(),
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
              color: isDark ? const Color(0xFFAAB0C6) : const Color.fromRGBO(0, 0, 0, 0.6),
              letterSpacing: -0.408,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveScenariosSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                onTap: () {},
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
              SizedBox(
                width: 240,
                height: 140,
                child: _buildScenarioCard(
                  title: 'Budget Simulator',
                  description:
                      'Practice managing a monthly budget and track expenses in a realistic scenario.',
                  progress: _budgetSimulatorProgress,
                  totalLevels: 3,
                  duration: '5 min',
                  xp: 40,
                  imageAsset: null,
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
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 240,
                height: 140,
                child: _buildScenarioCard(
                  title: 'Emergency Fund',
                  description:
                      'Learn how to prepare for unexpected expenses and build better saving habits.',
                  progress: 2,
                  totalLevels: 4,
                  duration: '7 min',
                  xp: 50,
                  imageAsset: null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EmergencyFundBuilderScreen(),
                      ),
                    );
                  },
                ),
              ),
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
            border: Border.all(color: isDark ? const Color(0xFF2A2D4A) : Colors.grey[300]!),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, size: 13, color: Colors.blue),
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
                    color: isDark ? const Color(0xFFAAB0C6) : const Color.fromRGBO(0, 0, 0, 0.6),
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
          for (int i = 0; i < _topicsInOrder.length; i++) ...[
            _buildTopicCard(meta: _topicsInOrder[i]),
            if (i < _topicsInOrder.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildTopicCard({required TopicMeta meta}) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: TopicProgressService.instance.topicProgressStream(meta.id),
      builder: (context, snapshot) {
        final persistedLessons =
            (snapshot.data?['lessonsCompleted'] as int?)?.clamp(0, meta.totalLessons);
        final displayProgress = persistedLessons ?? 0;
        final activeLessonNumber = snapshot.data?['activeLessonNumber'] as int?;
        final activeLessonStep = snapshot.data?['activeLessonStep'] as int?;
        final activeLessonTotalSteps =
            snapshot.data?['activeLessonTotalSteps'] as int?;

        final hasStepProgress = activeLessonNumber == displayProgress + 1 &&
            (activeLessonTotalSteps ?? 0) > 0 &&
            (activeLessonStep ?? 0) > 0;

        final partial = hasStepProgress
            ? ((activeLessonStep! / activeLessonTotalSteps!).clamp(0.0, 1.0))
            : 0.0;

        final displayProgressValue =
            (displayProgress + partial).clamp(0.0, meta.totalLessons.toDouble());

        Widget buildCard({required bool locked}) {
          if (locked) {
            return _buildLockedTopicCard(meta: meta);
          }
          return GestureDetector(
            onTap: () async => _startTopicFlow(topicId: meta.id),
            child: _buildUnlockedTopicCard(
              meta: meta,
              displayProgress: displayProgress,
              displayProgressValue: displayProgressValue,
            ),
          );
        }

        final lockedBecauseDisabled = !meta.enabled;

        if (meta.prerequisiteTopicId == null) {
          return buildCard(locked: lockedBecauseDisabled);
        }

        final prereqId = meta.prerequisiteTopicId!;
        final prereqMeta = TopicMetaService.instance.byId[prereqId];
        if (prereqMeta == null) return buildCard(locked: true);

        return StreamBuilder<Map<String, dynamic>?>(
          stream: TopicProgressService.instance.topicProgressStream(prereqId),
          builder: (context, prereqSnap) {
            final prereqData = prereqSnap.data;
            final prereqLessons =
                (prereqData?['lessonsCompleted'] as num?)?.toInt() ?? 0;
            final prereqAllLessonsCompleted =
                prereqData?['allLessonsCompleted'] == true;
            final prereqTopicCompleted = prereqData?['topicCompleted'] == true;
            final prereqComplete = prereqTopicCompleted ||
                prereqAllLessonsCompleted ||
                prereqLessons >= prereqMeta.totalLessons;

            return buildCard(locked: lockedBecauseDisabled || !prereqComplete);
          },
        );
      },
    );
  }

  Widget _buildLockedTopicCard({required TopicMeta meta}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1D33) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? const Color(0xFF2A2D4A) : Colors.grey[300]!),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: const LinearProgressIndicator(
                    value: 0.0,
                    minHeight: 7,
                    backgroundColor: Color(0xFFEBEBEB),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        border: Border.all(color: isDark ? const Color(0xFF2A2D4A) : Colors.grey[300]!),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: displayProgressValue / meta.totalLessons,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFEBEBEB),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(meta.progressColor),
                  ),
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

    // These are structural nodes in the learning flow, not content.
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

  // Bottom navigation is provided by HomeScreen; this screen only renders body content.
}