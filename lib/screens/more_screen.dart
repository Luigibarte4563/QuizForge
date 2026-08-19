import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/neo_card.dart';
import '../services/local_ai_service.dart';
import '../services/file_extraction_service.dart';
import '../services/storage_service.dart';
import '../models/quiz_result.dart';
import 'model_download_screen.dart';
import 'result_detail_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  bool _modelReady = false;
  List<QuizResult> _recentResults = [];

  @override
  void initState() {
    super.initState();
    _checkModel();
    _loadResults();
  }

  Future<void> _checkModel() async {
    final ready = await LocalAiService().isModelDownloaded();
    if (mounted) setState(() => _modelReady = ready);
  }

  Future<void> _loadResults() async {
    final results = await StorageService.getAllResults();
    if (mounted) setState(() => _recentResults = results.take(10).toList());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('More', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
            const SizedBox(height: 24),
            _buildSectionTitle('AI Model'),
            const SizedBox(height: 12),
            _buildAiModelCard(),
            const SizedBox(height: 20),
            _buildSectionTitle('Recent Results'),
            const SizedBox(height: 12),
            if (_recentResults.isEmpty)
              NeoCard(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.bar_chart, size: 40, color: AppColors.textSecondary.withAlpha(80)),
                      const SizedBox(height: 8),
                      const Text('No quiz results yet', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              )
            else
              ..._recentResults.map((r) => _buildResultCard(r)),
            const SizedBox(height: 20),
            _buildSectionTitle('About'),
            const SizedBox(height: 12),
            _buildInfoCard('How it works', [
              'Upload any learning material',
              'Text is extracted on your device',
              'AI generates questions and explanations locally',
              'No internet connection required',
              'Everything runs 100% offline',
            ]),
            const SizedBox(height: 12),
            _buildInfoCard('Supported Formats', [
              ...FileExtractionService.supportedExtensions.map((ext) =>
                '$ext - ${FileExtractionService.getFileTypeLabel('file$ext')}'),
            ]),
            const SizedBox(height: 12),
            _buildInfoCard('Privacy', [
              'Everything runs on your device',
              'No data is sent to any server',
              'AI model runs locally in memory',
              'Quizzes stored in local database',
              'Delete anytime by swiping',
            ]),
            const SizedBox(height: 12),
            _buildInfoCard('QuizForge', [
              'Version 4.0',
              'Offline AI Learning Assistant',
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary));
  }

  Widget _buildResultCard(QuizResult r) {
    final pct = r.totalQuestions > 0 ? (r.score / r.totalQuestions * 100).round() : 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () async {
          final quiz = await StorageService.getQuiz(r.quizId);
          if (!mounted) return;
          if (quiz == null) return;
          Navigator.push(context, MaterialPageRoute(builder: (_) => ResultDetailScreen(result: r, quiz: quiz)))
              .then((_) => _loadResults());
        },
        child: NeoCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                color: pct >= 80 ? AppColors.success : pct >= 50 ? AppColors.warning : AppColors.error,
                child: Center(
                  child: Text('$pct%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.quizTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${r.score}/${r.totalQuestions} correct', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiModelCard() {
    final modelInfo = LocalAiService.availableModels[LocalAiService().selectedModelKey]!;
    return NeoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                color: _modelReady ? AppColors.success : AppColors.textSecondary,
                child: Center(
                  child: _modelReady
                      ? const Icon(Icons.check, color: Colors.white, size: 24)
                      : const Icon(Icons.download, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI Model', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      _modelReady ? 'Running locally on your device' : 'Not installed',
                      style: TextStyle(fontSize: 13, color: _modelReady ? AppColors.success : AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildDetailRow('Status', _modelReady ? 'Ready' : 'Not downloaded'),
          const SizedBox(height: 6),
          _buildDetailRow('Model', modelInfo['displayName']!),
          const SizedBox(height: 6),
          _buildDetailRow('Model Size', modelInfo['sizeLabel']!),
          const SizedBox(height: 6),
          _buildDetailRow('Internet Required', 'No (after download)'),
          if (!_modelReady) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ModelDownloadScreen(
                      onComplete: () {
                        Navigator.pop(context);
                        _checkModel();
                      },
                    ),
                  ),
                );
              },
              child: NeoCard(
                padding: const EdgeInsets.all(14),
                color: AppColors.primaryBlue,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.download, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('Download ${modelInfo['displayName']!} (${modelInfo['sizeLabel']!})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<String> items) {
    return NeoCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 14, color: AppColors.primaryBlue, fontWeight: FontWeight.w700)),
                Expanded(
                  child: Text(item, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
