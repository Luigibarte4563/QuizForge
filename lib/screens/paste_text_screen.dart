import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_button.dart';
import '../models/quiz.dart';
import '../models/quiz_settings.dart';
import '../services/mastery_tracker.dart';
import '../services/quiz_service.dart';
import '../services/storage_service.dart';
import 'mastery_quiz_screen.dart';

class PasteTextScreen extends StatefulWidget {
  const PasteTextScreen({super.key});

  @override
  State<PasteTextScreen> createState() => _PasteTextScreenState();
}

class _PasteTextScreenState extends State<PasteTextScreen> {
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  bool _isAnalyzing = false;
  double _progress = 0;
  String _progressText = '';
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _generateQuiz() async {
    final text = _textController.text.trim();
    if (text.length < 30) {
      setState(() => _error = 'Please paste at least 30 characters of study material.');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _error = null;
      _progress = 0.1;
      _progressText = 'Preparing content...';
    });

    try {
      setState(() { _progress = 0.3; _progressText = 'Analyzing material...'; });
      await Future.delayed(const Duration(milliseconds: 500));

      final wordCount = text.split(RegExp(r'\s+')).length;
      final conceptCount = (wordCount / 50).round().clamp(5, 30);

      setState(() { _progress = 0.5; _progressText = '$conceptCount concepts found.'; });
      await Future.delayed(const Duration(milliseconds: 400));

      setState(() { _progress = 0.55; _progressText = 'Creating study notes...'; });
      final notes = _generateNotes(text);

      setState(() { _progress = 0.65; _progressText = 'Generating your personalized quiz...'; });

      final questions = await QuizService().generate(
        content: text,
        onProgress: (msg) {
          if (mounted) {
            setState(() {
              _progressText = msg;
              _progress = (_progress + 0.1).clamp(0.0, 0.95);
            });
          }
        },
      );

      setState(() { _progress = 0.95; _progressText = 'Saving...'; });

      if (questions.isEmpty) {
        setState(() { _error = 'Could not generate questions. Try more content.'; _isAnalyzing = false; });
        return;
      }

      final title = _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : 'Pasted Text Quiz';

      final newMastery = await MasteryTracker().createMastery(
        title: title,
        sourceText: text.length > 10000 ? text.substring(0, 10000) : text,
        concepts: questions.map((q) => q.topic).toSet().toList(),
        notes: notes,
      );

      final quiz = Quiz(
        id: newMastery.id,
        title: title,
        questions: questions,
        settings: const QuizSettings(),
        sourceText: text.length > 5000 ? text.substring(0, 5000) : text,
        createdAt: DateTime.now(),
      );
      await StorageService.saveQuiz(quiz);

      setState(() { _progress = 1.0; _progressText = 'Ready!'; });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MasteryQuizScreen(mastery: newMastery, questions: questions),
        ),
      );
    } catch (e) {
      setState(() { _error = 'Error: $e'; _isAnalyzing = false; });
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
              const SizedBox(height: 20),
              _buildTitleField(),
              const SizedBox(height: 14),
              _buildTextField(),
              const SizedBox(height: 20),
              const SizedBox(height: 20),
              if (_error != null) _buildError(),
              if (_isAnalyzing) _buildProgress() else _buildGenerateButton(),
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
              boxShadow: const [BoxShadow(color: AppColors.shadow, offset: Offset(2, 2), blurRadius: 0)],
            ),
            child: const Center(child: Icon(Icons.arrow_back, size: 20, color: AppColors.textPrimary)),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text('Paste Text', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return NeoCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _titleController,
        decoration: const InputDecoration(
          hintText: 'Material title (optional)',
          border: InputBorder.none,
          hintStyle: TextStyle(color: AppColors.textSecondary),
        ),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildTextField() {
    return NeoCard(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 220,
        child: TextField(
          controller: _textController,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          decoration: const InputDecoration(
            hintText: 'Paste your study material here...\n\nNotes, articles, textbook content, etc.',
            border: InputBorder.none,
            hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
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

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: NeoCard(
        color: AppColors.error,
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
        ]),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return NeoButton(label: 'Generate Quiz', icon: Icons.auto_awesome, onPressed: _generateQuiz);
  }

  String _generateNotes(String content) {
    return content.trim();
  }
}
