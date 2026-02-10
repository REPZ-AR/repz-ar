import 'package:flutter/material.dart';

class TabSelector extends StatelessWidget {
  final bool isFirstTabSelected;
  final String firstTabLabel;
  final String secondTabLabel;
  final Function(bool) onTabChanged;
  final Color accentColor;
  final Color? secondaryTextColor;

  const TabSelector({
    Key? key,
    required this.isFirstTabSelected,
    required this.firstTabLabel,
    required this.secondTabLabel,
    required this.onTabChanged,
    required this.accentColor,
    required this.secondaryTextColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildTab(
            label: firstTabLabel,
            isSelected: isFirstTabSelected,
            onTap: () => onTabChanged(true),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildTab(
            label: secondTabLabel,
            isSelected: !isFirstTabSelected,
            onTap: () => onTabChanged(false),
          ),
        ),
      ],
    );
  }

  Widget _buildTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? accentColor : Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? accentColor : secondaryTextColor,
            ),
          ),
        ),
      ),
    );
  }
}