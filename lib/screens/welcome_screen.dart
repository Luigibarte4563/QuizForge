import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_button.dart';
import '../services/local_ai_service.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const WelcomeScreen({super.key, required this.onComplete});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _step = 0;
  String _selectedModel = 'large';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _step == 0 ? _buildWelcome() : _buildModelSelect(),
      ),
    );
  }

  Widget _buildWelcome() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 80,
            height: 80,
            color: AppColors.primaryBlue,
            child: const Center(child: Icon(Icons.quiz, color: Colors.white, size: 40)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome to QuizForge',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Turn your learning materials into study notes, flashcards, and quizzes — all offline.',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildFeature(Icons.phone_android, 'On-Device AI'),
          const SizedBox(height: 16),
          _buildFeature(Icons.wifi_off, 'Works Offline'),
          const SizedBox(height: 16),
          _buildFeature(Icons.speed, 'Instant Quiz Generation'),
          const SizedBox(height: 16),
          _buildFeature(Icons.lock, '100% Private'),
          const Spacer(),
          NeoButton(
            label: 'Get Started',
            icon: Icons.arrow_forward,
            onPressed: () => setState(() => _step = 1),
          ),
          const SizedBox(height: 12),
          NeoButton(
            label: 'Skip Setup',
            icon: Icons.arrow_forward,
            outlined: true,
            color: AppColors.textSecondary,
            onPressed: widget.onComplete,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Row(
      children: [
        Container(width: 40, height: 40, color: AppColors.primaryBlue, child: Center(child: Icon(icon, color: Colors.white, size: 20))),
        const SizedBox(width: 14),
        Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildModelSelect() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text('Choose AI Model', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Pick a model size. You can change this later in Settings.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          _buildModelOption(
            key: 'small',
            title: 'Fast Model',
            subtitle: 'Qwen 3 0.6B',
            size: '~500 MB',
            pros: ['Faster responses', 'Less memory used', 'Good for older phones'],
            icon: Icons.speed,
          ),
          const SizedBox(height: 14),
          _buildModelOption(
            key: 'large',
            title: 'Better Model',
            subtitle: 'Qwen 3 1.7B',
            size: '~1 GB',
            pros: ['Higher quality quizzes', 'Better explanations', 'Recommended'],
            icon: Icons.star,
          ),
          const Spacer(),
          NeoButton(
            label: _selectedModel == 'small' ? 'Use Fast Model' : 'Use Better Model',
            icon: Icons.check,
            onPressed: () {
              LocalAiService().selectModel(_selectedModel);
              widget.onComplete();
            },
          ),
          const SizedBox(height: 12),
          NeoButton(
            label: 'Skip for Now',
            icon: Icons.arrow_forward,
            outlined: true,
            color: AppColors.textSecondary,
            onPressed: widget.onComplete,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildModelOption({
    required String key,
    required String title,
    required String subtitle,
    required String size,
    required List<String> pros,
    required IconData icon,
  }) {
    final isSelected = _selectedModel == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedModel = key),
      child: NeoCard(
        color: isSelected ? AppColors.primaryBlue : null,
        padding: const EdgeInsets.all(16),
        shadowOffset: isSelected ? 3 : 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  color: isSelected ? Colors.white.withAlpha(30) : AppColors.primaryBlue,
                  child: Center(child: Icon(icon, color: isSelected ? Colors.white : Colors.white, size: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isSelected ? Colors.white : AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text('$subtitle • $size', style: TextStyle(fontSize: 13, color: isSelected ? Colors.white70 : AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (isSelected) const Icon(Icons.check_circle, color: Colors.white, size: 24),
              ],
            ),
            const SizedBox(height: 12),
            ...pros.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.check, size: 16, color: isSelected ? Colors.white70 : AppColors.success),
                  const SizedBox(width: 8),
                  Text(p, style: TextStyle(fontSize: 13, color: isSelected ? Colors.white70 : AppColors.textSecondary)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
