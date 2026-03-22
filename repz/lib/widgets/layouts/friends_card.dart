import 'package:flutter/material.dart';
import '../../model/friend.dart';
import 'friend_bubble.dart';

class FriendsCard extends StatelessWidget {
  final bool isDarkMode;
  final List<Friend> friends;
  final bool isLoading;
  final VoidCallback onAddFriend;
  final void Function(Friend friend) onFriendTap;

  const FriendsCard({
    super.key,
    required this.isDarkMode,
    required this.friends,
    required this.isLoading,
    required this.onAddFriend,
    required this.onFriendTap,
  });

  // Same rotating colors as before
  static const _avatarColors = [
    Color(0xFFEEEDFE), Color(0xFFE1F5EE),
    Color(0xFFFAECE7), Color(0xFFFAEEDA), Color(0xFFFBEAF0),
  ];
  static const _avatarTextColors = [
    Color(0xFF3C3489), Color(0xFF085041),
    Color(0xFF712B13), Color(0xFF633806), Color(0xFF72243E),
  ];

  @override
  Widget build(BuildContext context) {
    final accentColor =
    isDarkMode ? const Color(0xFFCFF500) : const Color(0xFFA66CFF);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = primaryTextColor.withValues(alpha: 0.55);
    final dividerColor = primaryTextColor.withValues(alpha: 0.08);
    final shimmerColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              'Friends',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: secondaryTextColor,
                letterSpacing: 0.3,
              ),
            ),
          ),

          SizedBox(
            height: 86,
            child: isLoading
                ? ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, __) => Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: shimmerColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 36,
                    height: 8,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            )
                : ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: friends.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                if (index == friends.length) {
                  return FriendBubble(
                    isAddButton: true,
                    onTap: onAddFriend,
                  );
                }
                final friend = friends[index];
                final colorIndex = index % _avatarColors.length;
                return FriendBubble(
                  initials: friend.initials,
                  name: friend.name,
                  avatarUrl: friend.avatarUrl,
                  bgColor: _avatarColors[colorIndex],
                  textColor: _avatarTextColors[colorIndex],
                  onTap: () => onFriendTap(friend),
                );
              },
            ),
          ),

          const SizedBox(height: 4),
          Divider(height: 1, color: dividerColor),

          InkWell(
            onTap: onAddFriend,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_outlined,
                      size: 18, color: accentColor),
                  const SizedBox(width: 8),
                  Text(
                    'Add a friend',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: primaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}