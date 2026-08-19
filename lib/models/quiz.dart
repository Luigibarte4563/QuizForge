import 'dart:convert';
import 'question.dart';
import 'quiz_settings.dart';

class Quiz {
  final String id;
  final String title;
  final List<Question> questions;
  final QuizSettings settings;
  final String? sourceText;
  final String? masteryId;
  final DateTime createdAt;

  const Quiz({
    required this.id,
    required this.title,
    required this.questions,
    required this.settings,
    this.sourceText,
    this.masteryId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'questions': jsonEncode(questions.map((q) => q.toMap()).toList()),
      'settings': jsonEncode(settings.toMap()),
      'sourceText': sourceText,
      'masteryId': masteryId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Quiz.fromMap(Map<String, dynamic> map) {
    return Quiz(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Untitled Quiz',
      questions: List<Question>.from(
        jsonDecode(map['questions'] ?? '[]').map((q) => Question.fromMap(q)),
      ),
      settings: QuizSettings.fromMap(
          jsonDecode(map['settings'] ?? '{"questionCount":10,"difficulty":1,"questionType":0}')),
      sourceText: map['sourceText'],
      masteryId: map['masteryId'],
      createdAt: DateTime.parse(
          map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
