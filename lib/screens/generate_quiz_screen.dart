import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_button.dart';
import '../models/quiz_settings.dart';
import '../services/file_extraction_service.dart';
import '../services/quiz_service.dart';
import '../services/storage_service.dart';
import '../models/quiz.dart';
import 'quiz_screen.dart';

class GenerateQuizScreen extends StatefulWidget {
  final File file;
  final String fileName;

  const GenerateQuizScreen({
    super.key,
    required this.file,
    required this.fileName,
  });

  @override
  State<GenerateQuizScreen> createState() => _GenerateQuizScreenState();
}

class _GenerateQuizScreenState extends State<GenerateQuizScreen> {
  QuizSettings _settings = const QuizSettings();
  bool _isGenerating = false;
  String? _error;
  String _progressText = '';
  double _progress = 0;

  Future<void> _generateQuiz() async {
    setState(() {
      _isGenerating = true;
      _error = null;
      _progress = 0.05;
      _progressText = 'Reading file...';
    });

    try {
      setState(() { _progress = 0.15; _progressText = 'Extracting text...'; });
      final extractionResult = await FileExtractionService.extractText(widget.file);
      final content = extractionResult.text;

      if (content.trim().length < 20) {
        setState(() {
          _error = 'File too short or unreadable. Try a .txt file with more content.';
          _isGenerating = false;
        });
        return;
      }

      setState(() { _progress = 0.35; _progressText = 'Sending to AI...'; });
      final questions = await QuizService().generate(
        content: content,
        questionCount: _settings.questionCount,
        preferredType: _settings.questionType,
        difficulty: _settings.difficulty,
        onProgress: (msg) {
          if (mounted) {
            setState(() {
              _progressText = msg;
              _progress = (_progress + 0.2).clamp(0.0, 0.9);
            });
          }
        },
      );

      setState(() { _progress = 0.92; _progressText = 'Saving quiz...'; });

      if (questions.isEmpty) {
        setState(() {
          _error = 'Could not generate questions. Try a file with more text content.';
          _isGenerating = false;
        });
        return;
      }

      final quiz = Quiz(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: widget.fileName.replaceAll(RegExp(r'\.[^.]+$'), ''),
        questions: questions,
        settings: _settings,
        sourceText: content.length > 5000 ? content.substring(0, 5000) : content,
        createdAt: DateTime.now(),
      );

      await StorageService.saveQuiz(quiz);
      setState(() { _progress = 1.0; _progressText = 'Done!'; });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => QuizScreen(quiz: quiz)),
      );
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildFileCard(),
              const SizedBox(height: 24),
              _buildSettingsSection(),
              const SizedBox(height: 20),
              if (_error != null) _buildError(),
              if (_isGenerating) _buildProgress() else _buildGenerateButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 1.5),
              boxShadow: const [
                BoxShadow(color: AppColors.shadow, offset: Offset(2, 2), blurRadius: 0),
              ],
            ),
            child: const Center(child: Icon(Icons.arrow_back, size: 20, color: AppColors.textPrimary)),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            'Generate Quiz',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildFileCard() {
    return NeoCard(
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            color: AppColors.primaryBlue,
            child: const Icon(Icons.description, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.fileName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Text will be extracted locally',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppColors.success, size: 22),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quiz Settings',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 14),
        _buildOptionRow(
          'Questions',
          Icons.format_list_numbered,
          [5, 10, 15, 20].map((c) {
            final sel = _settings.questionCount == c;
            return _buildChoiceChip('$c', sel, () {
              setState(() => _settings = _settings.copyWith(questionCount: c));
            });
          }).toList(),
        ),
        const SizedBox(height: 10),
        _buildOptionRow(
          'Difficulty',
          Icons.signal_cellular_alt,
          [
            (Difficulty.easy, 'Easy'),
            (Difficulty.medium, 'Medium'),
            (Difficulty.hard, 'Hard'),
          ].map((d) {
            final sel = _settings.difficulty == d.$1;
            return _buildChoiceChip(d.$2, sel, () {
              setState(() => _settings = _settings.copyWith(difficulty: d.$1));
            });
          }).toList(),
        ),
        const SizedBox(height: 10),
        _buildOptionRow(
          'Type',
          Icons.help_outline,
          [
            (QuestionType.mixed, 'Mixed'),
            (QuestionType.multipleChoice, 'MCQ'),
            (QuestionType.trueFalse, 'True/False'),
            (QuestionType.fillInTheBlank, 'Fill-in'),
          ].map((t) {
            final sel = _settings.questionType == t.$1;
            return _buildChoiceChip(t.$2, sel, () {
              setState(() => _settings = _settings.copyWith(questionType: t.$1));
            });
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOptionRow(String title, IconData icon, List<Widget> chips) {
    return NeoCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primaryBlue),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue : Colors.transparent,
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: NeoCard(
        color: AppColors.error,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
    final pct = (_progress * 100).round();
    return NeoCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(_progressText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ),
              Text('$pct%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primaryBlue)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: AppColors.progressBg,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return NeoButton(
      label: 'Generate Quiz',
      icon: Icons.auto_awesome,
      onPressed: _generateQuiz,
    );
  }
}
