import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fintech/screens/home/home_screen/home_screen.dart';
 
 
class _Question {
  const _Question({
    required this.question,
    required this.options,
    required this.scores, 
  });
  final String question;
  final List<String> options;
  final List<Map<String, int>> scores;
}
 
const _kQuestions = [
  _Question(
    question: 'You get unexpected extra cash this month. What do you do first?',
    options: ['Save most of it', 'Spend on something fun', 'Split between both'],
    scores: [
      {'planner': 2, 'achiever': 0, 'explorer': 0},
      {'planner': 0, 'achiever': 0, 'explorer': 2},
      {'planner': 0, 'achiever': 2, 'explorer': 0},
    ],
  ),
  _Question(
    question: 'Your friends invite you out, but your budget is tight.',
    options: ['Skip and stick to plan', 'Go anyway, YOLO', 'Suggest a cheaper plan'],
    scores: [
      {'planner': 2, 'achiever': 0, 'explorer': 0},
      {'planner': 0, 'achiever': 0, 'explorer': 2},
      {'planner': 0, 'achiever': 2, 'explorer': 0},
    ],
  ),
  _Question(
    question: 'What helps you stay consistent with money habits?',
    options: ['A clear written plan', 'Hitting visible milestones', 'Daily reminders & tips'],
    scores: [
      {'planner': 2, 'achiever': 0, 'explorer': 0},
      {'planner': 0, 'achiever': 2, 'explorer': 0},
      {'planner': 0, 'achiever': 0, 'explorer': 2},
    ],
  ),
  _Question(
    question: 'When learning about money, you prefer...',
    options: ['Step-by-step guides', 'Challenge-based tasks', 'Short practical tips'],
    scores: [
      {'planner': 2, 'achiever': 0, 'explorer': 0},
      {'planner': 0, 'achiever': 2, 'explorer': 0},
      {'planner': 0, 'achiever': 0, 'explorer': 2},
    ],
  ),
  _Question(
    question: 'How do you feel about financial goals?',
    options: [
      'I love setting detailed targets',
      'I want to crush big milestones',
      'I like exploring what works for me',
    ],
    scores: [
      {'planner': 2, 'achiever': 0, 'explorer': 0},
      {'planner': 0, 'achiever': 2, 'explorer': 0},
      {'planner': 0, 'achiever': 0, 'explorer': 2},
    ],
  ),
];
 
//  Archetype model 
 
class _Archetype {
  const _Archetype({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    required this.tags,
    required this.color,
    required this.lightColor,
  });
  final String id;
  final String title;
  final String emoji;
  final String description;
  final List<String> tags;
  final Color color;
  final Color lightColor;
}
 
const _archetypes = {
  'planner': _Archetype(
    id: 'planner',
    title: 'The Planner',
    emoji: '📋',
    description:
        'You thrive with structure and clear goals. You think long-term and love having a solid financial roadmap.',
    tags: ['Strategic', 'Disciplined', 'Consistent'],
    color: Color(0xFF007AFF),
    lightColor: Color(0xFFEEF6FF),
  ),
  'achiever': _Archetype(
    id: 'achiever',
    title: 'The Achiever',
    emoji: '🏆',
    description:
        'You are motivated by visible progress. Hitting milestones and levelling up keeps you going.',
    tags: ['Goal-driven', 'Competitive', 'Focused'],
    color: Color(0xFF2563EB),
    lightColor: Color(0xFFEEF6FF),
  ),
  'explorer': _Archetype(
    id: 'explorer',
    title: 'The Explorer',
    emoji: '🧭',
    description:
        'You learn by doing. You like trying new approaches to money and improving as you discover what works.',
    tags: ['Curious', 'Flexible', 'Adaptive'],
    color: Color(0xFF059669),
    lightColor: Color(0xFFECFDF5),
  ),
};
 
//  Main widget 
 
class PreQuizScreen extends StatefulWidget {
  const PreQuizScreen({super.key});
 
  @override
  State<PreQuizScreen> createState() => _PreQuizScreenState();
}
 
