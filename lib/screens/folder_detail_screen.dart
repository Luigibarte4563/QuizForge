import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/neo_card.dart';
import '../models/mastery.dart';
import '../models/folder.dart';
import '../services/storage_service.dart';
import 'mastery_detail_screen.dart';

class FolderDetailScreen extends StatefulWidget {
  final Folder folder;
  const FolderDetailScreen({super.key, required this.folder});

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  List<Mastery> _materials = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final materials = await StorageService.getMasteryByFolder(widget.folder.id);
    if (mounted) setState(() { _materials = materials; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final colors = [0xFF2563EB, 0xFF16A34A, 0xFFF59E0B, 0xFFDC2626, 0xFF8B5CF6, 0xFFEC4899];
    final color = Color(colors[widget.folder.colorIndex % colors.length]);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.textPrimary,
            shape: const RoundedRectangleBorder(),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(width: 28, height: 28, color: color, child: const Icon(Icons.folder, color: Colors.white, size: 16)),
            const SizedBox(width: 10),
            Text(widget.folder.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _materials.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: AppColors.textSecondary.withAlpha(80)),
                      const SizedBox(height: 16),
                      const Text('This folder is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      const Text('Add materials from the Materials tab', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _materials.length,
                  itemBuilder: (context, i) => _buildMaterialCard(_materials[i]),
                ),
    );
  }

  Widget _buildMaterialCard(Mastery m) {
    final pct = m.masteryPercent;
    final isMastered = m.fullyMastered;
    return Dismissible(
      key: Key(m.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.cardBg,
            title: const Text('Remove from folder?', style: TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Remove', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        await StorageService.moveMasteryToFolder(m.id, null);
        _load();
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => MasteryDetailScreen(mastery: m)))
              .then((_) => _load());
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: NeoCard(
            padding: const EdgeInsets.all(16),
            shadowOffset: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      color: isMastered ? AppColors.success : AppColors.primaryBlue,
                      child: Center(
                        child: isMastered
                            ? const Icon(Icons.star, color: Colors.white, size: 26)
                            : Text('${pct.round()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.materialTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(isMastered ? 'Mastered' : '${m.totalCorrect}/${m.totalAttempted} correct', style: TextStyle(fontSize: 12, color: isMastered ? AppColors.success : AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 24),
                  ],
                ),
                if (!isMastered) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.zero,
                    child: LinearProgressIndicator(value: pct / 100, minHeight: 8, backgroundColor: AppColors.progressBg, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
