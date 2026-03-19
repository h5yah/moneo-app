import 'package:flutter/material.dart';
import '../services/transaction_service.dart';

class SplitExpensesScreen extends StatefulWidget {
  const SplitExpensesScreen({super.key});

  @override
  State<SplitExpensesScreen> createState() => _SplitExpensesScreenState();
}

class _SplitExpensesScreenState extends State<SplitExpensesScreen> {
      final TransactionService _transactionService = TransactionService();
    String? errorText;

    bool get isExpenseNameValid => expenseNameController.text.trim().isNotEmpty;
    bool get isTotalAmountValid => totalAmount > 0;
    bool get areCustomAmountsValid {
      if (selectedMethod != 1) return true;
      double sum = 0.0;
      for (final c in customControllers) {
        final val = double.tryParse(c.text) ?? 0.0;
        sum += val;
      }
      return (sum - totalAmount).abs() < 0.01 && customControllers.every((c) => c.text.trim().isNotEmpty);
    }

    bool get canLogShare => isExpenseNameValid && isTotalAmountValid && areCustomAmountsValid;
  TextEditingController expenseNameController = TextEditingController();
  TextEditingController totalAmountController = TextEditingController();
  double get totalAmount => double.tryParse(totalAmountController.text) ?? 0.0;
  int peopleCount = 3;
  int minPeople = 2;
  int maxPeople = 20;
  int selectedMethod = 0; // 0: Split Equally, 1: Custom Equally

  // Controllers for custom split amounts
  List<TextEditingController> customControllers = [];

  @override
  void initState() {
    super.initState();
    _initCustomControllers();
      // Start with empty fields
      expenseNameController.text = '';
      totalAmountController.text = '';
  }

  void _initCustomControllers() {
    customControllers = List.generate(peopleCount, (index) => TextEditingController());
  }

  void _updateCustomControllers() {
    if (customControllers.length < peopleCount) {
      // Add controllers if peopleCount increased
      customControllers.addAll(List.generate(peopleCount - customControllers.length, (index) => TextEditingController()));
    } else if (customControllers.length > peopleCount) {
      // Remove controllers if peopleCount decreased
      customControllers = customControllers.sublist(0, peopleCount);
    }
  }

  @override
  void dispose() {
    for (final c in customControllers) {
      c.dispose();
    }
      expenseNameController.dispose();
      totalAmountController.dispose();
      super.dispose();
  }

  double get share => totalAmount / peopleCount;

  @override
  Widget build(BuildContext context) {
        errorText = null;
        if (!isExpenseNameValid) {
          errorText = 'Please enter an expense name.';
        } else if (!isTotalAmountValid) {
          errorText = 'Please enter a valid total amount.';
        } else if (selectedMethod == 1) {
          double sum = 0.0;
          for (final c in customControllers) {
            final val = double.tryParse(c.text) ?? 0.0;
            sum += val;
          }
          if (customControllers.any((c) => c.text.trim().isEmpty)) {
            errorText = 'Please enter all custom amounts.';
          } else if ((sum - totalAmount).abs() >= 0.01) {
            errorText = 'Custom amounts must sum to total.';
          }
        }
    // Keep controllers in sync with peopleCount
    _updateCustomControllers();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Split Expense', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 28)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              _sectionLabel('EXPENSE NAME'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: expenseNameController,
                  decoration: InputDecoration(
                    hintText: 'Enter expense name',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 32),
              _sectionLabel('TOTAL AMOUNT'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Rs', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: totalAmountController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: 'Enter amount',
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _sectionLabel('NUMBER OF PEOPLE'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _circleButton(Icons.remove, () {
                    setState(() {
                      if (peopleCount > minPeople) peopleCount--;
                    });
                  }),
                  const SizedBox(width: 32),
                  Column(
                    children: [
                      Text('$peopleCount', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Including you', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(width: 32),
                  _circleButton(Icons.add, () {
                    setState(() {
                      if (peopleCount < maxPeople) peopleCount++;
                    });
                  }),
                ],
              ),
              const SizedBox(height: 32),
              _sectionLabel('SPLIT METHOD'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _splitMethodButton(
                    selected: selectedMethod == 0,
                    icon: Icons.balance,
                    label: 'Split Equally',
                    onTap: () => setState(() => selectedMethod = 0),
                  ),
                  const SizedBox(width: 16),
                  _splitMethodButton(
                    selected: selectedMethod == 1,
                    icon: Icons.edit,
                    label: 'Custom Split',
                    onTap: () => setState(() => selectedMethod = 1),
                  ),
                ],
              ),
              if (selectedMethod == 1) ...[
                const SizedBox(height: 32),
                _sectionLabel('ENTER AMOUNT FOR EACH PERSON'),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: peopleCount,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Color(0xFF0A2240),
                              child: Text(
                                String.fromCharCode(65 + index),
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (index == 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('You', style: TextStyle(color: Color(0xFF0A2240), fontWeight: FontWeight.w600, fontSize: 13)),
                              ),
                            ],
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: customControllers[index],
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  hintText: 'Enter amount',
                                  border: InputBorder.none,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('Rs', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Share', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                  Text(
                    selectedMethod == 1
                      ? 'Rs ${(customControllers.isNotEmpty && customControllers[0].text.isNotEmpty)
                          ? (double.tryParse(customControllers[0].text)?.toStringAsFixed(2) ?? '0.00')
                          : '0.00'}'
                      : 'Rs ${share.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This amount can be logged as an expense in your monthly budget.',
                        style: TextStyle(fontSize: 15, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (errorText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        errorText!,
                        style: TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                      if (selectedMethod == 1 && isTotalAmountValid) ...[
                        Builder(
                          builder: (context) {
                            double sum = 0.0;
                            for (final c in customControllers) {
                              sum += double.tryParse(c.text) ?? 0.0;
                            }
                            double diff = sum - totalAmount;
                            if (diff.abs() >= 0.01) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Difference: Rs ${diff.abs().toStringAsFixed(2)} ${diff > 0 ? "+" : "-"}',
                                  style: TextStyle(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              );
                            }
                            return SizedBox.shrink();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canLogShare
                      ? () async {
                          double myShare = selectedMethod == 1
                              ? (customControllers.isNotEmpty && customControllers[0].text.isNotEmpty)
                                  ? double.tryParse(customControllers[0].text) ?? 0.0
                                  : 0.0
                              : share;
                          bool confirmed = false;
                          await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Confirm Log'),
                              content: Text('Your share to log is Rs ${myShare.toStringAsFixed(2)}.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    confirmed = true;
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('Log'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed) {
                            await _transactionService.logExpense(
                              expenseName: expenseNameController.text.trim(),
                              totalAmount: totalAmount,
                              peopleCount: peopleCount,
                              splitMethod: selectedMethod,
                              myShare: myShare,
                              date: DateTime.now(),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Your share has been logged!')),
                            );
                            Navigator.of(context).pop(); // Go back after logging
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0A2240),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Log My Share', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                      const SizedBox(width: 12),
                      Icon(Icons.arrow_forward, size: 22, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 15,
        color: Colors.grey[600],
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 28, color: Colors.black),
      ),
    );
  }

  Widget _splitMethodButton({required bool selected, required IconData icon, required String label, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: selected ? Color(0xFF0A2240) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? Color(0xFF0A2240) : Colors.grey.shade300, width: 2),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? Colors.white : Color(0xFF0A2240), size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Color(0xFF0A2240),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
