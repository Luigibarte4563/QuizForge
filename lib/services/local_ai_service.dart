import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nobodywho/nobodywho.dart' as nobodywho;
import '../main.dart' as main;
import '../models/question.dart';
import '../models/quiz_settings.dart';

class LocalAiService {
  static final LocalAiService _instance = LocalAiService._();
  factory LocalAiService() => _instance;
  LocalAiService._();

  nobodywho.Chat? _chat;
  bool _isInitialized = false;
  bool _isGenerating = false;

  bool get isInitialized => _isInitialized;
  bool get isGenerating => _isGenerating;

  static const Map<String, Map<String, String>> availableModels = {
    'small': {
      'huggingFace': 'nobodywho/Qwen3-0.6B-GGUF/Qwen3-0.6B-Q4_K_M.gguf',
      'displayName': 'Qwen 3 0.6B (Fast)',
      'sizeLabel': '~500 MB',
    },
    'large': {
      'huggingFace': 'nobodywho/Qwen3-1.7B-GGUF/Qwen3-1.7B-Q4_K_M.gguf',
      'displayName': 'Qwen 3 1.7B (Better)',
      'sizeLabel': '~1 GB',
    },
  };

  String _selectedModelKey = 'large';
  String get selectedModelKey => _selectedModelKey;

  String get currentHuggingFaceModel => availableModels[_selectedModelKey]!['huggingFace']!;
  String get currentModelDisplayName => availableModels[_selectedModelKey]!['displayName']!;
  String get currentModelSizeLabel => availableModels[_selectedModelKey]!['sizeLabel']!;

  void selectModel(String key) {
    if (availableModels.containsKey(key)) {
      _selectedModelKey = key;
    }
  }

