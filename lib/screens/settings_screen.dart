import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_button.dart';
import '../services/local_ai_service.dart';
import '../services/file_extraction_service.dart';
import 'model_download_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _modelReady = false;
  int _modelSize = 0;

  @override
  void initState() {
    super.initState();
    _loadModelInfo();
  }

  Future<void> _loadModelInfo() async {
    final ready = await LocalAiService().isModelDownloaded();
    final size = await LocalAiService().getModelFileSize();
    if (mounted) {
      setState(() {
        _modelReady = ready;
        _modelSize = size;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Settings', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
            const SizedBox(height: 24),
            _buildAboutCard(),
            const SizedBox(height: 12),
            _buildAiModelCard(),
            const SizedBox(height: 12),
            _buildInfoCard('How it works', [
              'Upload any learning material (PDF, Word, PowerPoint, Excel, images, and more)',
              'Text is extracted locally on your device using advanced parsers',
              'A local AI model generates questions and explanations on your phone',
              'No internet connection is ever required',
              'Everything runs 100% offline on your device',
            ]),
            const SizedBox(height: 12),
            _buildInfoCard('Supported Formats', [
              ...FileExtractionService.supportedExtensions.map((ext) =>
                '$ext - ${FileExtractionService.getFileTypeLabel('file$ext')}'),
            ]),
            const SizedBox(height: 12),
            _buildInfoCard('AI Model', [
              'Qwen 3 1.7B Instruct (Q4_K_M quantization)',
              'Runs entirely on your device',
              'Generates quiz questions from your material',
              'Provides educational explanations',
              'No data ever leaves your phone',
            ]),
            const SizedBox(height: 12),
            _buildInfoCard('Privacy', [
              'Everything runs on your device',
              'No data is sent to any server',
              'AI model runs locally in memory',
              'Quizzes stored in local SQLite database',
              'Delete anytime by swiping on My Quizzes',
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
    return NeoCard(
      color: AppColors.primaryBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('QuizForge v3.0', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 4),
          const Text('Offline AI Learning Assistant', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
          const SizedBox(height: 12),
          Text(
            _modelReady
                ? 'AI model ready. Upload any learning material and generate quizzes with explanations instantly.'
                : 'Upload learning materials and generate quizzes. Download the AI model for better questions and explanations.',
            style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildAiModelCard() {
    final sizeLabel = _modelSize > 0 ? '${(_modelSize / (1024 * 1024)).toStringAsFixed(0)} MB' : 'Not downloaded';

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
                      _modelReady ? 'Qwen 3 1.7B - Ready' : 'Qwen 3 1.7B - $sizeLabel',
                      style: TextStyle(
                        fontSize: 13,
                        color: _modelReady ? AppColors.success : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_modelReady) ...[
            NeoButton(
              label: 'AI Model Ready',
              icon: Icons.check_circle,
              color: AppColors.success,
              onPressed: () {},
            ),
          ] else ...[
            NeoButton(
              label: 'Download AI Model (~1 GB)',
              icon: Icons.download,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ModelDownloadScreen(
                      onComplete: () {
                        Navigator.pop(context);
                        _loadModelInfo();
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
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
