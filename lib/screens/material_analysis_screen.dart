import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_button.dart';
import '../models/quiz.dart';
import '../models/quiz_settings.dart';
import '../services/file_extraction_service.dart';
import '../services/quiz_service.dart';
import '../services/storage_service.dart';
import '../services/mastery_tracker.dart';
import 'mastery_quiz_screen.dart';

class MaterialAnalysisScreen extends StatefulWidget {
  final dynamic file;
  final String fileName;

  const MaterialAnalysisScreen({
    super.key,
    required this.file,
    required this.fileName,
  });

  @override
  State<MaterialAnalysisScreen> createState() => _MaterialAnalysisScreenState();
}

class _MaterialAnalysisScreenState extends State<MaterialAnalysisScreen>
    with SingleTickerProviderStateMixin {
  double _progress = 0;
  String _statusText = 'Preparing...';
  String? _error;
  bool _isDone = false;
  bool _cancelled = false;
  int _conceptCount = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startAnalysis();
  }

  @override
  void dispose() {
    _cancelled = true;
    _pulseController.dispose();
    super.dispose();
  }

  void _cancel() {
    setState(() {
      _cancelled = true;
      _error = 'Cancelled.';
    });
  }

  Future<void> _startAnalysis() async {
    try {
      setState(() { _progress = 0.1; _statusText = 'Reading your file...'; });
      await Future.delayed(const Duration(milliseconds: 400));
      if (_cancelled || !mounted) return;

      setState(() { _progress = 0.25; _statusText = 'Understanding the content...'; });
      final extractionResult = await FileExtractionService.extractText(widget.file);
      final content = extractionResult.text;

      if (_cancelled || !mounted) return;

      if (content.trim().length < 30) {
        setState(() {
          _error = 'File too short or unreadable. Try a .txt file with more content.';
        });
        return;
      }

      setState(() { _progress = 0.45; _statusText = 'Analyzing your material...'; });
      await Future.delayed(const Duration(milliseconds: 600));
      if (_cancelled || !mounted) return;

      final wordCount = content.split(RegExp(r'\s+')).length;
      _conceptCount = (wordCount / 50).round().clamp(5, 30);

      setState(() { _progress = 0.55; _statusText = 'Creating study notes...'; });
      await Future.delayed(const Duration(milliseconds: 500));
      if (_cancelled || !mounted) return;

      setState(() { _progress = 0.6; _statusText = 'Creating flashcards...'; });
      final notes = _generateNotes(content);
      await Future.delayed(const Duration(milliseconds: 300));
      if (_cancelled || !mounted) return;

      setState(() { _progress = 0.7; _statusText = 'Creating quiz questions...'; });
      final questions = await QuizService().generate(
        content: content,
        onProgress: (msg) {
          if (mounted && !_cancelled) {
            setState(() {
              _progress = (_progress + 0.08).clamp(0.0, 0.95);
            });
          }
        },
      );

      if (_cancelled || !mounted) return;

      setState(() { _progress = 0.95; _statusText = 'Saving...'; });
      await Future.delayed(const Duration(milliseconds: 300));

      if (_cancelled || !mounted) return;

      if (questions.isEmpty) {
        setState(() { _error = 'Could not generate questions. Try a file with more text.'; });
        return;
      }

      final title = widget.fileName.replaceAll(RegExp(r'\.[^.]+$'), '');

      final mastery = await MasteryTracker().createMastery(
        title: title,
        sourceText: content.length > 10000 ? content.substring(0, 10000) : content,
        concepts: questions.map((q) => q.topic).toSet().toList(),
        notes: notes,
      );

      final quiz = Quiz(
        id: mastery.id,
        title: title,
        questions: questions,
        settings: const QuizSettings(),
        sourceText: content.length > 5000 ? content.substring(0, 5000) : content,
        createdAt: DateTime.now(),
      );
      await StorageService.saveQuiz(quiz);

      setState(() { _progress = 1.0; _statusText = 'Your material is ready!'; _isDone = true; });
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MasteryQuizScreen(mastery: mastery, questions: questions),
        ),
      );
    } catch (e) {
      if (!_cancelled && mounted) {
        setState(() { _error = 'Error: $e'; });
      }
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
              const SizedBox(height: 32),
              _buildMaterialCard(),
              const SizedBox(height: 32),
              _buildProgressSection(),
              const SizedBox(height: 24),
              if (_error != null) _buildError(),
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
          child: Text(
            'Preparing Material',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialCard() {
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
                Text(
                  _conceptCount > 0 ? '$_conceptCount concepts detected' : FileExtractionService.getFileTypeLabel(widget.fileName),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (_isDone)
            const Icon(Icons.check_circle, color: AppColors.success, size: 22),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final pct = (_progress * 100).round();
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isDone ? 1.0 : _pulseAnimation.value,
              child: child,
            );
          },
          child: Container(
            width: 80,
            height: 80,
            color: _isDone ? AppColors.success : AppColors.primaryBlue,
            child: Center(
              child: _isDone
                  ? const Icon(Icons.check, color: Colors.white, size: 40)
                  : Text(
                      '$pct%',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _statusText,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.zero,
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 8,
            backgroundColor: AppColors.progressBg,
            valueColor: AlwaysStoppedAnimation<Color>(
              _isDone ? AppColors.success : AppColors.primaryBlue,
            ),
          ),
        ),
        if (!_isDone && _error == null) ...[
          const SizedBox(height: 20),
          NeoButton(
            label: 'Cancel',
            icon: Icons.close,
            outlined: true,
            color: AppColors.textSecondary,
            onPressed: _cancel,
          ),
        ],
      ],
    );
  }

  Widget _buildError() {
    return NeoCard(
      color: AppColors.error,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                NeoButton(
                  label: 'Go Back',
                  onPressed: () => Navigator.pop(context),
                  color: Colors.white,
                  textColor: AppColors.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _generateNotes(String content) {
    return content.trim();
  }
}
