import 'package:flutter/material.dart';
import '../model/trainer.dart';
import '../services/trainer_service.dart';
import '../utils/theme_helper.dart';
import '../widgets/common/trainer_list.dart';

class TrainerManagementPage extends StatefulWidget {
  final bool isDarkMode;

  const TrainerManagementPage({Key? key, required this.isDarkMode})
      : super(key: key);

  @override
  State<TrainerManagementPage> createState() => _TrainerManagementPageState();
}

class _TrainerManagementPageState extends State<TrainerManagementPage> {
  static const String _bgAsset = 'assets/images/client_ui_image.png';

  List<Trainer> _trainers = [];
  bool _loading = true;
  String? _expandedTrainerId;

  final _service = TrainerService();

  @override
  void initState() {
    super.initState();
    _loadTrainers();
  }

  Future<void> _loadTrainers() async {
    setState(() => _loading = true);
    try {
      final trainers = await _service.fetchTrainers();
      setState(() => _trainers = trainers);
    } finally {
      setState(() => _loading = false);
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
        onAdded: _loadTrainers, // refresh list after adding
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor =
        AppTheme.getAccentColor(widget.isDarkMode) ?? const Color(0xFF6C63FF);
    final textColor =
        AppTheme.getTextColor(widget.isDarkMode) ?? Colors.black;
    final cardColor = widget.isDarkMode
        ? const Color(0xFF1E1E1E).withAlpha(200)
        : const Color(0xFFF5F5F5).withAlpha(200);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTrainerSheet,
        backgroundColor: accentColor,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
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
              color: Colors.black.withAlpha(widget.isDarkMode ? 160 : 80),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                            const Text('My Trainers',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5)),
                            Text('${_trainers.length} active trainers',
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _loading
                      ? Center(
                      child:
                      CircularProgressIndicator(color: accentColor))
                      : _trainers.isEmpty
                      ? _buildEmptyState(accentColor)
                      : TrainerList(
                    trainers: _trainers,
                    expandedTrainerId: _expandedTrainerId,
                    isDarkMode: widget.isDarkMode,
                    accentColor: accentColor,
                    cardColor: cardColor,
                    onRefresh: _loadTrainers,
                    onToggleExpand: (id) => setState(() {
                      _expandedTrainerId =
                      _expandedTrainerId == id ? null : id;
                    }),
                    onRemove: (trainer) async {
                      await _service.removeTrainer(trainerUserId: trainer.id);
                      _loadTrainers();
                    },
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
              style: TextStyle(fontSize: 14, color: Colors.white70)),
        ],
      ),
    );
  }
}

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
  String? _addingId; // tracks which trainer is being added

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

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: sheetColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
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

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Find a Trainer',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: widget.isDarkMode
                              ? Colors.white
                              : Colors.black)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // List
            Expanded(
              child: _loading
                  ? Center(
                  child: CircularProgressIndicator(color: accentColor))
                  : _available.isEmpty
                  ? const Center(
                  child: Text('No available trainers',
                      style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                itemCount: _available.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final trainer = _available[index];
                  final isAdding = _addingId == trainer.id;
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
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return trainer.name.isNotEmpty ? trainer.name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = isDarkMode
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFEEEEEE);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Avatar
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
              child: Image.network(trainer.avatarUrl!, fit: BoxFit.cover),
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

          // Name
          Expanded(
            child: Text(
              trainer.name,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black),
            ),
          ),

          // Add button
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
                  color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}