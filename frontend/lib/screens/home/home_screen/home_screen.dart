import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../learn_screen/learn_screen.dart';
import '../finance_screen/finance_screen.dart';
import '../deals_screen/deals_screen.dart';
import '../profile_screen/profile_screen.dart';
import '../ai_assistant/ai_assistant.dart';
import 'currency_converter_screen.dart';
import 'savings_calculator_screen.dart';
import 'loan_calculator_screen.dart';
import 'tip_splitter_screen.dart';
import 'notifications_screen.dart';
import 'package:fintech/services/topic_progress_service.dart';
import 'package:fintech/services/topic_meta_service.dart';
import 'package:fintech/services/app_theme_controller.dart';
import 'package:fintech/services/app_notification_service.dart';
import 'package:fintech/services/xp_service.dart';
import 'package:fintech/services/walkthrough_service.dart';
import 'package:fintech/widgets/app_walkthrough.dart';
import 'package:fintech/utils/icon_accent_style.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.userName});

  final String? userName;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _reviewCompleted = false;
  int _selectedIndex = 0;
  int _previousNavIndex = 0;
  int _dealsArcReplay = 0;
  int _learningProgressReplay = 0;
  int _learnTopicBarsReplay = 0;
  int _financeProgressReplay = 0;
  bool _showStreakCelebration = false;
  int _celebrationStreakDays = 0;
  bool _hasShownStreakCelebration = false;
  int? _pendingStreakCelebrationDays;
  bool _isCelebratingLevelUp = false;
  int? _observedLevel;
  Timer? _levelUpDismissTimer;
  OverlayEntry? _levelUpOverlay;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _levelSubscription;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _activeTopicId = 'budgeting_and_expense_tracking';
  Map<String, dynamic>? _activeTopicData;
  String? _pendingResumeTopicId;
  bool _pendingAutoOpenResumeTopic = false;

  final GlobalKey<LearnScreenState> _learnTabKey =
      GlobalKey<LearnScreenState>();
  final GlobalKey _financeTabKey = GlobalKey();
  final GlobalKey _dealsTabKey = GlobalKey();

  final GlobalKey _wtLearningKey = GlobalKey();
  final GlobalKey _wtStreakKey = GlobalKey();
  final GlobalKey _wtScenariosKey = GlobalKey();
  final GlobalKey _wtTopicsKey = GlobalKey();
  final GlobalKey _wtBalanceKey = GlobalKey();
  final GlobalKey _wtFinanceToolsKey = GlobalKey();
  final GlobalKey _wtAiNavKey = GlobalKey();
  final GlobalKey _wtDealsNavKey = GlobalKey();
  final GlobalKey _wtProfileKey = GlobalKey();
  double _walkthroughBodyOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    TopicMetaService.instance.ensureLoaded();
    _loadActiveTopicProgress();
    _watchLevelUps();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runPostLoginFlow();
    });
  }

  Future<void> _runPostLoginFlow() async {
    await _updateStreakIfNeeded();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    await _showAppWalkthrough();
    if (!mounted) return;
    _flushPendingStreakCelebration();
  }

  void _flushPendingStreakCelebration() {
    final days = _pendingStreakCelebrationDays;
    if (days == null) return;
    _pendingStreakCelebrationDays = null;
    _showStreakCelebrationOverlay(days);
  }

  Future<void> _walkthroughSelectTab(int index) async {
    if (!mounted) return;
    try {
      if (_selectedIndex != index) {
        setState(() => _walkthroughBodyOpacity = 0.4);
        await Future<void>.delayed(const Duration(milliseconds: 120));
        if (!mounted) return;

        setState(() {
          _previousNavIndex = _selectedIndex;
          _selectedIndex = index;
          if (index == 0) _learningProgressReplay++;
          if (index == 1) _learnTopicBarsReplay++;
          if (index == 3) _financeProgressReplay++;
          if (index == 4) _dealsArcReplay++;
        });

        if (index == 0) {
          _loadActiveTopicProgress();
        } else if (index == 1) {
          _learnTabKey.currentState?.refreshTopicProgress();
          _learnTabKey.currentState?.replayTopicBars();
        }

        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        setState(() => _walkthroughBodyOpacity = 1.0);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      if (!mounted) return;
      await WidgetsBinding.instance.endOfFrame;
    } finally {
      if (mounted && _walkthroughBodyOpacity != 1.0) {
        setState(() => _walkthroughBodyOpacity = 1.0);
      }
    }
  }

  Future<void> _replayAppWalkthrough() async {
    if (!mounted) return;
    setState(() {
      _previousNavIndex = _selectedIndex;
      _selectedIndex = 0;
    });
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await _showAppWalkthrough();
  }

  Future<void> _showAppWalkthrough() async {
    if (!mounted) return;

    try {
    Future<void> goHome() => _walkthroughSelectTab(0);
    Future<void> goLearn() => _walkthroughSelectTab(1);
    Future<void> goFinance() => _walkthroughSelectTab(3);
    Future<void> goDeals() => _walkthroughSelectTab(4);

    await AppWalkthrough.show(
      context,
      tourId: WalkthroughService.appTourId,
      steps: [
        WalkthroughStep(
          targetKey: _wtLearningKey,
          title: 'Your lessons',
          message: 'Tap here anytime to continue learning and earn XP.',
          beforeShow: goHome,
        ),
        WalkthroughStep(
          targetKey: _wtStreakKey,
          title: 'Daily streak',
          message: 'Come back each day to grow your streak.',
          beforeShow: goHome,
        ),
        WalkthroughStep(
          targetKey: _wtScenariosKey,
          title: 'Try scenarios',
          message: 'Practice real-life money decisions with no real risk.',
          beforeShow: goLearn,
        ),
        WalkthroughStep(
          targetKey: _wtTopicsKey,
          title: 'Your topics',
          message: 'Work through bite-sized lessons, one topic at a time.',
          beforeShow: goLearn,
        ),
        WalkthroughStep(
          targetKey: _wtAiNavKey,
          title: 'AI assistant',
          message:
              'Tap the owl anytime to ask about money, lessons, or budgeting.',
          position: WalkthroughTooltipPosition.above,
          beforeShow: goLearn,
        ),
        WalkthroughStep(
          targetKey: _wtBalanceKey,
          title: 'Practice wallet',
          message:
              'This is simulated money, perfect for learning safely.',
          beforeShow: goFinance,
        ),
        WalkthroughStep(
          targetKey: _wtFinanceToolsKey,
          title: 'Tools & planning',
          message:
              'Use quick actions, set savings goals, and plan your monthly budget.',
          beforeShow: goFinance,
        ),
        WalkthroughStep(
          targetKey: _wtDealsNavKey,
          title: 'Rewards & deals',
          message: 'Redeem XP for discounts and check in for daily rewards.',
          position: WalkthroughTooltipPosition.above,
          beforeShow: goDeals,
        ),
        WalkthroughStep(
          targetKey: _wtProfileKey,
          title: 'Your profile',
          message:
              'View your progress, update settings, and manage your account.',
          beforeShow: goHome,
        ),
      ],
    );
    } finally {
      if (mounted) {
        setState(() => _walkthroughBodyOpacity = 1.0);
      }
    }
  }

  @override
  void dispose() {
    _levelUpDismissTimer?.cancel();
    _levelUpOverlay?.remove();
    _levelSubscription?.cancel();
    super.dispose();
  }

  String get _displayName {
    if (widget.userName == null || widget.userName!.trim().isEmpty)
      return 'there';
    return widget.userName!.trim();
  }

  void _replayLearningProgress() {
    if (!mounted) return;
    setState(() => _learningProgressReplay++);
  }

  void _watchLevelUps() {
    final user = _auth.currentUser;
    if (user == null) return;

    _levelSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      if (!mounted || !snapshot.exists) return;

      final data = snapshot.data() ?? <String, dynamic>{};
      final currentXp = (data['xp'] as num?)?.toInt() ?? 0;
      final currentLevel = XpService.levelMetaFromTotalXp(currentXp).level;
      final lastCelebratedRaw = data['lastCelebratedLevel'];
      final lastCelebratedLevel =
          lastCelebratedRaw is num ? lastCelebratedRaw.toInt() : null;

      final previousObservedLevel = _observedLevel;
      if (previousObservedLevel == null) {
        _observedLevel = currentLevel;
        if (lastCelebratedLevel == null || lastCelebratedLevel < currentLevel) {
          _setLastCelebratedLevel(user.uid, currentLevel);
        }
        return;
      }

      _observedLevel = currentLevel;

      if (currentLevel <= previousObservedLevel ||
          currentLevel <= 1 ||
          _isCelebratingLevelUp) {
        return;
      }

      if (lastCelebratedLevel != null && currentLevel <= lastCelebratedLevel) {
        return;
      }

      _celebrateLevelUp(user.uid, currentLevel);
    });
  }

  Future<void> _setLastCelebratedLevel(String uid, int level) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'lastCelebratedLevel': level,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
    }
  }

  Future<void> _celebrateLevelUp(String uid, int level) async {
    _isCelebratingLevelUp = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final overlay = Overlay.of(context, rootOverlay: true);
      _levelUpOverlay?.remove();
      _levelUpOverlay = OverlayEntry(
        builder: (_) => _LevelUpCelebrationOverlay(level: level),
      );
      overlay.insert(_levelUpOverlay!);

      _levelUpDismissTimer?.cancel();
      _levelUpDismissTimer =
          Timer(const Duration(milliseconds: 3200), () async {
        _levelUpOverlay?.remove();
        _levelUpOverlay = null;

        await _setLastCelebratedLevel(uid, level);

        if (mounted) {
          setState(() => _isCelebratingLevelUp = false);
        } else {
          _isCelebratingLevelUp = false;
        }
      });
    });
  }

  int _tabStackIndex(int navIndex) {
    switch (navIndex) {
      case 1:
        return 1;
      case 3:
        return 2;
      case 4:
        return 3;
      default:
        return 0;
    }
  }

  void _selectNavIndex(int index, {bool clearLearnResume = false}) {
    if (index == _selectedIndex) return;

    setState(() {
      _previousNavIndex = _selectedIndex;
      _selectedIndex = index;
      if (clearLearnResume && index != 1) {
        _pendingResumeTopicId = null;
        _pendingAutoOpenResumeTopic = false;
      }
      if (index == 0) _learningProgressReplay++;
      if (index == 1) _learnTopicBarsReplay++;
      if (index == 3) _financeProgressReplay++;
      if (index == 4) _dealsArcReplay++;
    });

    if (index == 0) {
      _loadActiveTopicProgress();
    } else if (index == 1) {
      _learnTabKey.currentState?.refreshTopicProgress();
      _learnTabKey.currentState?.replayTopicBars();
    }
  }

  Widget _buildTabStack() {
    final activeIndex = _tabStackIndex(_selectedIndex);
    final previousIndex = _tabStackIndex(_previousNavIndex);
    final slideDirection =
        activeIndex >= previousIndex ? 1.0 : -1.0;

    Widget tabLayer(int index, Widget child) {
      return Positioned.fill(
        child: _NavTabTransition(
          isActive: activeIndex == index,
          slideDirection: slideDirection,
          child: child,
        ),
      );
    }

    final layers = <Widget>[
      tabLayer(0, _buildHomeBody()),
      tabLayer(
        1,
        LearnScreen(
          key: _learnTabKey,
          walkthroughScenariosKey: _wtScenariosKey,
          walkthroughTopicsKey: _wtTopicsKey,
          resumeTopicId: _pendingResumeTopicId,
          autoOpenResumeTopic: _pendingAutoOpenResumeTopic,
          progressReplaySeed: _learnTopicBarsReplay,
          onIndexChanged: (i) => _selectNavIndex(i, clearLearnResume: true),
        ),
      ),
      tabLayer(
        2,
        FinanceScreen(
          key: _financeTabKey,
          walkthroughBalanceKey: _wtBalanceKey,
          walkthroughFinanceToolsKey: _wtFinanceToolsKey,
          progressReplaySeed: _financeProgressReplay,
          onIndexChanged: _selectNavIndex,
        ),
      ),
      tabLayer(
        3,
        DealsScreen(
          key: _dealsTabKey,
          arcReplaySeed: _dealsArcReplay,
          isActive: _selectedIndex == 4,
          onIndexChanged: _selectNavIndex,
        ),
      ),
    ];

    // Paint the entering tab on top so its slide is always visible.
    final activeLayer = layers.removeAt(activeIndex);
    layers.add(activeLayer);

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: layers,
    );
  }

  String get _formattedDate {
    final now = DateTime.now();
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  Future<void> _loadActiveTopicProgress() async {
    await TopicMetaService.instance.ensureLoaded();
    final metas = TopicMetaService.instance.byId;
    final order = TopicMetaService.instance.order;
    if (order.isEmpty) return;
    String selectedId = order.first;
    Map<String, dynamic>? selectedData;

    for (final id in order) {
      final meta = metas[id];
      if (meta == null) continue;
      final data = await TopicProgressService.instance.getTopicProgress(id);
      final lessonsCompleted =
          (data?['lessonsCompleted'] as num?)?.toInt() ?? 0;
      final allLessonsCompleted = data?['allLessonsCompleted'] == true;
      final topicCompleted = data?['topicCompleted'] == true;
      final isComplete = topicCompleted ||
          allLessonsCompleted ||
          lessonsCompleted >= meta.totalLessons;

      selectedId = id;
      selectedData = data;

      if (!isComplete) {
        break;
      }
    }

    if (mounted) {
      setState(() {
        _activeTopicId = selectedId;
        _activeTopicData = selectedData;
      });
    }

    await _sendDailyHomeNotifications(
      topicId: selectedId,
      topicData: selectedData,
    );
  }

  Future<void> _sendDailyHomeNotifications({
    required String topicId,
    required Map<String, dynamic>? topicData,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final todayKey = _formatDate(DateTime.now());
      final userSnapshot =
          await _firestore.collection('users').doc(user.uid).get();
      final userData = userSnapshot.data() ?? <String, dynamic>{};
      final streakDays = (userData['streakDays'] as num?)?.toInt() ?? 0;

      await AppNotificationService.instance.createInboxNotification(
        title: 'Keep your streak alive',
        body: streakDays > 0
            ? 'You are on a $streakDays day streak. Keep going!'
            : 'Open Monéo daily to start your streak.',
        type: 'streak_reminder',
        uniqueKey: 'streak_reminder_$todayKey',
        payload: {'streakDays': streakDays},
      );

      final topicMeta = TopicMetaService.instance.byId[topicId];
      if (topicMeta != null && _hasStartedTopicProgress(topicData)) {
        final lessonsCompleted =
            (topicData?['lessonsCompleted'] as num?)?.toInt() ?? 0;
        await AppNotificationService.instance.createInboxNotification(
          title: 'Continue your lesson',
          body:
              '${topicMeta.title}: $lessonsCompleted/${topicMeta.totalLessons} lessons completed.',
          type: 'lesson_reminder',
          uniqueKey: 'lesson_reminder_$todayKey',
          payload: {
            'topicId': topicId,
            'lessonsCompleted': lessonsCompleted,
            'totalLessons': topicMeta.totalLessons,
          },
        );
      }
    } catch (e) {
      debugPrint('Daily notification error: $e');
    }
  }

  Future<void> _updateStreakIfNeeded() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('[Streak] Not updating: no user logged in');
      return;
    }

    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final snapshot = await docRef.get();
      final data =
          snapshot.data() as Map<String, dynamic>? ?? <String, dynamic>{};

      final String today = _formatDate(DateTime.now());
      final String yesterday =
          _formatDate(DateTime.now().subtract(const Duration(days: 1)));

      final String? lastActiveDate = data['lastActiveDate'] as String?;
      int streakDays = (data['streakDays'] as num?)?.toInt() ?? 0;

      if (lastActiveDate == today) {
        debugPrint('[Streak] Already counted today, streakDays=$streakDays');
        return;
      }

      if (lastActiveDate == yesterday) {
        streakDays += 1;
      } else {
        streakDays = 1;
      }

      await docRef.set(
        {
          ...data,
          'streakDays': streakDays,
          'lastActiveDate': today,
        },
        SetOptions(merge: true),
      );

      await AppNotificationService.instance.createInboxNotification(
        title: 'Streak updated',
        body: 'You are now on a $streakDays day streak. Keep going!',
        type: 'streak',
        uniqueKey: 'streak_updated_$today',
        payload: {'streakDays': streakDays},
      );

      _pendingStreakCelebrationDays = streakDays;

      debugPrint(
          '[Streak] Updated: streakDays=$streakDays, lastActiveDate=$today (doc: users/${user.uid})');
    } catch (e, st) {
      debugPrint('[Streak] Error: $e');
      debugPrint(st.toString());
    }
  }

  bool _hasStartedTopicProgress(Map<String, dynamic>? topicData) {
    if (topicData == null || topicData.isEmpty) return false;
    if (topicData['preQuizCompleted'] == true) return true;
    final lessonsCompleted =
        (topicData['lessonsCompleted'] as num?)?.toInt() ?? 0;
    if (lessonsCompleted > 0) return true;
    final activeLesson = (topicData['activeLessonNumber'] as num?)?.toInt();
    if (activeLesson != null && activeLesson > 0) return true;
    return false;
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void _showStreakCelebrationOverlay(int streakDays) {
    if (!mounted || streakDays <= 0) return;
    if (_hasShownStreakCelebration) return;
    _hasShownStreakCelebration = true;
    setState(() {
      _celebrationStreakDays = streakDays;
      _showStreakCelebration = true;
    });

    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      setState(() => _showStreakCelebration = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBgColor = isDark
        ? const Color(0xFF0F1020)
        : _selectedIndex == 1
            ? Colors.white
            : _selectedIndex == 3
                ? const Color(0xFFF0F4FA)
                : _selectedIndex == 4
                    ? const Color(0xFFF0F0F0)
                    : const Color(0xFFF5F7FB);
    
    final Widget body = _buildTabStack();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      color: scaffoldBgColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            SafeArea(
              top: _selectedIndex != 4,
              child: AnimatedOpacity(
                opacity: _walkthroughBodyOpacity,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: body,
              ),
            ),
            if (_showStreakCelebration) _buildStreakCelebrationOverlay(),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildStreakCelebrationOverlay() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.black.withValues(alpha: 0.24),
          alignment: Alignment.center,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 420),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B1D33) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2A2D4A)
                      : const Color(0xFFE7EAF2),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.7, end: 1.2),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: const Text('🔥', style: TextStyle(fontSize: 64)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Streak on fire!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'You are now on a $_celebrationStreakDays day streak. Keep going!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: isDark
                          ? const Color(0xFFAAB0C6)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeBody() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          KeyedSubtree(
            key: _wtLearningKey,
            child: _buildLearningModuleCard(),
          ),
          const SizedBox(height: 24),
          _buildToolsSection(),
          const SizedBox(height: 24),
          _buildSmartInsight(),
          const SizedBox(height: 24),
          KeyedSubtree(
            key: _wtStreakKey,
            child: _buildMotivationSection(),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeaderProfileAvatar({
    required Color headerCardColor,
    required Color headerBorderColor,
    required Color secondaryTextColor,
  }) {
    final user = _auth.currentUser;

    Widget avatarImage(String? photoUrl) {
      if (photoUrl != null && photoUrl.isNotEmpty) {
        return Image.network(
          photoUrl,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _headerProfilePlaceholder(
              headerCardColor: headerCardColor,
              secondaryTextColor: secondaryTextColor,
            );
          },
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _headerProfilePlaceholder(
              headerCardColor: headerCardColor,
              secondaryTextColor: secondaryTextColor,
            );
          },
        );
      }
      return Image.asset(
        'assets/profile_avatar.jpg',
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _headerProfilePlaceholder(
            headerCardColor: headerCardColor,
            secondaryTextColor: secondaryTextColor,
          );
        },
      );
    }

    final decoration = BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: headerBorderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );

    if (user == null) {
      return Container(
        width: 52,
        height: 52,
        decoration: decoration,
        child: ClipOval(
          child: avatarImage(null),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        final photoUrl =
            (snapshot.data?.data()?['photoUrl'] as String?)?.trim();
        return Container(
          width: 52,
          height: 52,
          decoration: decoration,
          child: ClipOval(
            child: avatarImage(photoUrl),
          ),
        );
      },
    );
  }

  Widget _headerProfilePlaceholder({
    required Color headerCardColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      color: headerCardColor,
      child: Icon(
        Icons.person_rounded,
        color: secondaryTextColor,
        size: 28,
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerCardColor = isDark ? const Color(0xFF1B1D33) : Colors.white;
    final headerBorderColor =
        isDark ? const Color(0xFF2A2D4A) : const Color(0xFFE8ECF4);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFAAB0C6) : const Color(0xFF6B7280);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Row(
        children: [
          KeyedSubtree(
            key: _wtProfileKey,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(
                      onIndexChanged: _selectNavIndex,
                    ),
                  ),
                ).then((result) {
                  _replayLearningProgress();
                  if (result == true) _replayAppWalkthrough();
                });
              },
              child: _buildHeaderProfileAvatar(
                headerCardColor: headerCardColor,
                headerBorderColor: headerBorderColor,
                secondaryTextColor: secondaryTextColor,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hi, $_displayName',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor)),
                const SizedBox(height: 4),
                Text(_formattedDate,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: secondaryTextColor)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppThemeController.modeNotifier,
            builder: (context, mode, _) {
              final isDark = mode == ThemeMode.dark;
              return Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: headerCardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: headerBorderColor),
                ),
                child: IconButton(
                  tooltip:
                      isDark ? 'Switch to light mode' : 'Switch to dark mode',
                  icon: Icon(
                    isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                    color: primaryTextColor,
                    size: 22,
                  ),
                  onPressed: AppThemeController.toggleTheme,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          _buildNotificationButton(
            headerCardColor: headerCardColor,
            headerBorderColor: headerBorderColor,
            primaryTextColor: primaryTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton({
    required Color headerCardColor,
    required Color headerBorderColor,
    required Color primaryTextColor,
  }) {
    final user = _auth.currentUser;

    if (user == null) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: headerCardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: headerBorderColor),
        ),
        child: IconButton(
          icon: Icon(Icons.notifications_none_rounded,
              color: primaryTextColor, size: 22),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ).then((_) => _replayLearningProgress());
          },
        ),
      );
    }

    final unreadStream = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: unreadStream,
      builder: (context, snapshot) {
        final unreadCount = snapshot.data?.docs.length ?? 0;
        final showBadge = unreadCount > 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: headerCardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: headerBorderColor),
              ),
              child: IconButton(
                icon: Icon(Icons.notifications_none_rounded,
                    color: primaryTextColor, size: 22),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()),
                  ).then((_) => _replayLearningProgress());
                },
              ),
            ),
            if (showBadge)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLearningModuleCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accentBlue = Color(0xFF007AFF);
    final meta = TopicMetaService.instance.byId[_activeTopicId]!;
    final data = _activeTopicData ?? {};

    final lessonsCompleted = (data['lessonsCompleted'] as num?)
            ?.toInt()
            ?.clamp(0, meta.totalLessons) ??
        0;

    final activeLessonNumber = data['activeLessonNumber'] as int?;
    final activeLessonStep = data['activeLessonStep'] as int?;
    final activeLessonTotalSteps = data['activeLessonTotalSteps'] as int?;
    final hasStepProgress = activeLessonNumber == lessonsCompleted + 1 &&
        (activeLessonTotalSteps ?? 0) > 0 &&
        (activeLessonStep ?? 0) > 0;
    final partial = hasStepProgress
        ? (activeLessonStep! / activeLessonTotalSteps!).clamp(0.0, 1.0)
        : 0.0;

    final progressValue =
        ((lessonsCompleted + partial) / meta.totalLessons).clamp(0.0, 1.0);

    final titleColor = isDark ? accentBlue : Colors.white;
    final subtitleColor = isDark
        ? accentBlue.withValues(alpha: 0.72)
        : Colors.white.withOpacity(0.88);
    final pillColor = isDark
        ? accentBlue.withValues(alpha: 0.18)
        : Colors.white.withOpacity(0.16);
    final accentColor = isDark ? accentBlue : Colors.white;
    final progressTrackColor = isDark
        ? accentBlue.withValues(alpha: 0.22)
        : Colors.white.withOpacity(0.18);
    final ringBgColor = isDark
        ? accentBlue.withValues(alpha: 0.14)
        : Colors.white.withOpacity(0.12);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : null,
        gradient: isDark
            ? null
            : const LinearGradient(
                colors: [accentBlue, accentBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(24),
        border: isDark
            ? Border.all(color: accentBlue.withValues(alpha: 0.22))
            : null,
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF6D5EF9).withOpacity(0.20),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: pillColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Current learning module',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  meta.title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                    '$lessonsCompleted of ${meta.totalLessons} lessons completed',
                    style: TextStyle(
                        color: subtitleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('learning-linear-$_learningProgressReplay'),
                    tween: Tween(begin: 0, end: progressValue),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedProgress, _) {
                      return LinearProgressIndicator(
                        value: animatedProgress,
                        minHeight: 8,
                        backgroundColor: progressTrackColor,
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: pillColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt,
                            color: accentColor,
                            size: 17,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+${XpService.lessonCompletionXp} XP',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _previousNavIndex = _selectedIndex;
                          _pendingResumeTopicId = _activeTopicId;
                          _pendingAutoOpenResumeTopic = true;
                          _selectedIndex = 1;
                          _learnTopicBarsReplay++;
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          setState(() => _pendingAutoOpenResumeTopic = false);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor:
                            isDark ? accentBlue : Colors.white,
                        foregroundColor:
                            isDark ? Colors.white : const Color(0xFF5B4CF0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        _hasStartedTopicProgress(data) ? 'Continue' : 'Start',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: ringBgColor,
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  key: ValueKey('learning-circle-$_learningProgressReplay'),
                  tween: Tween(begin: 0, end: progressValue),
                  duration: const Duration(milliseconds: 1100),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedProgress, _) {
                    final animatedPct = (animatedProgress * 100).toInt();

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: CircularProgressIndicator(
                            value: animatedProgress,
                            strokeWidth: 8,
                            backgroundColor: progressTrackColor,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(accentColor),
                          ),
                        ),
                        Text(
                          '$animatedPct%',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sectionTitleColor = isDark ? Colors.white : const Color(0xFF111827);
    final cardColor = isDark ? const Color(0xFF1B1D33) : Colors.white;
    final cardBorderColor =
        isDark ? const Color(0xFF2A2D4A) : const Color(0xFFE9ECF4);
    final labelColor = isDark ? Colors.white : const Color(0xFF111827);
    final subColor = isDark ? const Color(0xFFAAB0C6) : const Color(0xFF6B7280);
    final tools = [
      _ToolItem(
        label: 'Currency',
        sub: 'Convert rates',
        icon: Icons.currency_exchange_rounded,
        color: const Color(0xFF34C759),
        lightBg: const Color(0xFFEAF7EE),
        screen: const CurrencyConverterScreen(),
      ),
      _ToolItem(
        label: 'Savings',
        sub: 'Reach your goal',
        icon: Icons.savings_rounded,
        color: const Color(0xFF6D5EF9),
        lightBg: const Color(0xFFEAF2FF),
        screen: const SavingsCalculatorScreen(),
      ),
      _ToolItem(
        label: 'Loan',
        sub: 'Monthly payments',
        icon: Icons.credit_card_rounded,
        color: const Color(0xFFFF6B35),
        lightBg: const Color(0xFFFFF0EB),
        screen: const LoanCalculatorScreen(),
      ),
      _ToolItem(
        label: 'Bill splitter',
        sub: 'Split bills',
        icon: Icons.group_rounded,
        color: const Color(0xFFFF9500),
        lightBg: const Color(0xFFFFF4E0),
        screen: const TipSplitterScreen(),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tools',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: sectionTitleColor)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: tools
                .map((t) => GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => t.screen),
                      ).then((_) => _replayLearningProgress()),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: cardBorderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                  color: iconAccentBackground(
                                    accentColor: t.color,
                                    isDark: isDark,
                                    lightBackground: t.lightBg,
                                  ),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Icon(t.icon, color: t.color, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(t.label,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: labelColor)),
                                  Text(t.sub,
                                      style: TextStyle(
                                          fontSize: 11, color: subColor)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  final List<String> _insights = [
    "Rent appears to be one of the most frequent financial transactions. Planning housing expenses carefully can improve financial stability.",
    "Travel and food expenses represent significant spending categories. Setting limits for discretionary spending can help control budgets.",
    "Frequent transactions across multiple categories highlight the importance of tracking expenses regularly."
  ];

  Widget _buildSmartInsight() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF007AFF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1D33) : Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconAccentBackground(
                    accentColor: const Color(0xFF007AFF),
                    isDark: isDark,
                    lightBackground: const Color(0xFFEAF2FF),
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.psychology_rounded,
                    color: Color(0xFF007AFF), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Smart insight',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF111827))),
                    const SizedBox(height: 6),
                    Text(
                      _insights[DateTime.now().day % _insights.length],
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: isDark
                            ? const Color(0xFFAAB0C6)
                            : const Color(0xFF6B7280),
                      ),
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

  Widget _buildMotivationSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rewards & motivation',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111827))),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStreakCard(),
              const SizedBox(width: 12),
              _buildRewardsCard(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _auth.currentUser;
    final stream = user == null
        ? Stream<DocumentSnapshot<Map<String, dynamic>>?>.value(null)
        : _firestore
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .map((d) => d);

    return Expanded(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
        stream: stream,
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? <String, dynamic>{};
          final streakDays = (data['streakDays'] as num?)?.toInt() ?? 0;
          final activeDays = streakDays.clamp(0, 7);
          const weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
          final streakLabel = streakDays <= 0
              ? 'Learning\nconsistency'
              : '$streakDays-day streak';

          return Container(
            height: 170,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B1D33) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: isDark
                      ? const Color(0xFF2A2D4A)
                      : const Color(0xFFE9ECF7)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(streakLabel,
                            maxLines: 2,
                            style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1F2937),
                                fontSize: 16,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: weekDays
                        .map((d) => Text(d,
                            style: TextStyle(
                                color: isDark
                                    ? const Color(0xFFAAB0C6)
                                    : const Color(0xFF6B7280),
                                fontSize: 11,
                                fontWeight: FontWeight.w700)))
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(7, (i) {
                      final done = i < activeDays;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: done
                                  ? const Color(0xFF1D89FF)
                                  : const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  Text(
                    _reviewCompleted
                        ? 'Nice work — today\'s challenge completed'
                        : 'Keep your streak alive by using the app daily.',
                    style: TextStyle(
                        color: isDark
                            ? const Color(0xFFAAB0C6)
                            : const Color(0xFF6B7280),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.35),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRewardsCard() {
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectNavIndex(4),
        child: Container(
          height: 170,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9F43), Color(0xFFF67C20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFF67C20).withOpacity(0.26),
                  blurRadius: 16,
                  offset: const Offset(0, 8))
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -8,
                child: Opacity(
                  opacity: 0.18,
                  child: const Icon(Icons.card_giftcard_rounded,
                      size: 110, color: Colors.white),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rewards & deals',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text('Unlock exclusive offers and redeem your rewards.',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text('View offers',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
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

  Widget _buildBottomNav() {
    return _SimpleBottomNavBar(
      selectedIndex: _selectedIndex,
      aiNavKey: _wtAiNavKey,
      dealsNavKey: _wtDealsNavKey,
      onTap: (i) {
        if (i == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
          );
          return;
        }
        _selectNavIndex(i);
      },
    );
  }
}


class _LevelUpCelebrationOverlay extends StatelessWidget {
  const _LevelUpCelebrationOverlay({required this.level});

  final int level;

  static double _clamp01(double value) => value.clamp(0.0, 1.0).toDouble();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned.fill(
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 6000),
          curve: Curves.linear,
          builder: (context, progress, child) {
            final fadeIn = _clamp01(progress / 0.18);
            final fadeOut =
                progress < 0.78 ? 1.0 : 1 - _clamp01((progress - 0.78) / 0.22);
            final opacity = fadeIn * fadeOut;
            final pop = Curves.elasticOut.transform(_clamp01(progress / 0.42));
            final trophyScale = 0.72 + (0.28 * pop);
            final cardOffset = 22 * (1 - Curves.easeOutCubic.transform(fadeIn));

            return Opacity(
              opacity: opacity,
              child: Container(
                color: Colors.black.withValues(alpha: 0.42),
                alignment: Alignment.center,
                child: Transform.translate(
                  offset: Offset(0, cardOffset),
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      ...List.generate(14, (index) {
                        return _LevelUpSparkle(
                          index: index,
                          progress: progress,
                        );
                      }),
                      Container(
                        width: 280,
                        padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF17192B) : Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF2A2D4A)
                                : const Color(0xFFE4EEFF),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x300067DD),
                              blurRadius: 28,
                              offset: Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.scale(
                              scale: trophyScale,
                              child: Container(
                                width: 96,
                                height: 96,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF42A5FF),
                                      Color(0xFF0067DD),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.emoji_events_rounded,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Level Up!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You reached level $level',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFFAAB0C6)
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LevelUpSparkle extends StatelessWidget {
  const _LevelUpSparkle({
    required this.index,
    required this.progress,
  });

  final int index;
  final double progress;

  static double _clamp01(double value) => value.clamp(0.0, 1.0).toDouble();

  @override
  Widget build(BuildContext context) {
    final angle = (math.pi * 2 / 14) * index;
    final burstProgress = Curves.easeOutCubic.transform(
      _clamp01((progress - 0.08) / 0.62),
    );
    final fadeProgress = _clamp01((progress - 0.48) / 0.42);
    final distance = 48 + (burstProgress * (index.isEven ? 112 : 88));
    final opacity = (1 - fadeProgress) * _clamp01(progress / 0.22);
    final size = index.isEven ? 22.0 : 13.0;
    final color = index % 3 == 0
        ? const Color(0xFFFFD166)
        : index % 3 == 1
            ? const Color(0xFF42A5FF)
            : const Color(0xFFFFFFFF);

    return Transform.translate(
      offset: Offset(
        math.cos(angle) * distance,
        math.sin(angle) * distance,
      ),
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: progress * math.pi * 2,
          child: Icon(
            index.isEven ? Icons.star_rounded : Icons.circle,
            color: color,
            size: size,
          ),
        ),
      ),
    );
  }
}

class _SimpleBottomNavBar extends StatelessWidget {
  const _SimpleBottomNavBar({
    required this.selectedIndex,
    required this.onTap,
    required this.aiNavKey,
    required this.dealsNavKey,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final Key aiNavKey;
  final Key dealsNavKey;

  static const _selectedColor = Color(0xFF007AFF);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF17192B) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2D4A) : Colors.grey[300]!;
    final unselectedColor = isDark
        ? const Color(0xFF939BB6)
        : const Color.fromRGBO(0, 0, 0, 0.55);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _item(
                index: 0,
                icon: Icons.home_outlined,
                label: 'Home',
                unselectedColor: unselectedColor,
              ),
              _item(
                index: 1,
                icon: Icons.school_outlined,
                label: 'Learn',
                unselectedColor: unselectedColor,
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(2),
                  child: KeyedSubtree(
                    key: aiNavKey,
                    child: const _AiNavIcon(),
                  ),
                ),
              ),
              _item(
                index: 3,
                icon: Icons.account_balance_outlined,
                label: 'Finance',
                unselectedColor: unselectedColor,
              ),
              _item(
                index: 4,
                icon: Icons.card_giftcard_outlined,
                label: 'Deals',
                unselectedColor: unselectedColor,
                navKey: dealsNavKey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item({
    required int index,
    required IconData icon,
    required String label,
    required Color unselectedColor,
    Key? navKey,
  }) {
    final isSelected = selectedIndex == index;
    final color = isSelected ? _selectedColor : unselectedColor;

    Widget child = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );

    if (navKey != null) {
      child = KeyedSubtree(key: navKey, child: child);
    }

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: child,
      ),
    );
  }
}

class _AiNavIcon extends StatelessWidget {
  const _AiNavIcon();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: SizedBox(
        width: 60,
        height: 34,
        child: Image.asset(
          'assets/owl_Background_Removed.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _NavTabTransition extends StatefulWidget {
  const _NavTabTransition({
    required this.isActive,
    required this.slideDirection,
    required this.child,
  });

  final bool isActive;
  final double slideDirection;
  final Widget child;

  @override
  State<_NavTabTransition> createState() => _NavTabTransitionState();
}

class _NavTabTransitionState extends State<_NavTabTransition>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 300);
  static const _slideFraction = 0.14;

  late final AnimationController _controller;
  late final CurvedAnimation _curve;
  late Animation<Offset> _slide;
  double _slideDirection = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slideDirection = widget.slideDirection;
    _syncSlideAnimation();
    if (widget.isActive) {
      _controller.value = 1.0;
    }
  }

  void _syncSlideAnimation() {
    _slide = Tween<Offset>(
      begin: Offset(_slideFraction * _slideDirection, 0),
      end: Offset.zero,
    ).animate(_curve);
  }

  @override
  void didUpdateWidget(_NavTabTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive == oldWidget.isActive) return;
    if (widget.isActive) {
      _slideDirection = widget.slideDirection;
      _syncSlideAnimation();
      _controller.forward(from: 0);
    } else {
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.isActive,
      child: FadeTransition(
        opacity: _curve,
        child: SlideTransition(
          position: _slide,
          child: widget.child,
        ),
      ),
    );
  }
}

class _ToolItem {
  final String label, sub;
  final IconData icon;
  final Color color, lightBg;
  final Widget screen;
  const _ToolItem({
    required this.label,
    required this.sub,
    required this.icon,
    required this.color,
    required this.lightBg,
    required this.screen,
  });
}
