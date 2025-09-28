import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/reading_history.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<ReadingHistory> _readingSessions = [];
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _loadReadingSessions();
  }

  Future<void> _loadReadingSessions() async {
    final sessions = _showFavoritesOnly
        ? await _databaseService.getFavoriteSessions()
        : await _databaseService.getAllReadingSessions();

    if (mounted) {
      setState(() {
        _readingSessions = sessions;
      });
    }
  }

  Future<void> _toggleFavorite(ReadingHistory session) async {
    final updatedSession = ReadingHistory(
      id: session.id,
      url: session.url,
      title: session.title,
      timestamp: session.timestamp,
      isFavorite: !session.isFavorite,
    );

    await _databaseService.updateSession(updatedSession);
    _loadReadingSessions();
  }

  Future<void> _deleteSession(int id) async {
    await _databaseService.deleteSession(id);
    _loadReadingSessions();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Session deleted')));
    }
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
          ),
        ],
      ),
      body: _readingSessions.isEmpty
          ? const Center(
              child: Text(
                'No reading sessions yet',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: _readingSessions.length,
              itemBuilder: (context, index) {
                final session = _readingSessions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: Icon(
                      session.isFavorite ? Icons.star : Icons.history,
                      color: session.isFavorite ? Colors.amber : null,
                    ),
                    title: Text(
                      session.title.isEmpty ? 'Untitled' : session.title,
                      style: TextStyle(
                        fontWeight: session.isFavorite
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session.url),
                        Text(
                          '${session.timestamp.day}/${session.timestamp.month}/${session.timestamp.year}',
                          style: const TextStyle(fontSize: 12),
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
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteSession(session.id!),
                        ),
                      ],
                    ),
                    onTap: () {
                      // You could implement navigation back to the reading session
                      Navigator.pop(context, session.url);
                    },
                  ),
                );
              },
            ),
    );
  }
}
