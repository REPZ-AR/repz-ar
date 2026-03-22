class Trainer {
  final String id;
  final String name;
  final String subtitle;
  final String? avatarUrl;
  final DateTime? joinedDate;

  const Trainer({
    required this.id,
    required this.name,
    required this.subtitle,
    this.avatarUrl,
    this.joinedDate,
  });
}