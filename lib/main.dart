import 'package:flutter/material.dart';
import 'package:reading_app/screens/login_screen.dart';
import 'package:reading_app/screens/home_screen.dart';
import 'package:reading_app/services/auth_service.dart';
import 'package:reading_app/services/settings_service.dart';




//Remember to add option to change password by sending a code to the chosen email and make it so the history persists on the 

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
        primarySwatch: Colors.blue, // This will be overridden by appBarTheme
        appBarTheme: AppBarTheme(
          backgroundColor: settingsService
              .backgroundColor, // Use background color for app bar
          foregroundColor: _getTextColorForBackground(
            settingsService.backgroundColor,
          ), // Adaptive text color
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: settingsService.backgroundColor,
      ),
      home: FutureBuilder(
        future: AuthService().isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(settingsService.fontScale),
              ),
              child: snapshot.data == true
                  ? const HomeScreen()
                  : const LoginScreen(),
            );
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
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

  // Helper method to determine text color based on background brightness
  Color _getTextColorForBackground(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
  }
}
