import 'package:flutter/material.dart';
import '../../model/client.dart';

class ClientCard extends StatelessWidget {
  final Client client;
  final bool isExpanded;
  final bool isDarkMode;
  final Color accentColor;
  final Color cardColor;
  final VoidCallback onTap;
  final VoidCallback onViewClient;
  final VoidCallback onAssignPlan;
  final VoidCallback onProposeSchedule;

  const ClientCard({
    Key? key,
    required this.client,
    required this.isExpanded,
    required this.isDarkMode,
    required this.accentColor,
    required this.cardColor,
    required this.onTap,
    required this.onViewClient,
    required this.onAssignPlan,
    required this.onProposeSchedule,
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

  Color get _statusColor {
    switch (client.status.toLowerCase()) {
      case 'active':
        return const Color(0xFF4CAF50);
      case 'pending':
        return const Color(0xFFFFC107);
      case 'inactive':
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFF4CAF50);
    }
  }

  String get _initials {
    final parts = client.name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return client.name.isNotEmpty ? client.name[0].toUpperCase() : '?';
  }

  String get _joinedText {
    if (client.joinedDate == null) return 'Recently joined';
    final now = DateTime.now();
    final diff = now.difference(client.joinedDate!);
    if (diff.inDays == 0) return 'Joined today';
    if (diff.inDays == 1) return 'Joined yesterday';
    if (diff.inDays < 30) return 'Joined ${diff.inDays}d ago';
    if (diff.inDays < 365) return 'Joined ${(diff.inDays / 30).floor()}mo ago';
    return 'Joined ${(diff.inDays / 365).floor()}y ago';
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = _avatarColor();
    final statusColor = _statusColor;

    final primaryTextColor =
    isDarkMode ? Colors.white : const Color(0xFF1A1A1A);
    final labelTextColor =
    isDarkMode ? Colors.white60 : const Color(0xFF777777);
    final valueTextColor = isDarkMode ? Colors.white : accentColor;
    final dividerColor =
    isDarkMode ? Colors.white24 : const Color(0xFFEEEEEE);
    final chevronColor =
    isDarkMode ? Colors.white60 : const Color(0xFFAAAAAA);

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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Colored left status strip ──────────────────
                Container(
                  width: 4,
                  color: statusColor,
                ),

                // ── Card content ───────────────────────────────
                Expanded(
                  child: Column(
                    children: [
                      // ── Row (always visible) ─────────────────
                      InkWell(
                        onTap: onTap,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Avatar with status dot badge
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: avatarColor,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: client.avatarUrl != null
                                        ? ClipRRect(
                                      borderRadius:
                                      BorderRadius.circular(16),
                                      child: Image.network(
                                          client.avatarUrl!,
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
                                  // Status dot badge
                                  Positioned(
                                    bottom: -3,
                                    right: -3,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: cardColor,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),

                              // Name, subtitle & joined date
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(client.name,
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: primaryTextColor)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: accentColor.withAlpha(30),
                                            borderRadius:
                                            BorderRadius.circular(6),
                                          ),
                                          child: Text(client.subtitle,
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: accentColor)),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(_joinedText,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: labelTextColor)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Chevron
                              AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 300),
                                child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: chevronColor),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Expanded detail card ─────────────────
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
                              Divider(color: dividerColor),
                              const SizedBox(height: 12),

                              _detailRow(Icons.badge_outlined, 'Client ID',
                                  client.id, labelTextColor, valueTextColor),
                              const SizedBox(height: 10),
                              _detailRow(Icons.category_outlined, 'Type',
                                  client.subtitle, labelTextColor, valueTextColor),
                              const SizedBox(height: 10),
                              _detailRow(
                                  Icons.check_circle_outline,
                                  'Status',
                                  client.status.toUpperCase(),
                                  labelTextColor,
                                  statusColor),

                              const SizedBox(height: 20),

                              // ── View & Assign buttons ────────
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: onViewClient,
                                      icon: const Icon(
                                          Icons.visibility_outlined,
                                          size: 18),
                                      label: const Text('View',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: onAssignPlan,
                                      icon: const Icon(
                                          Icons.playlist_add_check_rounded,
                                          size: 18),
                                      label: const Text('Assign',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: accentColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(14)),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // ── Propose Schedule button ──────
                              SizedBox(
                                width: double.infinity,
                                child: TextButton.icon(
                                  onPressed: onProposeSchedule,
                                  icon: const Icon(
                                      Icons.calendar_month_rounded,
                                      size: 18),
                                  label: const Text('Propose Schedule',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value,
      Color labelColor, Color valueColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: labelColor),
        const SizedBox(width: 10),
        Text('$label: ', style: TextStyle(fontSize: 13, color: labelColor)),
        Expanded(
          child: Text(value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor)),
        ),
      ],
    );
  }
}