
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fintech/services/xp_service.dart';

class SurviveTheMonthScreen extends StatefulWidget {
  const SurviveTheMonthScreen({super.key});

  @override
  State<SurviveTheMonthScreen> createState() => _SurviveTheMonthScreenState();
}

class _SurviveTheMonthScreenState extends State<SurviveTheMonthScreen> {
  bool _xpAwarded = false;
  static const int _startingBudget = 12000;
  static const int _bonusSavingsGoal = 1500;

  late final List<SimulationEvent> _events;

  int _currentEventIndex = 0;
  int _budgetLeft = _startingBudget;
  int _savedMoney = 0;
  int _score = 0;

  bool _simulationStarted = false;
  bool _simulationEnded = false;

  int _bestScore = 0;
  int _bestMoneyLeft = 0;
  int _attempts = 0;

  String? _feedbackMessage;
  ChoiceOption? _selectedChoice;

  @override
  void initState() {
    super.initState();
    _events = _buildEvents();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bestScore = prefs.getInt('stm_best_score') ?? 0;
      _bestMoneyLeft = prefs.getInt('stm_best_money_left') ?? 0;
      _attempts = prefs.getInt('stm_attempts') ?? 0;
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();

    if (_score > _bestScore) {
      _bestScore = _score;
      await prefs.setInt('stm_best_score', _bestScore);
    }

    if (_budgetLeft > _bestMoneyLeft) {
      _bestMoneyLeft = _budgetLeft;
      await prefs.setInt('stm_best_money_left', _bestMoneyLeft);
    }

    _attempts += 1;
    await prefs.setInt('stm_attempts', _attempts);
  }

  List<SimulationEvent> _buildEvents() {
    return [
      SimulationEvent(
        day: 2,
        title: 'Weekly Groceries',
        description: 'Carla needs groceries for the week.',
        options: [
          ChoiceOption(
            text: 'Buy only essentials',
            cost: 900,
            scoreDelta: 10,
            feedback: 'Smart choice. Essentials keep spending under control.',
          ),
          ChoiceOption(
            text: 'Buy essentials + snacks',
            cost: 1300,
            scoreDelta: 5,
            feedback: 'Not terrible, but extras add up quickly.',
          ),
          ChoiceOption(
            text: 'Order takeout instead',
            cost: 1800,
            scoreDelta: 0,
            feedback: 'Convenient, but very expensive for one week.',
          ),
        ],
      ),
      SimulationEvent(
        day: 5,
        title: 'Friends Invite You Out',
        description: "Carla's friends want to go out for dinner.",
        options: [
          ChoiceOption(
            text: 'Go to a restaurant',
            cost: 700,
            scoreDelta: 3,
            feedback: 'Fun, but a costly choice for the budget.',
          ),
          ChoiceOption(
            text: 'Suggest a cheaper place',
            cost: 300,
            scoreDelta: 10,
            feedback: 'Great balance between social life and money control.',
          ),
          ChoiceOption(
            text: 'Stay home',
            cost: 0,
            scoreDelta: 8,
            feedback: 'You saved money, though you skipped the outing.',
          ),
        ],
      ),
      SimulationEvent(
        day: 8,
        title: 'Transport to Class',
        description: 'Carla needs transport for several classes this week.',
        options: [
          ChoiceOption(
            text: 'Take taxi',
            cost: 500,
            scoreDelta: 2,
            feedback: 'Fast, but not budget-friendly.',
          ),
          ChoiceOption(
            text: 'Take bus',
            cost: 150,
            scoreDelta: 10,
            feedback: 'Excellent choice. Affordable and practical.',
          ),
          ChoiceOption(
            text: 'Walk when possible',
            cost: 0,
            scoreDelta: 8,
            feedback: 'You saved money by avoiding transport costs.',
          ),
        ],
      ),
      SimulationEvent(
        day: 11,
        title: 'Mobile Data Expired',
        description: 'Carla’s mobile data package has finished.',
        options: [
          ChoiceOption(
            text: 'Buy a large package',
            cost: 500,
            scoreDelta: 4,
            feedback: 'Useful, but maybe more than needed.',
          ),
          ChoiceOption(
            text: 'Buy a basic package',
            cost: 200,
            scoreDelta: 10,
            feedback: 'Smart. You covered your need without overspending.',
          ),
          ChoiceOption(
            text: 'Use Wi-Fi only',
            cost: 0,
            scoreDelta: 7,
            feedback: 'You saved money, but flexibility may be lower.',
          ),
        ],
      ),
      SimulationEvent(
        day: 15,
        title: 'Unexpected Expense',
        description: 'Carla’s charger stopped working.',
        options: [
          ChoiceOption(
            text: 'Buy a branded charger',
            cost: 900,
            scoreDelta: 3,
            feedback: 'Reliable, but expensive for the current budget.',
          ),
          ChoiceOption(
            text: 'Buy an affordable charger',
            cost: 400,
            scoreDelta: 10,
            feedback: 'Good decision. You solved the problem affordably.',
          ),
          ChoiceOption(
            text: 'Borrow one temporarily',
            cost: 0,
            scoreDelta: 7,
            feedback: 'You avoided spending for now, which helps the budget.',
          ),
        ],
      ),
      SimulationEvent(
        day: 19,
        title: 'Shopping Temptation',
        description: 'There’s a sale on shoes Carla likes.',
        options: [
          ChoiceOption(
            text: 'Buy the new shoes',
            cost: 1500,
            scoreDelta: 0,
            feedback: 'That was a want, not a need. Big impact on budget.',
          ),
          ChoiceOption(
            text: 'Buy a cheaper pair',
            cost: 700,
            scoreDelta: 5,
            feedback: 'Better than overspending, but still optional spending.',
          ),
          ChoiceOption(
            text: 'Skip and buy later if needed',
            cost: 0,
            scoreDelta: 10,
            feedback: 'Excellent self-control. You protected the budget.',
          ),
        ],
      ),
      SimulationEvent(
        day: 23,
        title: 'Savings Decision',
        description: 'Carla wants to set aside some money before month-end.',
        options: [
          ChoiceOption(
            text: 'Save Rs 1,000',
            cost: 0,
            savingsDelta: 1000,
            scoreDelta: 10,
            feedback: 'Great move. Saving before spending is a strong habit.',
          ),
          ChoiceOption(
            text: 'Save Rs 500',
            cost: 0,
            savingsDelta: 500,
            scoreDelta: 7,
            feedback: 'Good job. Every amount saved matters.',
          ),
          ChoiceOption(
            text: 'Save nothing',
            cost: 0,
            savingsDelta: 0,
            scoreDelta: 2,
            feedback: 'You missed a chance to build a savings habit.',
          ),
        ],
      ),
      SimulationEvent(
        day: 28,
        title: 'End-of-Month Class Event',
        description: 'A class event comes up just before the end of the month.',
        options: [
          ChoiceOption(
            text: 'Spend Rs 600',
            cost: 600,
            scoreDelta: 3,
            feedback: 'This adds pressure near the end of the month.',
          ),
          ChoiceOption(
            text: 'Choose the cheaper option for Rs 250',
            cost: 250,
            scoreDelta: 10,
            feedback: 'Well done. You joined without overspending.',
          ),
          ChoiceOption(
            text: 'Skip the event',
            cost: 0,
            scoreDelta: 7,
            feedback: 'You protected your budget and stayed disciplined.',
          ),
        ],
      ),
    ];
  }