class _PreQuizScreenState extends State<PreQuizScreen>
    with TickerProviderStateMixin {
  int _phase = 0;
  int _qIndex = 0;
  int _selected = -1;
  final List<int> _answers = [];
  bool _saving = false;
  _Archetype? _archetype;
 
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;
 
  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _scaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _fadeCtrl.forward();
  }
 
  @override
  void dispose() {
    _fadeCtrl.dispose();
    _scaleCtrl.dispose();
    super.dispose();
  }
 
  void _goToQuiz() {
    _fadeCtrl.reverse().then((_) {
      if (!mounted) return;
      setState(() => _phase = 1);
      _fadeCtrl.forward();
    });
  }
 
  void _nextQuestion() {
    if (_selected == -1) return;
    _answers.add(_selected);
 
    if (_qIndex < _kQuestions.length - 1) {
      _fadeCtrl.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _qIndex++;
          _selected = -1;
        });
        _fadeCtrl.forward();
      });
    } else {
      _revealArchetype();
    }
  }
 
  void _revealArchetype() {
    final arch = _deriveArchetype();
    _fadeCtrl.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _phase = 2;
        _archetype = arch;
      });
      _fadeCtrl.forward();
      _scaleCtrl.forward();
    });
  }
 
  _Archetype _deriveArchetype() {
    int planner = 0, achiever = 0, explorer = 0;
    for (int i = 0; i < _answers.length; i++) {
      final s = _kQuestions[i].scores[_answers[i]];
      planner += s['planner']!;
      achiever += s['achiever']!;
      explorer += s['explorer']!;
    }
    if (planner >= achiever && planner >= explorer) return _archetypes['planner']!;
    if (achiever >= planner && achiever >= explorer) return _archetypes['achiever']!;
    return _archetypes['explorer']!;
  }
 
  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    final user = FirebaseAuth.instance.currentUser;
    final arch = _archetype ?? _deriveArchetype();
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'archetype': arch.id,
        'archetypeTitle': arch.title,
        'quizAnswers': _answers,
        'preferences': {
          'learningStyle': arch.id,
        },
        'onboardingCompletedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }
 
 
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: switch (_phase) {
        0 => _SplashScreen(onStart: _goToQuiz),
        1 => _QuizScreen(
            questions: _kQuestions,
            currentIndex: _qIndex,
            selected: _selected,
            onSelect: (i) => setState(() => _selected = i),
            onNext: _nextQuestion,
          ),
        _ => _ArchetypeScreen(
            archetype: _archetype!,
            scaleAnim: _scaleAnim,
            isSaving: _saving,
            onContinue: _finish,
          ),
      },
    );
  }
}
 
//  Splash screen 
 
