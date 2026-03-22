import 'package:flutter/material.dart';
import '../../model/repz_badge.dart';

class BadgeItem extends StatelessWidget {
  final RepzBadge badge;

  const BadgeItem({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: badge.earned ? () => _showBadgeSheet(context) : null,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ColorFiltered(
              colorFilter: badge.earned
                  ? const ColorFilter.mode(
                  Colors.transparent, BlendMode.multiply)
                  : const ColorFilter.matrix([
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0,      0,      0,      1, 0,
              ]),
              child: Opacity(
                opacity: badge.earned ? 1.0 : 0.35,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: badge.bgColor,
                    border: Border.all(
                      color: badge.earned
                          ? badge.borderColor
                          : Colors.grey.withValues(alpha: 0.3),
                      width: badge.earned ? 2 : 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      badge.icon,
                      size: 24,
                      color: badge.earned ? badge.iconColor : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              badge.month,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.withValues(alpha: 0.75),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              badge.earned ? badge.label : 'Locked',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: badge.earned
                    ? badge.iconColor
                    : Colors.grey.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badge.bgColor,
                  border: Border.all(color: badge.borderColor, width: 2.5),
                ),
                child: Center(
                  child: Icon(badge.icon, size: 36, color: badge.iconColor),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                badge.label,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                badge.month,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                badge.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}