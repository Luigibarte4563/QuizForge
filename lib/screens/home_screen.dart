import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_colors.dart';
import '../widgets/neo_card.dart';
import 'material_analysis_screen.dart';
import 'paste_text_screen.dart';
import '../models/mastery.dart';
import '../services/storage_service.dart';
import '../services/local_ai_service.dart';
import 'mastery_detail_screen.dart';
import 'flashcard_screen.dart';
import 'quiz_settings_screen.dart';
import '../models/quiz_settings.dart';
import '../services/quiz_service.dart';
import 'mastery_quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Mastery> _recentMasteries = [];
  bool _aiModelReady = false;

  @override
  void initState() {
    super.initState();
    _loadMasteries();
    _checkAiModel();
  }

  Future<void> _checkAiModel() async {
    final ready = await LocalAiService().isModelDownloaded();
    if (mounted) setState(() => _aiModelReady = ready);
  }

  Future<void> _loadMasteries() async {
    final masteries = await StorageService.getAllMastery();
    if (mounted) setState(() => _recentMasteries = masteries.take(5).toList());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildUploadSection(),
            const SizedBox(height: 24),
            if (_recentMasteries.isNotEmpty) ...[
              _buildContinueStudying(),
              const SizedBox(height: 24),
            ],
            _buildQuickActions(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'QuizForge',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        NeoCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                color: _aiModelReady ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 6),
              Text(
                _aiModelReady ? '🤖 AI Ready' : 'Offline Mode',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _aiModelReady ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What would you like to study?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        _buildUploadCard(),
        const SizedBox(height: 10),
        _buildPasteCard(),
      ],
    );
  }

  Widget _buildUploadCard() {
    return GestureDetector(
      onTap: _uploadFile,
      child: NeoCard(
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              color: AppColors.primaryBlue,
              child: const Icon(Icons.upload_file, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('+ Add Learning Material', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  SizedBox(height: 2),
                  Text('PDF, DOCX, PPTX, TXT and more', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildPasteCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PasteTextScreen()));
      },
      child: NeoCard(
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              color: AppColors.success,
              child: const Icon(Icons.content_paste, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Paste Text', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  SizedBox(height: 2),
                  Text('Paste your notes or any text', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueStudying() {
    final m = _recentMasteries.first;
    final pct = m.masteryPercent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Continue Studying', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => MasteryDetailScreen(mastery: m)))
                .then((_) => _loadMasteries());
          },
          child: NeoCard(
            padding: const EdgeInsets.all(16),
            shadowOffset: 2,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  color: m.fullyMastered ? AppColors.success : AppColors.primaryBlue,
                  child: Center(
                    child: m.fullyMastered
                        ? const Icon(Icons.star, color: Colors.white, size: 24)
                        : Text(
                            '${pct.round()}%',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.materialTitle,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (!m.fullyMastered)
                        ClipRRect(
                          borderRadius: BorderRadius.zero,
                          child: LinearProgressIndicator(
                            value: pct / 100,
                            minHeight: 6,
                            backgroundColor: AppColors.progressBg,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                          ),
                        )
                      else
                        const Text('Mastered!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _recentMasteries.isNotEmpty ? () => _startFlashcards(_recentMasteries.first) : null,
                child: NeoCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        color: _recentMasteries.isNotEmpty ? AppColors.success : AppColors.textSecondary,
                        child: const Icon(Icons.style, color: Colors.white, size: 24),
                      ),
                      const SizedBox(height: 8),
                      const Text('Flashcards', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: _recentMasteries.isNotEmpty ? () => _startQuiz(_recentMasteries.first) : null,
                child: NeoCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        color: _recentMasteries.isNotEmpty ? AppColors.warning : AppColors.textSecondary,
                        child: const Icon(Icons.quiz, color: Colors.white, size: 24),
                      ),
                      const SizedBox(height: 8),
                      const Text('Quiz', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _startFlashcards(Mastery m) async {
    final existingCards = await StorageService.getFlashcards(m.id);
    if (existingCards.isNotEmpty && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FlashcardScreen(title: m.materialTitle, cards: existingCards),
        ),
      );
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Open the material first to generate flashcards.'), backgroundColor: AppColors.primaryBlue),
      );
    }
  }

  Future<void> _startQuiz(Mastery m) async {
    final settings = await Navigator.push<QuizSettings>(
      context,
      MaterialPageRoute(
        builder: (_) => QuizSettingsScreen(
          initialSettings: const QuizSettings(
            questionCount: 10,
            difficulty: Difficulty.medium,
            questionType: QuestionType.mixed,
          ),
        ),
      ),
    );
    if (settings == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating quiz...'), backgroundColor: AppColors.primaryBlue),
    );

    try {
      final questions = await QuizService().generate(
        content: m.sourceText,
        questionCount: settings.questionCount,
        preferredType: settings.questionType,
        difficulty: settings.difficulty,
      );
      if (!mounted) return;
      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate questions.'), backgroundColor: AppColors.error),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MasteryQuizScreen(mastery: m, questions: questions),
        ),
      ).then((_) => _loadMasteries());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _uploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'docx', 'doc', 'pptx', 'ppt',
          'xlsx', 'xls', 'csv', 'txt', 'rtf',
          'html', 'htm', 'json',
        ],
      );

      if (result == null || result.files.isEmpty || !mounted) return;

      final file = File(result.files.first.path!);
      final fileName = result.files.first.name;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MaterialAnalysisScreen(file: file, fileName: fileName),
        ),
      ).then((_) => _loadMasteries());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e'), backgroundColor: AppColors.error),
      );
    }
  }
}
