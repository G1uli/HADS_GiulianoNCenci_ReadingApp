import 'package:flutter/material.dart';
import 'package:reading_app/screens/login_screen.dart';
import 'package:reading_app/screens/home_screen.dart';
import 'package:reading_app/services/auth_service.dart';
import 'package:reading_app/services/settings_service.dart';

void main() async {
  // Initialize settings first
  final settingsService = SettingsService();
  await settingsService.initialize();

  runApp(ReadingApp(settingsService: settingsService));
}

class ReadingApp extends StatelessWidget {
  final SettingsService settingsService;

  const ReadingApp({super.key, required this.settingsService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reading App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          backgroundColor: settingsService.backgroundColor,
          foregroundColor: _getTextColorForBackground(
            settingsService.backgroundColor,
          ),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: settingsService.backgroundColor,
      ),
      home: AppLoadingScreen(settingsService: settingsService),
      routes: {
        '/home': (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(settingsService.fontScale)),
          child: const HomeScreen(),
        ),
      },
    );
  }

  Color _getTextColorForBackground(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
  }
}

class AppLoadingScreen extends StatefulWidget {
  final SettingsService settingsService;

  const AppLoadingScreen({super.key, required this.settingsService});

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();
  }

  Future<void> _initializeApp() async {
    // Simulate minimum loading time for better UX
    await Future.wait([
      AuthService().isLoggedIn(),
      Future.delayed(const Duration(milliseconds: 2000)), // Minimum 2 seconds
    ]);

    final isLoggedIn = await AuthService().isLoggedIn();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(widget.settingsService.fontScale),
            ),
            child: isLoggedIn ? const HomeScreen() : const LoginScreen(),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade700,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Logo
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // App Name with Fade Animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'Reading App',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Tagline
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'Your Personal Reading Companion',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 50),

              // Animated Loading Indicator
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    children: [
                      Center(
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.8),
                            ),
                            backgroundColor: Colors.white.withOpacity(0.2),
                          ),
                        ),
                      ),
                      Center(
                        child: Icon(
                          Icons.auto_stories_rounded,
                          size: 20,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Loading Text
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'Preparing your reading experience...',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ),

              // Version Info (optional)
              const SizedBox(height: 40),
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'Version 1.0.0',
                  style: TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
