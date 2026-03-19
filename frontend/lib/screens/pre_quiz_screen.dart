import 'package:flutter/material.dart';
import 'package:fintech/screens/quiz_completion_screen.dart';

class PreQuizScreen extends StatefulWidget {
  const PreQuizScreen({super.key});

  @override
  _PreQuizScreenState createState() => _PreQuizScreenState();
}

class _PreQuizScreenState extends State<PreQuizScreen> {
  final List<Map<String, dynamic>> questions = [
    {
      'question': "If you have Rs 1,000 and the price of a loaf of bread goes up, what happens to your money's value?",
      'options': [
        'It buys more bread',
        'It buys less bread',
        'It stays the same'
      ],
      'answer': 1
    },
    {
      'question': "What does 'budgeting' help you do?",
      'options': [
        'Spend more than you earn',
        'Track and manage your money',
        'Ignore your expenses'
      ],
      'answer': 1
    },
    {
      'question': "What is the safest place to keep your savings?",
      'options': [
        'Under your mattress',
        'In a bank account',
        'With a friend'
      ],
      'answer': 1
    },
    {
      'question': "If you borrow money, what must you do?",
      'options': [
        'Spend it all',
        'Pay it back',
        'Forget about it'
      ],
      'answer': 1
    },
    {
      'question': "What is an example of a fixed expense?",
      'options': [
        'Movie tickets',
        'Monthly rent',
        'Groceries'
      ],
      'answer': 1
    }
  ];

  int currentQuestion = 0;
  int selectedOption = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          children: [
            Text('STEP ${currentQuestion + 1} OF 5', style: TextStyle(color: Colors.grey, fontSize: 14)),
            SizedBox(height: 4),
            Text('Financial Knowledge Test', style: TextStyle(fontSize: 18, color: Colors.black)),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24),
            LinearProgressIndicator(
              value: (currentQuestion + 1) / questions.length,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 32),
            Text(
              questions[currentQuestion]['question'],
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 32),
            ...List.generate(questions[currentQuestion]['options'].length, (index) {
              return Container(
                margin: EdgeInsets.only(bottom: 16),
                child: Material(
                  color: selectedOption == index ? Colors.blue[50] : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      setState(() {
                        selectedOption = index;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              questions[currentQuestion]['options'][index],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: selectedOption == index ? FontWeight.bold : FontWeight.normal,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedOption == index ? Colors.blue : Colors.grey,
                                width: 2,
                              ),
                              color: selectedOption == index ? Colors.blue : Colors.white,
                            ),
                            child: selectedOption == index
                                ? Icon(Icons.check, color: Colors.white, size: 16)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 18),
                ),
                onPressed: selectedOption != -1
                    ? () {
                        if (currentQuestion < questions.length - 1) {
                          setState(() {
                            currentQuestion++;
                            selectedOption = -1;
                          });
                        } else {
                          // Quiz completed, handle navigation
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => QuizCompletionScreen()),
                          );
                        }
                      }
                    : null,
                child: Text('Next', style: TextStyle(fontSize: 20)),
              ),
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
