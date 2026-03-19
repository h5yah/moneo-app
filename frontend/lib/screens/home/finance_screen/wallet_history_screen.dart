import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WalletHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final senderId = 'demo_user'; // Replace with FirebaseAuth.instance.currentUser?.uid if needed
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet History'),
        backgroundColor: const Color(0xFF0D1B2A),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('senderId', isEqualTo: senderId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No wallet history found.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final recipientName = data['recipient'] ?? '';
              final amount = data['amount'] ?? 0;
              return ListTile(
                title: Text('Sent money to $recipientName'),
                trailing: Text('-Rs ${amount.toString()}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                subtitle: Text(data['note'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}
