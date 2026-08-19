enum QuestionType { multipleChoice, trueFalse, fillInTheBlank, mixed }

enum Difficulty { easy, medium, hard }

class QuizSettings {
  final int questionCount;
  final Difficulty difficulty;
  final QuestionType questionType;

  const QuizSettings({
    this.questionCount = 10,
    this.difficulty = Difficulty.medium,
    this.questionType = QuestionType.mixed,
  });

  QuizSettings copyWith({
    int? questionCount,
    Difficulty? difficulty,
    QuestionType? questionType,
  }) {
    return QuizSettings(
      questionCount: questionCount ?? this.questionCount,
      difficulty: difficulty ?? this.difficulty,
      questionType: questionType ?? this.questionType,
    );
  }

  String get difficultyLabel {
    switch (difficulty) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
    }
  }

  String get typeLabel {
    switch (questionType) {
      case QuestionType.multipleChoice:
        return 'Multiple Choice';
      case QuestionType.trueFalse:
        return 'True/False';
      case QuestionType.fillInTheBlank:
        return 'Fill in the Blank';
      case QuestionType.mixed:
        return 'Mixed';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'questionCount': questionCount,
      'difficulty': difficulty.index,
      'questionType': questionType.index,
    };
  }

  factory QuizSettings.fromMap(Map<String, dynamic> map) {
    return QuizSettings(
      questionCount: map['questionCount'] ?? 10,
      difficulty: Difficulty.values[map['difficulty'] ?? 1],
      questionType: QuestionType.values[map['questionType'] ?? 0],
    );
  }
}
