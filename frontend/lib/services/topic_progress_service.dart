import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:fintech/services/xp_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TopicProgressService {
  TopicProgressService._();

  static final TopicProgressService instance = TopicProgressService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final StreamController<Map<String, Map<String, dynamic>>> _updatesController =
      StreamController<Map<String, Map<String, dynamic>>>.broadcast();

  Stream<Map<String, Map<String, dynamic>>> get progressUpdates =>
      _updatesController.stream;

  String? get _uid => _auth.currentUser?.uid;

  static int lessonsCompletedFrom(Map<String, dynamic>? data, int totalLessons) {
    return ((data?['lessonsCompleted'] as num?)?.toInt() ?? 0)
        .clamp(0, totalLessons);
  }

  static Map<String, Map<String, dynamic>> mapFromQuery(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return {
      for (final doc in snapshot.docs) doc.id: doc.data(),
    };
  }

  Future<bool> isPreQuizCompleted(String topicId) async {
    final data = await getTopicProgress(topicId);
    return data?['preQuizCompleted'] == true;
  }

  Future<void> savePreQuizResult({
    required String topicId,
    required int score,
    required int totalQuestions,
  }) async {
    await _saveTopicProgress(topicId, {
      'preQuizCompleted': true,
      'preQuizScore': score,
      'preQuizTotal': totalQuestions,
      'preQuizCompletedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> savePostQuizResult({
    required String topicId,
    required int score,
    required int totalQuestions,
  }) async {
    await _saveTopicProgress(topicId, {
      'postQuizCompleted': true,
      'postQuizScore': score,
      'postQuizTotal': totalQuestions,
      'postQuizCompletedAt': DateTime.now().toIso8601String(),
      'topicCompleted': true,
      'topicCompletedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> saveLessonsCompleted({
    required String topicId,
    required int lessonsCompleted,
    required int totalLessons,
  }) async {
    final clampedLessons = lessonsCompleted.clamp(0, totalLessons);
    await _saveTopicProgress(topicId, {
      'lessonsCompleted': clampedLessons,
      'totalLessons': totalLessons,
      'allLessonsCompleted': clampedLessons >= totalLessons,
    });
  }

  Future<void> saveLessonStepProgress({
    required String topicId,
    required int lessonNumber,
    required int currentStep,
    required int totalSteps,
  }) async {
    await _saveTopicProgress(topicId, {
      'activeLessonNumber': lessonNumber,
      'activeLessonStep': currentStep,
      'activeLessonTotalSteps': totalSteps,
    });
  }

  Future<Map<String, dynamic>?> getTopicProgress(String topicId) async {
    final all = await loadAllProgress();
    return all[topicId];
  }


  Future<Map<String, Map<String, dynamic>>> loadLocalProgress() async {
    final uid = _uid;
    if (uid == null) return {};
    return _loadLocalAll(uid);
  }

  Future<Map<String, Map<String, dynamic>>> loadAllProgress() async {
    final uid = _uid;
    if (uid == null) return {};

    final local = await _loadLocalAll(uid);
    final remote = await _fetchRemoteAll(uid);
    final merged = _mergeProgressMaps(remote, local);
    return merged;
  }

  Future<Map<String, Map<String, dynamic>>> fetchAllTopicProgressFromServer() async {
    return loadAllProgress();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAllTopicProgressSnapshots() {
    final collection = _progressCollection();
    if (collection == null) {
      return const Stream.empty();
    }
    return collection.snapshots();
  }

  Stream<Map<String, dynamic>?> topicProgressStream(String topicId) {
    final uid = _uid;
    if (uid == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('topicProgress')
        .doc(topicId)
        .snapshots()
        .map((doc) => doc.data());
  }

  Future<bool> clearAllTopicProgress() async {
    final uid = _uid;
    if (uid == null) return false;

    await _clearLocalAll(uid);

    final collection = _firestore
        .collection('users')
        .doc(uid)
        .collection('topicProgress');

    try {
      final snapshot = await collection.get();
      if (snapshot.docs.isEmpty) {
        await _notifyProgressChanged();
        return true;
      }

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      await _notifyProgressChanged();
      return true;
    } on FirebaseException catch (e) {
      debugPrint('clearAllTopicProgress failed: ${e.code} ${e.message}');
      await _notifyProgressChanged();
      return false;
    }
  }

  Future<bool> clearTopicProgress(String topicId) async {
    final uid = _uid;
    if (uid == null) return false;

    final local = await _loadLocalAll(uid);
    local.remove(topicId);
    await _saveLocalAll(uid, local);

    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('topicProgress')
        .doc(topicId);

    try {
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        await docRef.delete();
      }
      await _notifyProgressChanged();
      return true;
    } on FirebaseException catch (e) {
      debugPrint('clearTopicProgress failed: ${e.code} ${e.message}');
      await _notifyProgressChanged();
      return false;
    }
  }

  CollectionReference<Map<String, dynamic>>? _progressCollection() {
    final uid = _uid;
    if (uid == null) return null;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('topicProgress')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snap, _) => snap.data() ?? <String, dynamic>{},
          toFirestore: (data, _) => data,
        );
  }

  Future<void> _saveTopicProgress(
    String topicId,
    Map<String, dynamic> patch,
  ) async {
    final uid = _uid;
    if (uid == null) {
      debugPrint('TopicProgressService: not signed in — progress not saved.');
      return;
    }

    final local = await _loadLocalAll(uid);
    final existing = local[topicId] ?? <String, dynamic>{};
    local[topicId] = {
      ...existing,
      ...patch,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await _saveLocalAll(uid, local);

    try {
      await XpService.instance.ensureUserProfile();
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('topicProgress')
          .doc(topicId)
          .set(
        {
          ...local[topicId]!,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'TopicProgressService: Firestore save failed (${e.code}). '
        'Progress kept on this device. Deploy firestore.rules if needed.',
      );
    }

    await _notifyProgressChanged();
  }

  Future<Map<String, Map<String, dynamic>>> _fetchRemoteAll(String uid) async {
    final collection = _firestore
        .collection('users')
        .doc(uid)
        .collection('topicProgress');

    try {
      final snapshot = await collection.get(const GetOptions(source: Source.server));
      return {
        for (final doc in snapshot.docs) doc.id: doc.data(),
      };
    } on FirebaseException {
      try {
        final snapshot = await collection.get();
        return {
          for (final doc in snapshot.docs) doc.id: doc.data(),
        };
      } on FirebaseException {
        return {};
      }
    }
  }

  Map<String, Map<String, dynamic>> _mergeProgressMaps(
    Map<String, Map<String, dynamic>> remote,
    Map<String, Map<String, dynamic>> local,
  ) {
    final merged = Map<String, Map<String, dynamic>>.from(remote);

    for (final entry in local.entries) {
      final topicId = entry.key;
      final localData = entry.value;
      final remoteData = remote[topicId];

      if (remoteData == null || _isLocalAhead(localData, remoteData)) {
        merged[topicId] = localData;
      }
    }

    return merged;
  }

  bool _isLocalAhead(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    if (local['topicCompleted'] == true && remote['topicCompleted'] != true) {
      return true;
    }
    if (local['allLessonsCompleted'] == true &&
        remote['allLessonsCompleted'] != true) {
      return true;
    }

    final localLessons = (local['lessonsCompleted'] as num?)?.toInt() ?? 0;
    final remoteLessons = (remote['lessonsCompleted'] as num?)?.toInt() ?? 0;
    if (localLessons > remoteLessons) return true;

    if (local['preQuizCompleted'] == true && remote['preQuizCompleted'] != true) {
      return true;
    }
    if (local['postQuizCompleted'] == true && remote['postQuizCompleted'] != true) {
      return true;
    }

    return false;
  }

  String _localStorageKey(String uid) => 'topic_progress_v1_$uid';

  Future<Map<String, Map<String, dynamic>>> _loadLocalAll(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localStorageKey(uid));
    if (raw == null || raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};

      return decoded.map(
        (key, value) => MapEntry(
          key.toString(),
          Map<String, dynamic>.from(value as Map),
        ),
      );
    } catch (e) {
      debugPrint('TopicProgressService: corrupt local cache: $e');
      return {};
    }
  }

  Future<void> _saveLocalAll(
    String uid,
    Map<String, Map<String, dynamic>> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localStorageKey(uid), jsonEncode(data));
  }

  Future<void> _clearLocalAll(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localStorageKey(uid));
  }

  Future<void> _notifyProgressChanged() async {
    final merged = await loadAllProgress();
    if (!_updatesController.isClosed) {
      _updatesController.add(merged);
    }
  }
}
