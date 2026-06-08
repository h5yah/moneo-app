import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fintech/services/xp_service.dart';
import 'package:fintech/utils/icon_accent_style.dart';

class EmergencyFundBuilderScreen extends StatefulWidget {
  const EmergencyFundBuilderScreen({super.key});

  @override
  State<EmergencyFundBuilderScreen> createState() => _EmergencyFundBuilderScreenState();
}

class _EmergencyFundBuilderScreenState extends State<EmergencyFundBuilderScreen> {
  bool _xpAwarded = false;
  static const int _startingSalary = 18000;
  static const int _targetFund = 5000;

  late final List<EmergencyScenario> _scenarios;

  int _stepIndex = 0;
  int _cashLeft = _startingSalary;
  int _emergencyFund = 0;
  int _score = 0;
  int _stress = 20;

  bool _started = false;
  bool _finished = false;

  ChoiceDecision? _selectedDecision;
  String? _feedback;

  int _bestFund = 0;
  int _bestScore = 0;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _scenarios = _buildScenarios();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bestFund = prefs.getInt('ef_best_fund') ?? 0;
      _bestScore = prefs.getInt('ef_best_score') ?? 0;
      _attempts = prefs.getInt('ef_attempts') ?? 0;
    });
  }

  Future<void> _saveStats() async {
    final prefs = await SharedPreferences.getInstance();

    if (_emergencyFund > _bestFund) {
      _bestFund = _emergencyFund;
      await prefs.setInt('ef_best_fund', _bestFund);
    }

    if (_score > _bestScore) {
      _bestScore = _score;
      await prefs.setInt('ef_best_score', _bestScore);
    }

    _attempts += 1;
    await prefs.setInt('ef_attempts', _attempts);
  }

  List<EmergencyScenario> _buildScenarios() {
    return [
      EmergencyScenario(
        monthDay: 'Day 1',
        tag: 'Salary Day',
        title: 'You just got paid',
        description:
            'You receive Rs 18,000 this month. In Mauritius, unexpected costs can appear fast, so this is your chance to build protection before anything goes wrong.',
        icon: Icons.payments_rounded,
        decisions: [
          ChoiceDecision(
            text: 'Put Rs 2,000 into emergency fund',
            cashDelta: 0,
            fundDelta: 2000,
            scoreDelta: 12,
            stressDelta: -4,
            feedback:
                'Excellent start. Building your fund early makes later emergencies easier to handle.',
          ),
          ChoiceDecision(
            text: 'Put Rs 1,000 into emergency fund',
            cashDelta: 0,
            fundDelta: 1000,
            scoreDelta: 8,
            stressDelta: -2,
            feedback:
                'Good decision. It is a smaller step, but still builds financial protection.',
          ),
          ChoiceDecision(
            text: 'Save nothing for now',
            cashDelta: 0,
            fundDelta: 0,
            scoreDelta: 1,
            stressDelta: 3,
            feedback:
                'You kept your money available, but you missed a strong chance to prepare.',
          ),
        ],
      ),
      EmergencyScenario(
        monthDay: 'Day 4',
        tag: 'Transport',
        title: 'Metro Express disruption',
        description:
            'Your usual route is disrupted and you still need to get to class or work. You need a practical decision without damaging your budget too much.',
        icon: Icons.train_rounded,
        decisions: [
          ChoiceDecision(
            text: 'Take a taxi for Rs 450',
            cashDelta: -450,
            fundDelta: 0,
            scoreDelta: 2,
            stressDelta: -1,
            feedback:
                'You solved the problem quickly, but taxis can eat into your monthly cash.',
          ),
          ChoiceDecision(
            text: 'Use bus / alternate public transport for Rs 120',
            cashDelta: -120,
            fundDelta: 0,
            scoreDelta: 10,
            stressDelta: 0,
            feedback:
                'Smart move. You stayed mobile without overspending.',
          ),
          ChoiceDecision(
            text: 'Miss the day and spend nothing',
            cashDelta: 0,
            fundDelta: 0,
            scoreDelta: 3,
            stressDelta: 4,
            feedback:
                'You protected your money, but this choice can create other problems.',
          ),
        ],
      ),
      EmergencyScenario(
        monthDay: 'Day 8',
        tag: 'Phone Repair',
        title: 'Your phone screen cracks',
        description:
            'You rely on your phone for messages, banking, and university updates. Repairing it matters, but how you pay matters too.',
        icon: Icons.phone_android_rounded,
        decisions: [
          ChoiceDecision(
            text: 'Pay repair from cash: Rs 1,200',
            cashDelta: -1200,
            fundDelta: 0,
            scoreDelta: 6,
            stressDelta: 1,
            feedback:
                'Reasonable. You solved the issue, though your available cash took a hit.',
          ),
          ChoiceDecision(
            text: 'Use Rs 1,200 from emergency fund',
            cashDelta: 0,
            fundDelta: -1200,
            scoreDelta: 10,
            stressDelta: -2,
            requiresFundAmount: 1200,
            feedback:
                'Good use of the emergency fund. This is exactly what it is for.',
          ),
          ChoiceDecision(
            text: 'Delay repair and manage carefully',
            cashDelta: 0,
            fundDelta: 0,
            scoreDelta: 4,
            stressDelta: 5,
            feedback:
                'You avoided spending, but delaying an important repair increases inconvenience.',
          ),
        ],
      ),
      EmergencyScenario(
        monthDay: 'Day 12',
        tag: 'Health',
        title: 'You need a doctor visit',
        description:
            'You are not feeling well and need a consultation plus medicine. This is one of the most realistic reasons people need emergency savings.',
        icon: Icons.local_hospital_rounded,
        decisions: [
          ChoiceDecision(
            text: 'Pay doctor + medicine from cash: Rs 900',
            cashDelta: -900,
            fundDelta: 0,
            scoreDelta: 7,
            stressDelta: 1,
            feedback:
                'You handled the issue responsibly, but your regular cash is lower now.',
          ),
          ChoiceDecision(
            text: 'Use Rs 900 from emergency fund',
            cashDelta: 0,
            fundDelta: -900,
            scoreDelta: 10,
            stressDelta: -2,
            requiresFundAmount: 900,
            feedback:
                'Strong financial decision. Emergencies are easier when you planned ahead.',
          ),
          ChoiceDecision(
            text: 'Ignore it for now',
            cashDelta: 0,
            fundDelta: 0,
            scoreDelta: 0,
            stressDelta: 8,
            feedback:
                'Risky decision. Avoiding necessary care can create a bigger issue later.',
          ),
        ],
      ),
      EmergencyScenario(
        monthDay: 'Day 16',
        tag: 'Utilities',
        title: 'Higher-than-expected CWA / CEB expense',
        description:
            'A home utility expense needs to be covered this month. Even when it is not huge, sudden bills can disrupt your plan.',
        icon: Icons.lightbulb_circle_rounded,
        decisions: [
          ChoiceDecision(
            text: 'Pay full amount from cash: Rs 700',
            cashDelta: -700,
            fundDelta: 0,
            scoreDelta: 7,
            stressDelta: 0,
            feedback:
                'Solid choice. You stayed on top of the bill, though cash flow gets tighter.',
          ),
          ChoiceDecision(
            text: 'Use emergency fund for Rs 700',
            cashDelta: 0,
            fundDelta: -700,
            scoreDelta: 8,
            stressDelta: -1,
            requiresFundAmount: 700,
            feedback:
                'This works if cash is tight, though it reduces your safety cushion.',
          ),
          ChoiceDecision(
            text: 'Delay payment',
            cashDelta: 0,
            fundDelta: 0,
            scoreDelta: 1,
            stressDelta: 6,
            feedback:
                'Delaying may protect you today, but it increases future pressure.',
          ),
        ],
      ),
      EmergencyScenario(
        monthDay: 'Day 20',
        tag: 'Opportunity',
        title: 'A quiet week gives you a chance to save again',
        description:
            'No emergency hit this week. This is the moment where disciplined people strengthen their safety net instead of spending impulsively.',
        icon: Icons.savings_rounded,
        decisions: [
          ChoiceDecision(
            text: 'Add Rs 1,500 more to emergency fund',
            cashDelta: 0,
            fundDelta: 1500,
            scoreDelta: 12,
            stressDelta: -4,
            feedback:
                'Excellent discipline. Building the fund during calm periods is exactly the right move.',
          ),
          ChoiceDecision(
            text: 'Add Rs 700 to emergency fund',
            cashDelta: 0,
            fundDelta: 700,
            scoreDelta: 8,
            stressDelta: -2,
            feedback:
                'Good choice. Slow and consistent saving still creates protection.',
          ),
          ChoiceDecision(
            text: 'Spend it on non-essentials',
            cashDelta: -900,
            fundDelta: 0,
            scoreDelta: 1,
            stressDelta: 3,
            feedback:
                'You chose comfort now, but you gave up a valuable savings opportunity.',
          ),
        ],
      ),
      EmergencyScenario(
        monthDay: 'Day 25',
        tag: 'Academics',
        title: 'Urgent printing and project materials',
        description:
            'A last-minute university expense comes up for printing, transport, and materials. It is not huge, but it was not planned.',
        icon: Icons.print_rounded,
        decisions: [
          ChoiceDecision(
            text: 'Pay from cash: Rs 550',
            cashDelta: -550,
            fundDelta: 0,
            scoreDelta: 8,
            stressDelta: 0,
            feedback:
                'Good handling. You covered the need without panic.',
          ),
          ChoiceDecision(
            text: 'Use Rs 550 from emergency fund',
            cashDelta: 0,
            fundDelta: -550,
            scoreDelta: 7,
            stressDelta: -1,
            requiresFundAmount: 550,
            feedback:
                'Acceptable if cash is tight, though it reduces your emergency buffer.',
          ),
          ChoiceDecision(
            text: 'Borrow from someone',
            cashDelta: 0,
            fundDelta: 0,
            scoreDelta: 2,
            stressDelta: 5,
            feedback:
                'Borrowing solves today’s problem, but creates dependency and pressure.',
          ),
        ],
      ),
      EmergencyScenario(
        monthDay: 'Day 30',
        tag: 'Month End',
        title: 'Final decision before month closes',
        description:
            'You made it to the end of the month. You have one final chance to strengthen your emergency fund instead of entering next month unprepared.',
        icon: Icons.flag_rounded,
        decisions: [
          ChoiceDecision(
            text: 'Move Rs 1,000 into emergency fund',
            cashDelta: 0,
            fundDelta: 1000,
            scoreDelta: 10,
            stressDelta: -3,
            feedback:
                'Strong finish. You are ending the month with more protection.',
          ),
          ChoiceDecision(
            text: 'Move Rs 500 into emergency fund',
            cashDelta: 0,
            fundDelta: 500,
            scoreDelta: 6,
            stressDelta: -1,
            feedback:
                'Nice final step. Even smaller amounts improve stability.',
          ),
          ChoiceDecision(
            text: 'Keep all remaining cash outside the fund',
            cashDelta: 0,
            fundDelta: 0,
            scoreDelta: 2,
            stressDelta: 2,
            feedback:
                'You stayed flexible, but your emergency protection remains weaker.',
          ),
        ],
      ),
    ];
  }

  void _startSimulation() {
    setState(() {
      _xpAwarded = false;
      _started = true;
      _finished = false;
      _stepIndex = 0;
      _cashLeft = _startingSalary;
      _emergencyFund = 0;
      _score = 0;
      _stress = 20;
      _selectedDecision = null;
      _feedback = null;
    });
  }

  bool _decisionDisabled(ChoiceDecision d) {
    if (d.requiresFundAmount != null && _emergencyFund < d.requiresFundAmount!) {
      return true;
    }
    return false;
  }

  void _chooseDecision(ChoiceDecision decision) {
    if (_selectedDecision != null) return;
    if (_decisionDisabled(decision)) return;

    setState(() {
      _selectedDecision = decision;
      _cashLeft += decision.cashDelta;
      _emergencyFund += decision.fundDelta;
      _score += decision.scoreDelta;
      _stress += decision.stressDelta;

      if (_stress < 0) _stress = 0;
      if (_stress > 100) _stress = 100;

      _feedback = decision.feedback;
    });
  }

  Future<void> _nextStep() async {
    if (_stepIndex < _scenarios.length - 1) {
      setState(() {
        _stepIndex++;
        _selectedDecision = null;
        _feedback = null;
      });
    } else {
      setState(() {
        _finished = true;
      });
      await _saveStats();
      setState(() {});
    }
  }

  void _backToIntro() {
    setState(() {
      _xpAwarded = false;
      _started = false;
      _finished = false;
      _stepIndex = 0;
      _cashLeft = _startingSalary;
      _emergencyFund = 0;
      _score = 0;
      _stress = 20;
      _selectedDecision = null;
      _feedback = null;
    });
  }

  double get _fundProgress {
    final progress = _emergencyFund / _targetFund;
    return progress.clamp(0, 1).toDouble();
  }

  String get _preparednessLabel {
    if (_emergencyFund >= 5000) return 'Strong';
    if (_emergencyFund >= 3000) return 'Building Well';
    if (_emergencyFund >= 1500) return 'Average';
    return 'Weak';
  }

  String get _stressLabel {
    if (_stress <= 20) return 'Low';
    if (_stress <= 45) return 'Moderate';
    if (_stress <= 70) return 'High';
    return 'Critical';
  }

  String get _finalTitle {
    if (_emergencyFund >= 5000 && _score >= 65) {
      return 'Emergency Fund Achieved';
    }
    if (_emergencyFund >= 3000) {
      return 'Good Financial Preparation';
    }
    if (_emergencyFund >= 1500) {
      return 'Decent Start, But More Needed';
    }
    return 'You Were Financially Exposed';
  }

  String get _finalMessage {
    if (_emergencyFund >= 5000 && _score >= 65) {
      return 'Excellent work. You built real protection against unexpected costs in Mauritius and handled emergencies wisely.';
    }
    if (_emergencyFund >= 3000) {
      return 'Good job. You created a helpful safety buffer, though there is still room to strengthen it.';
    }
    if (_emergencyFund >= 1500) {
      return 'You made some progress, but a few emergencies could still cause stress next month.';
    }
    return 'Unexpected costs hit hard because the emergency fund stayed too low. Try again with stronger saving decisions.';
  }

  String get _scoreLabel {
    if (_score >= 70) return 'Excellent';
    if (_score >= 50) return 'Good';
    if (_score >= 30) return 'Fair';
    return 'Low';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: !_started
            ? _buildIntro()
            : _finished
                ? _buildResult()
                : _buildPlayView(),
      ),
    );
  }

  Widget _buildIntro() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                Navigator.of(context).maybePop();
              },
            ),
          ),
          _buildTopBanner(),
          const SizedBox(height: 18),
          _buildStatsStrip(),
          const SizedBox(height: 18),
          _buildInfoCard(
            title: 'Scenario',
            icon: Icons.location_city_rounded,
            child: const Text(
              'You are managing one month of life in Mauritius with Rs 18,000. Unexpected costs may appear, and your goal is to build an emergency fund before those events damage your financial stability.',
              style: TextStyle(height: 1.5, fontSize: 14.5),
            ),
          ),
          const SizedBox(height: 14),
          _buildInfoCard(
            title: 'What you must do',
            icon: Icons.track_changes_rounded,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MiniBullet('Build an emergency fund target of Rs 5,000'),
                _MiniBullet('Handle realistic unexpected expenses'),
                _MiniBullet('Avoid unnecessary financial stress'),
                _MiniBullet('Finish the month stronger than you started'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startSimulation,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF1E40AF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Start Emergency Fund Simulation',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1D4ED8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_rounded,
            color: Colors.white,
            size: 34,
          ),
          SizedBox(height: 16),
          Text(
            'Emergency Fund Builder',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'A savings simulation based on real-life money pressure. Build a financial buffer before transport, health, phone, and utility issues catch you off guard.',
            style: TextStyle(
              color: Color(0xFFDCE7FF),
              height: 1.5,
              fontSize: 14.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsStrip() {
    return Row(
      children: [
        Expanded(
          child: _introStatCard(
            title: 'Best Fund',
            value: 'Rs $_bestFund',
            icon: Icons.savings_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _introStatCard(
            title: 'Best Score',
            value: '$_bestScore',
            icon: Icons.emoji_events_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _introStatCard(
            title: 'Attempts',
            value: '$_attempts',
            icon: Icons.refresh_rounded,
          ),
        ),
      ],
    );
  }

  Widget _introStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1D4ED8)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1D4ED8)),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildPlayView() {
    final scenario = _scenarios[_stepIndex];

    return Column(
      children: [
        _buildLiveHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              children: [
                _buildScenarioTimelineCard(scenario),
                const SizedBox(height: 16),
                ...scenario.decisions.map(_buildDecisionCard),
                if (_feedback != null) ...[
                  const SizedBox(height: 16),
                  _buildOutcomeCard(),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        _stepIndex == _scenarios.length - 1
                            ? 'See Final Result'
                            : 'Continue',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: _backToIntro,
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Emergency Fund Builder',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${_stepIndex + 1}/${_scenarios.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: _buildFundRingCard(),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    _liveMetric(
                      'Cash Left',
                      'Rs $_cashLeft',
                      Icons.account_balance_wallet_rounded,
                    ),
                    const SizedBox(height: 10),
                    _liveMetric(
                      'Preparedness',
                      _preparednessLabel,
                      Icons.shield_outlined,
                    ),
                    const SizedBox(height: 10),
                    _liveMetric(
                      'Stress Level',
                      _stressLabel,
                      Icons.favorite_border_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFundRingCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 110,
            width: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 110,
                  width: 110,
                  child: CircularProgressIndicator(
                    value: _fundProgress,
                    strokeWidth: 10,
                    backgroundColor: Colors.white.withOpacity(0.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Rs $_emergencyFund',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Fund',
                      style: TextStyle(
                        color: Color(0xFFDCE7FF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Target Rs 5,000',
            style: TextStyle(
              color: Color(0xFFDCE7FF),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveMetric(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFFDCE7FF),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioTimelineCard(EmergencyScenario scenario) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: iconAccentBackground(
                    accentColor: const Color(0xFF1D4ED8),
                    isDark: isDark,
                    lightBackground: const Color(0xFFE8F0FF),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  scenario.icon,
                  color: const Color(0xFF1D4ED8),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 2,
                height: 120,
                color: const Color(0xFFE5E7EB),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(
                      scenario.monthDay,
                      const Color(0xFFDBEAFE),
                      const Color(0xFF1D4ED8),
                    ),
                    _chip(
                      scenario.tag,
                      const Color(0xFFEDE9FE),
                      const Color(0xFF6D28D9),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  scenario.title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  scenario.description,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    height: 1.5,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDecisionCard(ChoiceDecision decision) {
    final bool selected = _selectedDecision == decision;
    final bool disabled = _selectedDecision != null || _decisionDisabled(decision);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: disabled ? null : () => _chooseDecision(decision),
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEEF4FF) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? const Color(0xFF1D4ED8)
                  : Colors.grey.shade300,
              width: 1.3,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                height: 24,
                width: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFFF1F5F9),
                ),
                child: Icon(
                  selected ? Icons.check_rounded : Icons.circle_outlined,
                  size: 15,
                  color: selected ? Colors.white : Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      decision.text,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        fontWeight: FontWeight.w700,
                        color: disabled && !selected
                            ? Colors.grey.shade500
                            : const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (decision.fundDelta > 0)
                          _smallPill(
                            '+Rs ${decision.fundDelta} fund',
                            const Color(0xFFDCFCE7),
                            const Color(0xFF166534),
                          ),
                        if (decision.fundDelta < 0)
                          _smallPill(
                            '-Rs ${decision.fundDelta.abs()} fund',
                            const Color(0xFFFEE2E2),
                            const Color(0xFF991B1B),
                          ),
                        if (decision.cashDelta < 0)
                          _smallPill(
                            '-Rs ${decision.cashDelta.abs()} cash',
                            const Color(0xFFFFEDD5),
                            const Color(0xFF9A3412),
                          ),
                        _smallPill(
                          '${decision.scoreDelta >= 0 ? '+' : ''}${decision.scoreDelta} score',
                          const Color(0xFFE0E7FF),
                          const Color(0xFF3730A3),
                        ),
                      ],
                    ),
                    if (_decisionDisabled(decision)) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Not enough money in emergency fund for this option.',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallPill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildOutcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.insights_rounded,
            color: Color(0xFF059669),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _feedback!,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF065F46),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    Future.microtask(() async {
      if (!_xpAwarded && _emergencyFund >= 1500) {
        _xpAwarded = true;
        await XpService.instance.earnXp(
          amount: XpService.scenarioCompletionXp,
          source: 'emergency_fund_builder',
        );
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1D4ED8),
                  Color(0xFF0F172A),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 42,
                ),
                const SizedBox(height: 14),
                Text(
                  _finalTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _finalMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFDCE7FF),
                    fontSize: 14.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                if (_emergencyFund >= 1500)
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
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _resultBox(
                        'Emergency Fund',
                        'Rs $_emergencyFund',
                        Icons.savings_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _resultBox(
                        'Cash Left',
                        'Rs $_cashLeft',
                        Icons.account_balance_wallet_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _resultBox(
                        'Score',
                        '$_score',
                        Icons.emoji_events_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _resultBox(
                        'Stress',
                        _stressLabel,
                        Icons.favorite_border_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _resultBox(
                        'Preparedness',
                        _preparednessLabel,
                        Icons.shield_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _resultBox(
                        'Rating',
                        _scoreLabel,
                        Icons.bar_chart_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startSimulation,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF1D4ED8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Play Again',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _backToIntro,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Back to Intro',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultBox(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1D4ED8)),
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
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
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

class EmergencyScenario {
  final String monthDay;
  final String tag;
  final String title;
  final String description;
  final IconData icon;
  final List<ChoiceDecision> decisions;

  EmergencyScenario({
    required this.monthDay,
    required this.tag,
    required this.title,
    required this.description,
    required this.icon,
    required this.decisions,
  });
}

class ChoiceDecision {
  final String text;
  final int cashDelta;
  final int fundDelta;
  final int scoreDelta;
  final int stressDelta;
  final String feedback;
  final int? requiresFundAmount;

  ChoiceDecision({
    required this.text,
    required this.cashDelta,
    required this.fundDelta,
    required this.scoreDelta,
    required this.stressDelta,
    required this.feedback,
    this.requiresFundAmount,
  });
}

class _MiniBullet extends StatelessWidget {
  final String text;

  const _MiniBullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: Color(0xFF1D4ED8),
            ),
          ),
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