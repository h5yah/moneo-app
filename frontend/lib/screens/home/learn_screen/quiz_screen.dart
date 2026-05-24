import 'package:flutter/material.dart';
import 'package:fintech/services/xp_service.dart';
import 'package:fintech/services/topic_progress_service.dart';
import 'quiz_completion_screen.dart';

class QuizScreen extends StatefulWidget {
  final String quizTitle;
  final List<QuizQuestion> questions;
  final bool awardXp;
  final bool showCompletionFlow;
  final Future<void> Function(int score, int totalQuestions)? onQuizFinished;
  final bool revealAnswerFeedback;
  final String? topicId;
  final String? topicTitle;
  final int? lessonsCompleted;
  final int? totalLessons;

  const QuizScreen({
    super.key,
    required this.quizTitle,
    required this.questions,
    this.awardXp = true,
    this.showCompletionFlow = true,
    this.onQuizFinished,
    this.revealAnswerFeedback = true,
    this.topicId,
    this.topicTitle,
    this.lessonsCompleted,
    this.totalLessons,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const int _correctAnswerXp = 50;

  int _currentQuestionIndex = 0;
  String? _selectedAnswer;
  bool _answered = false;
  int _score = 0;
  int _totalXP = 0;
  bool _showXpPopup = false;
  int _xpPopupTick = 0;
  final List<Future<XpEarnResult>> _pendingXpWrites = [];

  QuizQuestion get _currentQuestion => widget.questions[_currentQuestionIndex];

  String get _quizAwardScope {
    final topicId = widget.topicId?.trim();
    if (topicId != null && topicId.isNotEmpty) return topicId;
    return widget.quizTitle
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1020) : const Color(0xFFF6F8FC),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header Section
                _buildHeader(),
                // Progress Section
                _buildProgressSection(),
                // Question and Answers Section
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildQuestionText(),
                        const SizedBox(height: 24),
                        _buildAnswerOptions(),
                        if (_answered && widget.revealAnswerFeedback) ...[
                          const SizedBox(height: 24),
                          _buildFeedbackCard(),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                if (widget.revealAnswerFeedback) _buildNextButton(),
              ],
            ),
            if (_showXpPopup)
              Positioned(
                bottom: 110,
                left: 0,
                right: 0,
                child: Center(child: _buildXpPopup()),
              ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _premiumSurfaceDecoration({Color color = Colors.white}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? const Color(0xFF1B1D33) : color,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark ? const Color(0xFF2A2D4A) : const Color(0xFF007AFF).withValues(alpha: 0.10),
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

  Widget _buildXpPopup() {
    if (!widget.awardXp) {
      return const SizedBox.shrink();
    }

    final popupKey = ValueKey(_xpPopupTick);

    return TweenAnimationBuilder<double>(
      key: popupKey,
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      builder: (context, value, child) {
        final offsetY = (1 - value) * 16;
        final opacity = value < 0.75 ? value : (1 - value) * 4;

        return Transform.translate(
          offset: Offset(0, -offsetY),
          child: Opacity(
            opacity: opacity.clamp(0, 1),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.35)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt, size: 16, color: Color(0xFFFF9800)),
            SizedBox(width: 4),
            Text(
              '+50 XP',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFF9800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1D33) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2D4A) : const Color(0xFF007AFF).withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, 6),
            blurRadius: 14,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black, size: 24),
            onPressed: () => _showExitDialog(),
          ),
          Expanded(
            child: Center(
              child: Text(
                widget.quizTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF007AFF), size: 24),
            onPressed: () => _showQuizInfo(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final progress = (_currentQuestionIndex + 1) / widget.questions.length;
    final xpForQuestion = _correctAnswerXp;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: _premiumSurfaceDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QUESTION ${_currentQuestionIndex + 1} OF ${widget.questions.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B7280),
                  letterSpacing: 0.5,
                ),
              ),
              if (widget.awardXp)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bolt,
                        color: Color(0xFFFF9800),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+$xpForQuestion XP',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFE8EEF7),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionText() {
    return Text(
      _currentQuestion.question,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.black,
        height: 1.3,
      ),
    );
  }

