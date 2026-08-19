# QuizForge v3.0 — Remove API, Add Local AI & Proper File Extraction

## Goal
Remove the OpenRouter API dependency entirely. Replace with:
1. **kreuzberg** for proper file extraction (PDF, DOCX, PPTX, XLSX, OCR)
2. **llm_llamacpp** for on-device LLM inference (quiz generation + explanations)
3. Clean architecture separating file extraction from AI processing

---

## Architecture Overview

```
📱 QUIZFORGE
     │
 Upload File
     ↓
┌──────────────────┐
│ File Extraction   │  ← kreuzberg (proper parsers, OCR)
│ (separate layer)  │
└──────────────────┘
     │
     ↓
 Extracted Text
     ↓
┌──────────────────┐
│ Content Analyzer  │  ← Topic detection, concept extraction
│ (pure Dart)       │
└──────────────────┘
     │
     ↓
 Structured Content
     ↓
┌──────────────────┐
│ Local AI Engine   │  ← llm_llamacpp + GGUF model
│ (separate layer)  │
└──────────────────┘
     │
     ↓
Quiz Questions + Explanations
```

---

## Files to DELETE
- `lib/config/api_config.dart` — API keys no longer needed

## Files to CREATE
- `lib/services/local_ai_service.dart` — LLM initialization, model management, prompt execution
- `lib/services/content_analyzer.dart` — Topic detection, concept extraction from raw text
- `lib/screens/model_download_screen.dart` — First-launch model download UI

## Files to HEAVILY REWRITE
- `lib/services/file_extraction_service.dart` — Replace binary scanning with kreuzberg
- `lib/services/quiz_service.dart` — Remove API calls, use LocalAiService
- `lib/services/quiz_generator.dart` — Enhance as smart fallback when LLM unavailable
- `lib/services/mastery_tracker.dart` — Update to use new QuizService interface
- `lib/screens/material_analysis_screen.dart` — Add model check, extraction pipeline
- `lib/screens/paste_text_screen.dart` — Use new QuizService
- `lib/screens/mastery_detail_screen.dart` — Use new QuizService
- `lib/screens/settings_screen.dart` — Add model info, device capabilities
- `pubspec.yaml` — Replace dependencies

## Files to MINORLY EDIT
- `lib/app.dart` — Add model check on startup
- `lib/screens/home_screen.dart` — Minor: add model status indicator

---

## Detailed Implementation Steps

### Step 1: Update pubspec.yaml

**Remove:**
- `http: ^1.2.2` (no more API calls)
- `csv: ^6.0.0` (kreuzberg handles CSV)

**Add:**
- `kreuzberg: ^3.0.0` (file extraction — PDF, DOCX, PPTX, XLSX, OCR)
- `llm_llamacpp: ^0.4.0` (on-device LLM inference)
- `permission_handler: ^11.0.0` (storage permissions for model download)

**Keep:**
- `file_picker`, `sqflite`, `path`, `path_provider`, `intl`, `cupertino_icons`

### Step 2: Delete api_config.dart

Remove `lib/config/api_config.dart` entirely. No API keys needed.

### Step 3: Create lib/services/local_ai_service.dart

Singleton service managing the local LLM:

```dart
class LocalAiService {
  // Singleton
  static final LocalAiService _instance = LocalAiService._();
  factory LocalAiService() => _instance;
  LocalAiService._();

  // llama.cpp instance
  Llama? _llama;
  bool _isInitialized = false;
  bool _isGenerating = false;

  // Model path management
  String? _modelPath;
  String get defaultModelName => 'qwen2.5-1.5b-instruct-q4_k_m.gguf';
  String get defaultModelUrl => 'https://huggingface.co/...'; // actual GGUF URL

  // Methods:
  Future<void> initialize(String modelPath) async { ... }
  Future<void> dispose() async { ... }
  Future<bool> isModelDownloaded() async { ... }
  Future<String> get modelDirectory async { ... }

  // Core generation
  Future<String> generate({
    required String prompt,
    int maxTokens = 2048,
    double temperature = 0.7,
    void Function(String)? onToken,
  }) async { ... }

  // Convenience methods for QuizForge
  Future<List<Question>> generateQuiz({
    required String content,
    required QuizSettings settings,
    void Function(String)? onProgress,
  }) async { ... }

  Future<String> generateExplanation({
    required String question,
    required String correctAnswer,
    required String sourceContext,
    void Function(String)? onProgress,
  }) async { ... }
}
```

