import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:reading_app/services/auth_service.dart';
import 'package:reading_app/services/settings_service.dart';
import 'package:reading_app/screens/pdf_conversion_screen.dart';
import 'package:reading_app/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final SettingsService _settingsService = SettingsService();
  final List<String> _readingSites = [
    'https://mangadex.org',
    'https://www.webnovel.com',
    'https://www.royalroad.com',
    'https://openlibrary.org',
  ];

  String _selectedUrl = 'https://openlibrary.org';
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
          },
        ),
      )
      ..loadRequest(Uri.parse(_selectedUrl));
  }

  void _safeNavigateAfterLogout() {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  // Helper method to determine text color based on background brightness
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
        backgroundColor: _settingsService
            .backgroundColor, // Use background color for app bar
        iconTheme: IconThemeData(
          color: _getTextColorForBackground(
            _settingsService.backgroundColor,
          ), // Set icon color
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.picture_as_pdf,
              color: _getTextColorForBackground(
                _settingsService.backgroundColor,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PdfConversionScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.settings,
              color: _getTextColorForBackground(
                _settingsService.backgroundColor,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) {
                // Refresh the screen when returning from settings to update colors
                if (mounted) {
                  setState(() {});
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              Icons.exit_to_app,
              color: _getTextColorForBackground(
                _settingsService.backgroundColor,
              ),
            ),
            onPressed: () async {
              await _authService.logout();
              _safeNavigateAfterLogout();
            },
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
                  color: _getTextColorForBackground(
                    _settingsService.sidebarColor,
                  ),
                  fontSize: 24,
                ),
              ),
            ),
            ..._readingSites.map(
              (url) => ListTile(
                title: Text(
                  Uri.parse(url).host,
                  style: TextStyle(
                    color: _getTextColorForBackground(
                      _settingsService.sidebarColor,
                    ),
                  ),
                ),
                onTap: () {
                  setState(() => _selectedUrl = url);
                  _webViewController.loadRequest(Uri.parse(url));
                  Navigator.pop(context);
                },
              ),
            ),
            Divider(
              // ignore: deprecated_member_use
              color: _getTextColorForBackground(
                _settingsService.sidebarColor,
                // ignore: deprecated_member_use
              ).withOpacity(0.3),
            ),
            ListTile(
              leading: Icon(
                Icons.picture_as_pdf,
                color: _getTextColorForBackground(
                  _settingsService.sidebarColor,
                ),
              ),
              title: Text(
                'PDF to Text Converter',
                style: TextStyle(
                  color: _getTextColorForBackground(
                    _settingsService.sidebarColor,
                  ),
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
            ListTile(
              leading: Icon(
                Icons.settings,
                color: _getTextColorForBackground(
                  _settingsService.sidebarColor,
                ),
              ),
              title: Text(
                'Settings',
                style: TextStyle(
                  color: _getTextColorForBackground(
                    _settingsService.sidebarColor,
                  ),
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
