// ─────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────

class FeedItem {
  final String id;
  final String type; // 'streak' | 'tournament' | 'activity' | 'challenge'
  final DateTime createdAt;
  final Map<String, dynamic> payload;

  const FeedItem({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.payload,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      id: json['id'] as String,
      type: json['type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
    );
  }
}