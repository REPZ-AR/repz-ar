import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/repz_badge.dart';
import '../model/friend.dart';
import '../services/friend_service.dart';
import '../widgets/layouts/friends_card.dart';
import '../widgets/layouts/menu_card.dart';
import '../widgets/layouts/profile_card.dart';
import '../widgets/layouts/settings_sheet.dart';
import '../widgets/layouts/badges_card.dart';

class ProfilePage extends StatefulWidget {
  final bool isDarkMode;
  final bool isCoach;
  final String? avatarUrl;
  final String? userName;
  final String? userEmail;
  final Future<void> Function()? onLogout;
  final Function(bool) onThemeChanged;

  const ProfilePage({
    super.key,
    required this.isDarkMode,
    required this.isCoach,
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
  final _friendService = FriendService();

  List<Friend> _friends = [];
  bool _friendsLoading = true;

  List<RepzBadge> _badges = [];
  bool _badgesLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFriends();
    _fetchBadges();
  }

  Future<void> _fetchFriends() async {
    try {
      final friends = await _friendService.fetchFriends();
      if (mounted) {
        setState(() {
          _friends = friends;
          _friendsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _friendsLoading = false);
    }
  }

  Future<void> _fetchBadges() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _badgesLoading = false);
        return;
      }

      final response = await Supabase.instance.client
          .from('badges')
          .select()
          .eq('user_id', userId)
          .order('created_at');

      if (mounted) {
        setState(() {
          _badges = (response as List)
              .map((row) => RepzBadge.fromMap(row as Map<String, dynamic>))
              .toList();
          _badgesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _badgesLoading = false);
    }
  }

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
              isLoading: _friendsLoading,
              onAddFriend: () {
                // TODO: navigate to AddFriendPage
              },
              onFriendTap: (friend) {
                // TODO: open friend profile
              },
            ),
            const SizedBox(height: 12),
            if (_badgesLoading)
              _BadgesShimmer(isDarkMode: widget.isDarkMode)
            else if (_badges.isNotEmpty)
              BadgesCard(
                isDarkMode: widget.isDarkMode,
                badges: _badges,
              ),
            const SizedBox(height: 12),
            MenuCard(
              isDarkMode: widget.isDarkMode,
              isCoach: widget.isCoach,
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgesShimmer extends StatelessWidget {
  final bool isDarkMode;

  const _BadgesShimmer({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final shimmerColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 12,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(
              5,
                  (i) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: shimmerColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 40,
                      height: 8,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}