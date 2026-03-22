import 'package:flutter/material.dart';

import '../model/repz_badge.dart';
import '../widgets/layouts/friends_card.dart';
import '../widgets/layouts/menu_card.dart';
import '../widgets/layouts/profile_card.dart';
import '../widgets/layouts/settings_sheet.dart';
import '../widgets/layouts/badges_card.dart';

class ProfilePage extends StatefulWidget {
  final bool isDarkMode;
  final String? avatarUrl;
  final String? userName;
  final String? userEmail;
  final Future<void> Function()? onLogout;
  final Function(bool) onThemeChanged;

  const ProfilePage({
    super.key,
    required this.isDarkMode,
    this.avatarUrl,
    this.userName,
    this.userEmail,
    this.onLogout,
    required this.onThemeChanged,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final List<Map<String, String>> _friends = [
    {'name': 'Anika', 'initials': 'AK'},
    {'name': 'Roshan', 'initials': 'RS'},
    {'name': 'Tanya', 'initials': 'TM'},
    {'name': 'Kavi', 'initials': 'KP'},
    {'name': 'Dev', 'initials': 'DV'},
  ];

  final List<Color> _avatarColors = const [
    Color(0xFFEEEDFE),
    Color(0xFFE1F5EE),
    Color(0xFFFAECE7),
    Color(0xFFFAEEDA),
    Color(0xFFFBEAF0),
  ];

  final List<Color> _avatarTextColors = const [
    Color(0xFF3C3489),
    Color(0xFF085041),
    Color(0xFF712B13),
    Color(0xFF633806),
    Color(0xFF72243E),
  ];

  final List<RepzBadge> _badges = const [
    RepzBadge(
      month: 'October',
      label: 'On Fire',
      description: 'You crushed every session in October. The grind was real.',
      earned: true,
      icon: Icons.local_fire_department_rounded,
      bgColor: Color(0xFFFAEEDA),
      borderColor: Color(0xFFEF9F27),
      iconColor: Color(0xFF854F0B),
    ),
    RepzBadge(
      month: 'November',
      label: 'Consistent',
      description: 'Not a single week skipped in November. Respect.',
      earned: true,
      icon: Icons.verified_rounded,
      bgColor: Color(0xFFE1F5EE),
      borderColor: Color(0xFF5DCAA5),
      iconColor: Color(0xFF085041),
    ),
    RepzBadge(
      month: 'December',
      label: 'Dedicated',
      description: 'You stayed disciplined through the holiday chaos. Legend.',
      earned: true,
      icon: Icons.military_tech_rounded,
      bgColor: Color(0xFFEEEDFE),
      borderColor: Color(0xFFAFA9EC),
      iconColor: Color(0xFF3C3489),
    ),
    RepzBadge(
      month: 'January',
      label: 'New Year',
      description: 'Started 2025 strong. New year, same beast.',
      earned: true,
      icon: Icons.celebration_rounded,
      bgColor: Color(0xFFFBEAF0),
      borderColor: Color(0xFFED93B1),
      iconColor: Color(0xFF72243E),
    ),
    RepzBadge(
      month: 'February',
      label: 'Grinder',
      description: 'Short month, zero excuses. You showed up every day.',
      earned: true,
      icon: Icons.bolt_rounded,
      bgColor: Color(0xFFE6F1FB),
      borderColor: Color(0xFF85B7EB),
      iconColor: Color(0xFF0C447C),
    ),
    RepzBadge(
      month: 'March',
      label: 'Locked',
      description: 'Keep your streak going to unlock this badge.',
      earned: false,
      icon: Icons.lock_rounded,
      bgColor: Color(0xFFF1EFE8),
      borderColor: Color(0xFFB4B2A9),
      iconColor: Color(0xFF888780),
    ),
  ];

  Future<void> _confirmLogout() async {
    if (widget.onLogout == null) return;
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (shouldLogout == true) await widget.onLogout!.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => SettingsSheet.show(
              context,
              isDarkMode: widget.isDarkMode,
              onThemeChanged: widget.onThemeChanged,
              onLogout: widget.onLogout == null ? null : _confirmLogout,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ProfileCard(
              isDarkMode: widget.isDarkMode,
              avatarUrl: widget.avatarUrl,
              userName: widget.userName,
              userEmail: widget.userEmail,
            ),
            const SizedBox(height: 12),
            FriendsCard(
              isDarkMode: widget.isDarkMode,
              friends: _friends,
              avatarColors: _avatarColors,
              avatarTextColors: _avatarTextColors,
              onAddFriend: () {
                // TODO: navigate to AddFriendPage
              },
              onFriendTap: (friend) {
                // TODO: open friend profile
              },
            ),
            const SizedBox(height: 12),
            BadgesCard(
              isDarkMode: widget.isDarkMode,
              badges: _badges,
            ),
            const SizedBox(height: 12),
            MenuCard(isDarkMode: widget.isDarkMode),
          ],
        ),
      ),
    );
  }
}