import 'package:flutter/material.dart';
import 'package:reportes_ai/shared/widgets/report_card.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.showIcon = false});

  final String status;
  final bool showIcon;

  bool get _isAttended {
    final s = status.toLowerCase();
    return s.contains('atendido') || s.contains('verific');
  }

  IconData _icon() {
    return _isAttended ? Icons.check_circle_rounded : Icons.circle_rounded;
  }

  String get _displayLabel => _isAttended ? 'ATENDIDO' : 'ACTIVO';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final badgeColor = status.statusColor;
    final bgColor = isDark ? badgeColor.withAlpha(32) : status.statusBackground;
    final borderColor = isDark
        ? badgeColor.withAlpha(90)
        : badgeColor.withAlpha(45);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 96, minHeight: 24),
      child: Container(
        padding: EdgeInsets.fromLTRB(showIcon ? 7 : 9, 4, 9, 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon) ...[
                Icon(_icon(), size: 12, color: badgeColor),
                const SizedBox(width: 4),
              ],
              Text(
                _displayLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: badgeColor,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
