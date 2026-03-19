import 'package:flutter/material.dart';
import 'lesson_content_screen.dart';
import 'quiz_screen.dart';
import 'learn_screen.dart';
import 'package:fintech/services/topic_progress_service.dart';
import 'package:fintech/services/xp_service.dart';

class SubtopicDetailScreen extends StatefulWidget {
  final String topicId;
  final bool preQuizCompleted;
  final bool autoStartFlow;
  final String topicTitle;
  final int currentLesson;
  final int totalLessons;
  final List<LessonItem> lessons;

  const SubtopicDetailScreen({
    super.key,
    required this.topicId,
    this.preQuizCompleted = false,
    this.autoStartFlow = false,
    required this.topicTitle,
    required this.currentLesson,
    required this.totalLessons,
    required this.lessons,
  });

  @override
  State<SubtopicDetailScreen> createState() => _SubtopicDetailScreenState();
}

class _SubtopicDetailScreenState extends State<SubtopicDetailScreen> {
  late int _completedLessons;
  late int _coreLessonCount;
  bool _preQuizCompleted = false;
  bool _postQuizCompleted = false;
  bool _hasAutoStartedFlow = false;
  int? _activeLessonNumber;
  int? _activeLessonStep;
  int? _activeLessonTotalSteps;

  @override
  void initState() {
    super.initState();
    _coreLessonCount = _resolveCoreLessonCount();
    _completedLessons = widget.currentLesson.clamp(0, _coreLessonCount);
    _preQuizCompleted = widget.preQuizCompleted;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoStartFlowIfNeeded();
    });
    _loadTopicProgress();
  }

  Future<void> _loadTopicProgress() async {
    final progress = await TopicProgressService.instance.getTopicProgress(widget.topicId);
    if (!mounted || progress == null) {
      return;
    }

    setState(() {
      _preQuizCompleted = progress['preQuizCompleted'] == true;
      _postQuizCompleted = progress['postQuizCompleted'] == true;
      _completedLessons =
          ((progress['lessonsCompleted'] as int?) ?? _completedLessons).clamp(0, _coreLessonCount);
      _activeLessonNumber = progress['activeLessonNumber'] as int?;
      _activeLessonStep = progress['activeLessonStep'] as int?;
      _activeLessonTotalSteps = progress['activeLessonTotalSteps'] as int?;
    });

    _autoStartFlowIfNeeded();
  }

  void _autoStartFlowIfNeeded() {
    if (!widget.autoStartFlow || _hasAutoStartedFlow || !mounted) {
      return;
    }

    if (!_preQuizCompleted || _postQuizCompleted) {
      return;
    }

    _hasAutoStartedFlow = true;
    _openNextStepAfter(_completedLessons);
  }

  @override
  Widget build(BuildContext context) {
    final progressPercentage =
      ((_displayProgressValue() / _coreLessonCount) * 100).toInt();

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
          widget.topicTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          // Course Progress Section
          _buildCourseProgressSection(progressPercentage),
          const SizedBox(height: 16),
          // Lessons List
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  for (int i = 0; i < widget.lessons.length; i++) ...[
                    _buildLessonCard(widget.lessons[i], _statusForLesson(widget.lessons[i]), i),
                    if (i < widget.lessons.length - 1) const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseProgressSection(int progressPercentage) {
    final hasStepProgress = _activeLessonNumber == _completedLessons + 1 &&
        (_activeLessonTotalSteps ?? 0) > 0 &&
        (_activeLessonStep ?? 0) > 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                'Course Progress',
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
                  '$progressPercentage%',
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
              value: progressPercentage / 100,
              minHeight: 10,
              backgroundColor: const Color(0xFFE8EEF7),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            hasStepProgress
                ? '$_completedLessons of $_coreLessonCount lessons completed • Lesson ${_activeLessonNumber!}: ${_activeLessonStep!}/${_activeLessonTotalSteps!} steps'
                : '$_completedLessons of $_coreLessonCount lessons completed',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black.withValues(alpha: 0.58),
            ),
          ),
        ],
      ),
    );
  }

  LessonStatus _statusForLesson(LessonItem lesson) {
  final step = lesson.step ?? '';

  // Fully locked topics
  const lockedTopics = {
    'Protecting Yourself from Fraud & Scams',
    'Taxes & Tax Planning',
    'Retirement Planning',
  };

  if (lockedTopics.contains(widget.topicTitle)) {
    return LessonStatus.locked;
  }

  // Topic 5: only pre-quiz and intro locked
  if (widget.topicTitle == 'Investing Basics') {
    if (step == 'PRE-QUIZ' || step == 'STEP 1') {
      return LessonStatus.locked;
    }

    if (step == 'FINAL QUIZ') {
      if (_postQuizCompleted) {
        return LessonStatus.completed;
      }
      return _completedLessons >= _coreLessonCount
          ? LessonStatus.quiz
          : LessonStatus.locked;
    }

    final lessonNumber = _lessonNumberForProgress(lesson, 0);

    if (lessonNumber <= _completedLessons) {
      return LessonStatus.completed;
    }
    if (lessonNumber == _completedLessons + 1) {
      return LessonStatus.current;
    }
    return LessonStatus.locked;
  }

  if (step == 'PRE-QUIZ') {
    return _preQuizCompleted ? LessonStatus.completed : LessonStatus.quiz;
  }

  if (step == 'FINAL QUIZ') {
    if (_postQuizCompleted) {
      return LessonStatus.completed;
    }
    return _completedLessons >= _coreLessonCount
        ? LessonStatus.quiz
        : LessonStatus.locked;
  }

  final lessonNumber = _lessonNumberForProgress(lesson, 0);

  if (!_preQuizCompleted) {
    return LessonStatus.locked;
  }
  if (lessonNumber <= _completedLessons) {
    return LessonStatus.completed;
  }
  if (lessonNumber == _completedLessons + 1) {
    return LessonStatus.current;
  }
  return LessonStatus.locked;
}

  Widget _buildLessonCard(LessonItem lesson, LessonStatus lessonStatus, int index) {
    final isPreQuiz = lesson.step == 'PRE-QUIZ';
    final isFinalQuiz = lesson.step == 'FINAL QUIZ';
    final card = Stack(
      children: [
        // Vertical connecting line
        if (index < widget.lessons.length - 1)
          Positioned(
            left: 17.5,
            top: 35,
            bottom: -16,
            child: Container(
              width: 1,
              color: const Color(0xFFCBD5E1),
            ),
          ),
        // Lesson Card
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Icon
            _buildStatusIcon(lessonStatus),
            const SizedBox(width: 16),
            // Lesson Content Card
            Expanded(
              child: GestureDetector(
                onTap: lessonStatus != LessonStatus.locked
                    ? () {
                        if (isPreQuiz && _preQuizCompleted) {
                          return;
                        }

                        // Check if it's a quiz
                        if (lessonStatus == LessonStatus.quiz || isPreQuiz || isFinalQuiz) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuizScreen(
                                quizTitle: isPreQuiz ? 'Before You Start Quiz' : 'Learning Checkup',
                                questions: isPreQuiz
                                  ? _getPreQuizQuestions()
                                  : _getPostQuizQuestions(),
                                awardXp: !isPreQuiz,
                                showCompletionFlow: !isPreQuiz,
                                revealAnswerFeedback: !isPreQuiz,
                                topicId: widget.topicId,
                                topicTitle: widget.topicTitle,
                                lessonsCompleted: _coreLessonCount,
                                totalLessons: _coreLessonCount,
                                onQuizFinished: (score, totalQuestions) async {
                                  if (isPreQuiz) {
                                    return TopicProgressService.instance.savePreQuizResult(
                                      topicId: widget.topicId,
                                      score: score,
                                      totalQuestions: totalQuestions,
                                    );
                                  } else {
                                    await TopicProgressService.instance.savePostQuizResult(
                                      topicId: widget.topicId,
                                      score: score,
                                      totalQuestions: totalQuestions,
                                    );
                                    // Award XP for quiz completion (not pre-quiz)
                                    await XpService.instance.earnXp(amount: 50, source: 'quiz_completion');
                                  }
                                },
                              ),
                            ),
                          ).then((_) async {
                            await _loadTopicProgress();
                            if (!mounted) {
                              return;
                            }
                            if (isPreQuiz && _preQuizCompleted && !_postQuizCompleted) {
                              _openNextStepAfter(_completedLessons);
                            }
                          });
                        } else {
                          // Navigate to lesson content screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LessonContentScreen(
                                lessonTitle: lesson.title,
                                lessonProgress: _lessonNumberForProgress(lesson, index),
                                topicId: widget.topicId,
                              ),
                            ),
                          ).then((result) async {
                            final completed = result == true;
                            final lessonNumber = _lessonNumberForProgress(lesson, index);
                            if (!completed || lessonNumber > _completedLessons + 1) {
                              return;
                            }

                            final newCompleted = lessonNumber > _completedLessons
                                ? lessonNumber
                                : _completedLessons;

                            if (newCompleted > _completedLessons) {
                              await TopicProgressService.instance.saveLessonsCompleted(
                                topicId: widget.topicId,
                                lessonsCompleted: newCompleted,
                                totalLessons: _coreLessonCount,
                              );

                              if (!mounted) {
                                return;
                              }

                              setState(() {
                                _completedLessons = newCompleted;
                              });
                            }

                            // Award XP for lesson completion
                            await XpService.instance.earnXp(amount: 20, source: 'lesson_completion');
                            final goToNextLesson = await _showLessonCompletedSheet(
                              lessonTitle: lesson.title,
                              earnedXp: 20,
                            );

                            if (!mounted) {
                              return;
                            }

                            if (goToNextLesson) {
                              _openNextStepAfter(newCompleted);
                            }
                          });
                        }
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _getCardBackgroundColor(lessonStatus),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getCardBorderColor(lessonStatus),
                      width: 1.5,
                    ),
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
                      // Step and Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _getBadgeBackgroundColor(lessonStatus),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              lesson.step ?? '',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _getStepTextColor(lessonStatus),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          if (_getBadgeText(lessonStatus).isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusBadgeBackgroundColor(lessonStatus),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _getBadgeText(lessonStatus),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _getBadgeTextColor(lessonStatus),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Lesson Title
                      Text(
                        lesson.title,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: lessonStatus == LessonStatus.locked
                              ? Colors.black.withValues(alpha: 0.4)
                              : Colors.black,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Duration and Status Info
                      Row(
                        children: [
                          Icon(
                            lessonStatus == LessonStatus.locked
                                ? Icons.lock_outline
                                : Icons.access_time,
                            size: 16,
                            color: lessonStatus == LessonStatus.locked
                                ? Colors.grey
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            lessonStatus == LessonStatus.locked
                                ? 'Locked'
                              : (lessonStatus == LessonStatus.completed
                                    ? 'Completed'
                                    : 'Current'),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          if ((lesson.duration ?? '').isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.grey[600],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              lesson.duration ?? '',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
    return card;
  }

  int _resolveCoreLessonCount() {
    final stepLessons = widget.lessons
        .where((lesson) => (lesson.step ?? '').startsWith('STEP'))
        .toList();
    if (stepLessons.isEmpty) {
      return widget.totalLessons.clamp(1, 99);
    }
    return stepLessons.length;
  }

  double _displayProgressValue() {
    final activeLessonNumber = _activeLessonNumber;
    final activeLessonStep = _activeLessonStep;
    final activeLessonTotalSteps = _activeLessonTotalSteps;

    if (activeLessonNumber == null || activeLessonStep == null || activeLessonTotalSteps == null) {
      return _completedLessons.toDouble();
    }

    final shouldApplyPartial =
        activeLessonNumber == _completedLessons + 1 && activeLessonTotalSteps > 0;
    if (!shouldApplyPartial) {
      return _completedLessons.toDouble();
    }

    final partial = (activeLessonStep / activeLessonTotalSteps).clamp(0.0, 1.0);
    return (_completedLessons + partial).clamp(0.0, _coreLessonCount.toDouble());
  }

  void _openNextStepAfter(int completedLessonNumber) {
    final nextLessonNumber = completedLessonNumber + 1;

    if (nextLessonNumber <= _coreLessonCount) {
      final nextIndex = widget.lessons.indexWhere(
        (lesson) =>
            (lesson.step ?? '').startsWith('STEP') &&
            _lessonNumberForProgress(lesson, 0) == nextLessonNumber,
      );
      if (nextIndex == -1) {
        return;
      }
      final nextLesson = widget.lessons[nextIndex];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LessonContentScreen(
            lessonTitle: nextLesson.title,
            lessonProgress: _lessonNumberForProgress(nextLesson, nextIndex),
            topicId: widget.topicId,
          ),
        ),
      ).then((result) async {
        final completed = result == true;
        if (!completed) {
          return;
        }

        final lessonNumber = _lessonNumberForProgress(nextLesson, nextIndex);
        if (lessonNumber > _completedLessons + 1) {
          return;
        }

        final newCompleted = lessonNumber > _completedLessons
            ? lessonNumber
            : _completedLessons;

        if (newCompleted > _completedLessons) {
          await TopicProgressService.instance.saveLessonsCompleted(
            topicId: widget.topicId,
            lessonsCompleted: newCompleted,
            totalLessons: _coreLessonCount,
          );

          if (!mounted) {
            return;
          }

          setState(() {
            _completedLessons = newCompleted;
          });
        }

        // Award XP for lesson completion
        await XpService.instance.earnXp(amount: 20, source: 'lesson_completion');
        final goToNextLesson = await _showLessonCompletedSheet(
          lessonTitle: nextLesson.title,
          earnedXp: 20,
        );

        if (!mounted) {
          return;
        }

        if (goToNextLesson) {
          _openNextStepAfter(newCompleted);
        }
      });
      return;
    }

    final finalQuizIndex = widget.lessons.indexWhere((lesson) => lesson.step == 'FINAL QUIZ');
    if (finalQuizIndex == -1 || _postQuizCompleted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          quizTitle: 'Learning Checkup',
          questions: _getPostQuizQuestions(),
          revealAnswerFeedback: true,
          topicId: widget.topicId,
          topicTitle: widget.topicTitle,
          lessonsCompleted: _coreLessonCount,
          totalLessons: _coreLessonCount,
          onQuizFinished: (score, totalQuestions) {
            return TopicProgressService.instance.savePostQuizResult(
              topicId: widget.topicId,
              score: score,
              totalQuestions: totalQuestions,
            );
          },
        ),
      ),
    ).then((_) => _loadTopicProgress());
  }

  int _lessonNumberForProgress(LessonItem lesson, int index) {
    final step = lesson.step ?? '';
    final match = RegExp(r'STEP\s+(\d+)').firstMatch(step);
    final parsed = int.tryParse(match?.group(1) ?? '');
    return (parsed ?? (index + 1)).clamp(1, _coreLessonCount);
  }

  Future<bool> _showLessonCompletedSheet({
    required String lessonTitle,
    required int earnedXp,
  }) async {
    if (!mounted) {
      return false;
    }

    final shouldGoNext = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Lesson Completed!',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 28),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFDCE6FF)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4D9),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFFFC24B)),
                        ),
                        child: Text(
                          '+$earnedXp XP',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB46900),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Icon(
                        Icons.emoji_events_rounded,
                        size: 46,
                        color: Color(0xFF007AFF),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '"$lessonTitle" completed successfully',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF007AFF),
                            minimumSize: const Size.fromHeight(50),
                            side: const BorderSide(color: Color(0xFF007AFF), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Back to Map',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007AFF),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Next Lesson',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    return shouldGoNext == true;
  }

  Widget _buildStatusIcon(LessonStatus status) {
    switch (status) {
      case LessonStatus.completed:
        return Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFF007AFF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 20,
          ),
        );
      case LessonStatus.current:
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF56CCF2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Color(0xFF56CCF2),
              size: 12,
            ),
          ),
        );
      case LessonStatus.locked:
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock,
            color: Colors.grey,
            size: 18,
          ),
        );
      case LessonStatus.quiz:
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.quiz_rounded,
            color: Color(0xFF007AFF),
            size: 20,
          ),
        );
    }
  }

  Color _getCardBackgroundColor(LessonStatus status) {
    switch (status) {
      case LessonStatus.completed:
        return const Color(0xFFF2F8FF);
      case LessonStatus.current:
        return const Color(0xFFEEF9FF);
      case LessonStatus.locked:
        return const Color(0xFFF7F8FA);
      case LessonStatus.quiz:
        return const Color(0xFFF6F8FF);
    }
  }

  Color _getCardBorderColor(LessonStatus status) {
    switch (status) {
      case LessonStatus.completed:
        return const Color(0xFF007AFF).withValues(alpha: 0.18);
      case LessonStatus.current:
        return const Color(0xFF3BB7FF);
      case LessonStatus.locked:
        return const Color(0xFFE5E7EB);
      case LessonStatus.quiz:
        return const Color(0xFF007AFF).withValues(alpha: 0.26);
    }
  }

  Color _getStepTextColor(LessonStatus status) {
    switch (status) {
      case LessonStatus.completed:
        return const Color(0xFF007AFF);
      case LessonStatus.current:
        return const Color(0xFF0891B2);
      case LessonStatus.locked:
        return const Color(0xFF9CA3AF);
      case LessonStatus.quiz:
        return const Color(0xFF1D4ED8);
    }
  }

  Color _getBadgeBackgroundColor(LessonStatus status) {
    switch (status) {
      case LessonStatus.completed:
        return const Color(0xFF007AFF).withValues(alpha: 0.15);
      case LessonStatus.current:
        return const Color(0xFF56CCF2).withValues(alpha: 0.2);
      case LessonStatus.quiz:
        return const Color(0xFF007AFF).withValues(alpha: 0.12);
      default:
        return const Color(0xFFEEF2F7);
    }
  }

  Color _getStatusBadgeBackgroundColor(LessonStatus status) {
    switch (status) {
      case LessonStatus.completed:
        return const Color(0xFF007AFF).withValues(alpha: 0.15);
      case LessonStatus.current:
        return const Color(0xFF56CCF2).withValues(alpha: 0.2);
      case LessonStatus.quiz:
        return const Color(0xFF007AFF).withValues(alpha: 0.12);
      default:
        return Colors.transparent;
    }
  }

  Color _getBadgeTextColor(LessonStatus status) {
    switch (status) {
      case LessonStatus.completed:
        return const Color(0xFF007AFF);
      case LessonStatus.current:
        return const Color(0xFF0891B2);
      case LessonStatus.quiz:
        return const Color(0xFF1D4ED8);
      default:
        return Colors.transparent;
    }
  }

  String _getBadgeText(LessonStatus status) {
    switch (status) {
      case LessonStatus.completed:
        return 'COMPLETED';
      case LessonStatus.current:
        return 'NEXT UP';
      case LessonStatus.quiz:
        return 'QUIZ';
      default:
        return '';
    }
  }

  List<QuizQuestion> _getPreQuizQuestions() {
    if (widget.topicTitle == 'Financial Planning for Big Goals') {
      return [
        QuizQuestion(
          question: 'Which of these is a "Specific" goal?',
          options: [
            'I want to be rich one day.',
            'I want to save 50,000 MUR for a laptop by December 20th.',
            'I want to buy something nice soon.',
          ],
          correctAnswer: 'I want to save 50,000 MUR for a laptop by December 20th.',
          explanation:
              'A specific goal clearly defines what you want, how much it costs, and by when.',
        ),
        QuizQuestion(
          question:
              'If you save 1,000 MUR a month for a car that costs 200,000 MUR, how long will it take?',
          options: [
            'About 5 years.',
            'About 16 years.',
            'About 2 years.',
          ],
          correctAnswer: 'About 16 years.',
          explanation:
              '200,000 ÷ 1,000 = 200 months, which is approximately 16 years and 8 months.',
        ),
        QuizQuestion(
          question: 'What is an "Inflation Adjustment"?',
          options: [
            'Realizing things get more expensive over time.',
            'Getting a discount at the store.',
            'Paying your bills on time.',
          ],
          correctAnswer: 'Realizing things get more expensive over time.',
          explanation:
              'Inflation adjustment means planning for future costs to be higher than today\'s price.',
        ),
      ];
    }

    if (widget.topicTitle == 'Debt Management') {
      return [
        QuizQuestion(
          question: 'What is "Debt"?',
          options: [
            'A cash reward for being a loyal customer',
            'Money you borrow today that you MUST pay back later',
            'A discount code for online shopping',
            'A type of savings account',
          ],
          correctAnswer: 'Money you borrow today that you MUST pay back later',
          explanation:
              'Debt is borrowed money that must be repaid, usually with extra cost.',
        ),
        QuizQuestion(
          question: 'What is "Interest"?',
          options: [
            'How much you like a new product',
            'The "rent" or extra fee you pay to use someone else\'s money',
            'A gift the bank gives you for borrowing',
            'The total amount of money you have in your pocket',
          ],
          correctAnswer:
              'The "rent" or extra fee you pay to use someone else\'s money',
          explanation: 'Interest is the cost of borrowing.',
        ),
        QuizQuestion(
          question:
              'What does "APR" tell you about a loan or "Pay Later" deal?',
          options: [
            'The name of the person who owns the bank',
            'The total "Price Tag" of the debt (interest + fees) for one year',
            'How many people have downloaded the app',
            'The day of the week you should pay',
          ],
          correctAnswer:
              'The total "Price Tag" of the debt (interest + fees) for one year',
          explanation:
              'APR reflects the yearly total borrowing cost (interest plus fees).',
        ),
      ];
    }

    if (widget.topicTitle == 'Saving & Emergency Funds') {
      return [
        QuizQuestion(
          question: 'What is an emergency fund?',
          options: [
            'A fund for planned vacations',
            'A "financial shield" for unexpected expenses',
            'A high-risk investment',
            'A secondary checking account',
          ],
          correctAnswer: 'A "financial shield" for unexpected expenses',
          explanation:
              'An emergency fund protects you against urgent, unexpected costs.',
        ),
        QuizQuestion(
          question: 'What is "Paying Yourself First"?',
          options: [
            'Buying a gift after you get paid',
            'Saving a portion of your income before spending anything else',
            'Paying your bills on time',
            'Giving yourself a raise',
          ],
          correctAnswer:
              'Saving a portion of your income before spending anything else',
          explanation:
              'This method prioritizes saving first, then spending the remainder.',
        ),
        QuizQuestion(
          question:
              'Where is the safest and most effective place for an emergency fund?',
          options: [
            'In a physical jar at home',
            'In a separate, liquid savings account',
            'In long-term stocks',
            'In your daily spending wallet',
          ],
          correctAnswer: 'In a separate, liquid savings account',
          explanation:
              'Emergency funds should be secure, liquid, and separated from daily spending.',
        ),
        QuizQuestion(
          question:
              'What is the "magic" effect where your interest earns more interest?',
          options: [
            'Simple interest',
            'Compound interest',
            'Inflation',
            'Net income',
          ],
          correctAnswer: 'Compound interest',
          explanation:
              'Compound interest means your returns also generate future returns.',
        ),
        QuizQuestion(
          question: 'When should you use your emergency fund?',
          options: [
            'For a flash sale on clothes',
            'For a sudden, necessary laptop repair',
            'To go to a concert with friends',
            'For monthly rent that you already planned for',
          ],
          correctAnswer: 'For a sudden, necessary laptop repair',
          explanation:
              'Use emergency funds only for urgent, necessary, unplanned situations.',
        ),
      ];
    }

    // Pre-quiz questions
    return [
      QuizQuestion(
        question: 'Which of the following is a fixed expense?',
        options: ['Rent', 'Groceries', 'Entertainment'],
        correctAnswer: 'Rent',
        explanation:
            'Rent is a set monthly cost that typically remains constant regardless of your usage or lifestyle.',
      ),
      QuizQuestion(
        question: 'What is a variable expense?',
        options: [
          'A cost that changes each month',
          'A cost that stays the same',
          'A cost you only pay once'
        ],
        correctAnswer: 'A cost that changes each month',
        explanation:
            'Variable expenses change based on your usage and choices, like dining out or entertainment.',
      ),
      QuizQuestion(
        question: 'Why is budgeting important?',
        options: [
          'To track spending and avoid overspending',
          'To impress friends',
          'It is not important'
        ],
        correctAnswer: 'To track spending and avoid overspending',
        explanation:
            'Budgeting helps you understand where your money goes and ensures you can cover essential expenses.',
      ),
      QuizQuestion(
        question: 'Which is an example of a variable expense?',
        options: ['Car insurance', 'Dining out', 'Rent'],
        correctAnswer: 'Dining out',
        explanation:
            'Dining out varies month to month based on your choices, making it a variable expense.',
      ),
      QuizQuestion(
        question: 'What should you prioritize in your budget?',
        options: [
          'Fixed expenses first',
          'Entertainment first',
          'Shopping first'
        ],
        correctAnswer: 'Fixed expenses first',
        explanation:
            'Fixed expenses like rent and bills should be paid first to ensure you meet your essential obligations.',
      ),
      QuizQuestion(
        question: 'How often should you review your budget?',
        options: ['Monthly', 'Once a year', 'Never'],
        correctAnswer: 'Monthly',
        explanation:
            'Regular monthly reviews help you stay on track and adjust for any changes in income or expenses.',
      ),
    ];
  }

  List<QuizQuestion> _getPostQuizQuestions() {
    if (widget.topicTitle == 'Financial Planning for Big Goals') {
      return [
        QuizQuestion(
          question: 'Why should you give your savings a "Name"?',
          options: [
            'To make the bank happy.',
            'To give the money a "job" and prevent impulsive spending.',
            'To get a better interest rate.',
          ],
          correctAnswer:
              'To give the money a "job" and prevent impulsive spending.',
          explanation:
              'Naming your fund makes it purpose-driven and harder to spend impulsively.',
        ),
        QuizQuestion(
          question: 'What exactly does a "Buffer" cover?',
          options: [
            'The monthly bank fees.',
            'Hidden costs like registration, insurance, and inflation.',
            'The cost of a new phone.',
          ],
          correctAnswer:
              'Hidden costs like registration, insurance, and inflation.',
          explanation:
              'A buffer protects you from extra charges and price increases beyond the sticker price.',
        ),
        QuizQuestion(
          question: 'What does the "S" in SMART stand for?',
          options: [
            'Savings.',
            'Specific (knowing exactly what you want).',
            'Small.',
          ],
          correctAnswer: 'Specific (knowing exactly what you want).',
          explanation:
              'Specific means the goal is clear, concrete, and easy to define.',
        ),
        QuizQuestion(
          question: 'How do separate bank accounts help you stay disciplined?',
          options: [
            'They hide your money from the government.',
            'They stop you from accidentally spending your "Goal" money on daily "Wants."',
            'They double your interest.',
          ],
          correctAnswer:
              'They stop you from accidentally spending your "Goal" money on daily "Wants."',
          explanation:
              'Separating money creates mental boundaries and protects long-term goals.',
        ),
        QuizQuestion(
          question: 'If you can\'t hit your monthly savings target, what should a professional do?',
          options: [
            'Give up on the goal.',
            'Adjust the timeline/date, but keep working toward the goal.',
            'Borrow money to hit the savings target.',
          ],
          correctAnswer:
              'Adjust the timeline/date, but keep working toward the goal.',
          explanation:
              'Professionals adapt the timeline while preserving the goal and the habit.',
        ),
      ];
    }

    if (widget.topicTitle == 'Debt Management') {
      return [
        QuizQuestion(
          question: 'What is the "Principal" of a loan?',
          options: [
            'A. The head of a school',
            'B. The original amount of money you borrowed',
            'C. The interest fee',
            'D. The bank\'s name',
          ],
          correctAnswer: 'B. The original amount of money you borrowed',
          explanation:
              'Principal means the original borrowed amount before interest.',
        ),
        QuizQuestion(
          question: 'What does a high APR mean?',
          options: [
            'A. The loan is a great deal',
            'B. The "rent" (cost) of borrowing that money is very expensive',
            'C. You get a cash reward',
            'D. You can pay whenever you want',
          ],
          correctAnswer:
              'B. The "rent" (cost) of borrowing that money is very expensive',
          explanation: 'Higher APR means higher borrowing cost.',
        ),
        QuizQuestion(
          question: 'What is the biggest danger of "Buy Now, Pay Later" apps?',
          options: [
            'A. They make you spend more than you can afford because the payments look small',
            'B. They give you too much free money',
            'C. They are only available in the morning',
            'D. They don\'t let you buy clothes',
          ],
          correctAnswer:
              'A. They make you spend more than you can afford because the payments look small',
          explanation:
              'Small installments can hide the true total commitment and cause overextension.',
        ),
        QuizQuestion(
          question: 'Why is your Credit Score important?',
          options: [
            'A. It shows how many followers you have',
            'B. It determines if banks will trust you with a house or car loan in the future',
            'C. It tells you how much money is in your savings account',
            'D. It\'s only for people over 50 years old',
          ],
          correctAnswer:
              'B. It determines if banks will trust you with a house or car loan in the future',
          explanation:
              'A strong credit history improves access to future loans and better terms.',
        ),
        QuizQuestion(
          question:
              'If you have two debts, which one should you usually try to pay off first to save money?',
          options: [
            'A. The one with the highest interest rate (APR)',
            'B. The one with the prettiest app',
            'C. The one you got most recently',
            'D. Neither; you should just ignore them',
          ],
          correctAnswer: 'A. The one with the highest interest rate (APR)',
          explanation:
              'Paying highest APR first reduces total interest paid over time.',
        ),
      ];
    }

    if (widget.topicTitle == 'Saving & Emergency Funds') {
      return [
        QuizQuestion(
          question: 'What is the "Starter" goal for an emergency fund?',
          options: [
            'A. 6 months of salary',
            'B. MUR 5,000 – 10,000',
            'C. MUR 1,000,000',
            'D. \$0 (you should spend it all)',
          ],
          correctAnswer: 'B. MUR 5,000 – 10,000',
          explanation:
              'The starter emergency fund target is usually MUR 5,000–10,000.',
        ),
        QuizQuestion(
          question:
              'If you earn MUR 20,000 and "Pay Yourself First" with 10%, how much do you move to savings immediately?',
          options: [
            'A. MUR 200',
            'B. MUR 2,000',
            'C. MUR 18,000',
            'D. MUR 0',
          ],
          correctAnswer: 'B. MUR 2,000',
          explanation:
              '10% of MUR 20,000 is MUR 2,000, moved to savings first.',
        ),
        QuizQuestion(
          question: 'Which of these is a "valid" emergency?',
          options: [
            'A. A weekend trip you forgot to plan for',
            'B. A sudden dental bill for a painful tooth',
            'C. Buying a new game that just came out',
            'D. Paying for a Netflix subscription',
          ],
          correctAnswer: 'B. A sudden dental bill for a painful tooth',
          explanation:
              'A valid emergency is unplanned, necessary, and urgent.',
        ),
        QuizQuestion(
          question: 'Why is Compound Interest better for younger people?',
          options: [
            'A. Younger people get higher interest rates',
            'B. They have more time for the "snowball effect" to work',
            'C. They have fewer expenses',
            'D. It isn\'t better; it\'s the same for everyone',
          ],
          correctAnswer: 'B. They have more time for the "snowball effect" to work',
          explanation:
              'The earlier you start, the longer compounding can grow your money.',
        ),
        QuizQuestion(
          question: 'What is the main benefit of "Automating" your savings?',
          options: [
            'A. It earns more interest',
            'B. It removes the need for willpower and ensures consistency',
            'C. It\'s the only way to open an account',
            'D. It\'s faster than manual transfers',
          ],
          correctAnswer:
              'B. It removes the need for willpower and ensures consistency',
          explanation:
              'Automation keeps saving consistent by removing monthly decision friction.',
        ),
      ];
    }

    return [
      QuizQuestion(
        question: 'What is a budget?',
        options: [
          'A. A plan for managing how money will be used',
          'B. A list of bank accounts',
          'C. A record of past purchases only',
          'D. A type of savings account',
        ],
        correctAnswer: 'A. A plan for managing how money will be used',
        explanation:
            'A budget is a forward-looking plan that helps you decide how to use your money intentionally.',
      ),
      QuizQuestion(
        question: 'Which type of income should usually be used when creating a budget?',
        options: [
          'A. Gross income',
          'B. Net income',
          'C. Bonus income',
          'D. Future income',
        ],
        correctAnswer: 'B. Net income',
        explanation:
            'Net income is the amount you actually receive after deductions, so it is the realistic number for planning.',
      ),
      QuizQuestion(
        question: 'Which of the following is a fixed expense?',
        options: [
          'A. Rent',
          'B. Groceries',
          'C. Entertainment',
          'D. Coffee',
        ],
        correctAnswer: 'A. Rent',
        explanation:
            'Rent is usually stable from month to month, making it a fixed expense.',
      ),
      QuizQuestion(
        question: 'Which of the following is an example of a want?',
        options: [
          'A. Bus fare to work or university',
          'B. Rent payment',
          'C. Dining out at a restaurant',
          'D. Electricity bill',
        ],
        correctAnswer: 'C. Dining out at a restaurant',
        explanation:
            'Dining out is typically optional, so it is usually classified as a want.',
      ),
      QuizQuestion(
        question: 'Why is tracking spending important?',
        options: [
          'A. It helps understand spending habits and control expenses',
          'B. It increases income automatically',
          'C. It removes the need for a budget',
          'D. It replaces saving money',
        ],
        correctAnswer:
            'A. It helps understand spending habits and control expenses',
        explanation:
            'Tracking shows where money goes in real life, helping you adjust your budget and control overspending.',
      ),
      QuizQuestion(
        question:
            'When creating a budget, which step should usually be done first?',
        options: [
          'A. List entertainment spending',
          'B. Calculate your income',
          'C. Buy necessary items',
          'D. Track spending',
        ],
        correctAnswer: 'B. Calculate your income',
        explanation:
            'A budget should start by identifying how much income you receive, because this determines how much money can be allocated to expenses and savings.',
      ),
    ];
  }
}
