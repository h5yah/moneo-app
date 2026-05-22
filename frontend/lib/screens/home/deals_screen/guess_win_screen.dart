import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:fintech/services/xp_service.dart';
import 'widgets/daily_reward_completed_view.dart';

class GuessWinScreen extends StatefulWidget {
  const GuessWinScreen({super.key});

  @override
  State<GuessWinScreen> createState() => _GuessWinScreenState();
}

class _GuessWinScreenState extends State<GuessWinScreen> {
  int? _winningCardIndex;
  int? _selectedCardIndex;
  int? _prizeValue;
  String _feedback = '';
  bool _gameWon = false;
  bool _gameLost = false;
  bool _loadingDaily = true;
  bool _playedToday = false;
  bool _roundComplete = false;
  final List<int> _prizePool = [150, 250, 400, 600, 800, 1000];

  @override
  void initState() {
    super.initState();
    _loadDailyStatus();
  }

  Future<void> _loadDailyStatus() async {
    final played = await XpService.instance.hasDailyReward(XpService.guessWinGame);
    if (!mounted) return;
    setState(() {
      _playedToday = played;
      _loadingDaily = false;
    });
    if (!played) {
      _startNewGame();
    }
  }

  void _startNewGame() {
    setState(() {
      _selectedCardIndex = null;
      _winningCardIndex = math.Random().nextInt(3);
      _prizeValue = null;
      _feedback = 'Pick a card to reveal rewards';
      _gameWon = false;
      _gameLost = false;
    });
  }

  void _selectCard(int index) {
    if (_playedToday || _roundComplete || _gameWon || _gameLost) return;

    setState(() {
      _selectedCardIndex = index;
      _feedback = 'Nice pick! Tap “Reveal Rewards” to check.';
    });
  }

  void _makeGuess(int index) {
    if (_playedToday || _roundComplete || _gameWon || _gameLost) return;

    final winningIndex = _winningCardIndex;
    if (winningIndex == null) return;

    setState(() {
      _selectedCardIndex = index;
      _prizeValue = _prizePool[math.Random().nextInt(_prizePool.length)];
      _roundComplete = true;

      if (index == winningIndex) {
        _gameWon = true;
        _feedback = 'Correct! 🎉 Card ${index + 1} is lucky';
        _showResultDialog(true);
      } else {
        _gameLost = true;
        _feedback = 'Not this time!';
        _showResultDialog(false);
      }
    });
  }

  void _showResultDialog(bool won) {
    final prize = won ? _prizeValue ?? 0 : 50;
    final winningIndex = _winningCardIndex ?? 0;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF0F2F7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                won ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
                size: 80,
                color: won ? const Color(0xFF00C6FF) : const Color(0xFFEF4444),
              ),
              const SizedBox(height: 16),
              Text(
                won ? 'Congratulations!' : 'Better Luck Next Time!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                won
                  ? 'You picked the lucky card!'
                  : 'Lucky card was #${winningIndex + 1}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF7B8494),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                won ? 'You won' : 'Consolation prize',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7B8494),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$prize XP',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: won ? const Color(0xFF1A3A52) : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final result = await XpService.instance.earnXpOnce(
                        amount: prize,
                        source: 'guess_win_reward',
                        awardKey: XpService.dailyAwardKey(XpService.guessWinGame),
                      );
                      if (!result.awarded) {
                        if (!mounted) return;
                        setState(() => _playedToday = true);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Daily guess reward already claimed.'),
                          ),
                        );
                        return;
                      }

                      if (!mounted) {
                        return;
                      }

                      setState(() => _playedToday = true);
                      Navigator.of(this.context).pop();
                      Navigator.of(this.context).pop();
                    } catch (error) {
                      if (!mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not claim reward right now. Try again.'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C6FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Claim XP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Guess & Win',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        centerTitle: true,
        actions: const [],
      ),
      body: _loadingDaily
          ? const Center(child: CircularProgressIndicator())
          : _playedToday
              ? const DailyRewardCompletedView(
                  gameTitle: 'Guess & Win',
                  accentColor: Color(0xFF00C6FF),
                )
              : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Pick a card!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Guess the card with the highest XP reward!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _feedback,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _gameWon
                      ? const Color(0xFF1A3A52)
                      : _gameLost
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: List.generate(3, (index) {
                  final isSelected = _selectedCardIndex == index;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index == 2 ? 0 : 12),
                      child: _MysteryCard(
                        selected: isSelected,
                        dimmed: _roundComplete || _gameWon || _gameLost,
                        onTap: () => _selectCard(index),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.info, size: 18, color: Color(0xFF111827)),
                        SizedBox(width: 8),
                        Text(
                          'How to Play',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _HowToPlayItem(
                      index: 1,
                      text: 'Select any of the three mystery cards above.',
                    ),
                    SizedBox(height: 12),
                    _HowToPlayItem(
                      index: 2,
                      text: 'Make your best pick and reveal rewards.',
                    ),
                    SizedBox(height: 12),
                    _HowToPlayItem(
                      index: 3,
                      text: 'The highest reward could be up to 5,000 XP!',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _selectedCardIndex == null ||
                          _roundComplete ||
                          _gameWon ||
                          _gameLost
                      ? null
                      : () => _makeGuess(_selectedCardIndex!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF87CEEB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    disabledForegroundColor: const Color(0xFF9CA3AF),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Reveal Rewards',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.style_rounded, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _MysteryCard extends StatelessWidget {
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  const _MysteryCard({
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: dimmed ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
                color: selected ? const Color(0xFF00C6FF) : const Color(0xFFE5E7EB),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6F4FF), // Light Teal bg
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ),
            ),
            if (selected)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A3A52),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HowToPlayItem extends StatelessWidget {
  final int index;
  final String text;

  const _HowToPlayItem({
    required this.index,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Color(0xFF1A3A52),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4B5563),
            ),
          ),
        ),
      ],
    );
  }
}

