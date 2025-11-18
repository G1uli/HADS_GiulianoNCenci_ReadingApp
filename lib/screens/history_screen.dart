import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/reading_history.dart';
import 'home_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  List<ReadingHistory> _readingSessions = [];
  List<ReadingHistory> _filteredSessions = [];
  bool _showFavoritesOnly = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadReadingSessions();
  }

  Future<void> _loadReadingSessions() async {
    final currentUserEmail = await _authService.getCurrentUserEmail();
    if (currentUserEmail == null) return;

    final sessions = _showFavoritesOnly
        ? await _databaseService.getFavoriteSessionsByUser(currentUserEmail)
        : await _databaseService.getSessionsByUser(currentUserEmail);

    if (mounted) {
      setState(() {
        _readingSessions = sessions;
        _filteredSessions = _filterSessions(sessions, _searchQuery);
      });
    }
  }

  List<ReadingHistory> _filterSessions(
    List<ReadingHistory> sessions,
    String query,
  ) {
    if (query.isEmpty) {
      return sessions;
    }

    final lowercaseQuery = query.toLowerCase();
    return sessions.where((session) {
      return session.title.toLowerCase().contains(lowercaseQuery) ||
          session.url.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filteredSessions = _filterSessions(_readingSessions, query);
    });
  }

  Future<void> _toggleFavorite(ReadingHistory session) async {
    final currentUserEmail = await _authService.getCurrentUserEmail();
    if (currentUserEmail == null) return;

    final updatedSession = ReadingHistory(
      id: session.id,
      url: session.url,
      title: session.title,
      timestamp: session.timestamp,
      isFavorite: !session.isFavorite,
      userEmail: currentUserEmail,
    );

    await _databaseService.updateSession(updatedSession);
    _loadReadingSessions();
  }

  Future<void> _deleteSession(int id) async {
    final currentUserEmail = await _authService.getCurrentUserEmail();
    if (currentUserEmail == null) return;

    await _databaseService.deleteSession(id, currentUserEmail);
    _loadReadingSessions();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Session deleted')));
    }
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _filteredSessions = _readingSessions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading History'),
        actions: [
          IconButton(
            icon: Icon(_showFavoritesOnly ? Icons.star : Icons.star_border),
            onPressed: () {
              setState(() {
                _showFavoritesOnly = !_showFavoritesOnly;
              });
              _loadReadingSessions();
            },
            tooltip: _showFavoritesOnly ? 'Show All' : 'Show Favorites Only',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by title or URL...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // Search Results Info
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                children: [
                  Text(
                    'Found ${_filteredSessions.length} result${_filteredSessions.length == 1 ? '' : 's'} for "$_searchQuery"',
                    style: const TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearSearch,
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),

          // History List
          Expanded(
            child: _filteredSessions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty
                              ? Icons.search_off
                              : Icons.history,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No results found for "$_searchQuery"'
                              : 'No reading sessions yet',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_searchQuery.isNotEmpty)
                          TextButton(
                            onPressed: _clearSearch,
                            child: const Text('Clear search'),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredSessions.length,
                    itemBuilder: (context, index) {
                      final session = _filteredSessions[index];
                      return _buildHistoryItem(session);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(ReadingHistory session) {
    String displayTitle = session.title.isEmpty ? 'Untitled' : session.title;
    String displayUrl = session.url;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: ListTile(
        leading: Icon(
          session.isFavorite ? Icons.star : Icons.history,
          color: session.isFavorite ? Colors.amber : null,
        ),
        title: _buildHighlightedText(displayTitle, _searchQuery),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHighlightedText(displayUrl, _searchQuery),
            Text(
              '${session.timestamp.day}/${session.timestamp.month}/${session.timestamp.year} ${session.timestamp.hour}:${session.timestamp.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                session.isFavorite ? Icons.star : Icons.star_border,
                color: session.isFavorite ? Colors.amber : null,
              ),
              onPressed: () => _toggleFavorite(session),
              tooltip: session.isFavorite
                  ? 'Remove from favorites'
                  : 'Add to favorites',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteSession(session.id!),
              tooltip: 'Delete session',
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WebViewScreen(url: session.url),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(text);
    }

    final lowercaseText = text.toLowerCase();
    final lowercaseQuery = query.toLowerCase();
    final matches = <TextSpan>[];
    int start = 0;
    int index = lowercaseText.indexOf(lowercaseQuery);

    while (index != -1) {
      if (index > start) {
        matches.add(
          TextSpan(
            text: text.substring(start, index),
            style: const TextStyle(color: Colors.black),
          ),
        );
      }

      matches.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.yellow,
          ),
        ),
      );

      start = index + query.length;
      index = lowercaseText.indexOf(lowercaseQuery, start);
    }

    // Add remaining text
    if (start < text.length) {
      matches.add(
        TextSpan(
          text: text.substring(start),
          style: const TextStyle(color: Colors.black),
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: matches,
      ),
    );
  }
}
