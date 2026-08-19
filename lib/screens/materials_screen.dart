import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../theme/app_colors.dart';
import '../widgets/neo_card.dart';
import '../models/mastery.dart';
import '../models/folder.dart';
import '../services/storage_service.dart';
import 'mastery_detail_screen.dart';
import 'folder_detail_screen.dart';
import 'material_analysis_screen.dart';
import 'paste_text_screen.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  List<Folder> _folders = [];
  List<Mastery> _uncategorized = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final folders = await StorageService.getAllFolders();
    final uncategorized = await StorageService.getMasteryByFolder(null);
    if (mounted) {
      setState(() {
        _folders = folders;
        _uncategorized = uncategorized;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Text('My Materials', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : (_folders.isEmpty && _uncategorized.isEmpty)
                        ? _buildEmpty()
                        : _buildContent(),
              ),
            ],
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              onPressed: _showAddMenu,
              child: const Icon(Icons.add, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.cardBg,
            border: Border(top: BorderSide(width: 1.5, color: AppColors.border)),
            boxShadow: [BoxShadow(color: AppColors.shadow, offset: Offset(2, 2), blurRadius: 0)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, color: AppColors.border),
              const SizedBox(height: 16),
              const Text('Add Material', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              _buildAddOption(
                icon: Icons.create_new_folder,
                label: 'New Folder',
                color: AppColors.primaryBlue,
                onTap: () { Navigator.pop(ctx); _createFolder(); },
              ),
              _buildAddOption(
                icon: Icons.upload_file,
                label: 'Upload File',
                color: AppColors.success,
                onTap: () { Navigator.pop(ctx); _uploadFile(); },
              ),
              _buildAddOption(
                icon: Icons.content_paste,
                label: 'Paste Text',
                color: AppColors.warning,
                onTap: () { Navigator.pop(ctx); _pasteText(); },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddOption({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(width: 40, height: 40, color: color, child: Center(child: Icon(icon, color: Colors.white, size: 22))),
      title: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      onTap: onTap,
    );
  }

  void _createFolder() {
    final controller = TextEditingController();
    int selectedColor = 0;
    final colors = [0xFF2563EB, 0xFF16A34A, 0xFFF59E0B, 0xFFDC2626, 0xFF8B5CF6, 0xFFEC4899];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape: const Border(top: BorderSide(width: 1.5, color: AppColors.border), left: BorderSide(width: 1.5, color: AppColors.border), right: BorderSide(width: 2.5, color: AppColors.border), bottom: BorderSide(width: 2.5, color: AppColors.border)),
          title: const Text('New Folder', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Folder name',
                  border: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: List.generate(colors.length, (i) => GestureDetector(
                  onTap: () => setDialogState(() => selectedColor = i),
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    color: Color(colors[i]),
                    child: selectedColor == i
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                )),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) return;
                await StorageService.saveFolder(Folder(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: controller.text.trim(),
                  colorIndex: selectedColor,
                  createdAt: DateTime.now(),
                ));
                if (mounted) { Navigator.pop(ctx); _load(); }
              },
              child: const Text('Create', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc', 'pptx', 'ppt', 'xlsx', 'xls', 'csv', 'txt', 'rtf', 'html', 'htm', 'json'],
      );
      if (result == null || result.files.isEmpty || !mounted) return;
    final file = File(result.files.first.path!);
    final fileName = result.files.first.name;

    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => MaterialAnalysisScreen(file: file, fileName: fileName)))
        .then((_) => _load());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _pasteText() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PasteTextScreen()))
        .then((_) => _load());
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: AppColors.textSecondary.withAlpha(80)),
          const SizedBox(height: 16),
          const Text('No materials yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Tap + to add a file, paste text, or create a folder', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
      children: [
        if (_folders.isNotEmpty) ...[
          const Text('Folders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          ..._folders.map((f) => _buildFolderCard(f)),
          const SizedBox(height: 20),
        ],
        if (_uncategorized.isNotEmpty) ...[
          const Text('Materials', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          ..._uncategorized.map((m) => _buildMaterialCard(m)),
        ],
      ],
    );
  }

  Widget _buildFolderCard(Folder folder) {
    final colors = [0xFF2563EB, 0xFF16A34A, 0xFFF59E0B, 0xFFDC2626, 0xFF8B5CF6, 0xFFEC4899];
    final color = Color(colors[folder.colorIndex % colors.length]);

    return Dismissible(
      key: Key('folder_${folder.id}'),
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
            title: const Text('Delete Folder?', style: TextStyle(fontWeight: FontWeight.w800)),
            content: Text('Materials inside "${folder.name}" will be moved to uncategorized.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        await StorageService.deleteFolder(folder.id);
        _load();
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => FolderDetailScreen(folder: folder)))
              .then((_) => _load());
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: NeoCard(
            padding: const EdgeInsets.all(16),
            shadowOffset: 2,
            child: Row(
              children: [
                Container(width: 48, height: 48, color: color, child: const Icon(Icons.folder, color: Colors.white, size: 26)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(folder.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(folder.name, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 24),
              ],
            ),
          ),
        ),
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
      onDismissed: (_) async {
        await StorageService.deleteMasteryCascade(m.id);
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
                            : Text(
                                '${pct.round()}%',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.materialTitle,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isMastered ? 'Mastered' : '${m.totalCorrect}/${m.totalAttempted} correct',
                            style: TextStyle(fontSize: 12, color: isMastered ? AppColors.success : AppColors.textSecondary),
                          ),
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
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 8,
                      backgroundColor: AppColors.progressBg,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                    ),
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
