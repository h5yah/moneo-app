import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  CollectionReference<Map<String, dynamic>>? _notificationCollection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications');
  }

  Future<void> _markAllRead(
      CollectionReference<Map<String, dynamic>> collection) async {
    final snapshot = await collection.where('isRead', isEqualTo: false).get();
    for (final doc in snapshot.docs) {
      await doc.reference.update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _markRead(DocumentReference<Map<String, dynamic>> ref) async {
    await ref.update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final dayDiff = today.difference(target).inDays;
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    if (dayDiff == 0) return 'Today, $hh:$mm';
    if (dayDiff == 1) return 'Yesterday, $hh:$mm';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}, $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final collection = _notificationCollection();

    if (collection == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please log in to view notifications.')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1020) : const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => _markAllRead(collection),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: collection.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                'No notifications yet.',
                style: TextStyle(
                  color: isDark ? const Color(0xFFAAB0C6) : const Color(0xFF6B7280),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final title = (data['title'] as String?)?.trim().isNotEmpty == true
                  ? data['title'] as String
                  : 'Notification';
              final body = (data['body'] as String?) ?? '';
              final isRead = data['isRead'] == true;
              final createdAt = data['createdAt'];
              final when = createdAt is Timestamp
                  ? _formatTime(createdAt.toDate())
                  : 'Just now';

              return Material(
                color: isDark
                    ? const Color(0xFF1B1D33)
                    : (isRead ? Colors.white : const Color(0xFFFFF5F5)),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    if (!isRead) {
                      _markRead(doc.reference);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2A2D4A)
                            : (isRead
                                ? const Color(0xFFE7EAF2)
                                : const Color(0xFFFFD9D9)),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: isRead
                                ? (isDark
                                    ? const Color(0xFF4D536A)
                                    : const Color(0xFFCBD5E1))
                                : const Color(0xFFFF3B30),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                      isRead ? FontWeight.w600 : FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF111827),
                                ),
                              ),
                              if (body.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  body,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? const Color(0xFFAAB0C6)
                                        : const Color(0xFF6B7280),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                when,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? const Color(0xFF8F96B2)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
