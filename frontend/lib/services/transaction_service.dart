import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionService {
              // Adds funds to the user's available balance in Firestore
              Future<void> addFunds(double amount, {String userId = 'demo_user'}) async {
                final docRef = FirebaseFirestore.instance.collection('balances').doc(userId);
                await FirebaseFirestore.instance.runTransaction((transaction) async {
                  final snapshot = await transaction.get(docRef);
                  final data = snapshot.data() ?? {};
                  final currentBalance = (data['available'] ?? 0).toDouble();
                  final newBalance = currentBalance + amount;
                  transaction.set(docRef, {'available': newBalance}, SetOptions(merge: true));
                });
                // Log the add funds transaction
                await _transactions.add({
                  'expenseName': 'Funds Added',
                  'myShare': amount,
                  'date': DateTime.now().toIso8601String(),
                  'createdAt': FieldValue.serverTimestamp(),
                  'userId': userId,
                  'type': 'add_funds',
                });
              }
            // Calculates average weekly spent for past 4 weeks
            Future<double> getAverageWeeklySpent({String userId = 'demo_user'}) async {
              final now = DateTime.now();
              double total = 0.0;
              int weeks = 4;
              for (int i = 0; i < weeks; i++) {
                final startOfWeek = now.subtract(Duration(days: now.weekday - 1 + i * 7));
                final endOfWeek = startOfWeek.add(const Duration(days: 7));
                final query = await _transactions
                    .where('date', isGreaterThanOrEqualTo: startOfWeek.toIso8601String())
                    .where('date', isLessThan: endOfWeek.toIso8601String())
                    .where('userId', isEqualTo: userId)
                    .get();
                for (var doc in query.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  total += (data['myShare'] ?? 0).toDouble();
                }
              }
              return weeks > 0 ? (total / weeks) : 0.0;
            }
          // Fetches the weekly budget for a user from Firestore
          Future<double> getWeeklyBudget({String userId = 'demo_user'}) async {
            final doc = await FirebaseFirestore.instance.collection('balances').doc(userId).get();
            final data = doc.data() ?? {};
            return (data['weeklyBudget'] ?? 0).toDouble();
          }

          // Sets the weekly budget for a user in Firestore
          Future<void> setWeeklyBudget(double budget, {String userId = 'demo_user'}) async {
            final docRef = FirebaseFirestore.instance.collection('balances').doc(userId);
            await docRef.set({'weeklyBudget': budget}, SetOptions(merge: true));
          }
        // Returns the total spent for the current week (Monday-Sunday)
        Future<double> getSpentThisWeek({String userId = 'demo_user'}) async {
          final now = DateTime.now();
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Monday
          final endOfWeek = startOfWeek.add(const Duration(days: 7));
          final query = await _transactions
              .where('date', isGreaterThanOrEqualTo: startOfWeek.toIso8601String())
              .where('date', isLessThan: endOfWeek.toIso8601String())
              .where('userId', isEqualTo: userId)
              .get();
          double total = 0.0;
          for (var doc in query.docs) {
            final data = doc.data() as Map<String, dynamic>;
            total += (data['myShare'] ?? 0).toDouble();
          }
          return total;
        }
      // Fetches the income, spent, and saved for a user from Firestore
      Future<Map<String, double>> getIncomeSpentSaved({String userId = 'demo_user'}) async {
        final doc = await FirebaseFirestore.instance.collection('balances').doc(userId).get();
        final data = doc.data() ?? {};
        return {
          'income': (data['income'] ?? 0).toDouble(),
          'spent': (data['spent'] ?? 0).toDouble(),
          'saved': (data['saved'] ?? 0).toDouble(),
        };
      }
    // Fetches the available balance for a user from Firestore
    Future<double> getAvailableBalance({String userId = 'demo_user'}) async {
      final doc = await FirebaseFirestore.instance.collection('balances').doc(userId).get();
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('available')) {
        return (doc.data()!['available'] as num).toDouble();
      }
      return 0.0;
    }
  final CollectionReference _transactions = FirebaseFirestore.instance.collection('transactions');

  Future<void> logExpense({
    required String expenseName,
    required double totalAmount,
    required int peopleCount,
    required int splitMethod,
    required double myShare,
    required DateTime date,
  }) async {
    await _transactions.add({
      'expenseName': expenseName,
      'totalAmount': totalAmount,
      'peopleCount': peopleCount,
      'splitMethod': splitMethod,
      'myShare': myShare,
      'date': date.toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getRecentTransactions() {
    return _transactions.orderBy('createdAt', descending: true).limit(10).snapshots();
  }
}
