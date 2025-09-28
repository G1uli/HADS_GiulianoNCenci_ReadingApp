class ReadingHistory {
  final int? id;
  final String url;
  final String title;
  final DateTime timestamp;
  final bool isFavorite;

  ReadingHistory({
    this.id,
    required this.url,
    required this.title,
    required this.timestamp,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  factory ReadingHistory.fromMap(Map<String, dynamic> map) {
    return ReadingHistory(
      id: map['id'],
      url: map['url'],
      title: map['title'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      isFavorite: map['isFavorite'] == 1,
    );
  }
}
