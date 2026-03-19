import 'package:flutter/material.dart';

void main() {
  final icons = <String, IconData>{
    'list_alt_outlined': Icons.list_alt_outlined,
    'savings_outlined': Icons.savings_outlined,
    'credit_card_outlined': Icons.credit_card_outlined,
    'tablet_outlined': Icons.tablet_outlined,
    'show_chart_outlined': Icons.show_chart_outlined,
    'security_outlined': Icons.security_outlined,
    'account_balance_outlined': Icons.account_balance_outlined,
    'schedule_outlined': Icons.schedule_outlined,
  };

  for (final e in icons.entries) {
    final icon = e.value;
    // ignore: avoid_print
    print('${e.key}: codePoint=${icon.codePoint} fontFamily=${icon.fontFamily}');
  }
}