**Key design decisions:**
- Model is downloaded to app's documents directory (`path_provider`)
- Single model at a time (simpler UX)
- Default model: Qwen 2.5 1.5B Q4_K_M (~1GB, runs on most phones)
- Streaming token generation for responsive UI
- Graceful degradation: if model not downloaded, fall back to enhanced LocalQuizGenerator

### Step 4: Create lib/services/content_analyzer.dart

Pure Dart service for content analysis without AI:

```dart
class ContentAnalyzer {
  // Analyze extracted text into structured content
  static AnalyzedContent analyze(String text) { ... }

  // Split text into topic sections
  static List<TopicSection> splitIntoTopics(String text) { ... }

  // Extract key concepts/terms
  static List<String> extractConcepts(String text) { ... }

  // Find relevant context for a specific question
  static String findRelevantContext(String text, String query) { ... }
}

class AnalyzedContent {
  final String title;
  final List<TopicSection> topics;
  final List<String> keyConcepts;
  final int wordCount;
  final String summary; // First 500 chars or auto-generated
}

class TopicSection {
  final String title;
  final String content;
  final List<String> keywords;
}
```

### Step 5: Rewrite lib/services/file_extraction_service.dart

Replace binary scanning with kreuzberg:

```dart
import 'package:kreuzberg/kreuzberg.dart';

class FileExtractionService {
  static Future<ExtractionResult> extractText(File file) async {
    final path = file.path.toLowerCase();

    // kreuzberg handles: PDF, DOCX, PPTX, XLSX, CSV, TXT, HTML, images
    if (isSupportedFormat(path)) {
      final result = await Kreuzberg.extract(file.path);
      return ExtractionResult(
        text: result.text,
        metadata: result.metadata,
      );
    }

    // Fallback for formats kreuzberg doesn't cover
    if (path.endsWith('.json')) {
      return ExtractionResult(text: _extractJson(await file.readAsString()));
    }

    throw UnsupportedError('Unsupported file format: $path');
  }

  static bool isSupportedFormat(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.pdf') ||
        lower.endsWith('.docx') || lower.endsWith('.doc') ||
        lower.endsWith('.pptx') || lower.endsWith('.ppt') ||
        lower.endsWith('.xlsx') || lower.endsWith('.xls') ||
        lower.endsWith('.csv') || lower.endsWith('.txt') ||
        lower.endsWith('.rtf') || lower.endsWith('.html') ||
        lower.endsWith('.jpg') || lower.endsWith('.jpeg') ||
        lower.endsWith('.png') || lower.endsWith('.webp');
  }
}

class ExtractionResult {
  final String text;
  final Map<String, dynamic>? metadata;
}
```

### Step 6: Rewrite lib/services/quiz_service.dart

Remove all API code. Use LocalAiService with LocalQuizGenerator fallback:

```dart
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
    // Try local LLM first
    if (await LocalAiService().isModelDownloaded()) {
      onProgress?.call('Loading AI model...');
      try {
        return await LocalAiService().generateQuiz(
          content: content,
          settings: QuizSettings(
            questionCount: questionCount,
            difficulty: difficulty ?? Difficulty.medium,
            questionType: preferredType ?? QuestionType.multipleChoice,
          ),
          onProgress: onProgress,
        );
      } catch (e) {
        onProgress?.call('AI unavailable, using offline generator...');
      }
    }

    // Fallback to enhanced local generator
    onProgress?.call('Generating questions offline...');
    return LocalQuizGenerator().generateMixed(
      content: content,
      count: questionCount,
      mixedTypes: mixedTypes,
    );
  }

  // Generate explanation for a specific answer
  Future<String> generateExplanation({
    required String question,
    required String correctAnswer,
    required String sourceText,
    void Function(String)? onProgress,
  }) async {
    if (await LocalAiService().isModelDownloaded()) {
      try {
        return await LocalAiService().generateExplanation(
          question: question,
          correctAnswer: correctAnswer,
          sourceContext: sourceText,
          onProgress: onProgress,
        );
      } catch (e) { /* fallback */ }
    }
    return 'The correct answer is: $correctAnswer';
  }
}
```

