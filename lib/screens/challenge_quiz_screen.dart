import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_button.dart';
import '../widgets/option_tile.dart';
import '../widgets/progress_indicator.dart';
import '../models/mastery.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';
import '../models/quiz_settings.dart';
import '../services/mastery_tracker.dart';
import '../services/storage_service.dart';
import 'mastery_result_screen.dart';

class ChallengeQuizScreen extends StatefulWidget {
  final Mastery mastery;
  final int challengeNumber;

  const ChallengeQuizScreen({
    super.key,
    required this.mastery,
    required this.challengeNumber,
  });

  @override
  State<ChallengeQuizScreen> createState() => _ChallengeQuizScreenState();
}

class _ChallengeQuizScreenState extends State<ChallengeQuizScreen> {
  int _currentIndex = 0;
  int? _selectedAnswer;
  bool _showingExplanation = false;
  final Map<int, int> _answers = {};
  final TextEditingController _fillController = TextEditingController();
  late Timer _timer;
  int _elapsedSeconds = 0;
  bool _isLoading = true;
  String _loadingText = 'Generating challenge...';
  List<Question> _questions = [];

  @override
  void initState() {
    super.initState();
    _generateChallenge();
  }

  Future<void> _generateChallenge() async {
    final questions = await MasteryTracker().generateChallengeQuestions(
      widget.mastery,
      challengeNumber: widget.challengeNumber,
      onProgress: (msg) {
        if (mounted) setState(() => _loadingText = msg);
      },
    );

    if (mounted) {
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _fillController.dispose();
    super.dispose();
  }

  bool get _isLastQuestion => _currentIndex == _questions.length - 1;
  Question get _currentQuestion => _questions[_currentIndex];

  void _nextQuestion() {
    _saveFillBlank();
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = _answers[_currentIndex];
        _showingExplanation = _answers.containsKey(_currentIndex);
        _fillController.clear();
      });
    }
  }

  void _saveFillBlank() {
    final q = _currentQuestion;
    if (q.type == QuestionType.fillInTheBlank && _fillController.text.trim().isNotEmpty) {
      final userAnswer = _fillController.text.trim().toLowerCase();
      final correctAnswer = q.options[0].toLowerCase();
      _answers[_currentIndex] = userAnswer == correctAnswer ? 0 : -1;
    }
  }

  void _selectAnswer(int index) {
    if (_showingExplanation) return;
    setState(() {
      _selectedAnswer = index;
      _answers[_currentIndex] = index;
      _showingExplanation = true;
    });
  }

  void _confirmAnswer() {
    if (_currentQuestion.type == QuestionType.fillInTheBlank) {
      _saveFillBlank();
      if (!_answers.containsKey(_currentIndex)) return;
    } else if (_selectedAnswer == null) {
      return;
    }
    setState(() => _showingExplanation = true);
  }

  bool _isCorrect(int questionIndex) {
    final q = _questions[questionIndex];
    final userAnswer = _answers[questionIndex] ?? -1;
    if (q.type == QuestionType.fillInTheBlank) return userAnswer == 0;
    return userAnswer == q.answer;
  }

  Future<void> _submitQuiz() async {
    _timer.cancel();
    _saveFillBlank();

    int correct = 0;
    for (var i = 0; i < _questions.length; i++) {
      if (_isCorrect(i)) correct++;
    }

    final scorePercent = (correct / _questions.length * 100).round();
    final updatedMastery = MasteryTracker().processChallengeResult(
      mastery: widget.mastery,
      challengeNumber: widget.challengeNumber,
      scorePercent: scorePercent.toDouble(),
    );

    await StorageService.saveMastery(updatedMastery);

    final result = QuizResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      quizId: '${widget.mastery.id}_challenge${widget.challengeNumber}',
      quizTitle: 'Challenge ${widget.challengeNumber}',
      score: correct,
      totalQuestions: _questions.length,
      topicResults: [],
      completedAt: DateTime.now(),
      timeTakenSeconds: _elapsedSeconds,
      answers: Map<int, int>.from(_answers),
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MasteryResultScreen(
          mastery: updatedMastery,
          result: result,
          questions: _questions,
          answers: _answers,
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  color: AppColors.primaryBlue,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  ),
                ),
                const SizedBox(height: 20),
                Text(_loadingText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                const Text('Could not generate challenge.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                NeoButton(label: 'Go Back', onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];
    const optionLabels = ['A', 'B', 'C', 'D'];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 16),
              _buildChallengeHeader(),
              const SizedBox(height: 16),
              QuestionProgress(current: _currentIndex + 1, total: _questions.length),
              const SizedBox(height: 16),
              _buildQuestionCard(question),
              const SizedBox(height: 16),
              if (question.type == QuestionType.fillInTheBlank)
                _buildFillBlank(question)
              else
                ...List.generate(question.options.length, (i) {
                  final isCorrectAnswer = i == question.answer;
                  final isSelected = _selectedAnswer == i;
                  return OptionTile(
                    label: optionLabels[i],
                    text: question.options[i],
                    isSelected: isSelected,
                    index: i,
                    onTap: () => _selectAnswer(i),
                    showResult: _showingExplanation,
                    isCorrect: isCorrectAnswer,
                  );
                }),
              const SizedBox(height: 16),
              if (_showingExplanation) _buildExplanation(question),
              const SizedBox(height: 16),
              _buildNavigation(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: _showExitDialog,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.textPrimary,
              border: Border.all(color: AppColors.border, width: 1.5),
              boxShadow: const [BoxShadow(color: AppColors.shadow, offset: Offset(2, 2), blurRadius: 0)],
            ),
            child: const Center(child: Icon(Icons.close, size: 20, color: Colors.white)),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              'Challenge ${widget.challengeNumber}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ),
        ),
        NeoCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shadowOffset: 2,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer, size: 16, color: AppColors.primaryBlue),
              const SizedBox(width: 4),
              Text(_formatTime(_elapsedSeconds), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeHeader() {
    return NeoCard(
      color: AppColors.warning,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_fire_department, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            'CHALLENGE ${widget.challengeNumber} — Different questions!',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Question question) {
    return NeoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              border: Border.all(color: AppColors.shadow, width: 1),
            ),
            child: Text(_getTypeLabel(question.type), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          const SizedBox(height: 12),
          Text(question.question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.4)),
        ],
      ),
    );
  }

  String _getTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice: return 'Multiple Choice';
      case QuestionType.trueFalse: return 'True or False';
      case QuestionType.fillInTheBlank: return 'Fill in the Blank';
      case QuestionType.mixed: return 'Mixed';
    }
  }

  Widget _buildFillBlank(Question question) {
    final isAnswered = _answers.containsKey(_currentIndex);
    return Column(
      children: [
        NeoCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: _fillController,
            textCapitalization: TextCapitalization.sentences,
            enabled: !_showingExplanation,
            onSubmitted: (_) => _confirmAnswer(),
            decoration: const InputDecoration(hintText: 'Type your answer...', border: InputBorder.none, hintStyle: TextStyle(color: AppColors.textSecondary)),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(height: 10),
        if (!_showingExplanation)
          SizedBox(width: double.infinity, child: NeoButton(label: isAnswered ? 'Change Answer' : 'Submit Answer', onPressed: _confirmAnswer)),
      ],
    );
  }

  Widget _buildExplanation(Question question) {
    final correct = _isCorrect(_currentIndex);
    return Column(
      children: [
        NeoCard(
          color: correct ? AppColors.success : AppColors.error,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(correct ? Icons.check_circle : Icons.cancel, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(correct ? 'Correct!' : 'Incorrect', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ],
          ),
        ),
        if (!correct) ...[
          const SizedBox(height: 8),
          NeoCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Correct answer: ${question.options[question.answer]}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ),
              ],
            ),
          ),
        ],
        if (question.explanation != null && question.explanation!.isNotEmpty) ...[
          const SizedBox(height: 8),
          NeoCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb, color: AppColors.warning, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(question.explanation!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNavigation() {
    if (_showingExplanation) {
      return NeoButton(
        label: _isLastQuestion ? 'See Results' : 'Next Question',
        icon: _isLastQuestion ? Icons.bar_chart : Icons.arrow_forward,
        onPressed: _isLastQuestion ? () => _submitQuiz() : () => _nextQuestion(),
      );
    }

    if (_currentQuestion.type == QuestionType.fillInTheBlank) {
      return NeoButton(
        label: 'Submit Answer',
        icon: Icons.check,
        onPressed: _confirmAnswer,
      );
    }

    return const SizedBox.shrink();
  }

  void _showExitDialog() {
    final answered = _answers.length;
    final total = _questions.length;
    final hasProgress = answered > 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(side: const BorderSide(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.zero),
        title: const Text('Exit Challenge?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          hasProgress
              ? 'You answered $answered/$total questions. Your progress will be saved.'
              : 'No answers yet. Challenge will be discarded.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              _timer.cancel();
              if (hasProgress) {
                await _saveProgressResult();
              }
              if (context.mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              }
            },
            child: const Text('Exit', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProgressResult() async {
    _saveFillBlank();
    int score = 0;
    for (final entry in _answers.entries) {
      final q = _questions[entry.key];
      if (q.type == QuestionType.fillInTheBlank) {
        if (entry.value == 0) score++;
      } else if (entry.value == q.answer) {
        score++;
      }
    }
    final result = QuizResult(
      id: 'challenge_${widget.challengeNumber}_progress_${DateTime.now().millisecondsSinceEpoch}',
      quizId: 'challenge_${widget.challengeNumber}',
      quizTitle: 'Challenge ${widget.challengeNumber} (Saved)',
      score: score,
      totalQuestions: _questions.length,
      topicResults: [],
      completedAt: DateTime.now(),
      timeTakenSeconds: _elapsedSeconds,
      answers: Map<int, int>.from(_answers),
    );
    await StorageService.saveResult(result);
  }
}
