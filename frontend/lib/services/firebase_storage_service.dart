import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageUploadResult {
  const StorageUploadResult({this.url, this.errorMessage});

  final String? url;
  final String? errorMessage;

  bool get isSuccess => url != null && url!.isNotEmpty;
}

/// Firebase Cloud Storage: profile photos, topic certificates, lesson media.
class FirebaseStorageService {
  FirebaseStorageService._();

  static final FirebaseStorageService instance = FirebaseStorageService._();

  FirebaseStorage get _storage {
    final bucket = Firebase.app().options.storageBucket;
    if (bucket == null || bucket.isEmpty) {
      return FirebaseStorage.instance;
    }
    return FirebaseStorage.instanceFor(bucket: bucket);
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Reference _userProfileRef(String uid) =>
      _storage.ref().child('users').child(uid).child('profile.jpg');

  Reference _certificateRef(String uid, String topicId) => _storage
      .ref()
      .child('certificates')
      .child(uid)
      .child('$topicId.json');

  Reference lessonAssetRef(String relativePath) =>
      _storage.ref().child('lesson_assets').child(relativePath);

  static String _contentTypeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  static String? _friendlyStorageError(FirebaseException e) {
    switch (e.code) {
      case 'object-not-found':
        return 'Storage bucket is missing or upload did not complete. '
            'Enable Cloud Storage in Firebase Console and deploy storage.rules.';
      case 'unauthorized':
      case 'permission-denied':
        return 'Storage permission denied. Deploy storage.rules from the backend folder.';
      case 'unauthenticated':
        return 'Please sign in again before uploading.';
      case 'bucket-not-found':
        return 'Firebase Storage is not set up for this project yet.';
      default:
        return e.message ?? e.code;
    }
  }

  Future<StorageUploadResult> uploadProfilePhoto(File file) async {
    final uid = _uid;
    if (uid == null) {
      return const StorageUploadResult(errorMessage: 'Not signed in.');
    }

    try {
      final ref = _userProfileRef(uid);
      final bytes = await file.readAsBytes();
      final metadata = SettableMetadata(
        contentType: _contentTypeForPath(file.path),
      );

      final snapshot = await ref.putData(bytes, metadata);
      final url = await snapshot.ref.getDownloadURL();
      return StorageUploadResult(url: url);
    } on FirebaseException catch (e) {
      debugPrint('[Storage] Profile upload failed: ${e.code} ${e.message}');
      return StorageUploadResult(errorMessage: _friendlyStorageError(e));
    } catch (e) {
      debugPrint('[Storage] Profile upload failed: $e');
      return StorageUploadResult(errorMessage: e.toString());
    }
  }

  Future<String?> uploadTopicCertificate({
    required String topicId,
    required String topicTitle,
    required int score,
    required int totalQuestions,
  }) async {
    final result = await uploadTopicCertificateResult(
      topicId: topicId,
      topicTitle: topicTitle,
      score: score,
      totalQuestions: totalQuestions,
    );
    return result.url;
  }

  Future<StorageUploadResult> uploadTopicCertificateResult({
    required String topicId,
    required String topicTitle,
    required int score,
    required int totalQuestions,
  }) async {
    final uid = _uid;
    if (uid == null) {
      return const StorageUploadResult(errorMessage: 'Not signed in.');
    }

    final payload = jsonEncode({
      'topicId': topicId,
      'topicTitle': topicTitle,
      'score': score,
      'totalQuestions': totalQuestions,
      'completedAt': DateTime.now().toIso8601String(),
      'app': 'Monéo',
    });

    try {
      final ref = _certificateRef(uid, topicId);
      final snapshot = await ref.putString(
        payload,
        format: PutStringFormat.raw,
        metadata: SettableMetadata(contentType: 'application/json'),
      );
      final url = await snapshot.ref.getDownloadURL();
      return StorageUploadResult(url: url);
    } on FirebaseException catch (e) {
      debugPrint('[Storage] Certificate upload failed: ${e.code} ${e.message}');
      return StorageUploadResult(errorMessage: _friendlyStorageError(e));
    } catch (e) {
      debugPrint('[Storage] Certificate upload failed: $e');
      return StorageUploadResult(errorMessage: e.toString());
    }
  }

  Future<String?> getLessonAssetUrl(String relativePath) async {
    try {
      return await lessonAssetRef(relativePath).getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<String?> getProfilePhotoUrl() async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      return await _userProfileRef(uid).getDownloadURL();
    } catch (e) {
      return null;
    }
  }
}
