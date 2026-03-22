import 'package:flutter/material.dart';

class SettingsSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final accentColor =
    isDarkMode ? const Color(0xFFCFF500) : const Color(0xFFA66CFF);
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
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
                    value: isDarkMode,
                    onChanged: (val) {
                      onThemeChanged(val);
                      setSheetState(() {});
                    },
                    activeThumbColor: accentColor,
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Divider(color: dividerColor),
              const SizedBox(height: 8),

              // Logout row
              InkWell(
                onTap: onLogout == null
                    ? null
                    : () {
                  Navigator.of(ctx).pop();
                  onLogout!();
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