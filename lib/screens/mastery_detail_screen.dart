import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_button.dart';
import '../models/mastery.dart';
import '../models/quiz_settings.dart';
import '../models/quiz.dart';
import '../services/storage_service.dart';
import '../services/quiz_service.dart';
import 'mastery_quiz_screen.dart';
import 'challenge_quiz_screen.dart';
import 'flashcard_screen.dart';
import 'quiz_settings_screen.dart';

class MasteryDetailScreen extends StatefulWidget {
  final Mastery mastery;

  const MasteryDetailScreen({super.key, required this.mastery});

  @override
  State<MasteryDetailScreen> createState() => _MasteryDetailScreenState();
}

class _MasteryDetailScreenState extends State<MasteryDetailScreen> {
  late Mastery _mastery;
  final TextEditingController _notesController = TextEditingController();
  bool _editingNotes = false;
  bool _generatingFlashcards = false;
  bool _generatingQuiz = false;
  String _loadingText = '';

  @override
  void initState() {
    super.initState();
    _mastery = widget.mastery;
    _notesController.text = _mastery.notes;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final updated = await StorageService.getMastery(_mastery.id);
    if (updated != null && mounted) {
      setState(() {
        _mastery = updated;
        if (!_editingNotes) _notesController.text = _mastery.notes;
      });
    }
  }

