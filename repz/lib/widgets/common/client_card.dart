import 'package:flutter/material.dart';
import '../../model/client.dart';

class ClientCard extends StatelessWidget {
  final Client client;
  final bool isExpanded;
  final bool isDarkMode;
  final Color accentColor;
  final Color cardColor;
  final VoidCallback onTap;
  final VoidCallback onAddSchedule;

  const ClientCard({
    Key? key,
    required this.client,
    required this.isExpanded,
    required this.isDarkMode,
    required this.accentColor,
    required this.cardColor,
    required this.onTap,
    required this.onAddSchedule,
  }) : super(key: key);

  Color _avatarColor() {
    final colors = [
      const Color(0xFF5C6BC0),
      const Color(0xFF26A69A),
      const Color(0xFFEF5350),
      const Color(0xFFAB47BC),
      const Color(0xFF42A5F5),
      const Color(0xFFFF7043),
    ];
    final index =
        client.id.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[index];
  }

  String get _initials {
    final parts = client.name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return client.name.isNotEmpty ? client.name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = _avatarColor();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isExpanded ? accentColor.withAlpha(128) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: isExpanded
              ? [
            BoxShadow(
              color: accentColor.withAlpha(20),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ]
              : [],
        ),
        child: Column(
          children: [
            // ── Row (always visible) ─────────────────────────
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: avatarColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: client.avatarUrl != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(client.avatarUrl!,
                            fit: BoxFit.cover),
                      )
                          : Center(
                        child: Text(_initials,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Name & subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(client.name,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accentColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(client.subtitle,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: accentColor)),
                          ),
                        ],
                      ),
                    ),

                    // Chevron
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),

            // ── Expanded detail card ─────────────────────────
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),

                    _detailRow(Icons.badge_outlined, 'Client ID', client.id),
                    const SizedBox(height: 10),
                    _detailRow(
                        Icons.category_outlined, 'Type', client.subtitle),
                    const SizedBox(height: 10),
                    _detailRow(
                        Icons.check_circle_outline, 'Status', 'Active'),

                    const SizedBox(height: 20),

                    // Add Schedule button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onAddSchedule,
                        icon: const Icon(Icons.calendar_month_rounded,
                            size: 18),
                        label: const Text('Add Schedule',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(width: 10),
        Text('$label: ',
            style: const TextStyle(fontSize: 13, color: Colors.white70)),
        Expanded(
          child: Text(value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ),
      ],
    );
  }
}