import 'package:flutter/material.dart';
import 'package:fintech/screens/home/home_screen/home_screen.dart';

class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  int selectedGoal = 1;

  late final List<Map<String, dynamic>> goals;

  @override
  void initState() {
    super.initState();
    goals = [
      {
        'icon': Icons.shield,
        'title': 'Emergency Fund',
        'subtitle': 'Security',
        'color': Colors.blue[100],
        'iconColor': Colors.blue,
      },
      {
        'icon': Icons.directions_car,
        'title': 'Buy a Car',
        'subtitle': 'Transport',
        'color': Colors.blue[900],
        'iconColor': Colors.white,
      },
      {
        'icon': Icons.school,
        'title': 'Save for University',
        'subtitle': 'Studies',
        'color': Colors.blue[100],
        'iconColor': Colors.blue,
      },
      {
        'icon': Icons.account_balance_wallet,
        'title': 'Control Spending',
        'subtitle': 'Habit',
        'color': Colors.green[100],
        'iconColor': Colors.green,
      },
      {
        'icon': Icons.lightbulb,
        'title': 'Other',
        'subtitle': 'Custom Goal',
        'color': Color(0xFF7C4DFF), // Deep purple accent
        'iconColor': Colors.white,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            Text(
              'Set your first financial goal',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2341),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'This will help us personalize your learning path.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: 32),
            ...List.generate(goals.length, (index) {
              final goal = goals[index];
              final isSelected = selectedGoal == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedGoal = index;
                  });
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CustomizeGoalScreen(
                        goal: goals[index],
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? Color(0xFF1A2341) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? Color(0xFF1A2341) : Colors.grey[200]!,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        margin: EdgeInsets.all(16),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: goal['color'],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          goal['icon'],
                          color: goal['iconColor'],
                          size: 28,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal['title'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Color(0xFF1A2341),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              goal['subtitle'],
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected ? Colors.white70 : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          margin: EdgeInsets.only(right: 16),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Color(0xFF1A2341),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check, color: Colors.white, size: 18),
                        ),
                    ],
                  ),
                ),
              );
            }),
            Spacer(),
            // Removed "I'll do this later" button as setting a goal is compulsory
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class CustomizeGoalScreen extends StatefulWidget {
  final Map<String, dynamic> goal;
  const CustomizeGoalScreen({super.key, required this.goal});

  @override
  State<CustomizeGoalScreen> createState() => _CustomizeGoalScreenState();
}

class _CustomizeGoalScreenState extends State<CustomizeGoalScreen> {
  late TextEditingController _goalNameController;
  late TextEditingController _targetAmountController;
  late TextEditingController _deadlineController;

  @override
  void initState() {
    super.initState();
    _goalNameController = TextEditingController(text: widget.goal['title']);
    _targetAmountController = TextEditingController(text: '500000');
    _deadlineController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF1A2341)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: ListView(
          children: [
            SizedBox(height: 16),
            Text(
              'Customise your financial goal',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2341),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Set the details for your new milestone.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF1A2341),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.goal['color'],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      widget.goal['icon'],
                      color: widget.goal['iconColor'],
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.goal['title'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.goal['subtitle'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Icon(Icons.check, color: Colors.white, size: 24),
                ],
              ),
            ),
            SizedBox(height: 32),
            Text('GOAL NAME', style: TextStyle(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            TextField(
              controller: _goalNameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                hintText: 'Goal Name',
                hintStyle: TextStyle(color: Colors.grey[400]),
              ),
              style: TextStyle(fontSize: 18, color: Color(0xFF1A2341)),
            ),
            SizedBox(height: 24),
            Text('TARGET AMOUNT (RS)', style: TextStyle(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            TextField(
              controller: _targetAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                prefixText: 'Rs ',
                hintText: 'Target Amount',
                hintStyle: TextStyle(color: Colors.grey[400]),
              ),
              style: TextStyle(fontSize: 18, color: Color(0xFF1A2341)),
            ),
            SizedBox(height: 24),
            Text('DEADLINE', style: TextStyle(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            TextField(
              controller: _deadlineController,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                hintText: 'mm/dd/yyyy',
                hintStyle: TextStyle(color: Colors.grey[400]),
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today, color: Colors.grey[400]),
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      _deadlineController.text = '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
                    }
                  },
                ),
              ),
              style: TextStyle(fontSize: 18, color: Color(0xFF1A2341)),
              readOnly: true,
            ),
            SizedBox(height: 8),
            Text(
              "We'll help you calculate monthly savings needed.",
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1A2341),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 18),
                ),
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(userName: null),
                    ),
                    (route) => false,
                  );
                },
                child: Text('Create My Goal', style: TextStyle(fontSize: 20)),
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
