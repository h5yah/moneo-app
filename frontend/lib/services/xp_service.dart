import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Progressive level curve
class XpLevelMeta {
  const XpLevelMeta({
    required this.level,
    required this.totalXp,
    required this.xpIntoLevel,
    required this.xpRequiredForLevel,
    required this.xpToNextLevel,
  });

  final int level;
  final int totalXp;
  final int xpIntoLevel;
  final int xpRequiredForLevel;
  final int xpToNextLevel;

  double get progressInLevel =>
      xpRequiredForLevel <= 0 ? 0 : (xpIntoLevel / xpRequiredForLevel).clamp(0.0, 1.0);
}

class XpEarnResult {
  const XpEarnResult({required this.xp, required this.awarded});

  final int xp;
  final bool awarded;
}

class XpService {
  XpService._();

  static final XpService instance = XpService._();

  static const String spinWinGame = 'spin_win';
  static const String guessWinGame = 'guess_win';
  static const String shakeWinGame = 'shake_win';

  static const int baseXpPerLevel = 500;
  static const int xpIncreasePerLevel = 200;

  static const int lessonCompletionXp = 100;

  static const int scenarioCompletionXp = 100;

  static const int topicCompletionBonusXp = 500;

  static const int postQuizCompletionXp = topicCompletionBonusXp;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  static int xpRequiredForLevel(int level) {
    if (level <= 1) return baseXpPerLevel;
    return baseXpPerLevel + ((level - 1) * xpIncreasePerLevel);
  }

  static XpLevelMeta levelMetaFromTotalXp(int totalXp) {
    var level = 1;
    var remaining = totalXp < 0 ? 0 : totalXp;

    while (true) {
      final required = xpRequiredForLevel(level);
      if (remaining < required) {
        return XpLevelMeta(
          level: level,
          totalXp: totalXp < 0 ? 0 : totalXp,
          xpIntoLevel: remaining,
          xpRequiredForLevel: required,
          xpToNextLevel: required - remaining,
        );
      }
      remaining -= required;
      level += 1;
    }
  }

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
    try {
      final callable = _functions.httpsCallable('getXp');
      final response = await callable.call();
      return _extractXp(response.data);
    } catch (_) {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return 0;
      final snap = await _firestore.collection('users').doc(uid).get();
      return (snap.data()?['xp'] as num?)?.toInt() ?? 0;
    }
  }

  Future<int> earnXp({required int amount, String source = 'unknown'}) async {
    await ensureUserProfile();
    final result = await earnXpOnce(
      amount: amount,
      source: source,
      awardKey: '${source}_${DateTime.now().microsecondsSinceEpoch}',
    );
    return result.xp;
  }

  static String dailyAwardKey(String gameId, [DateTime? when]) {
    final d = when ?? DateTime.now();
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$gameId:${d.year}-$month-$day';
  }

  Future<bool> hasDailyReward(String gameId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final awardRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('xpAwards')
        .doc(dailyAwardKey(gameId));

    final snap = await awardRef.get();
    return snap.exists;
  }

  Future<void> ensureUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore.collection('users').doc(user.uid);
    final snap = await docRef.get();
    if (snap.exists) return;

    final name = user.displayName?.trim() ?? '';
    final parts = name.split(RegExp(r'\s+'));
    await docRef.set({
      'firstName': parts.isNotEmpty ? parts.first : '',
      'lastName': parts.length > 1 ? parts.sublist(1).join(' ') : '',
      'email': user.email ?? '',
      'phone': '',
      'xp': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<XpEarnResult> earnXpOnce({
    required int amount,
    required String source,
    required String awardKey,
  }) async {
    final uid = _currentUidOrThrow();
    final normalizedKey = awardKey.trim();
    if (normalizedKey.isEmpty) {
      throw ArgumentError('awardKey must not be empty.');
    }

    await ensureUserProfile();

    try {
      final viaCallable = await _earnXpOnceViaCallable(
        amount: amount,
        source: source,
        awardKey: normalizedKey,
      );
      if (viaCallable.awarded) {
        return viaCallable;
      }
      return viaCallable;
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'earnXpOnce callable failed (${e.code}), using Firestore: ${e.message}',
      );
    } catch (e) {
      debugPrint('earnXpOnce callable failed, using Firestore: $e');
    }

    try {
      return await _earnXpOnceViaFirestore(
        uid: uid,
        amount: amount,
        source: source,
        awardKey: normalizedKey,
      );
    } catch (e) {
      debugPrint('earnXpOnce Firestore fallback failed: $e');
    }

    final currentXp = await _readXpFromFirestore(uid);
    return XpEarnResult(xp: currentXp, awarded: false);
  }

  Future<XpEarnResult> _earnXpOnceViaCallable({
    required int amount,
    required String source,
    required String awardKey,
  }) async {
    final callable = _functions.httpsCallable('earnXpOnce');
    final response = await callable.call({
      'amount': amount,
      'source': source,
      'awardKey': awardKey,
    });
    final data = response.data;
    if (data is Map) {
      return XpEarnResult(
        xp: (data['xp'] as num?)?.toInt() ?? 0,
        awarded: data['awarded'] == true,
      );
    }
    return XpEarnResult(xp: _extractXp(data), awarded: true);
  }

  Future<int> _readXpFromFirestore(String uid) async {
    try {
      final snap = await _firestore.collection('users').doc(uid).get();
      return (snap.data()?['xp'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<XpEarnResult> _earnXpOnceViaFirestore({
    required String uid,
    required int amount,
    required String source,
    required String awardKey,
  }) async {
    final userRef = _firestore.collection('users').doc(uid);
    final awardRef = userRef.collection('xpAwards').doc(awardKey);

    return _firestore.runTransaction((tx) async {
      final awardSnap = await tx.get(awardRef);
      final userSnap = await tx.get(userRef);

      if (awardSnap.exists) {
        final currentXp = (userSnap.data()?['xp'] as num?)?.toInt() ?? 0;
        return XpEarnResult(xp: currentXp, awarded: false);
      }

      if (!userSnap.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'User profile does not exist.',
        );
      }

      final currentXp = (userSnap.data()?['xp'] as num?)?.toInt() ?? 0;
      final newXp = currentXp + amount;

      tx.set(awardRef, {
        'amount': amount,
        'source': source,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.update(userRef, {
        'xp': newXp,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return XpEarnResult(xp: newXp, awarded: true);
    });
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
