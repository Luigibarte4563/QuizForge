import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_button.dart';
import '../widgets/option_tile.dart';
import '../widgets/progress_indicator.dart';
import '../models/quiz.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';
import '../models/quiz_settings.dart';
import '../services/storage_service.dart';
import 'results_screen.dart';

class QuizScreen extends StatefulWidget {
  final Quiz quiz;

  const QuizScreen({super.key, required this.quiz});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  int? _selectedAnswer;
  bool _showingExplanation = false;
  final Map<int, int> _answers = {};
  final TextEditingController _fillController = TextEditingController();
  late Timer _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
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

  bool get _isLastQuestion => _currentIndex == widget.quiz.questions.length - 1;
  bool get _allAnswered => _answers.length == widget.quiz.questions.length;

  void _nextQuestion() {
    _saveFillBlank();
    if (_currentIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = _answers[_currentIndex];
        _showingExplanation = false;
        _fillController.clear();
      });
      _restoreFillBlank();
    }
  }

  void _previousQuestion() {
    _saveFillBlank();
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _selectedAnswer = _answers[_currentIndex];
        _showingExplanation = _answers.containsKey(_currentIndex);
        _fillController.clear();
      });
      _restoreFillBlank();
    }
  }

  void _saveFillBlank() {
    final q = widget.quiz.questions[_currentIndex];
    if (q.type == QuestionType.fillInTheBlank && _fillController.text.trim().isNotEmpty) {
      final userAnswer = _fillController.text.trim().toLowerCase();
      final correctAnswer = q.options[0].toLowerCase();
      _answers[_currentIndex] = userAnswer == correctAnswer ? 0 : -1;
    }
  }

  void _restoreFillBlank() {
    final q = widget.quiz.questions[_currentIndex];
    if (q.type == QuestionType.fillInTheBlank && _answers.containsKey(_currentIndex)) {
      if (_answers[_currentIndex] == 0) {
        _fillController.text = q.options[0];
      }
    }
  }

  void _selectAnswer(int index) {
    if (_showingExplanation) return;
    setState(() {
      _selectedAnswer = index;
      _answers[_currentIndex] = index;
    });
  }

  void _confirmAnswer() {
    if (_selectedAnswer == null && _fillController.text.trim().isEmpty) return;
    _saveFillBlank();
    setState(() => _showingExplanation = true);
  }

  bool _isCorrect(int questionIndex) {
    final q = widget.quiz.questions[questionIndex];
    final userAnswer = _answers[questionIndex] ?? -1;
    if (q.type == QuestionType.fillInTheBlank) return userAnswer == 0;
    return userAnswer == q.answer;
  }

  Future<void> _submitQuiz() async {
    _timer.cancel();
    _saveFillBlank();

    final questions = widget.quiz.questions;
    int score = 0;
    final Map<String, int> topicCorrect = {};
    final Map<String, int> topicTotal = {};

    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final userAnswer = _answers[i] ?? -1;
      bool isCorrect = false;

      if (q.type == QuestionType.fillInTheBlank) {
        isCorrect = userAnswer == 0;
      } else {
        isCorrect = userAnswer == q.answer;
      }

      if (isCorrect) score++;

      topicTotal[q.topic] = (topicTotal[q.topic] ?? 0) + 1;
      if (isCorrect) {
        topicCorrect[q.topic] = (topicCorrect[q.topic] ?? 0) + 1;
      }
    }

    final topicResults = topicTotal.entries.map((e) {
      return TopicResult(
        topic: e.key,
        correct: topicCorrect[e.key] ?? 0,
        total: e.value,
      );
    }).toList();

    final result = QuizResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      quizId: widget.quiz.id,
      quizTitle: widget.quiz.title,
      score: score,
      totalQuestions: questions.length,
      topicResults: topicResults,
      completedAt: DateTime.now(),
      timeTakenSeconds: _elapsedSeconds,
      answers: Map<int, int>.from(_answers),
    );

    await StorageService.saveResult(result);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreen(result: result, quiz: widget.quiz),
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
    final question = widget.quiz.questions[_currentIndex];
    const optionLabels = ['A', 'B', 'C', 'D'];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 20),
              QuestionProgress(current: _currentIndex + 1, total: widget.quiz.questions.length),
              const SizedBox(height: 20),
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
              const SizedBox(height: 20),
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
              boxShadow: const [
                BoxShadow(color: AppColors.shadow, offset: Offset(2, 2), blurRadius: 0),
              ],
            ),
            child: const Center(child: Icon(Icons.close, size: 20, color: Colors.white)),          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              widget.quiz.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
              Text(
                _formatTime(_elapsedSeconds),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ],
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
            child: Text(
              question.type == QuestionType.fillInTheBlank
                  ? 'Fill in the Blank'
                  : question.type == QuestionType.trueFalse
                      ? 'True or False'
                      : 'Multiple Choice',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
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
            decoration: const InputDecoration(
              hintText: 'Type your answer...',
              border: InputBorder.none,
              hintStyle: TextStyle(color: AppColors.textSecondary),
            ),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (!_showingExplanation)
          SizedBox(
            width: double.infinity,
            child: NeoButton(
              label: isAnswered ? 'Change Answer' : 'Submit Answer',
              icon: isAnswered ? Icons.edit : null,
              onPressed: _confirmAnswer,
            ),
          ),
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
              Icon(
                correct ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  correct ? 'Correct!' : 'Incorrect',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                ),
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
                  child: Text(
                    'Correct answer: ${question.options[question.answer]}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
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
                  child: Text(
                    question.explanation!,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4),
                  ),
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
        onPressed: _isLastQuestion ? _submitQuiz : _nextQuestion,
      );
    }

    return Row(
      children: [
        if (_currentIndex > 0)
          Expanded(
            child: NeoButton(
              label: 'Previous',
              outlined: true,
              color: AppColors.textSecondary,
              onPressed: _previousQuestion,
            ),
          ),
        if (_currentIndex > 0) const SizedBox(width: 12),
        Expanded(
          child: NeoButton(
            label: _isLastQuestion ? 'Submit Quiz' : 'Next',
            icon: _isLastQuestion ? Icons.check : Icons.arrow_forward,
            onPressed: _isLastQuestion
                ? (_allAnswered ? () => _submitQuiz() : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please answer all questions!'),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                  })
                : (_selectedAnswer != null
                    ? () => _nextQuestion()
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select an answer first!'),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                      }),
          ),
        ),
      ],
    );
  }

  void _showExitDialog() {
    final answered = _answers.length;
    final total = widget.quiz.questions.length;
    final hasProgress = answered > 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.border, width: 1.5),
          borderRadius: BorderRadius.zero,
        ),
        title: const Text('Exit Quiz?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          hasProgress
              ? 'You answered $answered/$total questions. Your progress will be saved.'
              : 'No answers yet. Quiz will be discarded.',
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
      final q = widget.quiz.questions[entry.key];
      if (q.type == QuestionType.fillInTheBlank) {
        if (entry.value == 0) score++;
      } else if (entry.value == q.answer) {
        score++;
      }
    }
    final result = QuizResult(
      id: '${widget.quiz.id}_progress_${DateTime.now().millisecondsSinceEpoch}',
      quizId: widget.quiz.id,
      quizTitle: '${widget.quiz.title} (Saved)',
      score: score,
      totalQuestions: widget.quiz.questions.length,
      topicResults: [],
      completedAt: DateTime.now(),
      timeTakenSeconds: _elapsedSeconds,
      answers: Map<int, int>.from(_answers),
    );
    await StorageService.saveResult(result);
  }
}
