import 'package:flutter/material.dart';
import 'package:reportes_ai/shared/widgets/report_card.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.showIcon = false,
  });

  final String status;
  final bool showIcon;

  IconData _icon() {
    final s = status.toLowerCase();
    if (s.contains('enviado')) return Icons.send_rounded;
    if (s.contains('revisión') || s.contains('pendiente')) return Icons.search_rounded;
    if (s.contains('atendido') || s.contains('verificado')) return Icons.check_circle_rounded;
    if (s.contains('rechazado') || s.contains('error')) return Icons.cancel_rounded;
    return Icons.circle_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(showIcon ? 8 : 10, 4, 10, 4),
      decoration: BoxDecoration(
        color: status.statusBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(_icon(), size: 12, color: status.statusColor),
            const SizedBox(width: 4),
          ],
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: status.statusColor,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
