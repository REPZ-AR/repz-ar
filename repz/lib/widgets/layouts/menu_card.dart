import 'package:flutter/material.dart';
import 'package:repz/views/prebuilt_workout_plans_page.dart';
import 'package:repz/views/saved_workout_plans_page.dart';
import 'package:repz/views/weekly_schedule_page.dart';
import 'package:repz/views/trainer_plan_library_page.dart';

class MenuCard extends StatelessWidget {
  final bool isDarkMode;
  final bool isCoach;

  const MenuCard({
    super.key,
    required this.isDarkMode,
    required this.isCoach,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor =
    isDarkMode ? const Color(0xFFCFF500) : const Color(0xFFA66CFF);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final iconColor = isDarkMode ? accentColor : Colors.black;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          if (!isCoach) ...[
            _MenuItem(
              icon: Icons.playlist_play_rounded,
              iconColor: iconColor,
              iconBg: accentColor.withValues(alpha: 0.18),
              title: 'Saved Plans',
              subtitle: 'Open, edit, and start your saved workout plans',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const SavedWorkoutPlansPage())),
              showDivider: true,
            ),
            _MenuItem(
              icon: Icons.calendar_today_outlined,
              iconColor: iconColor,
              iconBg: accentColor.withValues(alpha: 0.18),
              title: 'Weekly Schedule',
              subtitle: 'Set which schedule profile you want to actively follow',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const WeeklySchedulePage())),
              showDivider: true,
            ),
            _MenuItem(
              icon: Icons.auto_awesome_outlined,
              iconColor: iconColor,
              iconBg: accentColor.withValues(alpha: 0.18),
              title: 'Pre-built Plans',
              subtitle: 'Browse curated plans and copy them into your routine',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const PrebuiltWorkoutPlansPage())),
              showDivider: false,
            ),
          ] else ...[
            _MenuItem(
              icon: Icons.assignment_rounded,
              iconColor: iconColor,
              iconBg: accentColor.withValues(alpha: 0.18),
              title: 'Client Plan Library',
              subtitle: 'Create reusable client plans and assign them to clients',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => TrainerPlanLibraryPage(
                    isDarkMode: isDarkMode,
                  ))),
              showDivider: false,
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: iconBg,
            child: Icon(icon, color: iconColor),
          ),
          title: Text(title,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}