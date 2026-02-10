import 'package:flutter/material.dart';
import '../model/client.dart';
import '../widgets/common/client_card.dart';
import '../widgets/common/tab_selector.dart';
import '../utils/theme_helper.dart';

class TrainerManagementPage extends StatefulWidget {
  final bool isDarkMode;
  final bool isCoach;

  const TrainerManagementPage({Key? key, required this.isDarkMode, required this.isCoach}) : super(key: key);

  @override
  State<TrainerManagementPage> createState() => _TrainerManagementPageState();
}

class _TrainerManagementPageState extends State<TrainerManagementPage> {
  bool isOnlineClients = true;
  int? selectedClientIndex;

  // Sample data
  final List<Client> clients = const [
    Client(name: 'Adam Park', subtitle: 'Active Plan'),
    Client(name: 'Sarah Johnson', subtitle: 'Premium Member'),
    Client(name: 'Mike Chen', subtitle: 'Beginner'),
    Client(name: 'Emma Wilson', subtitle: '3 Months'),
    Client(name: 'James Smith', subtitle: 'Weight Loss Goal'),
    Client(name: 'Emma Wales', subtitle: 'Weight Loss Goal'),
  ];

  @override
  Widget build(BuildContext context) {
    final accentColor = AppTheme.getAccentColor(widget.isDarkMode);
    final backgroundColor = AppTheme.getBackgroundColor(widget.isDarkMode);
    final textColor = AppTheme.getTextColor(widget.isDarkMode);
    final secondaryTextColor = AppTheme.getSecondaryTextColor(widget.isDarkMode);

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
            child: TabSelector(
              isFirstTabSelected: isOnlineClients,
              firstTabLabel: 'Online Clients',
              secondTabLabel: 'Gym Clients',
              onTabChanged: (value) => setState(() => isOnlineClients = value),
              accentColor: accentColor,
              secondaryTextColor: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 20),

          // Client List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: clients.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return ClientCard(
                  client: clients[index],
                  isDarkMode: widget.isDarkMode,
                  accentColor: accentColor,
                  isHighlighted: selectedClientIndex == index, // Check if selected
                  onTap: () {
                    setState(() {
                      selectedClientIndex = index; // Update selected index
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}