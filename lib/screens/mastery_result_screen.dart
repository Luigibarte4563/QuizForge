import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_button.dart';
import '../models/mastery.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';
import '../models/quiz_settings.dart';
import 'challenge_quiz_screen.dart';
import 'mastery_quiz_screen.dart';

class MasteryResultScreen extends StatelessWidget {
  final Mastery mastery;
  final QuizResult result;
  final List<Question> questions;
  final Map<int, int> answers;

  const MasteryResultScreen({
    super.key,
    required this.mastery,
    required this.result,
    required this.questions,
    required this.answers,
  });

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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        border: Border.all(color: AppColors.border, width: 1.5),
                        boxShadow: const [BoxShadow(color: AppColors.shadow, offset: Offset(2, 2), blurRadius: 0)],
                      ),
                      child: const Center(child: Icon(Icons.arrow_back, size: 20, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text('Quiz Complete!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 24),
              _buildScoreCard(),
              const SizedBox(height: 20),
              _buildMasteryProgress(),
              const SizedBox(height: 20),
              _buildChallengeSection(context),
              const SizedBox(height: 20),
              _buildReviewMistakes(),
              const SizedBox(height: 24),
              NeoButton(
                label: 'Practice Again',
                icon: Icons.replay,
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MasteryQuizScreen(mastery: mastery, questions: questions),
                    ),
                  );
                },
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
        ),
      ),
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

  Widget _buildMasteryProgress() {
    final pct = mastery.masteryPercent;
    return NeoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Text('${pct.round()}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryBlue)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 12,
              backgroundColor: AppColors.progressBg,
              valueColor: AlwaysStoppedAnimation<Color>(
                pct >= 100 ? AppColors.success : AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pct >= 100
                ? 'You\'ve mastered all concepts! Time for challenges.'
                : 'Keep answering correctly to reach 100% progress.',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeSection(BuildContext context) {
    return NeoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Challenge', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          _buildChallengeTile(
            context,
            title: 'Challenge Quiz 1',
            subtitle: mastery.challenge1Unlocked
                ? 'Score: ${mastery.challenge1Score}%'
                : mastery.masteryPercent >= 100 ? 'Ready to unlock!' : 'Reach 100% mastery to unlock',
            unlocked: mastery.masteryPercent >= 100,
            completed: mastery.challenge1Unlocked,
            score: mastery.challenge1Score,
            challengeNumber: 1,
          ),
          const SizedBox(height: 8),
          _buildChallengeTile(
            context,
            title: 'Challenge Quiz 2',
            subtitle: mastery.challenge2Unlocked
                ? 'Score: ${mastery.challenge2Score}%'
                : mastery.challenge1Unlocked ? 'Complete Challenge 1 first' : 'Locked',
            unlocked: mastery.challenge1Unlocked,
            completed: mastery.challenge2Unlocked,
            score: mastery.challenge2Score,
            challengeNumber: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool unlocked,
    required bool completed,
    required int score,
    required int challengeNumber,
  }) {
    return GestureDetector(
      onTap: unlocked && !completed
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChallengeQuizScreen(
                    mastery: mastery,
                    challengeNumber: challengeNumber,
                  ),
                ),
              );
            }
          : null,
      child: NeoCard(
        padding: const EdgeInsets.all(14),
        shadowOffset: 2,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              color: completed
                  ? AppColors.success
                  : unlocked
                      ? AppColors.primaryBlue
                      : AppColors.textSecondary,
              child: Center(
                child: completed
                    ? const Icon(Icons.check, color: Colors.white, size: 22)
                    : Icon(
                        unlocked ? Icons.play_arrow : Icons.lock,
                        color: Colors.white,
                        size: 22,
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: completed ? AppColors.success : AppColors.textSecondary)),
                ],
              ),
            ),
            if (completed)
              Icon(Icons.check_circle, color: AppColors.success, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewMistakes() {
    final mistakes = <int>[];
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final userAnswer = answers[i] ?? -1;
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
            const Text('Perfect Score!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.success)),
            const SizedBox(height: 4),
            const Text('You answered every question correctly.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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
            Text('Review Mistakes (${mistakes.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 12),
        ...mistakes.map((i) => _buildMistakeCard(i, questions[i])),
      ],
    );
  }

  Widget _buildMistakeCard(int index, Question question) {
    const optionLabels = ['A', 'B', 'C', 'D'];
    final userAnswer = answers[index] ?? -1;
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
                child: Center(child: Text('${index + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(question.question, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3))),
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
                color: isCorrect ? AppColors.success.withValues(alpha: 0.15) : wasSelected ? AppColors.error.withValues(alpha: 0.1) : Colors.transparent,
                border: Border.all(color: isCorrect ? AppColors.success : wasSelected ? AppColors.error : AppColors.border, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    color: isCorrect ? AppColors.success : wasSelected ? AppColors.error : AppColors.border,
                    child: Center(child: Text(optionLabels[i], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isCorrect || wasSelected ? Colors.white : AppColors.textSecondary))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(question.options[i], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isCorrect ? AppColors.success : wasSelected ? AppColors.error : AppColors.textPrimary))),
                  if (isCorrect) const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                  if (wasSelected && !isCorrect) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.cancel, color: AppColors.error, size: 18)),
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
                  Expanded(child: Text(question.explanation!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
