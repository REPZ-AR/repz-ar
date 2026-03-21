import 'package:flutter/material.dart';
import '../model/client.dart';
import '../services/client_service.dart';
import '../widgets/common/client_card.dart';
import '../widgets/common/tab_selector.dart';
import '../utils/theme_helper.dart';

class ClientManagementPage extends StatefulWidget {
  final bool isDarkMode;
  const ClientManagementPage({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  State<ClientManagementPage> createState() => _ClientManagementPageState();
}

class _ClientManagementPageState extends State<ClientManagementPage> {
  bool _isOnlineTab = true;
  int? _selectedIndex;
  List<Client> _clients = [];
  bool _loading = true;

  final _service = ClientService();

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() => _loading = true);
    try {
      final clients = await _service.fetchClients(
        clientType: _isOnlineTab ? 'online' : 'gym',
      );
      setState(() => _clients = clients);
    } finally {
      setState(() => _loading = false);
    }
  }

  // Call this when the tab changes
  void _onTabChanged(bool isOnline) {
    setState(() {
      _isOnlineTab = isOnline;
      _selectedIndex = null;
    });
    _loadClients();
  }

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Meet Your Clients',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TabSelector(
              isFirstTabSelected: _isOnlineTab,
              firstTabLabel: 'Online Clients',
              secondTabLabel: 'Gym Clients',
              onTabChanged: _onTabChanged,
              accentColor: accentColor,
              secondaryTextColor: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _clients.isEmpty
                ? Center(
              child: Text('No clients yet', style: TextStyle(color: secondaryTextColor)),
            )
                : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _clients.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => ClientCard(
                client: _clients[index],
                isDarkMode: widget.isDarkMode,
                accentColor: accentColor,
                isHighlighted: _selectedIndex == index,
                onTap: () => setState(() => _selectedIndex = index),
              ),
            ),
          ),
        ],
      ),
    );
  }
}