  void _startSimulation() {
    setState(() {
      _simulationStarted = true;
      _simulationEnded = false;
      _currentEventIndex = 0;
      _budgetLeft = _startingBudget;
      _savedMoney = 0;
      _score = 0;
      _feedbackMessage = null;
      _selectedChoice = null;
    });
  }

  void _selectChoice(ChoiceOption option) {
    if (_selectedChoice != null) return;

    setState(() {
      _selectedChoice = option;
      _budgetLeft -= option.cost;
      _savedMoney += option.savingsDelta;
      _score += option.scoreDelta;
      _feedbackMessage = option.feedback;
    });
  }

  Future<void> _goToNextEvent() async {
    if (_currentEventIndex < _events.length - 1) {
      setState(() {
        _currentEventIndex++;
        _selectedChoice = null;
        _feedbackMessage = null;
      });
    } else {
      setState(() {
        _simulationEnded = true;
      });
      await _saveProgress();
      setState(() {});
    }
  }

  void _resetSimulation() {
    setState(() {
      _simulationStarted = false;
      _simulationEnded = false;
      _currentEventIndex = 0;
      _budgetLeft = _startingBudget;
      _savedMoney = 0;
      _score = 0;
      _feedbackMessage = null;
      _selectedChoice = null;
    });
  }

  String get _budgetHealth {
    final ratio = _budgetLeft / _startingBudget;

    if (ratio >= 0.75) return 'Excellent';
    if (ratio >= 0.50) return 'Good';
    if (ratio >= 0.25) return 'Warning';
    return 'Critical';
  }

  IconData get _budgetHealthIcon {
    switch (_budgetHealth) {
      case 'Excellent':
        return Icons.health_and_safety_rounded;
      case 'Good':
        return Icons.thumb_up_alt_rounded;
      case 'Warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.error_outline_rounded;
    }
  }

  String get _finalResultTitle {
    if (_budgetLeft < 0) return 'You Overspent';
    if (_budgetLeft >= 2000 && _savedMoney >= _bonusSavingsGoal && _score >= 65) {
      return 'Excellent Budget Control';
    }
    if (_budgetLeft >= 0) return 'You Survived the Month';
    return 'Budget Review Needed';
  }

  String get _finalResultMessage {
    if (_budgetLeft < 0) {
      return 'Carla ran out of money before the month ended. Try again and make more careful spending choices.';
    }

    if (_budgetLeft >= 2000 && _savedMoney >= _bonusSavingsGoal) {
      return 'Amazing work. You managed spending wisely and built savings too.';
    }

    if (_budgetLeft >= 0) {
      return 'Good job. You made it to the end of the month with money left.';
    }

    return 'There is room to improve your budgeting choices.';
  }

