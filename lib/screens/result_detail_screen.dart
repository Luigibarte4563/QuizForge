import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_button.dart';
import '../models/quiz.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';
import '../models/quiz_settings.dart';
import 'quiz_screen.dart';

class ResultDetailScreen extends StatelessWidget {
  final QuizResult result;
  final Quiz quiz;

  const ResultDetailScreen({super.key, required this.result, required this.quiz});

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }

  String _getMessage() {
    if (result.percentage >= 0.9) return 'Outstanding!';
    if (result.percentage >= 0.7) return 'Great job!';
    if (result.percentage >= 0.5) return 'Good effort!';
    return 'Keep practicing!';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildScoreCard(),
          const SizedBox(height: 20),
          _buildTopics(),
          const SizedBox(height: 24),
          _buildReviewMistakes(),
          const SizedBox(height: 24),
          NeoButton(
            label: 'Retake Quiz',
            icon: Icons.replay,
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => QuizScreen(quiz: quiz))),
          ),
          const SizedBox(height: 10),
          NeoButton(
            label: 'Back to Home',
            icon: Icons.home,
            outlined: true,
            color: AppColors.textPrimary,
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.textPrimary,
              border: Border.all(color: AppColors.border, width: 1.5),
              boxShadow: const [
                BoxShadow(color: AppColors.shadow, offset: Offset(2, 2), blurRadius: 0),
              ],
            ),
            child: const Center(child: Icon(Icons.arrow_back, size: 20, color: Colors.white)),
          ),
        ),
        const SizedBox(width: 14),
        const Text('Quiz Complete!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildScoreCard() {
    return NeoCard(
      color: AppColors.primaryBlue,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('${result.score} / ${result.totalQuestions}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 4),
          Text('${(result.percentage * 100).round()}% Correct', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white70)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.shadow, width: 1)),
            child: Text('Time: ${_formatTime(result.timeTakenSeconds)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryBlue)),
          ),
          const SizedBox(height: 8),
          Text(_getMessage(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildTopics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.strongTopics.isNotEmpty) ...[
          const Text('Strong Topics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.success)),
          const SizedBox(height: 8),
          ...result.strongTopics.map((t) => _buildTopicTile(t.topic, t.correct, t.total, true)),
          const SizedBox(height: 16),
        ],
        if (result.weakTopics.isNotEmpty) ...[
          const Text('Needs Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.warning)),
          const SizedBox(height: 8),
          ...result.weakTopics.map((t) => _buildTopicTile(t.topic, t.correct, t.total, false)),
        ],
      ],
    );
  }

  Widget _buildTopicTile(String topic, int correct, int total, bool strong) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NeoCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shadowOffset: 2,
        child: Row(
          children: [
            Icon(strong ? Icons.check_circle : Icons.warning, color: strong ? AppColors.success : AppColors.warning, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(topic, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
            Text('$correct/$total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: strong ? AppColors.success : AppColors.warning)),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewMistakes() {
    final mistakes = <int>[];
    for (var i = 0; i < quiz.questions.length; i++) {
      final q = quiz.questions[i];
      final userAnswer = result.answers[i] ?? -1;
      bool isCorrect;
      if (q.type == QuestionType.fillInTheBlank) {
        isCorrect = userAnswer == 0;
      } else {
        isCorrect = userAnswer == q.answer;
      }
      if (!isCorrect) mistakes.add(i);
    }

    if (mistakes.isEmpty) {
      return NeoCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.emoji_events, color: AppColors.success, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Perfect Score!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.success),
            ),
            const SizedBox(height: 4),
            const Text(
              'You answered every question correctly.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.replay, color: AppColors.primaryBlue, size: 22),
            const SizedBox(width: 8),
            Text(
              'Review Mistakes (${mistakes.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...mistakes.map((i) => _buildMistakeCard(i, quiz.questions[i])),
      ],
    );
  }

  Widget _buildMistakeCard(int index, Question question) {
    const optionLabels = ['A', 'B', 'C', 'D'];
    final userAnswer = result.answers[index] ?? -1;
    return NeoCard(
      padding: const EdgeInsets.all(16),
      shadowOffset: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                color: AppColors.error,
                child: Center(
                  child: Text('${index + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  question.question,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(question.options.length, (i) {
            final isCorrect = i == question.answer;
            final wasSelected = i == userAnswer;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isCorrect
                    ? AppColors.success.withValues(alpha: 0.15)
                    : wasSelected
                        ? AppColors.error.withValues(alpha: 0.1)
                        : Colors.transparent,
                border: Border.all(
                  color: isCorrect
                      ? AppColors.success
                      : wasSelected
                          ? AppColors.error
                          : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    color: isCorrect
                        ? AppColors.success
                        : wasSelected
                            ? AppColors.error
                            : AppColors.border,
                    child: Center(
                      child: Text(
                        optionLabels[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isCorrect || wasSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      question.options[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isCorrect
                            ? AppColors.success
                            : wasSelected
                                ? AppColors.error
                                : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (isCorrect)
                    const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                  if (wasSelected && !isCorrect)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.cancel, color: AppColors.error, size: 18),
                    ),
                ],
              ),
            );
          }),
          if (question.explanation != null && question.explanation!.isNotEmpty) ...[
            const SizedBox(height: 10),
            NeoCard(
              padding: const EdgeInsets.all(12),
              shadowOffset: 1,
              color: AppColors.primaryBlue.withValues(alpha: 0.05),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb, color: AppColors.primaryBlue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      question.explanation!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
