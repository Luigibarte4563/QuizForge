# QuizForge

Offline AI-powered learning assistant. Turn any learning material into study notes, flashcards, and quizzes — 100% on-device, no internet required.

## Features

- **On-Device AI** — Qwen 3 language models run locally on your phone
- **Dual Model Choice** — Pick Fast (~500 MB) or Better (~1 GB) based on your device
- **File Import** — PDF, DOCX, PPTX, XLSX, TXT, RTF, HTML, JSON and more
- **Paste Text** — Paste notes, articles, or any text directly
- **Study Notes** — AI-generated summary notes from your material
- **Flashcards** — Tap-to-reveal flashcards with AI-generated Q&A pairs
- **Quizzes** — Multiple Choice, True/False, Fill-in-the-Blank, or Mixed
- **Challenge Mode** — Score-based challenges unlocked by progress
- **Folders** — Organize materials into color-coded folders
- **Progress Tracking** — Per-material mastery percentage, scores, and history
- **100% Offline** — After initial model download, everything runs without internet
- **Privacy First** — No data ever leaves your device

## Tech Stack

- **Flutter** + Dart
- **nobodywho** — On-device LLM inference (Qwen3 GGUF models)
- **sqflite** — Local SQLite database
- **archive** + **xml** — Pure Dart file extraction (no native dependencies)
- **shared_preferences** — First-launch onboarding state

## Project Structure

```
lib/
├── main.dart                    # App entry, NobodyWho init, first-launch check
├── app.dart                     # MainShell with bottom nav (Home | Materials | More)
├── constants.dart
├── models/
│   ├── folder.dart              # Folder model (name, color)
│   ├── mastery.dart             # Material progress model
│   ├── question.dart            # Question model (MCQ, T/F, FIB)
│   ├── quiz.dart                # Quiz model
│   ├── quiz_result.dart         # Quiz result + topic breakdown
│   └── quiz_settings.dart       # Settings + QuestionType enum (includes Mixed)
├── screens/
│   ├── welcome_screen.dart      # First-launch onboarding + model picker
│   ├── home_screen.dart         # Dashboard: continue studying, quick actions
│   ├── materials_screen.dart    # Folders + materials list, FAB to add
│   ├── folder_detail_screen.dart# Materials inside a folder
│   ├── material_analysis_screen.dart # Processing screen with progress
│   ├── paste_text_screen.dart   # Paste text input
│   ├── model_download_screen.dart    # AI model download with dual model picker
│   ├── quiz_settings_screen.dart     # Quiz config (count, type, difficulty)
│   ├── generate_quiz_screen.dart     # Quiz generation progress
│   ├── quiz_screen.dart              # Quiz player
│   ├── mastery_detail_screen.dart    # Material study hub (notes, flashcards, quizzes, progress)
│   ├── mastery_quiz_screen.dart      # Material-linked quiz player
│   ├── mastery_result_screen.dart    # Material quiz results + challenge unlock
│   ├── flashcard_screen.dart         # Tap-to-reveal flashcard viewer
│   ├── challenge_quiz_screen.dart    # Challenge mode quiz player
│   ├── result_detail_screen.dart     # Quiz result review (mistakes + explanations)
│   ├── more_screen.dart              # AI model info, recent results, about, privacy
│   ├── my_quizzes_screen.dart        # All quizzes list (legacy)
│   └── results_screen.dart           # All results list (legacy)
├── services/
│   ├── storage_service.dart     # SQLite DB (v6), CRUD for all models
│   ├── local_ai_service.dart    # NobodyWho wrapper, dual model support
│   ├── quiz_service.dart        # AI + offline quiz/flashcard generation
│   ├── quiz_generator.dart      # Offline fallback question generator
│   ├── content_analyzer.dart    # Content analysis
│   └── file_extraction_service.dart # Pure Dart file extraction
├── theme/
│   ├── app_colors.dart          # Color palette
│   └── app_theme.dart           # Theme configuration
└── widgets/
    ├── neo_card.dart            # Neubrutalist card widget
    └── neo_button.dart          # Neubrutalist button widget
```

## Getting Started

### Prerequisites
- Flutter SDK 3.12.2+
- Android SDK

### Build
```bash
flutter pub get
flutter build apk --debug
```

### First Launch
1. Welcome screen → tap "Get Started"
2. Pick a model: Fast (~500 MB) or Better (~1 GB)
3. Model downloads on-device (~1-3 min depending on connection)
4. Ready to use

## AI Models

| Model | Size | Best For |
|-------|------|----------|
| Qwen3-0.6B Q4_K_M | ~500 MB | Older/lower-end phones, faster responses |
| Qwen3-1.7B Q4_K_M | ~1 GB | Better quality quizzes and explanations |

Models are downloaded from HuggingFace on first launch and cached locally.

## Supported File Types

| Format | Extension |
|--------|-----------|
| PDF | .pdf |
| Word | .docx, .doc |
| PowerPoint | .pptx, .ppt |
| Excel | .xlsx, .xls |
| CSV | .csv |
| Text | .txt |
| Rich Text | .rtf |
| Web | .html, .htm |
| JSON | .json |
