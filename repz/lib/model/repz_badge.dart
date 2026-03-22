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

  factory RepzBadge.fromMap(Map<String, dynamic> map) {
    return RepzBadge(
      month: map['month'] as String,
      label: map['label'] as String,
      description: map['description'] as String,
      earned: map['earned'] as bool,
      icon: IconData(
        map['icon_code_point'] as int,
        fontFamily: 'MaterialIcons',
      ),
      bgColor: Color(map['bg_color'] as int),
      borderColor: Color(map['border_color'] as int),
      iconColor: Color(map['icon_color'] as int),
    );
  }
}