### Step 7: Enhance lib/services/quiz_generator.dart

Improve the offline generator to produce better questions and explanations:

- Better sentence selection (prioritize definitional sentences: "X is...", "X means...", "X refers to...")
- Generate explanations by extracting the source sentence
- Better topic grouping using TF-IDF-like scoring
- Add difficulty-aware question generation

### Step 8: Create lib/screens/model_download_screen.dart

First-launch screen that appears when no model is downloaded:

```dart
class ModelDownloadScreen extends StatefulWidget {
  // Shows:
  // - Model info (name, size, requirements)
  // - Download progress bar
  // - Device compatibility check
  // - "Skip for now" button (uses offline generator)
}
```

### Step 9: Update lib/app.dart

Add startup model check:
```dart
class QuizForgeApp extends StatefulWidget {
  // In initState:
  // Check if model is downloaded
  // If not, show ModelDownloadScreen as overlay or first route
}
```

### Step 10: Update material_analysis_screen.dart

- Add extraction result type handling (kreuzberg returns ExtractionResult)
- Show proper file type detection
- Add model status indicator during analysis

### Step 11: Update paste_text_screen.dart

- Minor: use updated QuizService interface (pass difficulty/type settings)

### Step 12: Update mastery_detail_screen.dart

- Use updated QuizService (pass settings to generate)

### Step 13: Update mastery_tracker.dart

- Update generateQuizForMastery and generateChallengeQuestions to pass settings

### Step 14: Update settings_screen.dart

- Add "AI Model" section: model name, size, status (downloaded/not), download/delete button
- Add "Device Info" section: RAM, platform
- Update "How it works" to mention local AI model
- Update "Supported Formats" with kreuzberg capabilities
- Update "Privacy" to mention model runs entirely on-device

### Step 15: Update home_screen.dart

- Add small model status indicator (green dot = model ready, gray = using offline mode)

---

## New Dependency Versions (to verify at implementation time)

| Package | Purpose | Est. Version |
|---------|---------|-------------|
| `kreuzberg` | File extraction (97+ formats) | ^3.0.0 |
| `llm_llamacpp` | On-device LLM inference | ^0.4.0 |
| `permission_handler` | Storage permissions | ^11.0.0 |

## Default Model

| Property | Value |
|----------|-------|
| Model | Qwen 2.5 1.5B Instruct |
| Quantization | Q4_K_M |
| File size | ~1 GB |
| RAM needed | ~2 GB |
| Platforms | Android, iOS, macOS, Windows, Linux |

---

## Risk Mitigation

1. **Model too large for device**: Check available RAM before download, offer offline fallback
2. **Slow inference on old devices**: Set timeout, fall back to LocalQuizGenerator after 30s
3. **kreuzberg platform issues**: Keep CSV/TXT extraction as manual fallback
4. **Model download interrupted**: Resume support, integrity check on completion
5. **Storage space**: Show required space before download, allow model deletion

---

## Implementation Order

1. pubspec.yaml changes + `flutter pub get`
2. Delete api_config.dart
3. Create local_ai_service.dart (model management + LLM interface)
4. Create content_analyzer.dart (topic extraction)
5. Rewrite file_extraction_service.dart (kreuzberg)
6. Rewrite quiz_service.dart (remove API, use LocalAiService)
7. Enhance quiz_generator.dart (better offline generation + explanations)
8. Create model_download_screen.dart
9. Update app.dart (startup model check)
10. Update material_analysis_screen.dart
11. Update paste_text_screen.dart
12. Update mastery_detail_screen.dart
13. Update mastery_tracker.dart
14. Update settings_screen.dart
15. Update home_screen.dart (model status)
16. Run `flutter analyze` and fix issues
