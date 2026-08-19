import 'package:flutter/material.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/materials_screen.dart';
import 'screens/more_screen.dart';
import 'screens/model_download_screen.dart';
import 'services/local_ai_service.dart';

class QuizForgeApp extends StatelessWidget {
  const QuizForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuizForge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      builder: (context, child) {
        return ColoredBox(
          color: AppColors.background,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    MaterialsScreen(),
    MoreScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkAiModel();
  }

  Future<void> _checkAiModel() async {
    final downloaded = await LocalAiService().isModelDownloaded();
    if (mounted && !downloaded) {
      _showModelDownloadPrompt();
    }
  }

  void _showModelDownloadPrompt() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(top: BorderSide(width: 1.5, color: AppColors.border)),
          ),
          child: ModelDownloadScreen(
            canSkip: true,
            onComplete: () {
              Navigator.pop(context);
            },
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(width: 1.5, color: Color(0xFF1A1A1A))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFFFAF6EE),
          selectedItemColor: const Color(0xFF2563EB),
          unselectedItemColor: const Color(0xFF6B7280),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.folder_outlined), activeIcon: Icon(Icons.folder), label: 'Materials'),
            BottomNavigationBarItem(icon: Icon(Icons.more_horiz_outlined), activeIcon: Icon(Icons.more_horiz), label: 'More'),
          ],
        ),
      ),
    );
  }
}
