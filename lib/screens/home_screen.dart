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

  // Predefined sites that cannot be removed
  final List<String> _predefinedSites = [
    'https://mangadex.org',
    'https://www.webnovel.com',
    'https://www.royalroad.com',
  ];

  // Combined list of predefined and custom sites
  List<String> _readingSites = [];
  List<String> _customSites = [];

  String _selectedUrl = 'https://www.royalroad.com';
  late final WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomSites();
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
            _autoSaveReadingSession(url);
          },
        ),
      )
      ..loadRequest(Uri.parse(_selectedUrl));
  }

  // Load custom sites from persistent storage
  Future<void> _loadCustomSites() async {
    final customSites = await _settingsService.getCustomSites();
    setState(() {
      _customSites = customSites;
      _readingSites = [..._predefinedSites, ..._customSites];
    });
  }

  // Save custom sites to persistent storage
  Future<void> _saveCustomSites() async {
    await _settingsService.saveCustomSites(_customSites);
  }

  Future<void> _autoSaveReadingSession(String url) async {
    final existingSession = await _databaseService.getSessionByUrl(url);
    if (existingSession == null) {
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

  // Add new website dialog
  Future<void> _showAddWebsiteDialog() async {
    TextEditingController urlController = TextEditingController();
    TextEditingController nameController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Website'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Website Name (Optional)',
                  hintText: 'e.g., My Favorite Site',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Website URL',
                  hintText: 'https://example.com',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter a valid URL starting with http:// or https://',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final url = urlController.text.trim();
                if (_isValidUrl(url)) {
                  _addNewWebsite(url, nameController.text.trim());
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a valid URL starting with http:// or https://',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Add Website'),
            ),
          ],
        );
      },
    );
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  void _addNewWebsite(String url, String name) {
    // Ensure URL has proper format
    String formattedUrl = url;
    if (!formattedUrl.startsWith('http://') &&
        !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }

    setState(() {
      _customSites.add(formattedUrl);
      _readingSites = [..._predefinedSites, ..._customSites];
    });

    _saveCustomSites();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Website ${name.isNotEmpty ? '"$name" ' : ''}added successfully!',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _removeWebsite(String url) {
    // Check if it's a predefined site (cannot be removed)
    if (_predefinedSites.contains(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Predefined websites cannot be removed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Website'),
          content: Text(
            'Are you sure you want to remove ${Uri.parse(url).host}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _customSites.remove(url);
                  _readingSites = [..._predefinedSites, ..._customSites];
                });
                _saveCustomSites();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Website removed')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  String _getWebsiteDisplayName(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceAll('www.', '');
    } catch (e) {
      return url;
    }
  }

  // Check if a website is predefined (cannot be removed)
  bool _isPredefinedWebsite(String url) {
    return _predefinedSites.contains(url);
  }

  // Helper method to handle opacity without deprecated method
  Color _withOpacity(Color color, double opacity) {
    // ignore: deprecated_member_use
    return color.withOpacity(opacity);
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
          IconButton(
            icon: Icon(
              Icons.favorite,
              color: _getTextColorForBackground(
                _settingsService.backgroundColor,
              ),
            ),
            onPressed: _saveCurrentSessionAsFavorite,
            tooltip: 'Save Current Session',
          ),
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
            tooltip: 'PDF to Text Converter',
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
                if (mounted) {
                  setState(() {});
                }
              });
            },
            tooltip: 'Settings',
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
                color: _withOpacity(_settingsService.sidebarColor, 0.8),
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

            // History Button
            ListTile(
              leading: Icon(
                Icons.history,
                color: _getTextColorForBackground(
                  _settingsService.sidebarColor,
                ),
              ),
              title: Text(
                'Reading History',
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
                    builder: (context) => const HistoryScreen(),
                  ),
                );
              },
            ),

            const Divider(),

            // Add Website Button
            ListTile(
              leading: Icon(
                Icons.add_link,
                color: _getTextColorForBackground(
                  _settingsService.sidebarColor,
                ),
              ),
              title: Text(
                'Add New Website',
                style: TextStyle(
                  color: _getTextColorForBackground(
                    _settingsService.sidebarColor,
                  ),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showAddWebsiteDialog();
              },
            ),

            // Reading Sites
            ..._readingSites.map(
              (url) => ListTile(
                title: Text(
                  _getWebsiteDisplayName(url),
                  style: TextStyle(
                    color: _getTextColorForBackground(
                      _settingsService.sidebarColor,
                    ),
                  ),
                ),
                trailing: _isPredefinedWebsite(url)
                    ? null // No remove button for predefined sites
                    : IconButton(
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: _withOpacity(
                            _getTextColorForBackground(
                              _settingsService.sidebarColor,
                            ),
                            0.7,
                          ),
                          size: 20,
                        ),
                        onPressed: () => _removeWebsite(url),
                        tooltip: 'Remove website',
                      ),
                onTap: () {
                  setState(() => _selectedUrl = url);
                  _webViewController.loadRequest(Uri.parse(url));
                  Navigator.pop(context);
                },
                onLongPress: _isPredefinedWebsite(url)
                    ? null // No long press for predefined sites
                    : () => _removeWebsite(url),
              ),
            ),

            const Divider(),

            // PDF Converter
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

            // Registered Accounts
            ListTile(
              leading: Icon(
                Icons.people,
                color: _getTextColorForBackground(
                  _settingsService.sidebarColor,
                ),
              ),
              title: Text(
                'Registered Accounts',
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
                    builder: (context) => const AccountsScreen(),
                  ),
                );
              },
            ),

            // Settings
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
                  setState(() {});
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
