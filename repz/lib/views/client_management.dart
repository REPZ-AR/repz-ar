import 'package:flutter/material.dart';
import '../model/client.dart';
import '../services/client_service.dart';
import '../utils/theme_helper.dart';
import '../widgets/common/client_card.dart';

class ClientManagementPage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback? onBack;

  const ClientManagementPage({
    Key? key,
    required this.isDarkMode,
    this.onBack,
  }) : super(key: key);

  @override
  State<ClientManagementPage> createState() => _ClientManagementPageState();
}

class _ClientManagementPageState extends State<ClientManagementPage> {
  static const String _bgAsset = 'assets/images/client_ui_image.png';

  List<Client> _clients = [];
  List<Client> _filtered = [];
  bool _loading = true;
  String? _expandedClientId;
  final _searchController = TextEditingController();

  final _service = ClientService();

  @override
  void initState() {
    super.initState();
    _loadClients();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? _clients
          : _clients
          .where((c) => c.name.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _loadClients() async {
    setState(() => _loading = true);
    try {
      final clients = await _service.fetchClients();
      setState(() {
        _clients = clients;
        _filtered = clients;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  void _handleBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      widget.onBack?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor =
        AppTheme.getAccentColor(widget.isDarkMode) ?? const Color(0xFF6C63FF);
    final backgroundColor =
        AppTheme.getBackgroundColor(widget.isDarkMode) ?? Colors.white;
    final textColor =
        AppTheme.getTextColor(widget.isDarkMode) ?? Colors.black;
    final cardColor = widget.isDarkMode
        ? const Color(0xFF1E1E1E).withAlpha(200)
        : const Color(0xFFF5F5F5).withAlpha(200);

    final activeCount = _clients.where((c) => c.status == 'active').length;
    final pendingCount = _clients.where((c) => c.status == 'pending').length;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image ──────────────────────────────
          Positioned.fill(
            child: Image.asset(
              _bgAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, _, __) =>
              const ColoredBox(color: Colors.black),
            ),
          ),

          // ── Dark overlay ──────────────────────────────────
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withAlpha(widget.isDarkMode ? 160 : 80),
            ),
          ),

          // ── Main content ──────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _handleBack,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.arrow_back_ios_new_rounded,
                              size: 18, color: textColor),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('My Clients',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5)),
                            Text('Manage your client list',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Search bar ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search clients...',
                        hintStyle: const TextStyle(
                            color: Colors.white54, fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: Colors.white54, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? GestureDetector(
                          onTap: () => _searchController.clear(),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white54, size: 18),
                        )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Section header ───────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'Active Clients ($activeCount)',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                            letterSpacing: 0.5),
                      ),
                      if (pendingCount > 0) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC107).withAlpha(40),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$pendingCount pending',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFFC107)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ── Client List ──────────────────────────────
                Expanded(
                  child: _loading
                      ? Center(
                      child:
                      CircularProgressIndicator(color: accentColor))
                      : _clients.isEmpty
                      ? _buildEmptyState(accentColor)
                      : RefreshIndicator(
                    onRefresh: _loadClients,
                    color: accentColor,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          20, 0, 20, 100),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final client = _filtered[index];
                        final isExpanded =
                            _expandedClientId == client.id;
                        return ClientCard(
                          client: client,
                          isExpanded: isExpanded,
                          isDarkMode: widget.isDarkMode,
                          accentColor: accentColor,
                          cardColor: cardColor,
                          onTap: () {
                            setState(() {
                              _expandedClientId =
                              isExpanded ? null : client.id;
                            });
                          },
                          onAddSchedule: () {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Add schedule for ${client.name}'),
                                backgroundColor: accentColor,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Floating stats strip ──────────────────────────
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? const Color(0xFF1E1E1E).withAlpha(230)
                    : Colors.white.withAlpha(230),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statItem(Icons.people_rounded, '${_clients.length}',
                      'Clients', accentColor),
                  _statDivider(),
                  _statItem(Icons.check_circle_outline_rounded,
                      '$activeCount', 'Active', const Color(0xFF4CAF50)),
                  _statDivider(),
                  _statItem(Icons.calendar_today_rounded, '0', 'Schedules',
                      const Color(0xFFFFC107)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(
      IconData icon, String value, String label, Color color) {
    final textColor =
    widget.isDarkMode ? Colors.white : const Color(0xFF1A1A1A);
    final subColor =
    widget.isDarkMode ? Colors.white54 : const Color(0xFF888888);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor)),
        Text(label, style: TextStyle(fontSize: 11, color: subColor)),
      ],
    );
  }

  Widget _statDivider() {
    return Container(
      height: 36,
      width: 1,
      color: widget.isDarkMode ? Colors.white12 : Colors.black12,
    );
  }

  Widget _buildEmptyState(Color accentColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: accentColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_outline_rounded,
                size: 40, color: accentColor),
          ),
          const SizedBox(height: 20),
          const Text('No clients yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Add your first client to get started',
              style: TextStyle(fontSize: 14, color: Colors.white70)),
        ],
      ),
    );
  }
}