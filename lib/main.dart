import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nobodywho/nobodywho.dart' as nobodywho;
import 'app.dart';
import 'screens/welcome_screen.dart';
import 'services/storage_service.dart';

bool nobodyWhoReady = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFFFAF6EE),
    statusBarIconBrightness: Brightness.dark,
  ));
  await StorageService.database;

  final prefs = await SharedPreferences.getInstance();
  final hasOnboarded = prefs.getBool('has_onboarded') ?? false;

  try {
    await nobodywho.NobodyWho.init();
    nobodyWhoReady = true;
  } catch (e) {
    debugPrint('NobodyWho init failed (app will run in offline mode): $e');
  }

  runApp(hasOnboarded ? const QuizForgeApp() : const WelcomeApp());
}

class WelcomeApp extends StatelessWidget {
  const WelcomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuizForge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Inter', scaffoldBackgroundColor: const Color(0xFFFAF6EE)),
      builder: (context, child) {
        return ColoredBox(
          color: const Color(0xFFFAF6EE),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: WelcomeScreen(
        onComplete: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('has_onboarded', true);
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const QuizForgeApp()),
            );
          }
        },
      ),
    );
  }
}
