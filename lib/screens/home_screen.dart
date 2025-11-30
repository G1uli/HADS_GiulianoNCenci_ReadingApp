import 'package:flutter/material.dart';
import 'package:reading_app/screens/accounts_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../services/database_service.dart';
import '../models/reading_history.dart';
import '../screens/settings_screen.dart';
import '../screens/history_screen.dart';
import '../screens/file_browser_screen.dart';
import '../screens/login_screen.dart';
import 'dart:developer' as developer;

class Website {
  final String url;
  final String name;
  final String? imageUrl;
  final String? imageAsset;
  final bool isPredefined;

  Website({
    required this.url,
    required this.name,
    this.imageUrl,
    this.imageAsset,
    required this.isPredefined,
  });

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'name': name,
      'imageUrl': imageUrl,
      'imageAsset': imageAsset,
      'isPredefined': isPredefined,
    };
  }

  // Create from Map
  factory Website.fromMap(Map<String, dynamic> map) {
    return Website(
      url: map['url'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'],
      imageAsset: map['imageAsset'],
      isPredefined: map['isPredefined'] ?? false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final SettingsService _settingsService = SettingsService();
  // final DatabaseService _databaseService = DatabaseService();

  // Predefined sites with images
  final List<Website> _predefinedSites = [
    Website(
      url: 'https://mangadex.org',
      name: 'MangaDex',
      imageAsset: 'assets/images/MangaDex_logo.png',
      isPredefined: true,
    ),
    Website(
      url: 'https://www.webnovel.com',
      name: 'WebNovel',
      imageAsset: 'assets/images/Webnovel.png',
      isPredefined: true,
    ),
    Website(
      url: 'https://www.royalroad.com',
      name: 'Royal Road',
      imageAsset: 'assets/images/RoyalRoad.png',
      isPredefined: true,
    ),
  ];

  // Combined list of predefined and custom sites
  List<Website> _readingSites = [];
  List<Website> _customSites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomSites();
  }

  void _refreshData() {
    if (mounted) {
      _loadCustomSites();
    }
  }

  // Load custom sites from persistent storage
  Future<void> _loadCustomSites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint(' TESTE _loadCustomSites ');

      final customSitesData = await _settingsService.getCustomSites();
      debugPrint('Loaded raw data: $customSitesData');
      debugPrint('Data type: ${customSitesData.runtimeType}');
      debugPrint('Data length: ${customSitesData.length}');

      // Convert stored data to Website objects
      final List<Website> loadedSites = [];

      for (var siteData in customSitesData) {
        debugPrint('Processing site data: $siteData');
        debugPrint('Site data type: ${siteData.runtimeType}');

        if (siteData is Map<String, dynamic>) {
          debugPrint('Converting Map to Website');
          loadedSites.add(Website.fromMap(siteData));
        } else if (siteData is String) {
          debugPrint('Converting String to Website');
          // Backward compatibility with old string format
          loadedSites.add(
            Website(
              url: siteData,
              name: _getWebsiteDisplayName(siteData),
              isPredefined: false,
            ),
          );
        } else {
          debugPrint('Unknown data type, skipping');
        }
      }

      debugPrint('Final loaded sites count: ${loadedSites.length}');

      if (mounted) {
        setState(() {
          _customSites = loadedSites;
          _readingSites = [..._predefinedSites, ..._customSites];
          _isLoading = false;
        });
      }

      debugPrint(' Finalizado teste _loadCustomSites ');
    } catch (e) {
      debugPrint('ERROR in _loadCustomSites: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildLoadingScreen() {
    final backgroundColor = _settingsService.backgroundColor;
    final textColor = _getTextColorForBackground(backgroundColor);

    return Scaffold(
      appBar: AppBar(
        title: Text('Reading App', style: TextStyle(color: textColor)),
        backgroundColor: backgroundColor,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading your websites...',
              style: TextStyle(
                color: textColor.withAlpha((0.7 * 255).round()),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performLogout() async {
    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(child: CircularProgressIndicator());
          },
        );
      }

      // Perform logout
      await _authService.logout();

      // Navigate to login screen
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Save custom sites to persistent storage
  Future<void> _saveCustomSites() async {
    try {
      debugPrint(' TESTE _saveCustomSites ');
      debugPrint('Saving ${_customSites.length} custom sites');

      final sitesToSave = _customSites.map((site) => site.toMap()).toList();
      debugPrint('Sites to save: $sitesToSave');

      await _settingsService.saveCustomSites(sitesToSave);

      debugPrint(' Fim do teste _saveCustomSites ');
    } catch (e) {
      debugPrint('ERROR in _saveCustomSites: $e');
    }
  }

  // Go to website
  void _navigateToWebsite(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WebViewScreen(url: url)),
    );
  }

  // Add new website
  Future<void> _showAddWebsiteDialog() async {
    TextEditingController urlController = TextEditingController();
    TextEditingController nameController = TextEditingController();
    TextEditingController imageUrlController = TextEditingController();

    String selectedImageType = 'auto'; // auto, url, none

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Website'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Website Name',
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
                    const SizedBox(height: 16),

                    // Image Selection Section
                    const Text(
                      'Website Image',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      initialValue: selectedImageType,
                      items: [
                        const DropdownMenuItem(
                          value: 'auto',
                          child: Text('Auto-detect favicon'),
                        ),
                        const DropdownMenuItem(
                          value: 'url',
                          child: Text('Custom image URL'),
                        ),
                        const DropdownMenuItem(
                          value: 'none',
                          child: Text('No image'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedImageType = value!;
                        });
                      },
                    ),

                    if (selectedImageType == 'url') ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Image URL',
                          hintText: 'https://example.com/icon.png',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),
                    const Text(
                      'Enter a valid URL starting with http:// or https://',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
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
                      _addNewWebsite(
                        url,
                        nameController.text.trim(),
                        selectedImageType,
                        imageUrlController.text.trim(),
                      );
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

  void _addNewWebsite(
    String url,
    String name,
    String imageType,
    String customImageUrl,
  ) {
    // Ensure URL has proper format
    String formattedUrl = url;
    if (!formattedUrl.startsWith('http://') &&
        !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }

    // Auto-generate name if empty
    String displayName = name.isEmpty
        ? _getWebsiteDisplayName(formattedUrl)
        : name;

    // Handle image based on type
    String? finalImageUrl;

    switch (imageType) {
      case 'auto':
        finalImageUrl = _getFaviconUrl(formattedUrl);
        break;
      case 'url':
        finalImageUrl = customImageUrl.isNotEmpty ? customImageUrl : null;
        break;
      case 'none':
        finalImageUrl = null;
        break;
    }

    final newWebsite = Website(
      url: formattedUrl,
      name: displayName,
      imageUrl: finalImageUrl,
      isPredefined: false,
    );

    setState(() {
      _customSites.add(newWebsite);
      _readingSites = [..._predefinedSites, ..._customSites];
    });

    _saveCustomSites();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Website "$displayName" added successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Helper to get favicon URL
  String _getFaviconUrl(String websiteUrl) {
    try {
      final uri = Uri.parse(websiteUrl);
      return '${uri.scheme}://${uri.host}/favicon.ico';
    } catch (e) {
      return '';
    }
  }

  void _removeWebsite(String url) {
    // Find the website to check if it's predefined
    final website = _readingSites.firstWhere((site) => site.url == url);

    if (website.isPredefined) {
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
          content: Text('Are you sure you want to remove ${website.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _customSites.removeWhere((site) => site.url == url);
                  _readingSites = [..._predefinedSites, ..._customSites];
                });
                _saveCustomSites();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${website.name} removed')),
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

  // Handle opacity without deprecated method
  Color _withOpacity(Color color, double opacity) {
    return color.withAlpha((opacity * 255).round());
  }

  Color _getTextColorForBackground(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
  }

  // Get card background color based on settings
  Color _getCardBackgroundColor() {
    final bgColor = _settingsService.backgroundColor;
    // Check if color is too dark so it changes card color
    if (bgColor.computeLuminance() < 0.1) {
      return Colors.grey[850]!;
    }
    // Check if color is too light so it changes card color
    else if (bgColor.computeLuminance() > 0.9) {
      return Colors.white;
    }
    // If not anything else, use slightly different color
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

  Widget _buildWebsiteImage(Website website, Color iconColor) {
    const double imageSize = 40;

    // Priority: asset image > network image > default icon
    if (website.imageAsset != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          website.imageAsset!,
          width: imageSize,
          height: imageSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            developer.log(
              'Error loading asset image: $error for ${website.name}',
            );
            return _buildDefaultIcon(iconColor, imageSize);
          },
        ),
      );
    } else if (website.imageUrl != null && website.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          website.imageUrl!,
          width: imageSize,
          height: imageSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            developer.log(
              'Error loading network image: $error for ${website.name}',
            );
            return _buildDefaultIcon(iconColor, imageSize);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: imageSize,
              height: imageSize,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        ),
      );
    } else {
      return _buildDefaultIcon(iconColor, imageSize);
    }
  }

  Widget _buildDefaultIcon(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.public, color: color, size: size * 0.6),
    );
  }

  Widget _buildWebsiteCard(Website website) {
    final cardBackgroundColor = _getCardBackgroundColor();
    final textColor = _getCardTextColor();
    final subtitleColor = _getCardSubtitleColor();
    final iconColor = _getIconColor();

    return Card(
      elevation: 2,
      color: cardBackgroundColor,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: _buildWebsiteImage(website, iconColor),
        title: Text(
          website.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        subtitle: Text(
          website.url,
          style: TextStyle(fontSize: 12, color: subtitleColor),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: website.isPredefined
            ? Icon(Icons.lock, color: subtitleColor, size: 20)
            : IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: subtitleColor,
                ),
                onPressed: () => _removeWebsite(website.url),
                tooltip: 'Remove website',
              ),
        onTap: () => _navigateToWebsite(website.url),
        onLongPress: website.isPredefined
            ? null
            : () => _removeWebsite(website.url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    final backgroundColor = _settingsService.backgroundColor;
    final textColor = _getTextColorForBackground(backgroundColor);
    final subtitleColor = textColor.withAlpha((0.7 * 255).round());

    return Scaffold(
      appBar: AppBar(
        title: Text('Reading App', style: TextStyle(color: textColor)),
        backgroundColor: backgroundColor,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.folder_open, color: textColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FileBrowserScreen(),
                ),
              );
            },
            tooltip: 'File Browser',
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
            onPressed: _performLogout,
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

            // File searcher
            ListTile(
              leading: Icon(
                Icons.folder_open,
                color: _getTextColorForBackground(
                  _settingsService.sidebarColor,
                ),
              ),
              title: Text(
                'File Browser',
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
                    builder: (context) => const FileBrowserScreen(),
                  ),
                );
              },
            ),

            const Divider(),

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
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccountsScreen(),
                  ),
                ).then((_) {
                  // Refresh when returning from accounts screen
                  if (mounted) {
                    _refreshData();
                  }
                });
              },
            ),

            const Divider(),

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

            const Divider(),
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
  final AuthService _authService = AuthService();

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
    final currentUserEmail = await _authService.getCurrentUserEmail();
    if (currentUserEmail == null) return;

    final existingSession = await _databaseService.getSessionByUrl(
      url,
      currentUserEmail,
    );
    if (existingSession == null) {
      final session = ReadingHistory(
        url: url,
        title: _getPageTitleFromUrl(url),
        timestamp: DateTime.now(),
        userEmail: currentUserEmail,
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
