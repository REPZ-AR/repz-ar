import 'package:flutter/material.dart';

class ClientManagementPage extends StatefulWidget {
  const ClientManagementPage({Key? key}) : super(key: key);

  @override
  State<ClientManagementPage> createState() => _ClientManagementPageState();
}

class _ClientManagementPageState extends State<ClientManagementPage> {
  bool isOnlineClients = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Meet Your Clients',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
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
                        color: isOnlineClients ? const Color(0xFFE8D5FF) : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          'Online Clients',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isOnlineClients ? const Color(0xFF7B2CBF) : Colors.grey,
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
                        color: !isOnlineClients ? const Color(0xFFE8D5FF) : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          'Gym Clients',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: !isOnlineClients ? const Color(0xFF7B2CBF) : Colors.grey,
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
                // First Client - Adam Park (with highlight)
                _buildClientCard(
                  name: 'Adam Park',
                  time: '00 mins',
                  isHighlighted: false,
                  avatarColor: Colors.orange,
                ),
                const SizedBox(height: 12),

                // Second Client - Highlighted in purple
                _buildClientCard(
                  name: 'Type Here',
                  time: '00 mins',
                  isHighlighted: true,
                  avatarColor: Colors.green,
                ),
                const SizedBox(height: 12),

                // Remaining Clients
                _buildClientCard(
                  name: 'Type Here',
                  time: '00 mins',
                  isHighlighted: false,
                  avatarColor: Colors.pink,
                ),
                const SizedBox(height: 12),

                _buildClientCard(
                  name: 'Type Here',
                  time: '00 mins',
                  isHighlighted: false,
                  avatarColor: Colors.blue,
                ),
                const SizedBox(height: 12),

                _buildClientCard(
                  name: 'Type Here',
                  time: '00 mins',
                  isHighlighted: false,
                  avatarColor: Colors.purple,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildClientCard({
    required String name,
    required String time,
    required bool isHighlighted,
    required Color avatarColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFFB565F5) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
                    color: isHighlighted ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: isHighlighted ? Colors.white.withOpacity(0.8) : Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Action Button
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHighlighted ? Colors.white : const Color(0xFF4A4A4A),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isHighlighted ? Icons.pause : Icons.arrow_forward_ios,
              color: isHighlighted ? const Color(0xFFB565F5) : Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF7B2CBF),
        unselectedItemColor: Colors.grey,
        currentIndex: 2,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library_outlined),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}