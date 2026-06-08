import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:fintech/utils/icon_accent_style.dart';

  IconData _iconFromString(String iconName) {
    switch (iconName) {
      case 'account_balance':
        return Icons.account_balance;
      case 'school_outlined':
        return Icons.school_outlined;
      case 'flight_takeoff':
        return Icons.flight_takeoff;
      case 'laptop_mac':
        return Icons.laptop_mac;
      case 'directions_car_outlined':
        return Icons.directions_car_outlined;
      case 'edit_note_rounded':
        return Icons.edit_note_rounded;
      default:
        return Icons.account_balance;
    }
  }

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key, this.openCreateOnLaunch = false});

  final bool openCreateOnLaunch;

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final List<_GoalCategoryOption> _goalCategoryOptions = const [
    _GoalCategoryOption(
      label: 'Emergency Fund',
      subtitle: 'Financial safety',
      description: 'Money set aside for unexpected events like medical bills, repairs, or urgent needs.',
      icon: Icons.account_balance,
    ),
    _GoalCategoryOption(
      label: 'Education',
      subtitle: 'Courses & tuition',
      description: 'Save for school fees, certifications, books, and learning expenses.',
      icon: Icons.school_outlined,
    ),
    _GoalCategoryOption(
      label: 'Travel',
      subtitle: 'Trips & vacations',
      description: 'Set a target for transport, accommodation, and other trip costs.',
      icon: Icons.flight_takeoff,
    ),
    _GoalCategoryOption(
      label: 'Gadgets',
      subtitle: 'Laptop, phone, accessories',
      description: 'Build savings for tech upgrades like laptops, phones, or accessories.',
      icon: Icons.laptop_mac,
    ),
    _GoalCategoryOption(
      label: 'Vehicle',
      subtitle: 'Car or bike savings',
      description: 'Plan for a vehicle deposit, purchase, or related ownership costs.',
      icon: Icons.directions_car_outlined,
    ),
    _GoalCategoryOption(
      label: 'Other',
      subtitle: 'Create your own goal',
      description: 'Choose this if your goal does not fit the listed categories.',
      icon: Icons.edit_note_rounded,
      isOther: true,
    ),
  ];

  final List<_GoalItem> _activeGoals = [
    _GoalItem(
      id: 'goal1',
      icon: Icons.account_balance,
      title: 'Emergency Fund',
      subtitle: 'Must-have safety net',
      date: '30/06/2026',
      current: 6500,
      target: 10000,
      color: const Color(0xFF2D4EFF),
    ),
    _GoalItem(
      id: 'goal2',
      icon: Icons.laptop_mac,
      title: 'New Laptop',
      subtitle: 'Work productivity',
      date: '30/09/2026',
      current: 7200,
      target: 40000,
      color: const Color(0xFF2D4EFF),
    ),
    _GoalItem(
      id: 'goal3',
      icon: Icons.directions_car_outlined,
      title: 'Car Downpayment',
      subtitle: 'Future mobility',
      date: '31/12/2027',
      current: 1500,
      target: 150000,
      color: const Color(0xFF2D4EFF),
    ),
  ];


  String _formatRs(double value) {
    final number = value.round();
    final asString = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < asString.length; i++) {
      final idxFromEnd = asString.length - i;
      buffer.write(asString[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return 'Rs ${buffer.toString()}';
  }

  String _remainingTimeLabel(String dateText) {
    final parsedDate = _parseGoalDate(dateText);
    if (parsedDate == null) return 'No target date';

    final today = DateTime.now();
    final currentDate = DateTime(today.year, today.month, today.day);
    final targetDate =
        DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    final daysLeft = targetDate.difference(currentDate).inDays;
    if (daysLeft <= 0) return 'This month';

    final monthsApprox = daysLeft / 30.44;
    if (monthsApprox < 1) {
      return daysLeft == 1 ? '1 day left' : '$daysLeft days left';
    }

    final roundedMonths = monthsApprox.round();
    if (roundedMonths <= 1) return '1 month remaining';
    return '$roundedMonths months remaining';
  }

  DateTime? _parseGoalDate(String input) {
    final value = input.trim();
    if (value.isEmpty || value.toLowerCase() == 'no date') return null;

    final parts = value.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return DateTime.tryParse(value);
  }

  @override
  void initState() {
    super.initState();
    if (widget.openCreateOnLaunch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showCreateGoalDialog();
      });
    }
  }

  String _iconNameFromIcon(IconData icon) {
    if (icon == Icons.account_balance) return 'account_balance';
    if (icon == Icons.school_outlined) return 'school_outlined';
    if (icon == Icons.flight_takeoff) return 'flight_takeoff';
    if (icon == Icons.laptop_mac) return 'laptop_mac';
    if (icon == Icons.directions_car_outlined) return 'directions_car_outlined';
    if (icon == Icons.edit_note_rounded) return 'edit_note_rounded';
    return 'account_balance';
  }

  Future<void> _showCreateGoalDialog() async {
    final selectedCategory = await Navigator.push<_GoalCategoryOption>(
      context,
      MaterialPageRoute(
        builder: (context) => _GoalCategoryPickerScreen(
          options: _goalCategoryOptions,
        ),
      ),
    );

    if (selectedCategory == null) return;

    final titleController = TextEditingController(
      text: selectedCategory.isOther ? '' : selectedCategory.label,
    );
    final targetController = TextEditingController();
    final dateController = TextEditingController(text: 'No date');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D1D6),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Create Goal',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Set a target and start tracking your progress.',
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
              ),
              const SizedBox(height: 18),
              _styledGoalInput(
                controller: titleController,
                label: 'Goal title',
                icon: Icons.flag_outlined,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 12),
              _styledGoalInput(
                controller: targetController,
                label: 'Target amount',
                icon: Icons.track_changes,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _styledGoalInput(
                controller: dateController,
                label: 'Finish by',
                icon: Icons.calendar_today_outlined,
                keyboardType: TextInputType.datetime,
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    dateController.text =
                        '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                  }
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D4EFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    final title = titleController.text.trim();
                    final target = double.tryParse(targetController.text.trim()) ?? 0;
                    if (title.isEmpty || target <= 0) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid title and target amount')),
                      );
                      return;
                    }

                    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'demo_user';
                    final iconName = _iconNameFromIcon(selectedCategory.icon);
                    final category = selectedCategory.label;
                    final timeRemaining = _remainingTimeLabel(dateController.text.trim());
                    FirebaseFirestore.instance.collection('goals').add({
                      'userId': userId,
                      'icon': iconName,
                      'title': title,
                      'category': category,
                      'current': 0,
                      'target': target,
                      'timeRemaining': timeRemaining,
                      'remaining': timeRemaining,
                      'date': dateController.text.trim().isEmpty ? 'No date' : dateController.text.trim(),
                      'createdAt': DateTime.now().toIso8601String(),
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Create Goal',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF8E8E93))),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _styledGoalInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9EBF2)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF2D4EFF), size: 20),
        ),
      ),
    );
  }
  void _showGoalDetails(_GoalItem goal) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goal.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(goal.subtitle, style: const TextStyle(color: Color(0xFF8E8E93))),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: goal.progress,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFE5E5EA),
                  valueColor: AlwaysStoppedAnimation<Color>(goal.color),
                ),
              ),
              const SizedBox(height: 12),
              Text('Saved: ${_formatRs(goal.current)}'),
              Text('Target: ${_formatRs(goal.target)}'),
              Text('Progress: ${goal.progressPercent}%'),
              const SizedBox(height: 8),
              Text('Date: ${goal.date}'),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    final shouldDelete = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) {
                        return AlertDialog(
                          title: const Text('Delete Goal'),
                          content: Text('Are you sure you want to delete "${goal.title}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext, true),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );

                    if (shouldDelete == true && mounted) {
                      setState(() {
                        _activeGoals.remove(goal);
                      });
                      try {
                        await FirebaseFirestore.instance.collection('goals').doc(goal.id).delete();
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Goal deleted.')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to delete goal: $e')),
                          );
                        }
                      }
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text(
                    'Delete Goal',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF17192B) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Goals',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: _showCreateGoalDialog,
              child: const CircleAvatar(
                backgroundColor: Color(0xFF2D4EFF),
                child: Icon(Icons.add, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: isDark ? const Color(0xFF0F1020) : const Color(0xFFF7F8FA),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('goals')
                    .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? 'demo_user')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No goals yet. Create one!'));
                  }
                  final goals = snapshot.data!.docs;
                  final totalSaved = goals.fold<double>(0, (sum, doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return sum + (data['current'] as num? ?? 0);
                  });
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('TOTAL GOALS', style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
                                const SizedBox(height: 6),
                                Text('${goals.length} Active', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('TOTAL SAVED', style: TextStyle(fontSize: 13, color: Color(0xFF34C759))),
                                const SizedBox(height: 6),
                                Text(_formatRs(totalSaved), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF34C759))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('ACTIVE GOALS', style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      ...goals.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final icon = _iconFromString(data['icon'] ?? 'account_balance');
                        final goal = _GoalItem(
                          id: doc.id,
                          icon: icon,
                          title: data['title'] ?? '',
                          subtitle: data['category'] ?? '',
                          date: data['date'] ?? '',
                          current: (data['current'] as num?)?.toDouble() ?? 0,
                          target: (data['target'] as num?)?.toDouble() ?? 0,
                          color: const Color(0xFF2D4EFF),
                        );
                        return Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: _goalCard(
                            goal: goal,
                            onTap: () => _showGoalDetails(goal),
                            onAdjust: () async {
                              final currentController = TextEditingController(text: goal.current.toStringAsFixed(0));
                              final targetController = TextEditingController(text: goal.target.toStringAsFixed(0));
                              final dateController = TextEditingController(text: goal.date);
                              bool isLoading = false;
                              await showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.white,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                ),
                                builder: (context) {
                                  return StatefulBuilder(
                                    builder: (context, setState) {
                                      return Padding(
                                        padding: EdgeInsets.fromLTRB(
                                          20,
                                          12,
                                          20,
                                          20 + MediaQuery.of(context).viewInsets.bottom,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Center(
                                              child: Container(
                                                width: 44,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFD1D1D6),
                                                  borderRadius: BorderRadius.circular(99),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 18),
                                            Text('Adjust ${goal.title}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                                            const SizedBox(height: 6),
                                            const Text('Update current savings and target amount.', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13)),
                                            const SizedBox(height: 18),
                                            _styledGoalInput(
                                              controller: currentController,
                                              label: 'Current amount',
                                              icon: Icons.savings,
                                              keyboardType: TextInputType.number,
                                            ),
                                            const SizedBox(height: 12),
                                            _styledGoalInput(
                                              controller: targetController,
                                              label: 'Target amount',
                                              icon: Icons.track_changes,
                                              keyboardType: TextInputType.number,
                                            ),
                                            const SizedBox(height: 12),
                                            _styledGoalInput(
                                              controller: dateController,
                                              label: 'Date',
                                              icon: Icons.calendar_today_outlined,
                                              keyboardType: TextInputType.datetime,
                                              readOnly: true,
                                              onTap: () async {
                                                final picked = await showDatePicker(
                                                  context: context,
                                                  initialDate: DateTime.now(),
                                                  firstDate: DateTime(2020),
                                                  lastDate: DateTime(2100),
                                                );
                                                if (picked != null) {
                                                  dateController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                                                }
                                              },
                                            ),
                                            const SizedBox(height: 18),
                                            if (isLoading)
                                              const Center(child: CircularProgressIndicator()),
                                            SizedBox(
                                              width: double.infinity,
                                              height: 50,
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF2D4EFF),
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(14),
                                                  ),
                                                ),
                                                onPressed: isLoading
                                                    ? null
                                                    : () async {
                                                        final newCurrent = double.tryParse(currentController.text.trim()) ?? 0;
                                                        final newTarget = double.tryParse(targetController.text.trim()) ?? 0;
                                                        final newDate = dateController.text.trim().isEmpty ? 'No date' : dateController.text.trim();
                                                        if (newCurrent < 0 || newTarget <= 0) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(content: Text('Please enter valid positive amounts')),
                                                          );
                                                          return;
                                                        }
                                                        setState(() => isLoading = true);
                                                        await FirebaseFirestore.instance.collection('goals').doc(doc.id).update({
                                                          'current': newCurrent,
                                                          'target': newTarget,
                                                          'date': newDate,
                                                          'timeRemaining': _remainingTimeLabel(newDate),
                                                          'remaining': _remainingTimeLabel(newDate),
                                                        });
                                                        setState(() => isLoading = false);
                                                        Navigator.pop(context);
                                                        ScaffoldMessenger.of(this.context).showSnackBar(
                                                          const SnackBar(content: Text('Goal updated successfully!')),
                                                        );
                                                      },
                                                child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Center(
                                              child: TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Cancel', style: TextStyle(color: Color(0xFF8E8E93))),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Center(
                                              child: TextButton(
                                                onPressed: isLoading
                                                    ? null
                                                    : () async {
                                                        setState(() => isLoading = true);
                                                        await FirebaseFirestore.instance.collection('goals').doc(doc.id).delete();
                                                        setState(() => isLoading = false);
                                                        Navigator.pop(context);
                                                        ScaffoldMessenger.of(this.context).showSnackBar(
                                                          const SnackBar(content: Text('Goal deleted.')),
                                                        );
                                                      },
                                                child: const Text('Delete Goal', style: TextStyle(color: Colors.red)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        );
                      }),
                      const SizedBox(height: 32),
                    ],
                  );
                },
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('goals')
                    .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? 'demo_user')
                    .snapshots(),
                builder: (context, completedSnapshot) {
                  if (completedSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!completedSnapshot.hasData || completedSnapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final completedGoals = completedSnapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return (data['current'] as num? ?? 0) >= (data['target'] as num? ?? 0) && (data['target'] as num? ?? 0) > 0;
                  }).toList();
                  if (completedGoals.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('COMPLETED', style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      ...completedGoals.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final icon = _iconFromString(data['icon'] ?? 'account_balance');
                        final title = data['title'] ?? '';
                        final achievedDate = data['date'] ?? '';
                        final current = (data['current'] as num?)?.toDouble() ?? 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: iconAccentBackground(
                                    accentColor: const Color(0xFFB5B5BC),
                                    isDark: isDark,
                                    lightBackground: const Color(0xFFE8E8ED),
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(icon, color: const Color(0xFFB5B5BC), size: 28),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF7D7D84),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Achieved on $achievedDate',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF9B9BA3),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatRs(current),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF7D7D84),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'GOAL MET',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFA7A7AE),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 32),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _goalCard({
    required _GoalItem goal,
    required VoidCallback onTap,
    required VoidCallback onAdjust,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 35,
                  height: 35,
                  decoration: const BoxDecoration(
                    color: Color(0x5CD9D9D9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(goal.icon, color: Colors.black, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          letterSpacing: -0.408,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        goal.subtitle.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0x63000000),
                          letterSpacing: -0.408,
                          height: 1.27,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 26,
                      child: ElevatedButton(
                        onPressed: onAdjust,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFFEAF3FF),
                          foregroundColor: const Color(0xFF007AFF),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: const Size(0, 26),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Adjust',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFD9FF)),
                  ),
                  child: Text(
                    _remainingTimeLabel(goal.date),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0B4C9E),
                      letterSpacing: -0.2,
                      height: 1.2,
                    ),
                  ),
                ),
                Text(
                  '${goal.progressPercent}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007AFF),
                    letterSpacing: -0.408,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 9,
                backgroundColor: const Color(0xFFEBEBEB),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current: ${_formatRs(goal.current)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0x63000000),
                    letterSpacing: -0.408,
                    height: 1.27,
                  ),
                ),
                Text(
                  'Target: ${_formatRs(goal.target)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: -0.408,
                    height: 1.27,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalItem {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  String date;
  final Color color;
  double current;
  double target;

  _GoalItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.current,
    required this.target,
    required this.color,
  });

  double get progress {
    if (target <= 0) return 0;
    final ratio = current / target;
    if (ratio < 0) return 0;
    if (ratio > 1) return 1;
    return ratio;
  }

  int get progressPercent => (progress * 100).round();
}

