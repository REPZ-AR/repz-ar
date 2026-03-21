class Trainer {
  final String id;
  final String name;
  final String subtitle;
  final String? avatarUrl;

  const Trainer({
    required this.id,
    required this.name,
    required this.subtitle,
    this.avatarUrl,
  });
}