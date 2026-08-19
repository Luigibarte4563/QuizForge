class TopicResult {
  final String topic;
  final int correct;
  final int total;

  const TopicResult({
    required this.topic,
    required this.correct,
    required this.total,
  });

  double get percentage => total > 0 ? correct / total : 0;

  Map<String, dynamic> toMap() {
    return {
      'topic': topic,
      'correct': correct,
      'total': total,
    };
  }

  factory TopicResult.fromMap(Map<String, dynamic> map) {
    return TopicResult(
      topic: map['topic'] ?? '',
      correct: map['correct'] ?? 0,
      total: map['total'] ?? 0,
    );
  }
}

class QuizResult {
  final String id;
  final String quizId;
  final String quizTitle;
  final int score;
  final int totalQuestions;
  final List<TopicResult> topicResults;
  final DateTime completedAt;
  final int timeTakenSeconds;
  final Map<int, int> answers;

  const QuizResult({
    required this.id,
    required this.quizId,
    required this.quizTitle,
    required this.score,
    required this.totalQuestions,
    required this.topicResults,
    required this.completedAt,
    this.timeTakenSeconds = 0,
    this.answers = const {},
  });

  double get percentage => totalQuestions > 0 ? score / totalQuestions : 0;

  List<TopicResult> get strongTopics =>
      topicResults.where((t) => t.percentage >= 0.7).toList();

  List<TopicResult> get weakTopics =>
      topicResults.where((t) => t.percentage < 0.7).toList();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quizId': quizId,
      'quizTitle': quizTitle,
      'score': score,
      'totalQuestions': totalQuestions,
      'topicResults':
          topicResults.map((t) => t.toMap()).toList(),
      'completedAt': completedAt.toIso8601String(),
      'timeTakenSeconds': timeTakenSeconds,
      'answers': answers.map((k, v) => MapEntry(k.toString(), v)),
    };
  }

  factory QuizResult.fromMap(Map<String, dynamic> map) {
    final rawAnswers = map['answers'] ?? {};
    final parsedAnswers = <int, int>{};
    rawAnswers.forEach((k, v) {
      parsedAnswers[int.parse(k.toString())] = v as int;
    });

    return QuizResult(
      id: map['id'] ?? '',
      quizId: map['quizId'] ?? '',
      quizTitle: map['quizTitle'] ?? '',
      score: map['score'] ?? 0,
      totalQuestions: map['totalQuestions'] ?? 0,
      topicResults: List<TopicResult>.from(
        (map['topicResults'] ?? []).map((t) => TopicResult.fromMap(t)),
      ),
      completedAt: DateTime.parse(
          map['completedAt'] ?? DateTime.now().toIso8601String()),
      timeTakenSeconds: map['timeTakenSeconds'] ?? 0,
      answers: parsedAnswers,
    );
  }
}