  Future<void> _saveNotes() async {
    final notes = _notesController.text.trim();
    final updated = _mastery.copyWith(notes: notes, updatedAt: DateTime.now());
    await StorageService.saveMastery(updated);
    if (mounted) {
      setState(() {
        _mastery = updated;
        _editingNotes = false;
      });
    }
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
              _buildTitleCard(),
              const SizedBox(height: 20),
              _buildMasteryProgress(),
              const SizedBox(height: 20),
              _buildStudyFlowSection(),
              const SizedBox(height: 20),
              _buildChallengeSection(),
              const SizedBox(height: 24),
              NeoButton(
                label: 'Back to Home',
                icon: Icons.home,
                outlined: true,
                color: AppColors.textPrimary,
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
        const Text('Material Detail', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildTitleCard() {
    return NeoCard(
      color: AppColors.primaryBlue,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_mastery.materialTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            '${_mastery.concepts.length} concepts  •  Created ${_formatDate(_mastery.createdAt)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildMasteryProgress() {
    final pct = _mastery.masteryPercent;
    return NeoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Text('${pct.round()}%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryBlue)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 14,
              backgroundColor: AppColors.progressBg,
              valueColor: AlwaysStoppedAnimation<Color>(
                pct >= 100 ? AppColors.success : AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Correct: ${_mastery.totalCorrect} / ${_mastery.totalAttempted}',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyFlowSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Study Tools', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        _buildStudyTile(
          icon: Icons.notes,
          title: 'Study Notes',
          subtitle: _mastery.notes.isNotEmpty ? 'Tap to view or edit' : 'No notes added yet',
          color: AppColors.primaryBlue,
          onTap: _showNotes,
        ),
        const SizedBox(height: 10),
        _buildStudyTile(
          icon: Icons.style,
          title: 'Flashcards',
          subtitle: _generatingFlashcards ? _loadingText : 'Study key concepts',
          color: AppColors.success,
          onTap: _generatingFlashcards ? null : _startFlashcards,
          isLoading: _generatingFlashcards,
        ),
        const SizedBox(height: 10),
        _buildStudyTile(
          icon: Icons.quiz,
          title: 'Take Quiz',
          subtitle: _generatingQuiz ? _loadingText : 'Test your knowledge',
          color: AppColors.warning,
          onTap: _generatingQuiz ? null : _openQuizSettings,
          isLoading: _generatingQuiz,
        ),
        const SizedBox(height: 10),
        _buildStudyTile(
          icon: Icons.bar_chart,
          title: 'View Progress',
          subtitle: '${_mastery.totalCorrect}/${_mastery.totalAttempted} correct',
          color: AppColors.textPrimary,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildStudyTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: NeoCard(
        padding: const EdgeInsets.all(14),
        shadowOffset: 2,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              color: color,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Icon(icon, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: isLoading ? AppColors.primaryBlue : AppColors.textSecondary)),
                ],
              ),
            ),
            if (!isLoading) const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeSection() {
    final pct = _mastery.masteryPercent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Challenge', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        if (pct < 100) ...[
          NeoCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      color: AppColors.textSecondary,
                      child: const Center(child: Icon(Icons.lock, color: Colors.white, size: 24)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Challenge Quiz', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text(
                            'Reach 100% to unlock',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 8,
                    backgroundColor: AppColors.progressBg,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(100 - pct).round()}% more to go',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ] else ...[
          _buildChallengeTile(
            title: 'Challenge Quiz 1',
            subtitle: _mastery.challenge1Unlocked
                ? 'Completed - Score: ${_mastery.challenge1Score}%'
                : 'Ready!',
            unlocked: true,
            completed: _mastery.challenge1Unlocked,
            score: _mastery.challenge1Score,
            challengeNumber: 1,
          ),
          const SizedBox(height: 10),
          _buildChallengeTile(
            title: 'Challenge Quiz 2',
            subtitle: _mastery.challenge2Unlocked
                ? 'Completed - Score: ${_mastery.challenge2Score}%'
                : _mastery.challenge1Unlocked ? 'Complete Challenge 1 first' : 'Locked',
            unlocked: _mastery.challenge1Unlocked,
            completed: _mastery.challenge2Unlocked,
            score: _mastery.challenge2Score,
            challengeNumber: 2,
          ),
        ],
      ],
    );
  }

  Widget _buildChallengeTile({
    required String title,
    required String subtitle,
    required bool unlocked,
    required bool completed,
    required int score,
    required int challengeNumber,
  }) {
    return GestureDetector(
      onTap: unlocked && !completed
          ? () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChallengeQuizScreen(mastery: _mastery, challengeNumber: challengeNumber),
                ),
              );
              _reload();
            }
          : null,
      child: NeoCard(
        padding: const EdgeInsets.all(14),
        shadowOffset: 2,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              color: completed ? AppColors.success : unlocked ? AppColors.primaryBlue : AppColors.textSecondary,
              child: Center(
                child: completed
                    ? const Icon(Icons.check, color: Colors.white, size: 24)
                    : Icon(unlocked ? Icons.play_arrow : Icons.lock, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _showNotes() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildNotesSheet(),
    );
  }

  Widget _buildNotesSheet() {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Your Notes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    Row(
                      children: [
                        if (_editingNotes)
                          GestureDetector(
                            onTap: () async {
                              await _saveNotes();
                              setSheetState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue,
                                border: Border.all(color: AppColors.shadow, width: 1),
                              ),
                              child: const Text('Save', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                          ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border, width: 1.5),
                            ),
                            child: const Center(child: Icon(Icons.close, size: 16, color: AppColors.textPrimary)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _mastery.notes.isEmpty && !_editingNotes
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.note_add, size: 48, color: AppColors.textSecondary),
                            const SizedBox(height: 16),
                            const Text('No notes added yet.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                            const SizedBox(height: 16),
                            NeoButton(
                              label: 'Add Notes',
                              icon: Icons.edit,
                              onPressed: () {
                                setSheetState(() => _editingNotes = true);
                              },
                            ),
                          ],
                        )
                      : TextField(
                          controller: _notesController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          enabled: _editingNotes,
                          onChanged: (_) => setSheetState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Add your notes here...\n\nKey points, formulas, reminders...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6)),
                          ),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.5),
                        ),
                ),
              ),
              if (!_editingNotes && _mastery.notes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: NeoButton(
                    label: 'Edit Notes',
                    icon: Icons.edit,
                    outlined: true,
                    color: AppColors.textPrimary,
                    onPressed: () => setSheetState(() => _editingNotes = true),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startFlashcards() async {
    final existingCards = await StorageService.getFlashcards(_mastery.id);
    if (existingCards.isNotEmpty && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FlashcardScreen(title: _mastery.materialTitle, cards: existingCards),
        ),
      );
      return;
    }

    setState(() {
      _generatingFlashcards = true;
      _loadingText = 'Generating flashcards...';
    });

    try {
      final cards = await QuizService().generateFlashcards(
        content: _mastery.sourceText,
        onProgress: (msg) {
          if (mounted) setState(() => _loadingText = msg);
        },
      );

      if (cards.isNotEmpty) {
        await StorageService.saveFlashcards(_mastery.id, cards);
        if (mounted) {
          setState(() => _generatingFlashcards = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FlashcardScreen(title: _mastery.materialTitle, cards: cards),
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() => _generatingFlashcards = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not generate flashcards.'), backgroundColor: AppColors.error),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _generatingFlashcards = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _openQuizSettings() async {
    final settings = await Navigator.push<QuizSettings>(
      context,
      MaterialPageRoute(
        builder: (_) => QuizSettingsScreen(
          initialSettings: const QuizSettings(
            questionCount: 10,
            difficulty: Difficulty.medium,
            questionType: QuestionType.mixed,
          ),
        ),
      ),
    );

    if (settings != null && mounted) {
      _startQuiz(settings);
    }
  }

  Future<void> _startQuiz(QuizSettings settings) async {
    setState(() {
      _generatingQuiz = true;
      _loadingText = 'Generating quiz...';
    });

    try {
      final questions = await QuizService().generate(
        content: _mastery.sourceText,
        questionCount: settings.questionCount,
        preferredType: settings.questionType,
        difficulty: settings.difficulty,
        onProgress: (msg) {
          if (mounted) setState(() => _loadingText = msg);
        },
      );

      if (!mounted) return;

      if (questions.isEmpty) {
        setState(() => _generatingQuiz = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate questions.'), backgroundColor: AppColors.error),
        );
        return;
      }

      final quiz = Quiz(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _mastery.materialTitle,
        questions: questions,
        settings: settings,
        sourceText: _mastery.sourceText.length > 5000 ? _mastery.sourceText.substring(0, 5000) : _mastery.sourceText,
        masteryId: _mastery.id,
        createdAt: DateTime.now(),
      );
      await StorageService.saveQuiz(quiz);

      setState(() => _generatingQuiz = false);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MasteryQuizScreen(mastery: _mastery, questions: questions),
        ),
      ).then((_) => _reload());
    } catch (e) {
      if (mounted) {
        setState(() => _generatingQuiz = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}
