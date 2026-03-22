class Friend {
  final String id;
  final String name;
  final String initials;
  final String? avatarUrl;

  const Friend({
    required this.id,
    required this.name,
    required this.initials,
    this.avatarUrl,
  });

  factory Friend.fromMap(Map<String, dynamic> map) {
    final name = (map['full_name'] as String? ?? '').trim();
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? '?'
        : parts.length == 1
        ? parts.first.substring(0, 1).toUpperCase()
        : (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();

    return Friend(
      id: map['id'] as String,
      name: name.isEmpty ? 'Unknown' : name,
      initials: initials,
      avatarUrl: map['avatar_url'] as String?,
    );
  }
}