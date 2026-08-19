import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_button.dart';
import '../models/mastery.dart';

class MasteredScreen extends StatelessWidget {
  final Mastery mastery;

  const MasteredScreen({super.key, required this.mastery});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              const SizedBox(height: 60),
              _buildTrophy(),
              const SizedBox(height: 24),
              _buildStars(),
              const SizedBox(height: 16),
              const Text(
                'MASTERED!',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                mastery.materialTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildStats(),
              const SizedBox(height: 24),
              _buildTopicsSummary(),
              const SizedBox(height: 32),
              NeoButton(
                label: 'Back to Home',
                icon: Icons.home,
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrophy() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.warning,
        border: Border.all(color: AppColors.shadow, width: 2),
        boxShadow: const [BoxShadow(color: AppColors.shadow, offset: Offset(4, 4), blurRadius: 0)],
      ),
      child: const Icon(Icons.emoji_events, color: Colors.white, size: 60),
    );
  }

  Widget _buildStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Icon(
          i < mastery.stars ? Icons.star : Icons.star_border,
          size: 48,
          color: i < mastery.stars ? AppColors.warning : AppColors.border,
        ),
      )),
    );
  }

  Widget _buildStats() {
    return NeoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildStatRow('Mastery', '${mastery.masteryPercent.round()}%', AppColors.primaryBlue),
          const Divider(height: 24, color: AppColors.border),
          _buildStatRow('Questions Answered', '${mastery.totalAttempted}', AppColors.textPrimary),
          const Divider(height: 24, color: AppColors.border),
          _buildStatRow('Correct Answers', '${mastery.totalCorrect}', AppColors.success),
          const Divider(height: 24, color: AppColors.border),
          _buildStatRow('Challenge 1 Score', '${mastery.challenge1Score}%', AppColors.primaryBlue),
          const Divider(height: 24, color: AppColors.border),
          _buildStatRow('Challenge 2 Score', '${mastery.challenge2Score}%', AppColors.primaryBlue),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: valueColor)),
      ],
    );
  }

  Widget _buildTopicsSummary() {
    return NeoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              const Text('All Topics Mastered', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.success)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: mastery.concepts.map((concept) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.success, width: 1),
              ),
              child: Text(concept, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
