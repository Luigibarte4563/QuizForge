import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_button.dart';
import '../services/local_ai_service.dart';

class ModelDownloadScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final bool canSkip;
  final String? initialModelKey;

  const ModelDownloadScreen({
    super.key,
    required this.onComplete,
    this.canSkip = true,
    this.initialModelKey,
  });

  @override
  State<ModelDownloadScreen> createState() => _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends State<ModelDownloadScreen>
    with SingleTickerProviderStateMixin {
  double _progress = 0;
  String _statusText = 'Preparing...';
  String? _error;
  bool _isDownloading = false;
  bool _isDone = false;
  bool _cancelled = false;
  String _selectedModel = 'large';
  bool _showPicker = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _selectedModel = widget.initialModelKey ?? LocalAiService().selectedModelKey;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _checkExistingModel();
  }

  @override
  void dispose() {
    _cancelled = true;
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingModel() async {
    final downloaded = await LocalAiService().isModelDownloaded();
    if (downloaded && mounted) {
      setState(() {
        _showPicker = false;
        _isDone = true;
        _statusText = 'AI model ready!';
        _progress = 1.0;
      });
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) widget.onComplete();
    }
  }

  void _selectModelAndDownload(String key) {
    LocalAiService().selectModel(key);
    setState(() {
      _selectedModel = key;
      _showPicker = false;
    });
    _startDownload();
  }

  Future<void> _startDownload() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _error = null;
      _progress = 0;
      _statusText = 'Starting download...';
    });

    try {
      await LocalAiService().downloadModel(
        modelKey: _selectedModel,
        onProgress: (p) {
          if (mounted && !_cancelled) {
            setState(() {
              _progress = p.fraction;
              _statusText = '${p.stage} - ${p.progressPercent.round()}%';
            });
          }
        },
      );

      if (_cancelled) return;

      setState(() {
        _progress = 1.0;
        _statusText = 'Initializing AI model...';
      });

      final initialized = await LocalAiService().initialize();

      if (initialized && mounted) {
        setState(() {
          _isDone = true;
          _statusText = 'AI model ready!';
        });
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) widget.onComplete();
      } else if (mounted) {
        setState(() {
          _error = 'Model downloaded but failed to initialize. The offline generator will be used instead.';
          _isDownloading = false;
        });
      }
    } catch (e) {
      if (mounted && !_cancelled) {
        setState(() {
          _error = 'Download failed: $e';
          _isDownloading = false;
        });
      }
    }
  }

  void _cancel() {
    setState(() {
      _cancelled = true;
      _isDownloading = false;
      _error = 'Download cancelled.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildInfoCard(),
              const SizedBox(height: 20),
              if (_showPicker && !_isDownloading && !_isDone) ...[
                _buildModelPicker(),
              ] else ...[
                _buildModelCard(),
              ],
              const SizedBox(height: 24),
              if (_isDownloading || _isDone) _buildProgressSection(),
              if (_error != null) ...[
                const SizedBox(height: 16),
                _buildError(),
              ],
              if (!_isDownloading && !_isDone && !_showPicker) ...[
                const SizedBox(height: 20),
                _buildActionButtons(),
              ],
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
        if (widget.canSkip)
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: 1.5),
                boxShadow: const [BoxShadow(color: AppColors.shadow, offset: Offset(2, 2), blurRadius: 0)],
              ),
              child: const Center(child: Icon(Icons.arrow_back, size: 20, color: AppColors.textPrimary)),
            ),
          ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            'AI Model Setup',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return NeoCard(
      color: AppColors.primaryBlue,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome to QuizForge', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          SizedBox(height: 6),
          Text(
            'Turn your learning materials into notes, flashcards, and quizzes. Everything works offline after setup.',
            style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildModelPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose Model Size', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text('Pick based on your device. You can change later in Settings.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 14),
        _buildModelPickCard(
          key: 'small',
          title: 'Fast Model',
          subtitle: 'Qwen 3 0.6B • ~500 MB',
          desc: 'Faster, uses less memory. Good for older phones.',
          icon: Icons.speed,
        ),
        const SizedBox(height: 10),
        _buildModelPickCard(
          key: 'large',
          title: 'Better Model',
          subtitle: 'Qwen 3 1.7B • ~1 GB',
          desc: 'Higher quality quizzes and explanations.',
          icon: Icons.star,
        ),
      ],
    );
  }

  Widget _buildModelPickCard({
    required String key,
    required String title,
    required String subtitle,
    required String desc,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () => _selectModelAndDownload(key),
      child: NeoCard(
        padding: const EdgeInsets.all(14),
        shadowOffset: 3,
        child: Row(
          children: [
            Container(width: 44, height: 44, color: AppColors.primaryBlue, child: Center(child: Icon(icon, color: Colors.white, size: 22))),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildModelCard() {
    final modelInfo = LocalAiService.availableModels[_selectedModel]!;
    return NeoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                color: _isDone ? AppColors.success : AppColors.primaryBlue,
                child: Center(
                  child: _isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 28)
                      : const Icon(Icons.smart_toy, color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(modelInfo['displayName']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      _isDone ? 'Ready' : 'Size: ${modelInfo['sizeLabel']!}',
                      style: TextStyle(fontSize: 13, color: _isDone ? AppColors.success : AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildFeatureRow(Icons.phone_android, 'Runs on your device'),
          const SizedBox(height: 6),
          _buildFeatureRow(Icons.wifi_off, 'Works completely offline'),
          const SizedBox(height: 6),
          _buildFeatureRow(Icons.speed, 'Fast quiz generation'),
          const SizedBox(height: 6),
          _buildFeatureRow(Icons.school, 'Educational explanations'),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryBlue),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildProgressSection() {
    final pct = (_progress * 100).round();
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isDone ? 1.0 : _pulseAnimation.value,
              child: child,
            );
          },
          child: Container(
            width: 80,
            height: 80,
            color: _isDone ? AppColors.success : AppColors.primaryBlue,
            child: Center(
              child: _isDone
                  ? const Icon(Icons.check, color: Colors.white, size: 40)
                  : Text('$pct%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(_statusText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.zero,
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 8,
            backgroundColor: AppColors.progressBg,
            valueColor: AlwaysStoppedAnimation<Color>(_isDone ? AppColors.success : AppColors.primaryBlue),
          ),
        ),
        if (!_isDone && _error == null) ...[
          const SizedBox(height: 20),
          NeoButton(label: 'Cancel', icon: Icons.close, outlined: true, color: AppColors.textSecondary, onPressed: _cancel),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    final modelInfo = LocalAiService.availableModels[_selectedModel]!;
    return Column(
      children: [
        NeoButton(
          label: 'Download ${modelInfo['displayName']!} (${modelInfo['sizeLabel']!})',
          icon: Icons.download,
          onPressed: _startDownload,
        ),
        if (widget.canSkip) ...[
          const SizedBox(height: 10),
          NeoButton(label: 'Skip for Now', icon: Icons.arrow_forward, outlined: true, color: AppColors.textSecondary, onPressed: widget.onComplete),
        ],
      ],
    );
  }

  Widget _buildError() {
    return NeoCard(
      color: AppColors.error,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    NeoButton(label: 'Retry', onPressed: _startDownload, color: Colors.white, textColor: AppColors.error),
                    const SizedBox(width: 8),
                    if (widget.canSkip)
                      NeoButton(label: 'Skip', onPressed: widget.onComplete, color: Colors.white, textColor: AppColors.error),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
