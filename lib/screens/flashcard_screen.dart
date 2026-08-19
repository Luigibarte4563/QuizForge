import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_button.dart';

class FlashcardScreen extends StatefulWidget {
  final String title;
  final List<Map<String, String>> cards;

  const FlashcardScreen({
    super.key,
    required this.title,
    required this.cards,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  int _currentIndex = 0;
  bool _showingAnswer = false;

  void _nextCard() {
    if (_currentIndex < widget.cards.length - 1) {
      setState(() {
        _currentIndex++;
        _showingAnswer = false;
      });
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _showingAnswer = false;
      });
    }
  }

  void _toggleAnswer() {
    setState(() => _showingAnswer = !_showingAnswer);
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.cards[_currentIndex];
    final progress = (_currentIndex + 1) / widget.cards.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(progress),
            Expanded(
              child: GestureDetector(
                onTap: _toggleAnswer,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildFlashcard(card),
                ),
              ),
            ),
            _buildNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Card ${_currentIndex + 1} of ${widget.cards.length}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.progressBg,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFlashcard(Map<String, String> card) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: NeoCard(
        key: ValueKey('$_currentIndex-$_showingAnswer'),
        color: _showingAnswer ? AppColors.primaryBlue : AppColors.cardBg,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_showingAnswer) ...[
                Text(
                  card['back'] ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, height: 1.4),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Tap to see question',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70),
                ),
              ] else ...[
                Text(
                  card['front'] ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.4),
                ),
                const SizedBox(height: 40),
                const Text(
                  '↓ Tap to reveal ↓',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: NeoButton(
              label: 'Previous',
              outlined: true,
              color: _currentIndex > 0 ? AppColors.textPrimary : AppColors.textSecondary,
              onPressed: _currentIndex > 0 ? _previousCard : () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: NeoButton(
              label: _currentIndex < widget.cards.length - 1 ? 'Next' : 'Done',
              icon: _currentIndex < widget.cards.length - 1 ? Icons.arrow_forward : Icons.check,
              onPressed: _currentIndex < widget.cards.length - 1
                  ? _nextCard
                  : () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
