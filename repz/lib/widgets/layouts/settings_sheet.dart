import 'package:flutter/material.dart';
import '../../services/friend_service.dart';
import '../../views/friend_requests.dart';

class SettingsSheet extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;
  final VoidCallback? onLogout;

  const SettingsSheet({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    this.onLogout,
  });

  static void show(
      BuildContext context, {
        required bool isDarkMode,
        required Function(bool) onThemeChanged,
        VoidCallback? onLogout,
      }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SettingsSheet(
        isDarkMode: isDarkMode,
        onThemeChanged: onThemeChanged,
        onLogout: onLogout,
      ),
    );
  }

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  final _friendService = FriendService();
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    try {
      final count = await _friendService.fetchPendingRequestCount();
      if (mounted) setState(() => _pendingCount = count);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final accentColor =
    widget.isDarkMode ? const Color(0xFFCFF500) : const Color(0xFFA66CFF);
    final primaryTextColor = widget.isDarkMode ? Colors.white : Colors.black;
    final dividerColor = primaryTextColor.withValues(alpha: 0.08);

    return StatefulBuilder(
      builder: (ctx, setSheetState) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: primaryTextColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Friend requests row
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => FriendRequestsPage(
                      isDarkMode: widget.isDarkMode,
                    ),
                  ));
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_add_outlined,
                        color: primaryTextColor.withValues(alpha: 0.6),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Friend Requests',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                        ),
                      ),
                      if (_pendingCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$_pendingCount',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: widget.isDarkMode
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: primaryTextColor.withValues(alpha: 0.3),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              Divider(color: dividerColor),

              // Dark mode row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.dark_mode_outlined,
                        color: primaryTextColor.withValues(alpha: 0.6),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Dark Mode',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: widget.isDarkMode,
                    onChanged: (val) {
                      widget.onThemeChanged(val);
                      setSheetState(() {});
                    },
                    activeThumbColor: accentColor,
                  ),
                ],
              ),

              Divider(color: dividerColor),

              // Logout row
              InkWell(
                onTap: widget.onLogout == null
                    ? null
                    : () {
                  Navigator.of(ctx).pop();
                  widget.onLogout!();
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: Colors.redAccent.withValues(alpha: 0.8),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}