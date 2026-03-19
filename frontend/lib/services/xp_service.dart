import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class XpService {
  XpService._();

  static final XpService instance = XpService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  Stream<int> xpStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    return _firestore.collection('users').doc(user.uid).snapshots().map((doc) {
      if (!doc.exists) {
        return 0;
      }
      final dynamic xpRaw = doc.data()?['xp'];
      if (xpRaw is num) {
        return xpRaw.toInt();
      }
      return 0;
    });
  }

  Future<int> getXp() async {
    final callable = _functions.httpsCallable('getXp');
    final response = await callable.call();
    return _extractXp(response.data);
  }

  Future<int> earnXp({required int amount, String source = 'unknown'}) async {
    final uid = _currentUidOrThrow();

    try {
      final callable = _functions.httpsCallable('earnXp');
      final response = await callable.call({
        'amount': amount,
        'source': source,
      });
      return _extractXp(response.data);
    } catch (_) {
      return _earnXpViaFirestore(uid: uid, amount: amount, source: source);
    }
  }

  Future<int> spendXp({required int amount, String source = 'unknown'}) async {
    final uid = _currentUidOrThrow();

    try {
      final callable = _functions.httpsCallable('spendXp');
      final response = await callable.call({
        'amount': amount,
        'source': source,
      });
      return _extractXp(response.data);
    } catch (_) {
      return _spendXpViaFirestore(uid: uid, amount: amount, source: source);
    }
  }

  int _extractXp(dynamic data) {
    if (data is Map && data['xp'] is num) {
      return (data['xp'] as num).toInt();
    }
    return 0;
  }

  String _currentUidOrThrow() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User must be logged in.',
      );
    }
    return uid;
  }

  Future<int> _earnXpViaFirestore({
    required String uid,
    required int amount,
    required String source,
  }) async {
    final userRef = _firestore.collection('users').doc(uid);

    return _firestore.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final currentXp = (snap.data()?['xp'] as num?)?.toInt() ?? 0;
      final newXp = currentXp + amount;

      tx.set(userRef, {
        'xp': newXp,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      tx.set(
        userRef.collection('xpTransactions').doc(),
        {
          'type': 'earn',
          'amount': amount,
          'previousXp': currentXp,
          'newXp': newXp,
          'source': source,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      return newXp;
    });
  }

  Future<int> _spendXpViaFirestore({
    required String uid,
    required int amount,
    required String source,
  }) async {
    final userRef = _firestore.collection('users').doc(uid);

    return _firestore.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      if (!snap.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'User profile does not exist.',
        );
      }

      final currentXp = (snap.data()?['xp'] as num?)?.toInt() ?? 0;
      if (currentXp < amount) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'failed-precondition',
          message: 'Not enough XP.',
        );
      }

      final newXp = currentXp - amount;

      tx.update(userRef, {
        'xp': newXp,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.set(
        userRef.collection('xpTransactions').doc(),
        {
          'type': 'spend',
          'amount': amount,
          'previousXp': currentXp,
          'newXp': newXp,
          'source': source,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      return newXp;
    });
  }
}
