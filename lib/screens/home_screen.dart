import 'package:flutter/material.dart';
import 'package:reading_app/screens/accounts_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../services/database_service.dart';
import '../models/reading_history.dart';
import '../screens/pdf_conversion_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final SettingsService _settingsService = SettingsService();
  final DatabaseService _databaseService = DatabaseService();
  final List<String> _readingSites = [
    'https://mangadex.org',
    'https://www.webnovel.com',
    'https://www.royalroad.com',
  ];

  String _selectedUrl = 'https://mangadex.org';
  late final WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            // Auto-save the reading session when page loads
            _autoSaveReadingSession(url);
          },
        ),
      )
      ..loadRequest(Uri.parse(_selectedUrl));
  }

  Future<void> _autoSaveReadingSession(String url) async {
    // Check if this URL is already saved
    final existingSession = await _databaseService.getSessionByUrl(url);
    if (existingSession == null) {
      // Auto-save with page title as the title
      final session = ReadingHistory(
        url: url,
        title: _getPageTitleFromUrl(url),
        timestamp: DateTime.now(),
      );
      await _databaseService.addReadingSession(session);
    }
  }

  String _getPageTitleFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host;
      // Create a readable title from the URL
      return host
          .replaceAll('www.', '')
          .replaceAll('.com', '')
          .replaceAll('.org', '');
    } catch (e) {
      return 'Unknown Site';
    }
  }

  Future<void> _saveCurrentSessionAsFavorite() async {
    final title = await _showSaveDialog();
    if (title != null) {
      final session = ReadingHistory(
        url: _selectedUrl,
        title: title,
        timestamp: DateTime.now(),
        isFavorite: true,
      );
      await _databaseService.addReadingSession(session);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session saved as favorite!')),
        );
      }
    }
  }

  Future<String?> _showSaveDialog() async {
    TextEditingController titleController = TextEditingController();
    titleController.text = _getPageTitleFromUrl(_selectedUrl);

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Reading Session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pause the reading session?'),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Session Title',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, titleController.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _safeNavigateAfterLogout() {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  Color _getTextColorForBackground(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reading App',
          style: TextStyle(
            color: _getTextColorForBackground(_settingsService.backgroundColor),
          ),
        ),
        backgroundColor: _settingsService.backgroundColor,
        iconTheme: IconThemeData(
          color: _getTextColorForBackground(_settingsService.backgroundColor),
        ),
        actions: [
          // Save Current Session button
          IconButton(
            icon: Icon(
              Icons.favorite,
              color: _getTextColorForBackground(_settingsService.backgroundColor),
            ),
            onPressed: _saveCurrentSessionAsFavorite,
            tooltip: 'Save Current Session',
          ),
          // PDF Converter button
          IconButton(
            icon: Icon(
              Icons.picture_as_pdf,
              color: _getTextColorForBackground(_settingsService.backgroundColor),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PdfConversionScreen(),
                ),
              );
            },
            tooltip: 'PDF to Text Converter',
          ),
          // Settings button
          IconButton(
            icon: Icon(
              Icons.settings,
              color: _getTextColorForBackground(_settingsService.backgroundColor),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) {
                if (mounted) {
                  setState(() {});
                }
              });
            },
            tooltip: 'Settings',
          ),
          // Logout button
          IconButton(
            icon: Icon(
              Icons.exit_to_app,
              color: _getTextColorForBackground(_settingsService.backgroundColor),
            ),
            onPressed: () async {
              await _authService.logout();
              _safeNavigateAfterLogout();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: _settingsService.sidebarColor,
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: _settingsService.sidebarColor.withOpacity(0.8),
              ),
              child: Text(
                'Reading Sites', 
                style: TextStyle(
                  color: _getTextColorForBackground(_settingsService.sidebarColor),
                  fontSize: 24,
                ),
              ),
            ),
            
            // History Button
            ListTile(
              leading: Icon(
                Icons.history,
                color: _getTextColorForBackground(_settingsService.sidebarColor),
              ),
              title: Text(
                'Reading History',
                style: TextStyle(
                  color: _getTextColorForBackground(_settingsService.sidebarColor),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoryScreen(),
                  ),
                );
              },
            ),

            const Divider(),

            // Reading Sites
            ..._readingSites.map(
              (url) => ListTile(
                title: Text(
                  Uri.parse(url).host,
                  style: TextStyle(
                    color: _getTextColorForBackground(_settingsService.sidebarColor),
                  ),
                ),
                onTap: () {
                  setState(() => _selectedUrl = url);
                  _webViewController.loadRequest(Uri.parse(url));
                  Navigator.pop(context);
                },
              ),
            ),

            const Divider(),

            // PDF Converter
            ListTile(
              leading: Icon(
                Icons.picture_as_pdf,
                color: _getTextColorForBackground(_settingsService.sidebarColor),
              ),
              title: Text(
                'PDF to Text Converter',
                style: TextStyle(
                  color: _getTextColorForBackground(_settingsService.sidebarColor),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PdfConversionScreen(),
                  ),
                );
              },
            ),

            // Registered Accounts
            ListTile(
              leading: Icon(
                Icons.people,
                color: _getTextColorForBackground(_settingsService.sidebarColor),
              ),
              title: Text(
                'Registered Accounts',
                style: TextStyle(
                  color: _getTextColorForBackground(_settingsService.sidebarColor),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccountsScreen(),
                  ),
                );
              },
            ),

            // Settings
            ListTile(
              leading: Icon(
                Icons.settings,
                color: _getTextColorForBackground(_settingsService.sidebarColor),
              ),
              title: Text(
                'Settings',
                style: TextStyle(
                  color: _getTextColorForBackground(_settingsService.sidebarColor),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                ).then((_) {
                  if (mounted) {
                    setState(() {});
                  }
                });
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isLoading) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}