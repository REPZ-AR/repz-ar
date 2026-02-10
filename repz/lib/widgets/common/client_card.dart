import 'package:flutter/material.dart';
import '../../model/client.dart';

class ClientCard extends StatelessWidget {
  final Client client;
  final bool isDarkMode;
  final Color accentColor;
  final VoidCallback? onTap;

  const ClientCard({
    Key? key,
    required this.client,
    required this.isDarkMode,
    required this.accentColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: client.isHighlighted ? accentColor : cardColor,
          borderRadius: BorderRadius.circular(15),
          border: client.isHighlighted
              ? null
              : Border.all(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.purple.withOpacity(0.3),
              child: Text(
                client.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: client.isHighlighted ? Colors.black : textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    client.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: client.isHighlighted
                          ? Colors.black.withOpacity(0.6)
                          : secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),

            // Action Button
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: client.isHighlighted
                    ? Colors.black
                    : (isDarkMode ? Colors.grey[700] : const Color(0xFF4A4A4A)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                color: client.isHighlighted ? accentColor : Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}