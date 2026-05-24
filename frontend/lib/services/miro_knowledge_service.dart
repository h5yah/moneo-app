import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:fintech/services/learn_content_service.dart';

/// Builds retrieval context for Ask Miro from app guide, lessons, and quizzes.
class MiroKnowledgeService {
  MiroKnowledgeService._();

  static final MiroKnowledgeService instance = MiroKnowledgeService._();

  static const int _maxContextChars = 14000;
  static const int _maxMatchedLessonChars = 6000;

  Map<String, dynamic>? _appGuide;
  Map<String, dynamic>? _lessons;
  String? _fullAppGuideText;

  static const Set<String> _stopwords = {
    'the', 'and', 'for', 'are', 'but', 'not', 'you', 'all', 'can', 'had', 'her',
    'was', 'one', 'our', 'out', 'day', 'get', 'has', 'him', 'his', 'how', 'its',
    'may', 'new', 'now', 'old', 'see', 'two', 'way', 'who', 'did', 'let', 'put',
    'say', 'she', 'too', 'use', 'any', 'why', 'what', 'when', 'where', 'which',
    'with', 'this', 'that', 'from', 'they', 'have', 'been', 'were', 'each',
    'will', 'just', 'into', 'your', 'more', 'also', 'does', 'like', 'about',
    'some', 'could', 'would', 'should', 'there', 'their', 'them', 'then', 'than',
    'very', 'much', 'such', 'here', 'help', 'tell', 'want', 'know', 'need',
    'good', 'best', 'explain', 'difference', 'between',
  };

  static final RegExp _wordRe = RegExp(r'[a-z0-9]+', caseSensitive: false);

  Future<void> ensureLoaded() async {
    if (_appGuide != null && _lessons != null) return;
    final results = await Future.wait([
      rootBundle.loadString('assets/miro_app_guide.json'),
      rootBundle.loadString('assets/miro_lessons.json'),
    ]);
    _appGuide = jsonDecode(results[0]) as Map<String, dynamic>;
    _lessons = jsonDecode(results[1]) as Map<String, dynamic>;
    _fullAppGuideText = _formatAppGuide(_appGuide!);
    await LearnContentService.instance.ensureLoaded();
  }

  static Set<String> _tokens(String text) {
    final out = <String>{};
    for (final m in _wordRe.allMatches(text.toLowerCase())) {
      final w = m.group(0)!;
      if (w.length <= 2 || _stopwords.contains(w)) continue;
      out.add(w);
    }
    return out;
  }

  static int _overlapScore(Set<String> query, String blob) {
    final b = _tokens(blob);
    if (b.isEmpty) return 0;
    var n = 0;
    for (final t in query) {
      if (b.contains(t)) n++;
    }
    return n;
  }

  static String _cap(String text, int max) {
    if (text.length <= max) return text;
    return '${text.substring(0, max)}\n…';
  }

  String _formatAppGuide(Map<String, dynamic> guide) {
    final buf = StringBuffer();
    final overview = (guide['overview'] as String?)?.trim();
    if (overview != null && overview.isNotEmpty) {
      buf.writeln('=== Monéo app overview ===');
      buf.writeln(overview);
      buf.writeln();
    }
    final sections = (guide['sections'] as List?) ?? const [];
    for (final s in sections) {
      if (s is! Map<String, dynamic>) continue;
      final title = (s['title'] as String?)?.trim() ?? 'Feature';
      final content = (s['content'] as String?)?.trim() ?? '';
      if (content.isEmpty) continue;
      buf.writeln('=== $title ===');
      buf.writeln(content);
      buf.writeln();
    }
    return buf.toString().trim();
  }

  String _lessonToText(Map<String, dynamic> lesson) {
    final buf = StringBuffer();
    final title = (lesson['title'] as String?)?.trim() ?? '';
    final topicId = (lesson['topicId'] as String?)?.trim();
    if (title.isNotEmpty) {
      buf.writeln('Lesson: $title${topicId != null ? ' (topic: $topicId)' : ''}');
    }
    final steps = (lesson['steps'] as List?) ?? const [];
    for (final s in steps) {
      if (s is! Map<String, dynamic>) continue;
      final stepTitle = (s['title'] as String?)?.trim() ?? '';
      final body = (s['body'] as String?)?.trim() ?? '';
      if (stepTitle.isNotEmpty) buf.writeln('## $stepTitle');
      if (body.isNotEmpty) buf.writeln(body);
      final bullets = (s['bullets'] as List?)?.cast<String>() ?? const [];
      for (final b in bullets) {
        if (b.trim().isNotEmpty) buf.writeln('- ${b.trim()}');
      }
      final note = (s['note'] as String?)?.trim() ?? '';
      if (note.isNotEmpty) buf.writeln('Note: $note');
      buf.writeln();
    }
    return buf.toString().trim();
  }

  /// Knowledge bundle: full app guide + matched lessons/quizzes for [question].
  Future<String> buildKnowledgeContext(String question) async {
    await ensureLoaded();
    final qTokens = _tokens(question.trim());
    final parts = <String>[];

    if (_fullAppGuideText != null && _fullAppGuideText!.isNotEmpty) {
      parts.add(_fullAppGuideText!);
    }

    final lessonList = (_lessons?['lessons'] as List?) ?? const [];
    final scoredLessons = <({int score, String text})>[];
    for (final lesson in lessonList) {
      if (lesson is! Map<String, dynamic>) continue;
      final text = _lessonToText(lesson);
      if (text.isEmpty) continue;
      final score = qTokens.isEmpty ? 0 : _overlapScore(qTokens, text);
      scoredLessons.add((score: score, text: text));
    }
    scoredLessons.sort((a, b) => b.score.compareTo(a.score));

    final minLessonOverlap = qTokens.length <= 2 ? 1 : 2;
    var lessonBudget = _maxMatchedLessonChars;
    for (final entry in scoredLessons) {
      if (entry.score < minLessonOverlap) break;
      final chunk = _cap(entry.text, lessonBudget);
      parts.add('=== Lesson content ===\n$chunk');
      lessonBudget -= chunk.length;
      if (lessonBudget <= 800) break;
    }

    final topicExcerpt =
        await LearnContentService.instance.contextExcerptForAiQuestion(question);
    if (topicExcerpt != null && topicExcerpt.isNotEmpty) {
      parts.add('=== Topic quizzes & lesson list ===\n$topicExcerpt');
    }

    var combined = parts.join('\n\n');
    if (combined.length > _maxContextChars) {
      combined = _cap(combined, _maxContextChars);
    }
    return combined;
  }
}
