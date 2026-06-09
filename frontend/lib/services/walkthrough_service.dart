import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalkthroughService {
  WalkthroughService._();

  static const appTourId = 'app_tour_v3';

  static String _storageKey(String tourId) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return 'walkthrough_$tourId';
    }
    return 'walkthrough_${tourId}_$uid';
  }

  /// Legacy device-wide key (pre per-account storage).
  static String _legacyStorageKey(String tourId) => 'walkthrough_$tourId';

  static Future<void> reset(String tourId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey(tourId));
    await prefs.remove(_legacyStorageKey(tourId));
  }

  static Future<void> resetAppTour() => reset(appTourId);

  static Future<bool> hasCompleted(String tourId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _storageKey(tourId);
    if (prefs.containsKey(key)) {
      return prefs.getBool(key) ?? false;
    }
    // New account on a device that completed the old global tour must still see it.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      return false;
    }
    return prefs.getBool(_legacyStorageKey(tourId)) ?? false;
  }

  static Future<void> markCompleted(String tourId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageKey(tourId), true);
  }
}
