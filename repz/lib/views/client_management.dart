import 'package:flutter/material.dart';

class ClientManagementPage extends StatefulWidget {
  final bool isDarkMode;

  const ClientManagementPage({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  State<ClientManagementPage> createState() => _ClientManagementPageState();
}

class _ClientManagementPageState extends State<ClientManagementPage> {
  bool isOnlineClients = true;

  @override
  Widget build(BuildContext context) {
    // Theme colors matching HomePage
    final accentColor = widget.isDarkMode ? const Color(0xFFCFF500) : const Color(0xFFA66CFF);
    final backgroundColor = widget.isDarkMode ? const Color(0xFF121212) : Colors.white;
    final cardColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = widget.isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Meet Your Clients',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Tab Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isOnlineClients = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isOnlineClients
                            ? accentColor.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isOnlineClients ? accentColor : Colors.grey.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Online Clients',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isOnlineClients ? accentColor : secondaryTextColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isOnlineClients = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !isOnlineClients
                            ? accentColor.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: !isOnlineClients ? accentColor : Colors.grey.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Gym Clients',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: !isOnlineClients ? accentColor : secondaryTextColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Client List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // First Client - Adam Park
                _buildClientCard(
                  name: 'Adam Park',
                  time: '00 mins',
                  isHighlighted: false,
                  avatarColor: Colors.orange,
                  cardColor: cardColor,
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                  accentColor: accentColor,
                ),
                const SizedBox(height: 12),

                // Second Client - Highlighted
                _buildClientCard(
                  name: 'Type Here',
                  time: '00 mins',
                  isHighlighted: true,
                  avatarColor: Colors.green,
                  cardColor: cardColor,
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                  accentColor: accentColor,
                ),
                const SizedBox(height: 12),

                // Remaining Clients
                _buildClientCard(
                  name: 'Type Here',
                  time: '00 mins',
                  isHighlighted: false,
                  avatarColor: Colors.pink,
                  cardColor: cardColor,
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                  accentColor: accentColor,
                ),
                const SizedBox(height: 12),

                _buildClientCard(
                  name: 'Type Here',
                  time: '00 mins',
                  isHighlighted: false,
                  avatarColor: Colors.blue,
                  cardColor: cardColor,
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                  accentColor: accentColor,
                ),
                const SizedBox(height: 12),

                _buildClientCard(
                  name: 'Type Here',
                  time: '00 mins',
                  isHighlighted: false,
                  avatarColor: Colors.purple,
                  cardColor: cardColor,
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                  accentColor: accentColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard({
    required String name,
    required String time,
    required bool isHighlighted,
    required Color avatarColor,
    required Color cardColor,
    required Color textColor,
    required Color? secondaryTextColor,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted ? accentColor : cardColor,
        borderRadius: BorderRadius.circular(15),
        border: isHighlighted
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
            backgroundColor: avatarColor.withOpacity(0.3),
            child: const Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 12),

          // Name and Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isHighlighted ? Colors.black : textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: isHighlighted
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
              color: isHighlighted
                  ? Colors.black
                  : (widget.isDarkMode ? Colors.grey[700] : const Color(0xFF4A4A4A)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isHighlighted ? Icons.pause : Icons.arrow_forward_ios,
              color: isHighlighted ? accentColor : Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}