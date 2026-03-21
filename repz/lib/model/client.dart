class Client {
  final String id;
  final String name;
  final String subtitle;
  final String? avatarUrl;

  const Client({
    required this.id,
    required this.name,
    required this.subtitle,
    this.avatarUrl,
  });
}