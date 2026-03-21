import 'package:flutter/material.dart';
import 'package:repz/views/saved_workout_plans_page.dart';

class MenuPage extends StatelessWidget {
  final bool isDarkMode;
  final String? avatarUrl;
  final String? userName;
  final String? userEmail;
  final Future<void> Function()? onLogout;
  final Function(bool) onThemeChanged;

  const MenuPage({
    Key? key,
    required this.isDarkMode,
    this.avatarUrl,
    this.userName,
    this.userEmail,
    this.onLogout,
    required this.onThemeChanged,
  }) : super(key: key);

  String _initialsFor(String? name, String? email) {
    final source = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : (email != null && email.trim().isNotEmpty)
            ? email.trim()
            : 'Guest';
    final parts = source
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'G';
    }

    if (parts.length == 1) {
      final clean = parts.first.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
      return clean.isEmpty ? 'G' : clean.substring(0, 1).toUpperCase();
    }

    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Future<void> _confirmLogout(BuildContext context) async {
    if (onLogout == null) {
      return;
    }

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await onLogout!.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = isDarkMode
        ? const Color(0xFFCFF500)
        : const Color(0xFFA66CFF);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final photoUrl = avatarUrl;
    final displayName = userName;
    final email = userEmail;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = primaryTextColor.withValues(alpha: 0.65);

    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: accentColor.withValues(alpha: 0.25),
                    foregroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                    child: hasPhoto
                        ? null
                        : Text(
                            _initialsFor(displayName, email),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: primaryTextColor,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (displayName != null && displayName.isNotEmpty)
                              ? displayName
                              : (email != null && email.isNotEmpty)
                                  ? email
                                  : 'Guest',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (email != null && email.isNotEmpty)
                              ? email
                              : 'Not signed in',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: secondaryTextColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonal(
                    onPressed: onLogout == null
                        ? null
                        : () => _confirmLogout(context),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Dark Mode',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Switch(
                    value: isDarkMode,
                    onChanged: onThemeChanged,
                    activeThumbColor: accentColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: accentColor.withValues(alpha: 0.18),
                  child: Icon(
                    Icons.playlist_play_rounded,
                    color: isDarkMode ? accentColor : Colors.black,
                  ),
                ),
                title: const Text(
                  'Saved Plans',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Open, edit, and start your saved workout plans',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SavedWorkoutPlansPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