class _SplashScreen extends StatelessWidget {
  const _SplashScreen({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F5FF),
      body: Stack(
        children: [
          //  background circles 
          Positioned(
            top: -70, right: -70,
            child: _Circle(size: 260, color: const Color(0xFFBFDBFE)),
          ),
          Positioned(
            top: 110, right: -20,
            child: _Circle(size: 110, color: const Color(0xFF93C5FD)),
          ),
          Positioned(
            bottom: 80, left: -60,
            child: _Circle(size: 220, color: const Color(0xFFC7D9FF)),
          ),
          Positioned(
            bottom: 180, right: 30,
            child: _Circle(size: 40, color: const Color(0xFFA5C8FE)),
          ),

          //  content 
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 44),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  

                  const Spacer(),

                  //  badge 
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF93C5FD)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5, height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        const Text(
                          'Personalized for you',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1D4ED8),
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0F172A),
                        height: 1.12,
                        letterSpacing: -1,
                      ),
                      children: [
                        TextSpan(text: 'Money habits\nthat actually\n'),
                        TextSpan(
                          text: 'stick.',
                          style: TextStyle(color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  //  subtitle 
                  const Text(
                    'Answer 5 quick questions. We\'ll build a money profile that actually fits your life.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF475569),
                      height: 1.65,
                    ),
                  ),

                  const Spacer(),
                  _SwipeToContinue(onComplete: onStart),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SwipeToContinue extends StatefulWidget {
  const _SwipeToContinue({required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<_SwipeToContinue> createState() => _SwipeToContinueState();
}

class _SwipeToContinueState extends State<_SwipeToContinue>
    with SingleTickerProviderStateMixin {
  static const double _height = 56;

  late final AnimationController _chevronCtrl;
  double _dragDistance = 0;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _chevronCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _chevronCtrl.dispose();
    super.dispose();
  }

  void _complete() {
    if (_completed) return;
    setState(() {
      _completed = true;
      _dragDistance = 0;
    });
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final threshold = constraints.maxWidth * 0.35;
        final progress = threshold <= 0
            ? 0.0
            : (_dragDistance / threshold).clamp(0.0, 1.0);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) {
            if (_completed) return;
            setState(() {
              _dragDistance =
                  (_dragDistance + (details.primaryDelta ?? 0)).clamp(
                0.0,
                threshold,
              );
            });
          },
          onHorizontalDragEnd: (_) {
            if (_completed) return;
            if (progress > 0.9) {
              _complete();
            } else {
              setState(() => _dragDistance = 0);
            }
          },
          child: SizedBox(
            height: _height,
            child: Center(
              child: AnimatedBuilder(
                animation: _chevronCtrl,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(progress * 18, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Swipe right to start',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ...List.generate(3, (index) {
                          final shifted =
                              (_chevronCtrl.value + (index * 0.16)) % 1.0;
                          final pulse = shifted < 0.5
                              ? shifted * 2
                              : (1 - shifted) * 2;
                          final opacity = 0.25 + (pulse * 0.75);

                          return Opacity(
                            opacity: opacity,
                            child: Transform.translate(
                              offset: Offset(pulse * 4, 0),
                              child: const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF2563EB),
                                size: 27,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
 
//  Quiz screen 
 
class _QuizScreen extends StatelessWidget {
  const _QuizScreen({
    required this.questions,
    required this.currentIndex,
    required this.selected,
    required this.onSelect,
    required this.onNext,
  });
  final List<_Question> questions;
  final int currentIndex;
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onNext;
 
  @override
  Widget build(BuildContext context) {
    final q = questions[currentIndex];
    final total = questions.length;
 
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(total, (i) {
                  final active = i <= currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 5),
                    height: 5,
                    width: active ? 22 : 8,
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFF007AFF)
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
 
              //  question
              Text(
                'Question ${currentIndex + 1} of $total',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                q.question,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 28),
 
              //  options 
              ...List.generate(q.options.length, (i) {
                final isSelected = selected == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => onSelect(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFEEF6FF)
                            : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF007AFF)
                              : const Color(0xFFE5E7EB),
                          width: isSelected ? 2 : 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              q.options[i],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF007AFF)
                                    : const Color(0xFF374151),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? const Color(0xFF007AFF)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF007AFF)
                                    : const Color(0xFFD1D5DB),
                                width: 1.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 13)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
 
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selected != -1 ? onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    currentIndex == questions.length - 1
                        ? 'Reveal my personality'
                        : 'Next',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: selected != -1
                          ? Colors.white
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
 
//  Archetype reveal screen 
 
class _ArchetypeScreen extends StatelessWidget {
  const _ArchetypeScreen({
    required this.archetype,
    required this.scaleAnim,
    required this.isSaving,
    required this.onContinue,
  });
  final _Archetype archetype;
  final Animation<double> scaleAnim;
  final bool isSaving;
  final VoidCallback onContinue;
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
          child: Column(
            children: [
              const Text(
                'Your money personality',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 32),
 
              //  animated badge 
              ScaleTransition(
                scale: scaleAnim,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: archetype.lightColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: archetype.color.withOpacity(0.3), width: 3),
                  ),
                  child: Center(
                    child: Text(
                      archetype.emoji,
                      style: const TextStyle(fontSize: 56),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
 
              //  title 
              Text(
                archetype.title,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: archetype.color,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
 
              //  description 
              Text(
                archetype.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280),
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 24),
 
              //  trait pills 
              Wrap(
                spacing: 8,
                children: archetype.tags.map((tag) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: archetype.lightColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: archetype.color.withOpacity(0.2), width: 1),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: archetype.color,
                      ),
                    ),
                  );
                }).toList(),
              ),
 
              const Spacer(),
 
              //  cta 
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving ? null : onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: archetype.color,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Start my journey',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
