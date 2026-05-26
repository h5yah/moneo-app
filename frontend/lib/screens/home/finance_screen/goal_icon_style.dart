import 'package:flutter/material.dart';

IconData goalIconFromKey(String? iconKey) {
  switch (iconKey ?? '') {
    case 'account_balance':
      return Icons.account_balance;
    case 'school_outlined':
      return Icons.school_outlined;
    case 'flight_takeoff':
      return Icons.flight_takeoff;
    case 'laptop_mac':
      return Icons.laptop_mac;
    case 'directions_car_outlined':
      return Icons.directions_car_outlined;
    case 'edit_note_rounded':
      return Icons.edit_note_rounded;
    case 'target':
      return Icons.track_changes;
    default:
      return Icons.account_balance;
  }
}

String goalIconKeyFromIcon(IconData icon) {
  if (icon == Icons.account_balance) return 'account_balance';
  if (icon == Icons.school_outlined) return 'school_outlined';
  if (icon == Icons.flight_takeoff) return 'flight_takeoff';
  if (icon == Icons.laptop_mac) return 'laptop_mac';
  if (icon == Icons.directions_car_outlined) return 'directions_car_outlined';
  if (icon == Icons.edit_note_rounded) return 'edit_note_rounded';
  return 'account_balance';
}

class GoalIconAccent {
  const GoalIconAccent(this.background, this.foreground);
  final Color background;
  final Color foreground;
}

GoalIconAccent goalIconAccent(String? iconKey, {required bool isDark}) {
  late final Color lightBg;
  late final Color lightFg;
  switch (iconKey ?? '') {
    case 'account_balance':
      lightBg = const Color(0xFFE8F5E9);
      lightFg = const Color(0xFF2E7D32);
      break;
    case 'school_outlined':
      lightBg = const Color(0xFFF3E5F5);
      lightFg = const Color(0xFF7B1FA2);
      break;
    case 'flight_takeoff':
      lightBg = const Color(0xFFFFECB3);
      lightFg = const Color(0xFFE65100);
      break;
    case 'laptop_mac':
      lightBg = const Color(0xFFE3F2FD);
      lightFg = const Color(0xFF1565C0);
      break;
    case 'directions_car_outlined':
      lightBg = const Color(0xFFFFF8E1);
      lightFg = const Color(0xFFF57F17);
      break;
    case 'edit_note_rounded':
      lightBg = const Color(0xFFECEFF1);
      lightFg = const Color(0xFF455A64);
      break;
    case 'target':
      lightBg = const Color(0xFFE8F5E9);
      lightFg = const Color(0xFF2E7D32);
      break;
    default:
      lightBg = const Color(0xFFE8EAFF);
      lightFg = const Color(0xFF2D4EFF);
      break;
  }
  if (!isDark) return GoalIconAccent(lightBg, lightFg);
  return GoalIconAccent(
    Color.alphaBlend(lightFg.withOpacity(0.28), const Color(0xFF1B1D33)),
    Color.lerp(lightFg, Colors.white, 0.45)!,
  );
}
