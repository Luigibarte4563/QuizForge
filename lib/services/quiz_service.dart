import '../models/question.dart';
import '../models/quiz_settings.dart';
import 'local_ai_service.dart';
import 'quiz_generator.dart';

class QuizService {
  static final QuizService _instance = QuizService._();
  factory QuizService() => _instance;
  QuizService._();

  Future<List<Question>> generate({
    required String content,
    int questionCount = 10,
    bool mixedTypes = true,
    QuestionType? preferredType,
    Difficulty? difficulty,
    void Function(String)? onProgress,
  }) async {
    if (await LocalAiService().isModelDownloaded()) {
      try {
        onProgress?.call('Initializing AI model...');
        final initialized = await LocalAiService().initialize();
        if (initialized) {
          onProgress?.call('Generating questions with AI...');
          final questions = await LocalAiService().generateQuiz(
            content: content,
            settings: QuizSettings(
              questionCount: questionCount,
              difficulty: difficulty ?? Difficulty.medium,
              questionType: preferredType ?? QuestionType.multipleChoice,
            ),
            onProgress: onProgress,
          );
          if (questions.isNotEmpty) return questions;
        }
      } catch (e) {
        onProgress?.call('AI unavailable, using offline generator...');
      }
    }

    onProgress?.call('Generating questions offline...');
    return LocalQuizGenerator().generateMixed(
      content: content,
      count: questionCount,
      mixedTypes: mixedTypes,
      preferredType: preferredType,
    );
  }

  Future<List<Map<String, String>>> generateFlashcards({
    required String content,
    void Function(String)? onProgress,
  }) async {
    if (await LocalAiService().isModelDownloaded()) {
      try {
        onProgress?.call('Initializing AI model...');
        final initialized = await LocalAiService().initialize();
        if (initialized) {
          onProgress?.call('Generating flashcards with AI...');
          final cards = await LocalAiService().generateFlashcards(
            content: content,
            onProgress: onProgress,
          );
          if (cards.isNotEmpty) return cards;
        }
      } catch (e) {
        onProgress?.call('AI unavailable, generating offline...');
      }
    }

    onProgress?.call('Generating flashcards offline...');
    return _generateOfflineFlashcards(content);
  }

  List<Map<String, String>> _generateOfflineFlashcards(String content) {
    final sentences = content
        .split(RegExp(r'[.!?\n]+'))
        .map((s) => s.trim())
        .where((s) => s.length > 20)
        .toList();

    final cards = <Map<String, String>>[];
    final usedIndices = <int>{};

    final capPattern = RegExp(r'\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\b');
    final definitionPattern = RegExp(r'(.+?)\s*(?:is|are|means|refers to|defined as)\s+(.+)', caseSensitive: false);

    for (final sentence in sentences) {
      if (cards.length >= 20) break;

      final defMatch = definitionPattern.firstMatch(sentence);
      if (defMatch != null && !usedIndices.contains(sentences.indexOf(sentence))) {
        final term = defMatch.group(1)?.trim() ?? '';
        final definition = defMatch.group(2)?.trim() ?? '';
        if (term.isNotEmpty && definition.isNotEmpty && term.length < 50) {
          cards.add({
            'front': 'What is $term?',
            'back': '$term $definition',
          });
          usedIndices.add(sentences.indexOf(sentence));
        }
      }
    }

    for (final sentence in sentences) {
      if (cards.length >= 20) break;
      final idx = sentences.indexOf(sentence);
      if (usedIndices.contains(idx)) continue;

      final matches = capPattern.allMatches(sentence);
      for (final match in matches) {
        if (cards.length >= 20) break;
        final term = match.group(1) ?? '';
        if (term.isNotEmpty && term.length > 3 && term.length < 40) {
          final shortSentence = sentence.length > 100 ? sentence.substring(0, 100) + '...' : sentence;
          cards.add({
            'front': 'Define: $term',
            'back': shortSentence,
          });
          usedIndices.add(idx);
          break;
        }
      }
    }

    if (cards.isEmpty && sentences.isNotEmpty) {
      for (var i = 0; i < sentences.length && cards.length < 5; i++) {
        final s = sentences[i];
        if (s.length > 30) {
          final words = s.split(RegExp(r'\s+'));
          if (words.length > 3) {
            final key = words[words.length ~/ 2];
            cards.add({
              'front': 'Complete: ${s.replaceAll(key, '______')}',
              'back': s,
            });
          }
        }
      }
    }

    return cards;
  }

  Future<String> generateExplanation({
    required String question,
    required String correctAnswer,
    required String sourceText,
    void Function(String)? onProgress,
  }) async {
    if (await LocalAiService().isModelDownloaded()) {
      try {
        final initialized = await LocalAiService().initialize();
        if (initialized) {
          return await LocalAiService().generateExplanation(
            question: question,
            correctAnswer: correctAnswer,
            sourceContext: sourceText,
            onProgress: onProgress,
          );
        }
      } catch (e) {
        // Fall through to default
      }
    }

    return 'The correct answer is: $correctAnswer';
  }
}
