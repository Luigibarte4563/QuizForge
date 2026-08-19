import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/neo_card.dart';
import '../models/quiz.dart';
import '../services/storage_service.dart';
import 'quiz_screen.dart';
import 'mastery_detail_screen.dart';

class MyQuizzesScreen extends StatefulWidget {
  const MyQuizzesScreen({super.key});

  @override
  State<MyQuizzesScreen> createState() => _MyQuizzesScreenState();
}

class _MyQuizzesScreenState extends State<MyQuizzesScreen> {
  List<Quiz> _quizzes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final quizzes = await StorageService.getAllQuizzes();
    if (mounted) setState(() { _quizzes = quizzes; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text('My Quizzes', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _quizzes.isEmpty
                    ? _buildEmpty()
                    : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz, size: 64, color: AppColors.textSecondary.withAlpha(80)),
          const SizedBox(height: 16),
          const Text('No quizzes yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Upload a file from Home to get started!', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _quizzes.length,
      itemBuilder: (context, i) => _buildItem(_quizzes[i]),
    );
  }

  Widget _buildItem(Quiz quiz) {
    final date = DateFormat('MMM d, yyyy').format(quiz.createdAt);
    final hasMastery = quiz.masteryId != null && quiz.masteryId!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key(quiz.id),
        direction: DismissDirection.endToStart,
        background: Container(
          color: AppColors.error,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) async {
          await StorageService.deleteQuiz(quiz.id);
          _load();
        },
        child: NeoCard(
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                color: hasMastery ? AppColors.primaryBlue : AppColors.success,
                child: Icon(
                  hasMastery ? Icons.school : Icons.quiz,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(quiz.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${quiz.questions.length} questions • $date', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      hasMastery ? 'Study Material • ${quiz.settings.difficultyLabel}' : quiz.settings.typeLabel,
                      style: TextStyle(fontSize: 11, color: hasMastery ? AppColors.primaryBlue : AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _openQuiz(quiz),
                icon: Icon(
                  hasMastery ? Icons.open_in_new : Icons.play_arrow_rounded,
                  color: hasMastery ? AppColors.primaryBlue : AppColors.primaryBlue,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openQuiz(Quiz quiz) async {
    final hasMastery = quiz.masteryId != null && quiz.masteryId!.isNotEmpty;
    if (hasMastery) {
      final mastery = await StorageService.getMastery(quiz.masteryId!);
      if (mastery != null && mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => MasteryDetailScreen(mastery: mastery)))
            .then((_) => _load());
      } else {
        if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(quiz: quiz)));
      }
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(quiz: quiz)));
    }
  }
}
