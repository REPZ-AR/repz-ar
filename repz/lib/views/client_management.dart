import 'package:flutter/material.dart';
import '../model/client.dart';
import '../services/client_service.dart';
import '../utils/theme_helper.dart';
import '../widgets/common/client_card.dart';
import 'client_detail_page.dart';
import 'trainer_plan_library_page.dart';
import 'trainer_schedule_editor_page.dart';

class ClientManagementPage extends StatefulWidget {
  final bool isDarkMode;
  const ClientManagementPage({Key? key, required this.isDarkMode})
      : super(key: key);

  @override
  State<ClientManagementPage> createState() => _ClientManagementPageState();
}

class _ClientManagementPageState extends State<ClientManagementPage> {
  static const String _bgAsset = 'assets/images/client_ui_image.png';

  List<Client> _clients = [];
  bool _loading = true;
  String? _expandedClientId;

  final _service = ClientService();

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() => _loading = true);
    try {
      final clients = await _service.fetchClients();
      setState(() => _clients = clients);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openClientDetail(Client client) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => ClientDetailPage(
              client: client,
              isDarkMode: widget.isDarkMode,
            ),
      ),
    );
    if (mounted) {
      await _loadClients();
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

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image ────────────────────────────────
          Positioned.fill(
            child: Image.asset(
              _bgAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, _, __) {
                return const ColoredBox(color: Colors.black);
              },
            ),
          ),

          // ── Dark overlay ────────────────────────────────────
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withAlpha(widget.isDarkMode ? 200 : 150),
            ),
          ),

          // ── Main content ────────────────────────────────────
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
                        onTap: () => Navigator.pop(context),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('My Clients',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5)),
                            Text('${_clients.length} active clients',
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

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
                      padding:
                      const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      itemCount: _clients.length,
                      itemBuilder: (context, index) {
                        final client = _clients[index];
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
                          onViewClient: () => _openClientDetail(client),
                          onAssignPlan: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => TrainerPlanLibraryPage(
                                      isDarkMode: widget.isDarkMode,
                                      preselectedClientId: client.id,
                                    ),
                              ),
                            );
                            if (mounted) {
                              await _loadClients();
                            }
                          },
                          onProposeSchedule: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => TrainerScheduleEditorPage(
                                      client: client,
                                      isDarkMode: widget.isDarkMode,
                                    ),
                              ),
                            );
                            if (mounted) {
                              await _loadClients();
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