  Future<bool> isModelDownloaded() async {
    if (!main.nobodyWhoReady) return false;
    try {
      final cached = nobodywho.getCachedModels();
      for (final entry in cached) {
        final path = entry.$1.toLowerCase();
        if (path.contains('qwen') && path.endsWith('.gguf')) {
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isSpecificModelDownloaded(String modelKey) async {
    if (!main.nobodyWhoReady) return false;
    final modelInfo = availableModels[modelKey];
    if (modelInfo == null) return false;
    try {
      final cached = nobodywho.getCachedModels();
      final hfName = modelInfo['huggingFace']!.toLowerCase();
      for (final entry in cached) {
        if (entry.$1.toLowerCase().contains(hfName.split('/').last.toLowerCase())) {
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getDownloadedModelPath() async {
    if (!main.nobodyWhoReady) return null;
    try {
      final cached = nobodywho.getCachedModels();
      for (final entry in cached) {
        final path = entry.$1.toLowerCase();
        if (path.contains('qwen') && path.endsWith('.gguf')) {
          return entry.$1;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<int> getModelFileSize() async {
    if (!main.nobodyWhoReady) return 0;
    try {
      final cached = nobodywho.getCachedModels();
      for (final entry in cached) {
        final path = entry.$1.toLowerCase();
        if (path.contains('qwen') && path.endsWith('.gguf')) {
          return entry.$2.toInt();
        }
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<DownloadProgress> downloadModel({
    void Function(DownloadProgress)? onProgress,
    String? modelKey,
  }) async {
    if (!main.nobodyWhoReady) {
      throw StateError('AI engine not available on this device. The app will use the offline question generator instead.');
    }

    final key = modelKey ?? _selectedModelKey;
    final hfModel = availableModels[key]!['huggingFace']!;

    onProgress?.call(DownloadProgress(stage: 'Downloading', progressPercent: 0));

    try {
      _chat = await nobodywho.Chat.fromPath(
        modelPath: 'huggingface:$hfModel',
        onDownloadProgress: (downloadedBytes, totalBytes) {
          final percent = totalBytes > 0 ? (downloadedBytes / totalBytes * 100) : 0.0;
          onProgress?.call(DownloadProgress(stage: 'Downloading model', progressPercent: percent));
        },
      );

      _isInitialized = true;
      _selectedModelKey = key;

      final progress = DownloadProgress(stage: 'Complete', progressPercent: 100);
      onProgress?.call(progress);
      return progress;
    } catch (e) {
      debugPrint('Model download failed: $e');
      rethrow;
    }
  }

  Future<bool> initialize() async {
    if (_isInitialized && _chat != null) return true;
    if (!main.nobodyWhoReady) return false;

    try {
      final cachedPath = await getDownloadedModelPath();
      if (cachedPath == null) return false;

      _chat = await nobodywho.Chat.fromPath(modelPath: cachedPath);
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('LocalAiService init failed: $e');
      await dispose();
      return false;
    }
  }

  Future<void> dispose() async {
    _chat = null;
    _isInitialized = false;
  }

  Future<String> generate({
    required String prompt,
    String? systemPrompt,
    int maxTokens = 2048,
    double temperature = 0.7,
    void Function(String)? onToken,
  }) async {
    if (!_isInitialized || _chat == null) {
      throw StateError('LocalAiService not initialized. Call initialize() first.');
    }

    _isGenerating = true;

    try {
      if (systemPrompt != null) {
        await _chat!.resetContext(systemPrompt: systemPrompt, tools: []);
      }

      final sampler = nobodywho.SamplerPresets.temperature(temperature: temperature);
      await _chat!.setSamplerConfig(sampler);

      final buffer = StringBuffer();

      final stream = _chat!.ask(prompt);
      await for (final token in stream) {
        buffer.write(token);
        onToken?.call(token);
      }

      return buffer.toString();
    } finally {
      _isGenerating = false;
    }
  }

  Future<List<Question>> generateQuiz({
    required String content,
    required QuizSettings settings,
    void Function(String)? onProgress,
  }) async {
    onProgress?.call('Loading AI model...');

    if (!_isInitialized || _chat == null) {
      final ok = await initialize();
      if (!ok) throw StateError('Failed to initialize AI model');
    }

    onProgress?.call('Analyzing content...');

    final truncated = content.length > 8000 ? content.substring(0, 8000) : content;

    final typeInstruction = _buildTypeInstruction(settings);

    final prompt = '''Generate a quiz from this learning material. Return ONLY valid JSON, no markdown.

SETTINGS:
- Number of questions: ${settings.questionCount}
- Difficulty: ${settings.difficulty.name}
- Question types: $typeInstruction

RULES:
- Generate EXACTLY ${settings.questionCount} questions
- Each question MUST have a "topic" field (short category name, max 3 words)
- Each question MUST have an "explanation" field that explains ALL options - why the correct answer is correct AND why each incorrect option is wrong
- Make questions clear, educational, and factually correct based ONLY on the material
- Cover DIFFERENT parts of the material
- Avoid repeating the same concept
- Difficulty "${settings.difficulty.name}": ${_difficultyGuide(settings.difficulty)}

RESPOND WITH VALID JSON ONLY. No markdown, no code blocks:
{
  "title": "Quiz Title",
  "questions": [
    {
      "question": "Question text here",
      "options": ["A", "B", "C", "D"],
      "answer": 0,
      "type": 0,
      "topic": "Topic Name",
      "explanation": "Option A is correct because... Option B is wrong because... Option C is wrong because... Option D is wrong because..."
    }
  ]
}

LEARNING MATERIAL:
$truncated''';

    onProgress?.call('Generating questions with AI...');

    final response = await generate(
      prompt: prompt,
      systemPrompt: 'You are an expert quiz generator. You create educational quizzes from learning materials. Always respond with valid JSON only.',
      maxTokens: 4096,
      temperature: 0.7,
      onToken: (_) {
        onProgress?.call('AI is generating questions...');
      },
    );

    onProgress?.call('Parsing questions...');

    return _parseQuizResponse(response);
  }

  Future<String> generateExplanation({
    required String question,
    required String correctAnswer,
    required String sourceContext,
    void Function(String)? onProgress,
  }) async {
    if (!_isInitialized || _chat == null) {
      final ok = await initialize();
      if (!ok) return 'The correct answer is: $correctAnswer';
    }

    onProgress?.call('Generating explanation...');

    final truncatedSource = sourceContext.length > 3000 ? sourceContext.substring(0, 3000) : sourceContext;

    final prompt = '''Explain why this answer is correct based on the source material.

Question: $question
Correct Answer: $correctAnswer

Source Material:
$truncatedSource

Provide a clear, educational explanation in 2-4 sentences. Reference the source material when possible. Do NOT use JSON formatting.''';

    final response = await generate(
      prompt: prompt,
      systemPrompt: 'You are a helpful tutor. Explain answers clearly and concisely, referencing the source material.',
      maxTokens: 512,
      temperature: 0.5,
    );

    return response.trim().isNotEmpty ? response.trim() : 'The correct answer is: $correctAnswer';
  }

  Future<List<Map<String, String>>> generateFlashcards({
    required String content,
    void Function(String)? onProgress,
  }) async {
    if (!_isInitialized || _chat == null) {
      final ok = await initialize();
      if (!ok) return [];
    }

    onProgress?.call('Generating flashcards...');

    final truncated = content.length > 6000 ? content.substring(0, 6000) : content;

    final prompt = '''Generate flashcards from this learning material. Return ONLY valid JSON, no markdown.

RULES:
- Create flashcards for the MOST IMPORTANT concepts, definitions, and key facts
- Number of flashcards should be based on material size: small ~5, medium ~10-15, large ~20-30
- Each card should test ONE concept
- Front: concise question or term
- Back: clear, complete answer or definition
- Make cards educational and factually correct based ONLY on the material

RESPOND WITH VALID JSON ONLY. No markdown, no code blocks:
{
  "flashcards": [
    {
      "front": "What is a primary key?",
      "back": "A primary key uniquely identifies each record in a database table."
    }
  ]
}

LEARNING MATERIAL:
$truncated''';

    final response = await generate(
      prompt: prompt,
      systemPrompt: 'You are an expert educator. Create clear, concise flashcards that test understanding of key concepts.',
      maxTokens: 4096,
      temperature: 0.7,
      onToken: (_) {
        onProgress?.call('AI is generating flashcards...');
      },
    );

    onProgress?.call('Parsing flashcards...');

    return _parseFlashcardResponse(response);
  }

  String _buildTypeInstruction(QuizSettings settings) {
    switch (settings.questionType) {
      case QuestionType.multipleChoice:
        return 'Multiple Choice only (type 0): 4 options, 1 correct, answer is 0-based index';
      case QuestionType.trueFalse:
        return 'True/False only (type 1): options ["True", "False"], answer is 0 or 1';
      case QuestionType.fillInTheBlank:
        return 'Fill in the Blank only (type 2): question has "________", first option is the answer, answer is 0';
      case QuestionType.mixed:
        return 'Mix of all types: Multiple Choice (type 0), True/False (type 1), Fill in the Blank (type 2)';
    }
  }

  String _difficultyGuide(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return 'Use simple recall questions. Ask about definitions, basic facts, and straightforward concepts.';
      case Difficulty.medium:
        return 'Mix recall and application questions. Ask about relationships, comparisons, and cause-effect.';
      case Difficulty.hard:
        return 'Use analysis and synthesis questions. Ask about implications, evaluations, and complex reasoning.';
    }
  }

  List<Question> _parseQuizResponse(String text) {
    var cleaned = text.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    final data = jsonDecode(cleaned) as Map<String, dynamic>;
    final questions = (data['questions'] as List)
        .map((q) => Question.fromMap(q as Map<String, dynamic>))
        .toList();

    return questions;
  }

  List<Map<String, String>> _parseFlashcardResponse(String text) {
    try {
      var cleaned = text.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      } else if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();

      final data = jsonDecode(cleaned) as Map<String, dynamic>;
      final cards = (data['flashcards'] as List)
          .map((c) => {
                'front': (c['front'] ?? '').toString(),
                'back': (c['back'] ?? '').toString(),
              })
          .where((c) => c['front']!.isNotEmpty && c['back']!.isNotEmpty)
          .toList();
      return cards;
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteModel() async {
    await dispose();
  }
}

class DownloadProgress {
  final String stage;
  final double progressPercent;

  DownloadProgress({
    required this.stage,
    required this.progressPercent,
  });

  double get fraction => progressPercent / 100.0;
}
