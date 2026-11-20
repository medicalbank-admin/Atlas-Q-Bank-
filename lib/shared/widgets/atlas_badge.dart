import 'package:flutter/material.dart';

import '../../app/atlas_academy_app.dart';
import '../../theme/atlas_spacing.dart';

enum AtlasBadgeType {
  active,
  pending,
  expired,
  rejected,
  premium,
  completed,
  upcoming,
  inProgress,
  locked,
  published,
  draft,
}

class AtlasBadge extends StatelessWidget {
  const AtlasBadge({
    super.key,
    required this.label,
    required this.type,
    this.icon,
  });

  final String label;
  final AtlasBadgeType type;
  final IconData? icon;

  Color get backgroundColor {
    switch (type) {
      case AtlasBadgeType.active:
      case AtlasBadgeType.completed:
      case AtlasBadgeType.published:
        return const Color(0xFFE4F4EC);

      case AtlasBadgeType.pending:
      case AtlasBadgeType.upcoming:
      case AtlasBadgeType.inProgress:
        return const Color(0xFFFFF3D9);

      case AtlasBadgeType.expired:
      case AtlasBadgeType.rejected:
      case AtlasBadgeType.locked:
        return const Color(0xFFFCE8E9);

      case AtlasBadgeType.premium:
        return const Color(0xFFF5EBD5);

      case AtlasBadgeType.draft:
        return const Color(0xFFECEFF1);
    }
  }

  Color get foregroundColor {
    switch (type) {
      case AtlasBadgeType.active:
      case AtlasBadgeType.completed:
      case AtlasBadgeType.published:
        return const Color(0xFF25845C);

      case AtlasBadgeType.pending:
      case AtlasBadgeType.upcoming:
      case AtlasBadgeType.inProgress:
        return const Color(0xFFAA7922);

      case AtlasBadgeType.expired:
      case AtlasBadgeType.rejected:
      case AtlasBadgeType.locked:
        return const Color(0xFFC34D55);

      case AtlasBadgeType.premium:
        return const Color(0xFF9A722B);

      case AtlasBadgeType.draft:
        return const Color(0xFF65737C);
    }
  }

  IconData get defaultIcon {
    switch (type) {
      case AtlasBadgeType.active:
        return Icons.check_circle_rounded;
      case AtlasBadgeType.pending:
        return Icons.schedule_rounded;
      case AtlasBadgeType.expired:
        return Icons.event_busy_rounded;
      case AtlasBadgeType.rejected:
        return Icons.cancel_rounded;
      case AtlasBadgeType.premium:
        return Icons.workspace_premium_rounded;
      case AtlasBadgeType.completed:
        return Icons.task_alt_rounded;
      case AtlasBadgeType.upcoming:
        return Icons.event_available_rounded;
      case AtlasBadgeType.inProgress:
        return Icons.timelapse_rounded;
      case AtlasBadgeType.locked:
        return Icons.lock_rounded;
      case AtlasBadgeType.published:
        return Icons.public_rounded;
      case AtlasBadgeType.draft:
        return Icons.edit_note_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(
          AtlasRadius.pill,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? defaultIcon,
            size: 13,
            color: foregroundColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.15,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}

class AtlasCustomBadge extends StatelessWidget {
  const AtlasCustomBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(
          AtlasRadius.pill,
        ),
        border: Border.all(
          color: color.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class AtlasNotificationDot extends StatelessWidget {
  const AtlasNotificationDot({
    super.key,
    this.color = AtlasColors.error,
    this.size = 9,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).scaffoldBackgroundColor,
          width: 1.5,
        ),
      ),
    );
  }
}
