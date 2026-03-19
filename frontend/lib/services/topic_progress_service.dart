import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TopicProgressService {
  TopicProgressService._();

  static final TopicProgressService instance = TopicProgressService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> isPreQuizCompleted(String topicId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return false;
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('topicProgress')
        .doc(topicId)
        .get();

    return snapshot.data()?['preQuizCompleted'] == true;
  }

  Future<void> savePreQuizResult({
    required String topicId,
    required int score,
    required int totalQuestions,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return;
    }

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('topicProgress')
        .doc(topicId)
        .set({
      'preQuizCompleted': true,
      'preQuizScore': score,
      'preQuizTotal': totalQuestions,
      'preQuizCompletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> savePostQuizResult({
    required String topicId,
    required int score,
    required int totalQuestions,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return;
    }

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('topicProgress')
        .doc(topicId)
        .set({
      'postQuizCompleted': true,
      'postQuizScore': score,
      'postQuizTotal': totalQuestions,
      'postQuizCompletedAt': FieldValue.serverTimestamp(),
      'topicCompleted': true,
      'topicCompletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveLessonsCompleted({
    required String topicId,
    required int lessonsCompleted,
    required int totalLessons,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return;
    }

    final clampedLessons = lessonsCompleted.clamp(0, totalLessons);

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('topicProgress')
        .doc(topicId)
        .set({
      'lessonsCompleted': clampedLessons,
      'totalLessons': totalLessons,
      'allLessonsCompleted': clampedLessons >= totalLessons,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveLessonStepProgress({
    required String topicId,
    required int lessonNumber,
    required int currentStep,
    required int totalSteps,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return;
    }

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('topicProgress')
        .doc(topicId)
        .set({
      'activeLessonNumber': lessonNumber,
      'activeLessonStep': currentStep,
      'activeLessonTotalSteps': totalSteps,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>?> topicProgressStream(String topicId) {
    final uid = _auth.currentUser?.uid;
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

  Future<Map<String, dynamic>?> getTopicProgress(String topicId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return null;
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('topicProgress')
        .doc(topicId)
        .get();

    return snapshot.data();
  }

  Future<bool> clearAllTopicProgress() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return false;
    }

    final collection = _firestore
        .collection('users')
        .doc(uid)
        .collection('topicProgress');

    final snapshot = await collection.get();
    if (snapshot.docs.isEmpty) {
      return true;
    }

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    return true;
  }

  Future<bool> clearTopicProgress(String topicId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return false;
    }

    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('topicProgress')
        .doc(topicId);

    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      return true;
    }

    await docRef.delete();
    return true;
  }
}
