import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BudgetPlannerScreen extends StatefulWidget {
  const BudgetPlannerScreen({super.key});

  @override
  State<BudgetPlannerScreen> createState() => _BudgetPlannerScreenState();
}

class _BudgetPlannerScreenState extends State<BudgetPlannerScreen> {

  double _dailyBudget = 0;
  double _spentToday = 0;
  int _selectedDayIndex = 29;

  List<DateTime> get _days {
    final today = DateTime.now();
    return List.generate(
      30,
      (i) => today.subtract(Duration(days: 29 - i)),
    );
  }

  double get _remaining => _dailyBudget - _spentToday;

  double get _progress {
    if (_dailyBudget <= 0) return 0;
    return (_spentToday / _dailyBudget).clamp(0.0, 1.0);
  }

  String _monthName(int month) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return months[month - 1];
  }

  @override
  void initState() {
    super.initState();
    _loadBudgetAndExpenses();
  }

  Future<void> _loadBudgetAndExpenses() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'demo_user';

    final selectedDay = _days[_selectedDayIndex];

    final dayString =
        '${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}';

    /// Load budget
    final budgetDoc =
        await FirebaseFirestore.instance.collection('budgets').doc(userId).get();

    double dailyBudget = 0;

    if (budgetDoc.exists) {
      final data = budgetDoc.data() as Map<String, dynamic>;
      dailyBudget = (data['dailyBudget'] as num?)?.toDouble() ?? 0;
    }

    /// Load expenses
    final expenseQuery = await FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: dayString)
        .get();

    double spentToday = 0;

    for (final doc in expenseQuery.docs) {
      final data = doc.data();
      spentToday += (data['amount'] as num?)?.toDouble() ?? 0;
    }

    if (!mounted) return;

    setState(() {
      _dailyBudget = dailyBudget;
      _spentToday = spentToday;
    });
  }

  Future<void> _showSetBudgetDialog() async {

    final controller = TextEditingController(
      text: _dailyBudget > 0 ? _dailyBudget.toStringAsFixed(0) : '',
    );

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            "Set Daily Budget",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D1B2A),
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: "Rs ",
              hintText: "500",
              filled: true,
              fillColor: const Color(0xFFF5F7FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {

                final value =
                    double.tryParse(controller.text.trim());

                if (value != null && value > 0) {

                  final userId =
                      FirebaseAuth.instance.currentUser?.uid ?? 'demo_user';

                  await FirebaseFirestore.instance
                      .collection('budgets')
                      .doc(userId)
                      .set(
                    {
                      "dailyBudget": value,
                    },
                    SetOptions(merge: true),
                  );

                  setState(() {
                    _dailyBudget = value;
                  });

                  await _loadBudgetAndExpenses();
                }

                if (mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D1B2A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Save",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _changeDay(int index) {
    setState(() {
      _selectedDayIndex = index;
    });

    _loadBudgetAndExpenses();
  }

  @override
  Widget build(BuildContext context) {

    final today = DateTime.now();
    final selectedDay = _days[_selectedDayIndex];

    final isToday =
        selectedDay.year == today.year &&
        selectedDay.month == today.month &&
        selectedDay.day == today.day;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),

        title: const Text(
          "Expenses",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Color(0xFF2C2E4A),
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBudgetAndExpenses,
          )
        ],
      ),

      body: Column(
        children: [

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              IconButton(
                icon: const Icon(Icons.arrow_left),
                onPressed: _selectedDayIndex > 0
                    ? () => _changeDay(_selectedDayIndex - 1)
                    : null,
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Text(
                  isToday
                      ? "Today"
                      : "${selectedDay.day} ${_monthName(selectedDay.month)} ${selectedDay.year}",

                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ),

              IconButton(
                icon: const Icon(Icons.arrow_right),
                onPressed: _selectedDayIndex < _days.length - 1
                    ? () => _changeDay(_selectedDayIndex + 1)
                    : null,
              ),
            ],
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [

                const SizedBox(height: 10),

                Text(
                  _remaining >= 0
                      ? "Rs ${_remaining.toStringAsFixed(0)}"
                      : "-Rs ${_remaining.abs().toStringAsFixed(0)}",

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w900,
                    color: _remaining >= 0
                        ? const Color(0xFF2C2E4A)
                        : const Color(0xFFFF6B4A),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  isToday
                      ? (_remaining >= 0
                          ? "Left to spend today"
                          : "You are over budget")
                      : "Viewing budget for selected day",

                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF8C90A3),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 22),

                Container(
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
                            child: _stat(
                              "Left to spend",
                              "Rs ${_remaining.toStringAsFixed(0)}",
                            ),
                          ),

                          Container(
                            width: 1,
                            height: 48,
                            color: const Color(0xFFE8EAF1),
                          ),

                          Expanded(
                            child: _stat(
                              "Budget",
                              "Rs ${_dailyBudget.toStringAsFixed(0)}",
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      LinearProgressIndicator(
                        value: _progress,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFEAECEF),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _progress >= 1
                              ? const Color(0xFFFF6B4A)
                              : const Color(0xFF6C4DFF),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed: _showSetBudgetDialog,
                    child: const Text("Edit Budget"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF8C90A3),
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF2C2E4A),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}