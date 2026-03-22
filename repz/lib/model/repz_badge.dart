import 'package:flutter/material.dart';

class RepzBadge {
  final String month;
  final String label;
  final String description;
  final bool earned;
  final IconData icon;
  final Color bgColor;
  final Color borderColor;
  final Color iconColor;

  const RepzBadge({
    required this.month,
    required this.label,
    required this.description,
    required this.earned,
    required this.icon,
    required this.bgColor,
    required this.borderColor,
    required this.iconColor,
  });
}