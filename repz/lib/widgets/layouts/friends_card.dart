import 'package:flutter/material.dart';
import 'friend_bubble.dart';

class FriendsCard extends StatelessWidget {
  final bool isDarkMode;
  final List<Map<String, String>> friends;
  final List<Color> avatarColors;
  final List<Color> avatarTextColors;
  final VoidCallback onAddFriend;
  final void Function(Map<String, String> friend) onFriendTap;

  const FriendsCard({
    super.key,
    required this.isDarkMode,
    required this.friends,
    required this.avatarColors,
    required this.avatarTextColors,
    required this.onAddFriend,
    required this.onFriendTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor =
    isDarkMode ? const Color(0xFFCFF500) : const Color(0xFFA66CFF);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = primaryTextColor.withValues(alpha: 0.55);
    final dividerColor = primaryTextColor.withValues(alpha: 0.08);

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

          // Horizontal scrolling avatars
          SizedBox(
            height: 86,
            child: ListView.separated(
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
                final colorIndex = index % avatarColors.length;
                return FriendBubble(
                  initials: friend['initials']!,
                  name: friend['name']!,
                  bgColor: avatarColors[colorIndex],
                  textColor: avatarTextColors[colorIndex],
                  onTap: () => onFriendTap(friend),
                );
              },
            ),
          ),

          const SizedBox(height: 4),
          Divider(height: 1, color: dividerColor),

          // Add friend wide button
          InkWell(
            onTap: onAddFriend,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_outlined, size: 18, color: accentColor),
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