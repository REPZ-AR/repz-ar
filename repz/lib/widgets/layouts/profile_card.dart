import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  final bool isDarkMode;
  final String? avatarUrl;
  final String? userName;
  final String? userEmail;

  const ProfileCard({
    super.key,
    required this.isDarkMode,
    this.avatarUrl,
    this.userName,
    this.userEmail,
  });

  String _initialsFor(String? name, String? email) {
    final source = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : (email != null && email.trim().isNotEmpty)
        ? email.trim()
        : 'Guest';
    final parts = source
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'G';
    if (parts.length == 1) {
      final clean = parts.first.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
      return clean.isEmpty ? 'G' : clean.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor =
    isDarkMode ? const Color(0xFFCFF500) : const Color(0xFFA66CFF);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = primaryTextColor.withValues(alpha: 0.55);
    final hasPhoto = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: accentColor.withValues(alpha: 0.25),
            foregroundImage: hasPhoto ? NetworkImage(avatarUrl!) : null,
            child: hasPhoto
                ? null
                : Text(
              _initialsFor(userName, userEmail),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: primaryTextColor,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (userName != null && userName!.isNotEmpty)
                      ? userName!
                      : (userEmail != null && userEmail!.isNotEmpty)
                      ? userEmail!
                      : 'Guest',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  (userEmail != null && userEmail!.isNotEmpty)
                      ? userEmail!
                      : 'Not signed in',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: secondaryTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}