import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Persists linked payment card metadata on the user's balance document.
class WalletCardService {
  WalletCardService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> saveCard({
    required String last4,
    required String type,
    String holder = '',
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('not_signed_in');
    }

    await _firestore.collection('balances').doc(uid).set(
      {
        'savedCard': {
          'last4': last4,
          'type': type,
          'holder': holder,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // Legacy path — keep in sync when rules allow.
    try {
      await _firestore.collection('cards').doc(uid).set(
        {
          'last4': last4,
          'type': type,
          'holder': holder,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // balances write is the source of truth
    }
  }

  static Future<Map<String, String>?> loadCard() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final balanceSnap =
        await _firestore.collection('balances').doc(uid).get();
    final fromBalance = _parseCard(balanceSnap.data()?['savedCard']);
    if (fromBalance != null) return fromBalance;

    final cardsSnap = await _firestore.collection('cards').doc(uid).get();
    return _parseCard(cardsSnap.data());
  }

  static Map<String, String>? _parseCard(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final last4 = map['last4']?.toString();
    if (last4 == null || last4.isEmpty) return null;
    return {
      'last4': last4,
      'type': map['type']?.toString() ?? 'debit',
      if (map['holder'] != null) 'holder': map['holder'].toString(),
    };
  }
}
