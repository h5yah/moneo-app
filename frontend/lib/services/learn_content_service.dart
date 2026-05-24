import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'package:fintech/screens/home/learn_screen/quiz_screen.dart';

class LearnContentService {
  LearnContentService._();

  static final LearnContentService instance = LearnContentService._();

  Map<String, dynamic>? _raw;

  bool get isLoaded => _raw != null;

  Future<void> ensureLoaded() async {
    if (_raw != null) return;
    final jsonString = await rootBundle.loadString('assets/learn_content.json');
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('learn_content.json root must be an object');
    }
    _raw = decoded;
  }

  List<Map<String, dynamic>> _topicLessons(String topicId) {
    final topics = (_raw?['topics'] as Map?)?.cast<String, dynamic>() ?? const {};
    final topic = (topics[topicId] as Map?)?.cast<String, dynamic>() ?? const {};
    final lessons = (topic['lessons'] as List?)?.cast<dynamic>() ?? const [];
    return lessons
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _topicPreQuiz(String topicId) {
    final topics = (_raw?['topics'] as Map?)?.cast<String, dynamic>() ?? const {};
    final topic = (topics[topicId] as Map?)?.cast<String, dynamic>() ?? const {};
    final preQuiz = (topic['preQuiz'] as List?)?.cast<dynamic>() ?? const [];
    return preQuiz
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _topicFinalQuiz(String topicId) {
    final topics = (_raw?['topics'] as Map?)?.cast<String, dynamic>() ?? const {};
    final topic = (topics[topicId] as Map?)?.cast<String, dynamic>() ?? const {};
    final finalQuiz = (topic['finalQuiz'] as List?)?.cast<dynamic>() ?? const [];
    return finalQuiz
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);
  }

  List<LearnLessonData> lessonsForTopic(String topicId) {
    return _topicLessons(topicId)
        .map(
          (m) => LearnLessonData(
            step: (m['step'] as String?)?.trim() ?? '',
            title: (m['title'] as String?)?.trim() ?? '',
            duration: (m['duration'] as String?)?.trim(),
          ),
        )
        .where((l) => l.step.isNotEmpty && l.title.isNotEmpty)
        .toList(growable: false);
  }

  List<QuizQuestion> preQuizQuestionsForTopic(String topicId) {
    return _topicPreQuiz(topicId)
        .map((m) {
          final options = (m['options'] as List?)?.cast<dynamic>() ?? const [];
          return QuizQuestion(
            question: (m['question'] as String?)?.trim() ?? '',
            options: options.map((o) => o.toString()).toList(growable: false),
            correctAnswer: (m['correctAnswer'] as String?)?.trim() ?? '',
            explanation: (m['explanation'] as String?)?.trim(),
          );
        })
        .where((q) => q.question.isNotEmpty && q.options.isNotEmpty && q.correctAnswer.isNotEmpty)
        .toList(growable: false);
  }

  List<QuizQuestion> finalQuizQuestionsForTopic(String topicId) {
    return _topicFinalQuiz(topicId)
        .map((m) {
          final options = (m['options'] as List?)?.cast<dynamic>() ?? const [];
          return QuizQuestion(
            question: (m['question'] as String?)?.trim() ?? '',
            options: options.map((o) => o.toString()).toList(growable: false),
            correctAnswer: (m['correctAnswer'] as String?)?.trim() ?? '',
            explanation: (m['explanation'] as String?)?.trim(),
          );
        })
        .where((q) => q.question.isNotEmpty && q.options.isNotEmpty && q.correctAnswer.isNotEmpty)
        .toList(growable: false);
  }

  static const Set<String> _aiStopwords = {
    'the', 'and', 'for', 'are', 'but', 'not', 'you', 'all', 'can', 'had', 'her',
    'was', 'one', 'our', 'out', 'day', 'get', 'has', 'him', 'his', 'how', 'its',
    'may', 'new', 'now', 'old', 'see', 'two', 'way', 'who', 'did', 'let', 'put',
    'say', 'she', 'too', 'use', 'any', 'why', 'what', 'when', 'where', 'which',
    'with', 'this', 'that', 'from', 'they', 'have', 'been', 'were', 'each',
    'will', 'just', 'into', 'your', 'more', 'also', 'does', 'like',
    'about', 'some', 'could', 'would', 'should', 'there', 'their', 'them',
    'then', 'than', 'very', 'much', 'such', 'here', 'help', 'tell', 'want',
    'know', 'need', 'good', 'best', 'explain', 'difference', 'between',
  };

  static final RegExp _wordRe = RegExp(r'[a-z0-9]+', caseSensitive: false);

  static Set<String> _tokens(String text) {
    final out = <String>{};
    for (final m in _wordRe.allMatches(text.toLowerCase())) {
      final w = m.group(0)!;
      if (w.length <= 2 || _aiStopwords.contains(w)) continue;
      out.add(w);
    }
    return out;
  }

  static String _humanizeTopicId(String topicId) {
    return topicId
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  /// Text from [learn_content.json] (lesson titles + pre-quiz excerpts) for
  /// one topic, used to ground Ask Miro when the user question seems on-curriculum.
  String _topicAiContextText(String topicId, Map<String, dynamic> topic) {
    final buf = StringBuffer();
    buf.writeln('Unit: ${_humanizeTopicId(topicId)}');
    final lessons = (topic['lessons'] as List?) ?? const [];
    if (lessons.isNotEmpty) {
      buf.writeln('Lessons:');
      for (final l in lessons) {
        if (l is Map<String, dynamic>) {
          final step = (l['step'] as String?)?.trim() ?? '';
          final title = (l['title'] as String?)?.trim() ?? '';
          if (title.isNotEmpty) {
            buf.writeln('- ${step.isEmpty ? title : '$step: $title'}');
          }
        }
      }
    }
    for (final label in ['Review quiz excerpts', 'Final quiz excerpts']) {
      final key = label.startsWith('Review') ? 'preQuiz' : 'finalQuiz';
      final questions = (topic[key] as List?) ?? const [];
      if (questions.isEmpty) continue;
      buf.writeln('$label:');
      for (final q in questions) {
        if (q is Map<String, dynamic>) {
          final question = (q['question'] as String?)?.trim() ?? '';
          final answer = (q['correctAnswer'] as String?)?.trim() ?? '';
          final expl = (q['explanation'] as String?)?.trim() ?? '';
          if (question.isNotEmpty) buf.writeln('Q: $question');
          if (answer.isNotEmpty) buf.writeln('Answer: $answer');
          if (expl.isNotEmpty) buf.writeln('Note: $expl');
          buf.writeln();
        }
      }
    }
    return buf.toString().trim();
  }

  /// When the user's question overlaps meaningfully with one topic in
  /// [learn_content.json], returns a capped excerpt the server can pass to the
  /// model. For unrelated questions, returns `null` so the AI answers normally.
  Future<String?> contextExcerptForAiQuestion(String question) async {
    await ensureLoaded();
    final qTokens = _tokens(question);
    if (qTokens.isEmpty) return null;

    final topics =
        (_raw?['topics'] as Map?)?.cast<String, dynamic>() ?? const {};
    if (topics.isEmpty) return null;

    String? bestId;
    int bestOverlap = 0;

    for (final e in topics.entries) {
      final id = e.key;
      final topic = (e.value as Map?)?.cast<String, dynamic>();
      if (topic == null) continue;
      final blob = _topicAiContextText(id, topic);
      if (blob.isEmpty) continue;
      final bTokens = _tokens(blob);
      if (bTokens.isEmpty) continue;
      var overlap = 0;
      for (final t in qTokens) {
        if (bTokens.contains(t)) overlap++;
      }
      if (overlap > bestOverlap) {
        bestOverlap = overlap;
        bestId = id;
      }
    }

    // Require a clear signal; avoids attaching curriculum to "hello" or vague chit-chat.
    final minOverlap = qTokens.length == 1
        ? 1
        : (qTokens.length <= 4 ? 2 : 3);
    if (bestId == null || bestOverlap < minOverlap) return null;

    final topic = (topics[bestId] as Map?)?.cast<String, dynamic>();
    if (topic == null) return null;
    final excerpt = _topicAiContextText(bestId, topic);
    const maxLen = 7000;
    if (excerpt.length <= maxLen) return excerpt;
    return '${excerpt.substring(0, maxLen)}\n…';
  }
}

class LearnLessonData {
  final String step;
  final String title;
  final String? duration;

  const LearnLessonData({
    required this.step,
    required this.title,
    this.duration,
  });
}

