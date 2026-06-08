import 'package:shared_preferences/shared_preferences.dart';

class WalkthroughService {
  WalkthroughService._();

  static const appTourId = 'app_tour_v3';

  static Future<void> reset(String tourId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('walkthrough_$tourId');
  }

  static Future<void> resetAppTour() => reset(appTourId);

  static Future<bool> hasCompleted(String tourId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('walkthrough_$tourId') ?? false;
  }

  static Future<void> markCompleted(String tourId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('walkthrough_$tourId', true);
  }
}