  String get _scoreLabel {
    if (_score >= 70) return 'Excellent';
    if (_score >= 50) return 'Good';
    if (_score >= 30) return 'Average';
    return 'Needs Improvement';
  }

  double get _progressValue => (_currentEventIndex + 1) / _events.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Survive the Month'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: !_simulationStarted
            ? _buildIntroView()
            : _simulationEnded
                ? _buildResultView()
                : _buildSimulationView(),
      ),
    );
  }

  Widget _buildIntroView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroCard(),
          const SizedBox(height: 20),
          _buildProgressStatsCard(),
          const SizedBox(height: 20),
          _buildGoalsCard(),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startSimulation,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Start Simulation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF2563EB),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          // Icon removed as requested
          SizedBox(height: 16),
          Text(
            'Survive the Month',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Help Carla manage her monthly budget, handle expenses, and finish the month with money left.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Progress',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'Best Score',
                  _bestScore.toString(),
                  Icons.emoji_events_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat(
                  'Best Left',
                  'Rs $_bestMoneyLeft',
                  Icons.savings_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMiniStat(
            'Attempts',
            _attempts.toString(),
            Icons.refresh_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Simulation Goals',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 14),
          _GoalRow(text: 'Start with Rs 12,000'),
          _GoalRow(text: 'Complete all 8 financial situations'),
          _GoalRow(text: 'Finish the month with money left'),
          _GoalRow(text: 'Bonus: save at least Rs 1,500'),
        ],
      ),
    );
  }

  Widget _buildSimulationView() {
    final event = _events[_currentEventIndex];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTopStatus(),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildEventCard(event),
                  const SizedBox(height: 20),
                  ...event.options.map((option) => _buildChoiceButton(option)),
                  if (_feedbackMessage != null) ...[
                    const SizedBox(height: 18),
                    _buildFeedbackCard(),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _goToNextEvent,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _currentEventIndex == _events.length - 1
                              ? 'See Results'
                              : 'Next Event',
                        ),
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
  }

  Widget _buildTopStatus() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                title: 'Budget Left',
                value: 'Rs $_budgetLeft',
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatusCard(
                title: 'Saved',
                value: 'Rs $_savedMoney',
                icon: Icons.savings_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                title: 'Score',
                value: '$_score',
                icon: Icons.star_outline_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatusCard(
                title: 'Health',
                value: _budgetHealth,
                icon: _budgetHealthIcon,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Event ${_currentEventIndex + 1} of ${_events.length}',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: _progressValue,
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(SimulationEvent event) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Day ${event.day}',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            event.description,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade800,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceButton(ChoiceOption option) {
    final bool isSelected = _selectedChoice == option;
    final bool isDisabled = _selectedChoice != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: isDisabled ? null : () => _selectChoice(option),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDisabled && !isSelected
                        ? Colors.grey.shade500
                        : Colors.black87,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle_rounded)
              else
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Text(
        _feedbackMessage!,
        style: const TextStyle(
          fontSize: 14.5,
          height: 1.45,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildResultView() {
    // Award XP only once per completion
    Future.microtask(() async {
      if (!_xpAwarded && _budgetLeft >= 0) {
        _xpAwarded = true;
        await XpService.instance.earnXpOnce(
          amount: 100,
          source: 'survive_the_month',
          awardKey: 'scenario:survive_the_month',
        );
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _budgetLeft < 0
                    ? [Colors.red.shade400, Colors.red.shade600]
                    : [Colors.green.shade400, Colors.green.shade600],
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 14),
                Text(
                  _finalResultTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _finalResultMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                if (_budgetLeft >= 0)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.star, color: Colors.yellow, size: 22),
                        SizedBox(width: 8),
                        Text('XP Earned: 100',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildResultStatsCard(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startSimulation,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Play Again'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _resetSimulation,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Back to Intro'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'Money Left',
                  'Rs $_budgetLeft',
                  Icons.account_balance_wallet_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat(
                  'Saved',
                  'Rs $_savedMoney',
                  Icons.savings_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'Score',
                  '$_score',
                  Icons.star_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat(
                  'Rating',
                  _scoreLabel,
                  Icons.bar_chart_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMiniStat(
            'Budget Health',
            _budgetHealth,
            _budgetHealthIcon,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String title, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SimulationEvent {
  final int day;
  final String title;
  final String description;
  final List<ChoiceOption> options;

  SimulationEvent({
    required this.day,
    required this.title,
    required this.description,
    required this.options,
  });
}

class ChoiceOption {
  final String text;
  final int cost;
  final int savingsDelta;
  final int scoreDelta;
  final String feedback;

  ChoiceOption({
    required this.text,
    required this.cost,
    this.savingsDelta = 0,
    required this.scoreDelta,
    required this.feedback,
  });

  String get label {
    if (savingsDelta > 0) {
      return '$text  •  Save Rs $savingsDelta';
    }
    return '$text  •  Cost Rs $cost';
  }
}

class _GoalRow extends StatelessWidget {
  final String text;

  const _GoalRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}