  Widget _buildAnswerOptions() {
    return Column(
      children: _currentQuestion.options.map((option) {
        final isSelected = _selectedAnswer == option;
        final isCorrect = option == _currentQuestion.correctAnswer;
        final showCorrect = widget.revealAnswerFeedback && _answered && isCorrect;
        final showIncorrect = widget.revealAnswerFeedback && _answered && isSelected && !isCorrect;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: (widget.revealAnswerFeedback && _answered) ||
                    (!widget.revealAnswerFeedback && _answered)
                ? null
                : () => _onAnswerSelected(option),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: showCorrect
                    ? const Color(0xFFE8F5E9)
                    : showIncorrect
                        ? const Color(0xFFFFEBEE)
                        : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: showCorrect
                      ? const Color(0xFF4CAF50)
                      : showIncorrect
                          ? const Color(0xFFF44336)
                          : isSelected
                              ? const Color(0xFF007AFF)
                              : const Color(0xFFD9E2EF),
                  width: showCorrect || showIncorrect || isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    offset: const Offset(0, 4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: showIncorrect ? const Color(0xFFF44336) : Colors.black,
                      ),
                    ),
                  ),
                  if (showCorrect)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF4CAF50),
                      size: 24,
                    ),
                  if (showIncorrect)
                    const Icon(
                      Icons.cancel,
                      color: Color(0xFFF44336),
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeedbackCard() {
    final isCorrect = _selectedAnswer == _currentQuestion.correctAnswer;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect
              ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
              : const Color(0xFFF44336).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            offset: const Offset(0, 6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Correct!' : 'Incorrect',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                ),
              ),
            ],
          ),
          if (_currentQuestion.explanation != null) ...[
            const SizedBox(height: 12),
            Text(
              _currentQuestion.explanation!,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -3),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _answered ? _nextQuestion : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007AFF),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _currentQuestionIndex == widget.questions.length - 1
                    ? 'Finish'
                    : 'Next',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _onAnswerSelected(String option) {
    setState(() {
      _selectedAnswer = option;
      _answered = true;
    });

    if (widget.revealAnswerFeedback) {
      _submitAnswer(markAnswered: true);
      return;
    }

    // Pre-quiz: brief highlight, then advance (no blocking save on last question).
    _submitAnswer(markAnswered: true);
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted || !_answered) return;
      _nextQuestion();
    });
  }

  void _submitAnswer({required bool markAnswered}) {
    if (_selectedAnswer == _currentQuestion.correctAnswer) {
      _score++;
      if (widget.awardXp) {
        _persistCorrectAnswerXp();
      }
    }

    if (markAnswered) {
      setState(() {
        _answered = true;
      });
    }
  }

  void _persistCorrectAnswerXp() {
    final future = XpService.instance.earnXpOnce(
      amount: _correctAnswerXp,
      source: 'quiz_correct_answer',
      awardKey: 'quiz_correct:$_quizAwardScope:$_currentQuestionIndex',
    );
    _pendingXpWrites.add(future);

    future.then((result) {
      if (!result.awarded || !mounted) return;
      setState(() {
        _totalXP += _correctAnswerXp;
        _showXpPopup = true;
        _xpPopupTick++;
      });

      Future.delayed(const Duration(milliseconds: 950), () {
        if (!mounted) return;
        setState(() => _showXpPopup = false);
      });
    }).catchError((error) {
      debugPrint('Failed to persist correct-answer XP: $error');
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex == widget.questions.length - 1) {
      _showResults();
    } else {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
    }
  }

  Future<void> _showResults() async {
    if (widget.awardXp && _pendingXpWrites.isNotEmpty) {
      try {
        await Future.wait(_pendingXpWrites);
      } catch (error) {
        debugPrint('Failed waiting for quiz XP writes: $error');
      }
    }

    if (!widget.showCompletionFlow) {
      if (!mounted) {
        return;
      }

      final payload = {
        'score': _score,
        'totalQuestions': widget.questions.length,
      };

      // Close immediately; save progress in the background (Firestore/XP are slow).
      if (widget.onQuizFinished != null) {
        widget
            .onQuizFinished!(_score, widget.questions.length)
            .catchError((error) {
          debugPrint('Failed running quiz finish callback: $error');
        });
      }

      Navigator.of(context).pop(payload);
      return;
    }

    if (widget.onQuizFinished != null) {
      try {
        await widget.onQuizFinished!(_score, widget.questions.length);
      } catch (error) {
        debugPrint('Failed running quiz finish callback: $error');
      }
    }

    var topicCompletionBonus = 0;
    if (widget.topicId != null && widget.topicId!.isNotEmpty) {
      topicCompletionBonus = XpService.topicCompletionBonusXp;
      try {
        await XpService.instance.earnXpOnce(
          amount: topicCompletionBonus,
          source: 'topic_completion',
          awardKey: 'post_quiz:${widget.topicId}',
        );
      } catch (error) {
        debugPrint('Failed to award topic completion XP: $error');
      }
    }

    var currentLevel = 1;
    var xpToNextLevel = XpService.baseXpPerLevel;
    int? preQuizScore;
    int? preQuizTotal;

    try {
      final totalXp = await XpService.instance.getXp();
      final levelMeta = XpService.levelMetaFromTotalXp(totalXp);
      currentLevel = levelMeta.level;
      xpToNextLevel = levelMeta.xpToNextLevel;
    } catch (error) {
      debugPrint('Failed to load XP progress for completion screen: $error');
    }

    if (widget.topicId != null) {
      try {
        final progress = await TopicProgressService.instance.getTopicProgress(
          widget.topicId!,
        );
        final rawPreScore = progress?['preQuizScore'];
        final rawPreTotal = progress?['preQuizTotal'];

        if (rawPreScore is int && rawPreTotal is int && rawPreTotal > 0) {
          preQuizScore = rawPreScore;
          preQuizTotal = rawPreTotal;
        }
      } catch (error) {
        debugPrint('Failed to load pre-quiz progress for completion screen: $error');
      }
    }

    if (!mounted) {
      return;
    }

    // Navigate to completion screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => QuizCompletionScreen(
          score: _score,
          totalQuestions: widget.questions.length,
          earnedXP: topicCompletionBonus > 0
              ? topicCompletionBonus
              : _totalXP,
          currentLevel: currentLevel,
          xpToNextLevel: xpToNextLevel,
          topicId: widget.topicId,
          topicTitle: widget.topicTitle,
          lessonsCompleted: widget.lessonsCompleted,
          totalLessons: widget.totalLessons,
          preQuizScore: preQuizScore,
          preQuizTotal: preQuizTotal,
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Quiz?'),
        content: const Text('Your progress will be lost if you exit now.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close quiz screen
            },
            child: const Text(
              'Exit',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuizInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quiz Info'),
        content: const Text(
          'Answer all questions to complete the quiz. You earn 50 XP for each correct answer!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.explanation,
  });
}
