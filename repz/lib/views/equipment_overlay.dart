import 'package:flutter/material.dart';

class EquipmentOverlay extends StatelessWidget {
  const EquipmentOverlay({super.key, required this.equipmentName});

  final String equipmentName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Equipment detected'),
      content: Text(equipmentName),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
