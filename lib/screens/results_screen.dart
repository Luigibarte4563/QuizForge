import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/neo_card.dart';
import '../models/quiz_result.dart';
import '../services/storage_service.dart';
import 'result_detail_screen.dart';

class ResultsScreen extends StatefulWidget {
  final QuizResult? result;
  final dynamic quiz;

  const ResultsScreen({super.key, this.result, this.quiz});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  List<QuizResult> _results = [];
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
    final results = await StorageService.getAllResults();
    if (mounted) setState(() { _results = results; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.result != null) {
      return _buildSingleResult(widget.result!, widget.quiz);
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text('Quiz Results', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
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
          Icon(Icons.bar_chart, size: 64, color: AppColors.textSecondary.withAlpha(80)),
          const SizedBox(height: 16),
          const Text('No results yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Complete a quiz to see your results here!', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _results.length,
      itemBuilder: (context, i) => _buildResultCard(_results[i]),
    );
  }

  Widget _buildResultCard(QuizResult result) {
    final date = DateFormat('MMM d, yyyy • h:mm a').format(result.completedAt);
    final pct = (result.percentage * 100).round();
    final color = pct >= 70 ? AppColors.success : pct >= 50 ? AppColors.warning : AppColors.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () async {
          final quiz = await StorageService.getQuiz(result.quizId);
          if (quiz != null && mounted) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => ResultDetailScreen(result: result, quiz: quiz),
            ));
          }
        },
        child: NeoCard(
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                color: color,
                child: Center(
                  child: Text('$pct%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.quizTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${result.score}/${result.totalQuestions} correct • $date', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleResult(QuizResult result, dynamic quiz) {
    return Scaffold(
      body: SafeArea(
        child: ResultDetailScreen(result: result, quiz: quiz),
      ),
    );
  }
}
