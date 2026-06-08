import 'package:flutter/material.dart';

/// Tinted background for icon chips on cards and lists.
Color iconAccentBackground({
  required Color accentColor,
  required bool isDark,
  Color? lightBackground,
  double darkAlpha = 0.15,
  double lightAlpha = 0.12,
}) {
  if (isDark) {
    return accentColor.withValues(alpha: darkAlpha);
  }
  if (lightBackground != null) {
    return lightBackground;
  }
  return accentColor.withValues(alpha: lightAlpha);
}
