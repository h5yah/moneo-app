import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'package:fintech/screens/home/learn_screen/quiz_screen.dart';

class LearnContentService {
  LearnContentService._();

  static final LearnContentService instance = LearnContentService._();

  Map<String, dynamic>? _raw;

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

