import 'package:flutter/material.dart';
import '../model/trainer.dart';
import '../services/trainer_service.dart';
import '../utils/theme_helper.dart';
import '../widgets/common/trainer_card.dart';

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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              _bgAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, _, __) =>
              const ColoredBox(color: Colors.black),
            ),
          ),

          // Dark overlay
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withAlpha(widget.isDarkMode ? 160 : 80),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
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
                            const Text(
                              'My Trainers',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              '${_trainers.length} active trainers',
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Trainer list
                Expanded(
                  child: _loading
                      ? Center(
                      child: CircularProgressIndicator(color: accentColor))
                      : _trainers.isEmpty
                      ? _buildEmptyState(accentColor)
                      : RefreshIndicator(
                    onRefresh: _loadTrainers,
                    color: accentColor,
                    child: ListView.builder(
                      padding:
                      const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      itemCount: _trainers.length,
                      itemBuilder: (context, index) {
                        final trainer = _trainers[index];
                        final isExpanded =
                            _expandedTrainerId == trainer.id;
                        return TrainerCard(
                          trainer: trainer,
                          isExpanded: isExpanded,
                          isDarkMode: widget.isDarkMode,
                          accentColor: accentColor,
                          cardColor: cardColor,
                          onTap: () {
                            setState(() {
                              _expandedTrainerId =
                              isExpanded ? null : trainer.id;
                            });
                          },
                          onAddSchedule: () {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Schedule with ${trainer.name}'),
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
          const Text(
            'No trainers yet',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'You have no trainers assigned',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}