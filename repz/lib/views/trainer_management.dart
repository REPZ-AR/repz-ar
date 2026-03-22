import 'package:flutter/material.dart';
import '../model/trainer.dart';
import '../services/trainer_service.dart';
import '../utils/theme_helper.dart';
import '../widgets/common/trainer_card.dart';

class TrainerManagementPage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback? onBack;

  const TrainerManagementPage({
    Key? key,
    required this.isDarkMode,
    this.onBack,
  }) : super(key: key);

  @override
  State<TrainerManagementPage> createState() =>
      _TrainerManagementPageState();
}

class _TrainerManagementPageState
    extends State<TrainerManagementPage> {
  static const String _bgAsset = 'assets/images/client_ui_image.png';

  List<Trainer> _trainers = [];
  List<Trainer> _filtered = [];
  bool _loading = true;
  String? _expandedTrainerId;
  final _searchController = TextEditingController();

  final _service = TrainerService();

  @override
  void initState() {
    super.initState();
    _loadTrainers();
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
          ? _trainers
          : _trainers
          .where((t) => t.name.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _loadTrainers() async {
    setState(() => _loading = true);
    try {
      final trainers = await _service.fetchTrainers();
      setState(() {
        _trainers = trainers;
        _filtered = trainers;
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

  void _openAddTrainerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTrainerSheet(
        service: _service,
        isDarkMode: widget.isDarkMode,
        onAdded: _loadTrainers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor =
        AppTheme.getAccentColor(widget.isDarkMode) ??
            const Color(0xFF6C63FF);
    final textColor =
        AppTheme.getTextColor(widget.isDarkMode) ?? Colors.black;
    final cardColor = widget.isDarkMode
        ? const Color(0xFF1E1E1E).withAlpha(200)
        : const Color(0xFFF5F5F5).withAlpha(200);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image ──────────────────────────
          Positioned.fill(
            child: Image.asset(
              _bgAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
              const ColoredBox(color: Colors.black),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black
                  .withAlpha(widget.isDarkMode ? 160 : 80),
            ),
          ),

          // ── Main content ──────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────
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
                          child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: textColor),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            const Text('My Trainers',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5)),
                            Text(
                                'Manage your trainer connections',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70)),
                          ],
                        ),
                      ),
                      // ── Add Trainer button in header ───
                      GestureDetector(
                        onTap: _openAddTrainerSheet,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                              Icons.person_add_rounded,
                              size: 20,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Search bar ───────────────────────────
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style:
                      const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search trainers...',
                        hintStyle: const TextStyle(
                            color: Colors.white54, fontSize: 14),
                        prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Colors.white54,
                            size: 20),
                        suffixIcon:
                        _searchController.text.isNotEmpty
                            ? GestureDetector(
                          onTap: () =>
                              _searchController.clear(),
                          child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white54,
                              size: 18),
                        )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Section header ───────────────────────
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Active Trainers (${_trainers.length})',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                        letterSpacing: 0.5),
                  ),
                ),

                const SizedBox(height: 10),

                // ── Trainer List ─────────────────────────
                Expanded(
                  child: _loading
                      ? Center(
                      child: CircularProgressIndicator(
                          color: accentColor))
                      : _trainers.isEmpty
                      ? _buildEmptyState(accentColor)
                      : RefreshIndicator(
                    onRefresh: _loadTrainers,
                    color: accentColor,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          20, 0, 20, 100),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final trainer = _filtered[index];
                        final isExpanded =
                            _expandedTrainerId ==
                                trainer.id;
                        return TrainerCard(
                          trainer: trainer,
                          isExpanded: isExpanded,
                          isDarkMode: widget.isDarkMode,
                          accentColor: accentColor,
                          cardColor: cardColor,
                          onTap: () => setState(() {
                            _expandedTrainerId =
                            isExpanded
                                ? null
                                : trainer.id;
                          }),
                          onRemove: () async {
                            await _service.removeTrainer(
                                trainerUserId: trainer.id);
                            _loadTrainers();
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Floating stats strip ──────────────────────
          if (!_loading && _trainers.isNotEmpty)
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
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
                    _statItem(
                        Icons.people_rounded,
                        '${_trainers.length}',
                        'Trainers',
                        accentColor,
                        widget.isDarkMode),
                    _statDivider(widget.isDarkMode),
                    _statItem(
                        Icons.check_circle_outline_rounded,
                        '${_trainers.length}',
                        'Active',
                        const Color(0xFF4CAF50),
                        widget.isDarkMode),
                    _statDivider(widget.isDarkMode),
                    _statItem(
                        Icons.calendar_today_rounded,
                        '0',
                        'Sessions',
                        const Color(0xFFFFC107),
                        widget.isDarkMode),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label,
      Color color, bool isDarkMode) {
    final textColor =
    isDarkMode ? Colors.white : const Color(0xFF1A1A1A);
    final subColor =
    isDarkMode ? Colors.white54 : const Color(0xFF888888);
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
        Text(label,
            style: TextStyle(fontSize: 11, color: subColor)),
      ],
    );
  }

  Widget _statDivider(bool isDarkMode) {
    return Container(
      height: 36,
      width: 1,
      color: isDarkMode ? Colors.white12 : Colors.black12,
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
            child: Icon(Icons.fitness_center_rounded,
                size: 40, color: accentColor),
          ),
          const SizedBox(height: 20),
          const Text('No trainers yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Tap + to find a trainer',
              style: TextStyle(
                  fontSize: 14, color: Colors.white70)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _openAddTrainerSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text('Find a Trainer',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add Trainer Sheet ────────────────────────────────────────────────────────
class _AddTrainerSheet extends StatefulWidget {
  final TrainerService service;
  final bool isDarkMode;
  final VoidCallback onAdded;

  const _AddTrainerSheet({
    required this.service,
    required this.isDarkMode,
    required this.onAdded,
  });

  @override
  State<_AddTrainerSheet> createState() => _AddTrainerSheetState();
}

class _AddTrainerSheetState extends State<_AddTrainerSheet> {
  List<Trainer> _available = [];
  bool _loading = true;
  String? _addingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final trainers = await widget.service.fetchAvailableTrainers();
    setState(() {
      _available = trainers;
      _loading = false;
    });
  }

  Future<void> _add(Trainer trainer) async {
    setState(() => _addingId = trainer.id);
    try {
      await widget.service.addTrainer(trainerUserId: trainer.id);
      widget.onAdded();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add trainer: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _addingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isDarkMode
        ? const Color(0xFFCFF500)
        : const Color(0xFF6C63FF);
    final sheetColor = widget.isDarkMode
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFF9F9F9);
    final textColor =
    widget.isDarkMode ? Colors.white : Colors.black;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: sheetColor,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(80),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Find a Trainer',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? Center(
                  child: CircularProgressIndicator(
                      color: accentColor))
                  : _available.isEmpty
                  ? const Center(
                  child: Text('No available trainers',
                      style:
                      TextStyle(color: Colors.grey)))
                  : ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                    20, 0, 20, 32),
                itemCount: _available.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final trainer = _available[index];
                  final isAdding =
                      _addingId == trainer.id;
                  return _AvailableTrainerTile(
                    trainer: trainer,
                    accentColor: accentColor,
                    isDarkMode: widget.isDarkMode,
                    isAdding: isAdding,
                    onAdd: () => _add(trainer),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailableTrainerTile extends StatelessWidget {
  final Trainer trainer;
  final Color accentColor;
  final bool isDarkMode;
  final bool isAdding;
  final VoidCallback onAdd;

  const _AvailableTrainerTile({
    required this.trainer,
    required this.accentColor,
    required this.isDarkMode,
    required this.isAdding,
    required this.onAdd,
  });

  String get _initials {
    final parts = trainer.name.trim().split(' ');
    if (parts.length >= 2)
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return trainer.name.isNotEmpty
        ? trainer.name[0].toUpperCase()
        : '?';
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = isDarkMode
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFEEEEEE);
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border(
            left: BorderSide(
                color: const Color(0xFF4CAF50), width: 4)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor.withAlpha(40),
              borderRadius: BorderRadius.circular(14),
            ),
            child: trainer.avatarUrl != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(trainer.avatarUrl!,
                  fit: BoxFit.cover),
            )
                : Center(
              child: Text(_initials,
                  style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trainer.name,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Available',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4CAF50))),
                ),
              ],
            ),
          ),
          isAdding
              ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: accentColor),
          )
              : GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_rounded,
                  color: Colors.black, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}