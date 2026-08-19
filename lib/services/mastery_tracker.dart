import 'dart:math';
import '../models/mastery.dart';
import '../models/question.dart';
import '../models/quiz_settings.dart';
import '../services/quiz_service.dart';
import '../services/storage_service.dart';

class MasteryTracker {
  static final MasteryTracker _instance = MasteryTracker._();
  factory MasteryTracker() => _instance;
  MasteryTracker._();

  static const int questionsPerRound = 10;
  static const int masteryTarget = 100;

  Future<Mastery> createMastery({
    required String title,
    required String sourceText,
    required List<String> concepts,
    String notes = '',
  }) async {
    final mastery = Mastery(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      materialTitle: title,
      sourceText: sourceText,
      concepts: concepts,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await StorageService.saveMastery(mastery);
    return mastery;
  }

  Future<List<Question>> generateQuizForMastery(
    Mastery mastery, {
    void Function(String)? onProgress,
  }) async {
    onProgress?.call('Analyzing material...');
    await Future.delayed(const Duration(milliseconds: 800));

    onProgress?.call('Extracting concepts...');
    await Future.delayed(const Duration(milliseconds: 600));

    onProgress?.call('Generating questions...');

    final questions = await QuizService().generate(
      content: mastery.sourceText,
      questionCount: questionsPerRound,
      mixedTypes: true,
      onProgress: onProgress,
    );

    return questions;
  }

  Mastery updateMasteryAfterQuiz({
    required Mastery mastery,
    required List<Question> questions,
    required Map<int, int> answers,
  }) {
    int correct = 0;
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final userAnswer = answers[i] ?? -1;
      bool isCorrect;

      if (q.type == QuestionType.fillInTheBlank) {
        isCorrect = userAnswer == 0;
      } else {
        isCorrect = userAnswer == q.answer;
      }

      if (isCorrect) correct++;
    }

    final newTotalCorrect = mastery.totalCorrect + correct;
    final newTotalAttempted = mastery.totalAttempted + questions.length;
    final newPercent = min(100.0, (newTotalCorrect / newTotalAttempted) * 100);

    return mastery.copyWith(
      masteryPercent: newPercent,
      totalCorrect: newTotalCorrect,
      totalAttempted: newTotalAttempted,
      updatedAt: DateTime.now(),
    );
  }

  bool checkAllCorrect(List<Question> questions, Map<int, int> answers) {
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final userAnswer = answers[i] ?? -1;
      bool isCorrect;

      if (q.type == QuestionType.fillInTheBlank) {
        isCorrect = userAnswer == 0;
      } else {
        isCorrect = userAnswer == q.answer;
      }

      if (!isCorrect) return false;
    }
    return true;
  }

  int calculateStars(Mastery mastery) {
    if (!mastery.fullyMastered) return 0;
    int stars = 1;

    if (mastery.challenge1Unlocked && mastery.challenge1Score >= 70) {
      stars = 2;
    }
    if (mastery.challenge2Unlocked && mastery.challenge2Score >= 70) {
      stars = 3;
    }

    return stars;
  }

  Mastery processChallengeResult({
    required Mastery mastery,
    required int challengeNumber,
    required double scorePercent,
  }) {
    Mastery updated;

    if (challengeNumber == 1) {
      updated = mastery.copyWith(
        challenge1Unlocked: true,
        challenge1Score: scorePercent.round(),
        updatedAt: DateTime.now(),
      );
    } else {
      updated = mastery.copyWith(
        challenge2Unlocked: true,
        challenge2Score: scorePercent.round(),
        updatedAt: DateTime.now(),
      );
    }

    updated = updated.copyWith(
      stars: calculateStars(updated),
    );

    return updated;
  }

  Future<List<Question>> generateChallengeQuestions(
    Mastery mastery, {
    required int challengeNumber,
    void Function(String)? onProgress,
  }) async {
    onProgress?.call('Generating challenge...');

    final questions = await QuizService().generate(
      content: mastery.sourceText,
      questionCount: questionsPerRound,
      mixedTypes: true,
      onProgress: onProgress,
    );

    return questions;
  }
}
