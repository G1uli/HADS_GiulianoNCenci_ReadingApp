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

  // Predefined sites that cannot be removed
  final List<String> _predefinedSites = [
    'https://mangadex.org',
    'https://www.webnovel.com',
    'https://www.royalroad.com',
  ];

  // Combined list of predefined and custom sites
  List<String> _readingSites = [];
  List<String> _customSites = [];

  @override
  void initState() {
    super.initState();
    _loadCustomSites();
  }

  // Load custom sites from persistent storage
  Future<void> _loadCustomSites() async {
    final customSites = await _settingsService.getCustomSites();
    if (mounted) {
      setState(() {
        _customSites = customSites;
        _readingSites = [..._predefinedSites, ..._customSites];
      });
    }
  }

  // Save custom sites to persistent storage
  Future<void> _saveCustomSites() async {
    await _settingsService.saveCustomSites(_customSites);
  }

  // Navigate to website
  void _navigateToWebsite(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WebViewScreen(url: url)),
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
      String host = uri.host.replaceAll('www.', '');
      // Make the first letter uppercase for better presentation
      if (host.isNotEmpty) {
        host = host[0].toUpperCase() + host.substring(1);
      }
      return host;
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

  Color _getTextColorForBackground(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
  }

  // Get card background color based on settings
  Color _getCardBackgroundColor() {
    final bgColor = _settingsService.backgroundColor;
    // If background is very dark, use a slightly lighter dark color for cards
    if (bgColor.computeLuminance() < 0.1) {
      return Colors.grey[850]!;
    }
    // If background is very light, use white for cards
    else if (bgColor.computeLuminance() > 0.9) {
      return Colors.white;
    }
    // Otherwise, use a slightly different shade of the background
    else {
      return _withOpacity(bgColor, 0.95);
    }
  }

  // Get card text color based on background
  Color _getCardTextColor() {
    final bgColor = _getCardBackgroundColor();
    return bgColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  // Get card subtitle color based on background
  Color _getCardSubtitleColor() {
    final bgColor = _getCardBackgroundColor();
    return bgColor.computeLuminance() > 0.5
        ? Colors.grey[600]!
        : Colors.grey[400]!;
  }

  // Get icon color based on background
  Color _getIconColor() {
    final bgColor = _getCardBackgroundColor();
    return bgColor.computeLuminance() > 0.5 ? Colors.blue : Colors.blue[200]!;
  }

  Widget _buildWebsiteCard(String url) {
    final cardBackgroundColor = _getCardBackgroundColor();
    final textColor = _getCardTextColor();
    final subtitleColor = _getCardSubtitleColor();
    final iconColor = _getIconColor();

    return Card(
      elevation: 2,
      color: cardBackgroundColor,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: Icon(Icons.public, size: 30, color: iconColor),
        title: Text(
          _getWebsiteDisplayName(url),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        subtitle: Text(
          url,
          style: TextStyle(fontSize: 12, color: subtitleColor),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _isPredefinedWebsite(url)
            ? Icon(Icons.lock, color: subtitleColor, size: 20)
            : IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: subtitleColor,
                ),
                onPressed: () => _removeWebsite(url),
                tooltip: 'Remove website',
              ),
        onTap: () => _navigateToWebsite(url),
        onLongPress: _isPredefinedWebsite(url)
            ? null
            : () => _removeWebsite(url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _settingsService.backgroundColor;
    final textColor = _getTextColorForBackground(backgroundColor);
    final subtitleColor = textColor.withOpacity(0.7);

    return Scaffold(
      appBar: AppBar(
        title: Text('Reading App', style: TextStyle(color: textColor)),
        backgroundColor: backgroundColor,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite, color: textColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
            tooltip: 'Favorites',
          ),
          IconButton(
            icon: Icon(Icons.picture_as_pdf, color: textColor),
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
            icon: Icon(Icons.settings, color: textColor),
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
            icon: Icon(Icons.exit_to_app, color: textColor),
            onPressed: () async {
              await _authService.logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
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
                'Reading App',
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
      backgroundColor: backgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Reading App',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose a website to start reading',
                  style: TextStyle(fontSize: 14, color: subtitleColor),
                ),
              ],
            ),
          ),

          // Add Website Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_link),
              label: const Text('Add New Website'),
              onPressed: _showAddWebsiteDialog,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Websites Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Your Reading Websites',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Websites List
          Expanded(
            child: _readingSites.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.public, size: 64, color: subtitleColor),
                        const SizedBox(height: 16),
                        Text(
                          'No websites added yet',
                          style: TextStyle(fontSize: 16, color: subtitleColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the button above to add your first website',
                          style: TextStyle(fontSize: 12, color: subtitleColor),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _readingSites.length,
                    itemBuilder: (context, index) =>
                        _buildWebsiteCard(_readingSites[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

// WebView Screen for when user selects a website
class WebViewScreen extends StatefulWidget {
  final String url;

  const WebViewScreen({super.key, required this.url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _webViewController;
  bool _isLoading = true;
  final DatabaseService _databaseService = DatabaseService();

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
            _autoSaveReadingSession(url);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getPageTitleFromUrl(widget.url)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
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
