import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class TopicMeta {
  final String id;
  final String title;
  final int totalLessons;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final Color progressColor;
  final bool enabled;
  final String? prerequisiteTopicId;

  const TopicMeta({
    required this.id,
    required this.title,
    required this.totalLessons,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.progressColor,
    required this.enabled,
    required this.prerequisiteTopicId,
  });
}

class TopicMetaService {
  TopicMetaService._();

  static final TopicMetaService instance = TopicMetaService._();

  bool _loaded = false;
  List<String> _order = const [];
  Map<String, TopicMeta> _byId = const {};

  bool get isLoaded => _loaded;
  List<String> get order => _order;
  Map<String, TopicMeta> get byId => _byId;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final jsonString = await rootBundle.loadString('assets/topic_meta.json');
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('topic_meta.json root must be an object');
    }

    final orderRaw = (decoded['order'] as List?)?.cast<dynamic>() ?? const [];
    _order = orderRaw.map((e) => e.toString()).toList(growable: false);

    final topicsRaw = (decoded['topics'] as Map?)?.cast<String, dynamic>() ?? const {};

    final map = <String, TopicMeta>{};
    for (final entry in topicsRaw.entries) {
      final id = entry.key;
      final m = (entry.value as Map?)?.cast<String, dynamic>() ?? const {};
      map[id] = TopicMeta(
        id: id,
        title: (m['title'] as String?)?.trim() ?? id,
        totalLessons: (m['totalLessons'] as num?)?.toInt() ?? 0,
        icon: _iconFromName((m['iconName'] as String?)?.trim() ?? ''),
        iconColor: _colorFromHex((m['iconColor'] as String?)?.trim() ?? '#000000'),
        iconBgColor: _colorFromHex((m['iconBgColor'] as String?)?.trim() ?? '#000000'),
        progressColor: _colorFromHex((m['progressColor'] as String?)?.trim() ?? '#000000'),
        enabled: m['enabled'] == true,
        prerequisiteTopicId: (m['prerequisiteTopicId'] as String?)?.trim(),
      );
    }

    _byId = Map.unmodifiable(map);
    _loaded = true;
  }

  // NOTE: Icons are a Flutter runtime type. We keep the mapping minimal and
  // driven by JSON values so the app can change icon choices without editing UI code.
  IconData _iconFromName(String name) {
    switch (name) {
      case 'list_alt_outlined':
        return Icons.list_alt_outlined;
      case 'savings_outlined':
        return Icons.savings_outlined;
      case 'credit_card_outlined':
        return Icons.credit_card_outlined;
      case 'tablet_outlined':
        return Icons.tablet_outlined;
      case 'show_chart_outlined':
        return Icons.show_chart_outlined;
      case 'security_outlined':
        return Icons.security_outlined;
      case 'account_balance_outlined':
        return Icons.account_balance_outlined;
      case 'schedule_outlined':
        return Icons.schedule_outlined;
      default:
        return Icons.school_outlined;
    }
  }

  Color _colorFromHex(String hex) {
    var s = hex.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s';
    final value = int.tryParse(s, radix: 16) ?? 0xFF000000;
    return Color(value);
  }
}

