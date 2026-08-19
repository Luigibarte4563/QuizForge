import 'dart:convert';
import 'quiz_settings.dart';

class Question {
  final String question;
  final List<String> options;
  final int answer;
  final String topic;
  final QuestionType type;
  final String? explanation;

  // Matching type fields
  final List<String>? matchingColumnA;
  final List<String>? matchingColumnB;
  final Map<int, int>? correctConnections;

  const Question({
    required this.question,
    required this.options,
    required this.answer,
    required this.topic,
    this.type = QuestionType.multipleChoice,
    this.explanation,
    this.matchingColumnA,
    this.matchingColumnB,
    this.correctConnections,
  });

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'answer': answer,
      'topic': topic,
      'type': type.index,
      'explanation': explanation,
      'matchingColumnA': matchingColumnA,
      'matchingColumnB': matchingColumnB,
      'correctConnections': correctConnections?.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    Map<int, int>? connections;
    if (map['correctConnections'] != null) {
      final raw = Map<String, dynamic>.from(map['correctConnections']);
      connections = raw.map((k, v) => MapEntry(int.parse(k), v as int));
    }

    return Question(
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      answer: map['answer'] ?? 0,
      topic: map['topic'] ?? 'General',
      type: QuestionType.values[map['type'] ?? 0],
      explanation: map['explanation'],
      matchingColumnA: map['matchingColumnA'] != null
          ? List<String>.from(map['matchingColumnA'])
          : null,
      matchingColumnB: map['matchingColumnB'] != null
          ? List<String>.from(map['matchingColumnB'])
          : null,
      correctConnections: connections,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory Question.fromJson(String source) =>
      Question.fromMap(jsonDecode(source));
}
