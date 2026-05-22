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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.userName});

  final String? userName;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _reviewCompleted = false;
  int _selectedIndex = 0;
  bool _showStreakCelebration = false;
  int _celebrationStreakDays = 0;
  bool _hasShownStreakCelebration = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Active topic progress state
  String _activeTopicId = 'budgeting_and_expense_tracking';
  Map<String, dynamic>? _activeTopicData;
  String? _pendingResumeTopicId;
  bool _pendingAutoOpenResumeTopic = false;

  @override
  void initState() {
    super.initState();
    TopicMetaService.instance.ensureLoaded();
    _updateStreakIfNeeded();
    _loadActiveTopicProgress();
  }

  String get _displayName {
    if (widget.userName == null || widget.userName!.trim().isEmpty) return 'there';
    return widget.userName!.trim();
  }

  String get _formattedDate {
    final now = DateTime.now();
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  Future<void> _loadActiveTopicProgress() async {
    // Pick the first incomplete topic (Topic 1 → 4). If all complete, keep Topic 4.
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
      final lessonsCompleted = (data?['lessonsCompleted'] as num?)?.toInt() ?? 0;
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
      final userSnapshot = await _firestore.collection('users').doc(user.uid).get();
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
      final data = snapshot.data() as Map<String, dynamic>? ?? <String, dynamic>{};

      final String today = _formatDate(DateTime.now());
      final String yesterday = _formatDate(DateTime.now().subtract(const Duration(days: 1)));

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

      _showStreakCelebrationOverlay(streakDays);

      debugPrint('[Streak] Updated: streakDays=$streakDays, lastActiveDate=$today (doc: users/${user.uid})');
    } catch (e, st) {
      debugPrint('[Streak] Error: $e');
      debugPrint(st.toString());
    }
  }

  /// True when the user has begun this topic (pre-quiz, a lesson, or mid-lesson progress).
  bool _hasStartedTopicProgress(Map<String, dynamic>? topicData) {
    if (topicData == null || topicData.isEmpty) return false;
    if (topicData['preQuizCompleted'] == true) return true;
    final lessonsCompleted = (topicData['lessonsCompleted'] as num?)?.toInt() ?? 0;
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
    Widget body;

    switch (_selectedIndex) {
      case 0:
        body = _buildHomeBody();
        break;
      case 1:
        body = LearnScreen(
          resumeTopicId: _pendingResumeTopicId,
          autoOpenResumeTopic: _pendingAutoOpenResumeTopic,
          onIndexChanged: (i) {
            setState(() {
              _selectedIndex = i;
              if (i != 1) {
                _pendingResumeTopicId = null;
                _pendingAutoOpenResumeTopic = false;
              }
            });
            // Refresh active topic progress when returning to Home
            if (i == 0) _loadActiveTopicProgress();
          },
        );
        break;
      case 2:
        body = _buildHomeBody();
        break;
      case 3:
        body = FinanceScreen(onIndexChanged: (i) => setState(() => _selectedIndex = i));
        break;
      case 4:
        body = DealsScreen(onIndexChanged: (i) => setState(() => _selectedIndex = i));
        break;
      default:
        body = _buildHomeBody();
        break;
    }

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: Stack(
        children: [
          SafeArea(top: _selectedIndex != 4, child: body),
          if (_showStreakCelebration) _buildStreakCelebrationOverlay(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
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
                  color: isDark ? const Color(0xFF2A2D4A) : const Color(0xFFE7EAF2),
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
                      color: isDark ? const Color(0xFFAAB0C6) : const Color(0xFF6B7280),
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
          _buildLearningModuleCard(),
          const SizedBox(height: 24),
          _buildToolsSection(),
          const SizedBox(height: 24),
          _buildSmartInsight(),
          const SizedBox(height: 24),
          _buildMotivationSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerCardColor = isDark ? const Color(0xFF1B1D33) : Colors.white;
    final headerBorderColor = isDark ? const Color(0xFF2A2D4A) : const Color(0xFFE8ECF4);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor = isDark ? const Color(0xFFAAB0C6) : const Color(0xFF6B7280);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(
                    onIndexChanged: (i) => setState(() => _selectedIndex = i),
                  ),
                ),
              );
            },
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: headerCardColor,
                shape: BoxShape.circle,
                border: Border.all(color: headerBorderColor),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Icon(Icons.person_rounded, color: secondaryTextColor, size: 28),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hi, $_displayName',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: primaryTextColor)),
                const SizedBox(height: 4),
                Text(_formattedDate,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: secondaryTextColor)),
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
                  tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
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
          icon: Icon(Icons.notifications_none_rounded, color: primaryTextColor, size: 22),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
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
                icon: Icon(Icons.notifications_none_rounded, color: primaryTextColor, size: 22),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                },
              ),
            ),
            if (showBadge)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
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
    final meta = TopicMetaService.instance.byId[_activeTopicId]!;
    final data = _activeTopicData ?? {};

    final lessonsCompleted =
        (data['lessonsCompleted'] as num?)?.toInt()?.clamp(0, meta.totalLessons) ??
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

    final progressValue = ((lessonsCompleted + partial) / meta.totalLessons)
        .clamp(0.0, 1.0);
    final progressPct = (progressValue * 100).toInt();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF007AFF), Color(0xFF007AFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF6D5EF9).withOpacity(0.20), blurRadius: 22, offset: const Offset(0, 10))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text('Current learning module',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 16),
                Text(meta.title,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('$lessonsCompleted of ${meta.totalLessons} lessons completed',
                    style: TextStyle(color: Colors.white.withOpacity(0.88), fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.18),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
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
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bolt,
                            color: Colors.white,
                            size: 17,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+${XpService.lessonCompletionXp} XP',
                            style: const TextStyle(
                              color: Colors.white,
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
                          _pendingResumeTopicId = _activeTopicId;
                          _pendingAutoOpenResumeTopic = true;
                          _selectedIndex = 1;
                        });
                        // One-shot: after LearnScreen consumes it, disable auto-open.
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          setState(() => _pendingAutoOpenResumeTopic = false);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF5B4CF0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: progressValue,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                Text('$progressPct%',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
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
    final cardBorderColor = isDark ? const Color(0xFF2A2D4A) : const Color(0xFFE9ECF4);
    final labelColor = isDark ? Colors.white : const Color(0xFF111827);
    final subColor = isDark ? const Color(0xFFAAB0C6) : const Color(0xFF6B7280);
    final tools = [
      _ToolItem(
        label: 'Currency',
        sub: 'Convert rates',
        icon: Icons.currency_exchange_rounded,
        color: const Color(0xFF34C759),
        bg: const Color(0xFFEAF7EE),
        screen: const CurrencyConverterScreen(),
      ),
      _ToolItem(
        label: 'Savings',
        sub: 'Reach your goal',
        icon: Icons.savings_rounded,
        color: const Color(0xFF6D5EF9),
        bg: const Color(0xFFEAF2FF),
        screen: const SavingsCalculatorScreen(),
      ),
      _ToolItem(
        label: 'Loan',
        sub: 'Monthly payments',
        icon: Icons.credit_card_rounded,
        color: const Color(0xFFFF6B35),
        bg: const Color(0xFFFFF0EB),
        screen: const LoanCalculatorScreen(),
      ),
      _ToolItem(
        label: 'Bill splitter',
        sub: 'Split bills',
        icon: Icons.group_rounded,
        color: const Color(0xFFFF9500),
        bg: const Color(0xFFFFF4E0),
        screen: const TipSplitterScreen(),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tools',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: sectionTitleColor)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: tools.map((t) => GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => t.screen)),
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
                      decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(12)),
                      child: Icon(t.icon, color: t.color, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(t.label,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: labelColor)),
                          Text(t.sub,
                              style: TextStyle(fontSize: 11, color: subColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )).toList(),
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
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.psychology_rounded, color: Color(0xFF007AFF), size: 24),
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
                            color: isDark ? Colors.white : const Color(0xFF111827))),
                    const SizedBox(height: 6),
                    Text(
  _insights[DateTime.now().day % _insights.length],
  style: TextStyle(
    fontSize: 13,
    height: 1.45,
    color: isDark ? const Color(0xFFAAB0C6) : const Color(0xFF6B7280),
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
        : _firestore.collection('users').doc(user.uid).snapshots().map((d) => d);

    return Expanded(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
        stream: stream,
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? <String, dynamic>{};
          final streakDays = (data['streakDays'] as num?)?.toInt() ?? 0;
          final activeDays = streakDays.clamp(0, 7);
          const weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
          final streakLabel = streakDays <= 0 ? 'Learning\nconsistency' : '$streakDays-day streak';

          return Container(
            height: 170,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B1D33) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: isDark ? const Color(0xFF2A2D4A) : const Color(0xFFE9ECF7)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
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
                            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1F2937), fontSize: 16,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: weekDays.map((d) => Text(d,
                        style: TextStyle(color: isDark ? const Color(0xFFAAB0C6) : const Color(0xFF6B7280), fontSize: 11,
                            fontWeight: FontWeight.w700))).toList(),
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
                              color: done ? const Color(0xFF1D89FF) : const Color(0xFFE5E7EB),
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
                    style: TextStyle(color: isDark ? const Color(0xFFAAB0C6) : const Color(0xFF6B7280), fontSize: 11,
                        fontWeight: FontWeight.w500, height: 1.35),
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
        onTap: () => setState(() => _selectedIndex = 4),
        child: Container(
          height: 170,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9F43), Color(0xFFF67C20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: const Color(0xFFF67C20).withOpacity(0.26),
                blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -8,
                child: Opacity(
                  opacity: 0.18,
                  child: const Icon(Icons.card_giftcard_rounded, size: 110, color: Colors.white),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rewards & deals',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text('Unlock exclusive offers and redeem your rewards.',
                        style: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: 13,
                            height: 1.35, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text('View offers',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: isDark ? const Color(0xFF2A2D4A) : Colors.grey[300]!),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) {
          if (i == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
            );
            return;
          }
          setState(() => _selectedIndex = i);
          if (i == 0) _loadActiveTopicProgress();
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? const Color(0xFF17192B) : Colors.white,
        elevation: 0,
        // Let us control icon sizes via custom widgets.
        iconSize: 0,
        selectedItemColor: const Color(0xFF007AFF),
        unselectedItemColor: isDark ? const Color(0xFF939BB6) : const Color.fromRGBO(0, 0, 0, 0.55),
        selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        items: const [
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 24,
              height: 24,
              child: Icon(Icons.home_outlined, size: 24),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 24,
              height: 24,
              child: Icon(Icons.school_outlined, size: 24),
            ),
            label: 'Learn',
          ),
          BottomNavigationBarItem(
            icon: _AiNavIcon(),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 24,
              height: 24,
              child: Icon(Icons.account_balance_outlined, size: 24),
            ),
            label: 'Finance',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 34,
              height: 34,
              child: Icon(Icons.card_giftcard_outlined, size: 24),
            ),
            label: 'Deals',
          ),
        ],
      ),
    );
  }
}

// AI assistant screen lives in `ai_assistant/ai_assistant.dart`.

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


class _ToolItem {
  final String label, sub;
  final IconData icon;
  final Color color, bg;
  final Widget screen;
  const _ToolItem({
    required this.label, required this.sub,
    required this.icon, required this.color,
    required this.bg, required this.screen,
  });
}