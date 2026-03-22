import 'package:flutter/material.dart';

class FriendBubble extends StatelessWidget {
  final String? initials;
  final String? name;
  final String? avatarUrl;
  final Color? bgColor;
  final Color? textColor;
  final bool isAddButton;
  final VoidCallback? onTap;

  const FriendBubble({
    super.key,
    this.initials,
    this.name,
    this.avatarUrl,
    this.bgColor,
    this.textColor,
    this.isAddButton = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = avatarUrl != null && avatarUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAddButton)
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.35),
                  width: 1.5,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: const Icon(Icons.add_rounded,
                  size: 22, color: Colors.grey),
            )
          else
            CircleAvatar(
              radius: 26,
              backgroundColor: bgColor,
              foregroundImage:
              hasPhoto ? NetworkImage(avatarUrl!) : null,
              child: hasPhoto
                  ? null
                  : Text(
                initials ?? '',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            isAddButton ? 'Add' : (name ?? ''),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.withValues(alpha: 0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}