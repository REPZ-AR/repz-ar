class Client {
  final String name;
  final String subtitle;
  final bool isHighlighted;

  const Client({
    required this.name,
    required this.subtitle,
    this.isHighlighted = false,
  });
}