class _GoalCategoryOption {
  final String label;
  final String subtitle;
  final String description;
  final IconData icon;
  final bool isOther;

  const _GoalCategoryOption({
    required this.label,
    required this.subtitle,
    required this.description,
    required this.icon,
    this.isOther = false,
  });
}

class _GoalCategoryPickerScreen extends StatefulWidget {
  const _GoalCategoryPickerScreen({required this.options});

  final List<_GoalCategoryOption> options;

  @override
  State<_GoalCategoryPickerScreen> createState() => _GoalCategoryPickerScreenState();
}

class _GoalCategoryPickerScreenState extends State<_GoalCategoryPickerScreen> {
  Future<void> _showCategoryInfo(_GoalCategoryOption option) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D1D6),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: iconAccentBackground(
                          accentColor: const Color(0xFF007AFF),
                          isDark: isDark,
                          lightBackground: const Color(0xFFEAF3FF),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(option.icon, color: const Color(0xFF007AFF), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        option.label,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  option.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6E6E73),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.pop(context, option);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D4EFF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Use this category',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pick Category',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pick the category that matches your desired goal or create your own.',
                style: TextStyle(
                  color: Color(0xFF6E6E73),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: widget.options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final option = widget.options[index];
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;

                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _showCategoryInfo(option),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E5EA)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: iconAccentBackground(
                                  accentColor: const Color(0xFF007AFF),
                                  isDark: isDark,
                                  lightBackground: const Color(0xFFEAF3FF),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(option.icon, color: const Color(0xFF007AFF), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option.label,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1C1C1E),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    option.subtitle,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF8E8E93),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFF8E8E93),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
