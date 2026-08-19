import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_button.dart';
import '../models/quiz_settings.dart';

class QuizSettingsScreen extends StatefulWidget {
  final QuizSettings initialSettings;

  const QuizSettingsScreen({super.key, required this.initialSettings});

  @override
  State<QuizSettingsScreen> createState() => _QuizSettingsScreenState();
}

class _QuizSettingsScreenState extends State<QuizSettingsScreen> {
  late QuizSettings _settings;
  bool _showExplanations = true;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildHeader(),
              const SizedBox(height: 24),
              _buildSettingsCard(),
              const SizedBox(height: 20),
              _buildQuestionTypesCard(),
              const SizedBox(height: 20),
              _buildDifficultyCard(),
              const SizedBox(height: 20),
              _buildOptionsCard(),
              const SizedBox(height: 24),
              NeoButton(
                label: 'Start Quiz',
                icon: Icons.play_arrow,
                onPressed: _startQuiz,
              ),
              const SizedBox(height: 10),
              NeoButton(
                label: 'Cancel',
                outlined: true,
                color: AppColors.textSecondary,
                onPressed: () => Navigator.pop(context),
              ),
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
              color: AppColors.textPrimary,
              border: Border.all(color: AppColors.border, width: 1.5),
              boxShadow: const [BoxShadow(color: AppColors.shadow, offset: Offset(2, 2), blurRadius: 0)],
            ),
            child: const Center(child: Icon(Icons.arrow_back, size: 20, color: Colors.white)),
          ),
        ),
        const SizedBox(width: 14),
        const Text('Quiz Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildSettingsCard() {
    return NeoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Number of Questions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          _buildQuestionCountSelector(),
        ],
      ),
    );
  }

  Widget _buildQuestionCountSelector() {
    final options = [5, 10, 15, 20];
    return Row(
      children: options.map((count) {
        final selected = _settings.questionCount == count;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _settings = _settings.copyWith(questionCount: count)),
            child: Container(
              margin: EdgeInsets.only(right: count != options.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryBlue : AppColors.cardBg,
                border: Border.all(
                  color: selected ? AppColors.primaryBlue : AppColors.border,
                  width: 1.5,
                ),
                boxShadow: selected
                    ? const [BoxShadow(color: AppColors.shadow, offset: Offset(2, 2), blurRadius: 0)]
                    : null,
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuestionTypesCard() {
    return NeoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Question Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          _buildTypeOption(QuestionType.mixed, 'Mixed'),
          const SizedBox(height: 8),
          _buildTypeOption(QuestionType.multipleChoice, 'Multiple Choice'),
          const SizedBox(height: 8),
          _buildTypeOption(QuestionType.trueFalse, 'True or False'),
          const SizedBox(height: 8),
          _buildTypeOption(QuestionType.fillInTheBlank, 'Fill in the Blank'),
        ],
      ),
    );
  }

  Widget _buildTypeOption(QuestionType type, String label) {
    final selected = _settings.questionType == type;
    return GestureDetector(
      onTap: () => setState(() => _settings = _settings.copyWith(questionType: type)),
      child: NeoCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        color: selected ? AppColors.primaryBlue.withValues(alpha: 0.1) : AppColors.cardBg,
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primaryBlue : AppColors.border,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.primaryBlue : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyCard() {
    return NeoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Difficulty', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildDifficultyOption(Difficulty.easy, 'Easy', AppColors.success),
              const SizedBox(width: 8),
              _buildDifficultyOption(Difficulty.medium, 'Medium', AppColors.warning),
              const SizedBox(width: 8),
              _buildDifficultyOption(Difficulty.hard, 'Hard', AppColors.error),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyOption(Difficulty diff, String label, Color color) {
    final selected = _settings.difficulty == diff;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _settings = _settings.copyWith(difficulty: diff)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : AppColors.cardBg,
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: 1.5,
            ),
            boxShadow: selected
                ? const [BoxShadow(color: AppColors.shadow, offset: Offset(2, 2), blurRadius: 0)]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsCard() {
    return NeoCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Show explanations after answering', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                SizedBox(height: 2),
                Text('Learn from each question', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: _showExplanations,
            onChanged: (v) => setState(() => _showExplanations = v),
            activeThumbColor: AppColors.primaryBlue,
          ),
        ],
      ),
    );
  }

  void _startQuiz() {
    Navigator.pop(context, _settings);
  }
}
