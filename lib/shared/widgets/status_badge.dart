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
            _displayLabel,
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
