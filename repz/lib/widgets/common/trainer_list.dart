import 'package:flutter/material.dart';
import '../../model/trainer.dart';
import 'trainer_card.dart';

class TrainerList extends StatelessWidget {
  final List<Trainer> trainers;
  final String? expandedTrainerId;
  final bool isDarkMode;
  final Color accentColor;
  final Color cardColor;
  final VoidCallback onRefresh;
  final void Function(String id) onToggleExpand;
  final void Function(Trainer trainer) onRemove;

  const TrainerList({
    Key? key,
    required this.trainers,
    required this.expandedTrainerId,
    required this.isDarkMode,
    required this.accentColor,
    required this.cardColor,
    required this.onRefresh,
    required this.onToggleExpand,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: accentColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        itemCount: trainers.length,
        itemBuilder: (context, index) {
          final trainer = trainers[index];
          final isExpanded = expandedTrainerId == trainer.id;
          return TrainerCard(
            trainer: trainer,
            isExpanded: isExpanded,
            isDarkMode: isDarkMode,
            accentColor: accentColor,
            cardColor: cardColor,
            onTap: () => onToggleExpand(trainer.id),
            onRemove: () => onRemove(trainer),
          );
        },
      ),
    );
  }
}