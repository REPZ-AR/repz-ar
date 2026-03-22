class Client {
  final String id;
  final String name;
  final String subtitle;
  final String? avatarUrl;
  final String status;
  final DateTime? joinedDate;

  const Client({
    required this.id,
    required this.name,
    required this.subtitle,
    this.avatarUrl,
    this.status = 'active',
    this.joinedDate,
  });
}