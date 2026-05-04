import 'package:flutter/material.dart';

import 'package:reportes_ai/app/theme/app_colors.dart';

abstract final class ReportStatus {
  static const String pending = 'Pendiente';
  static const String submitted = 'Enviado';
  static const String reviewing = 'En revisión';
  static const String verified = 'Verificado';
  static const String attended = 'Atendido';
  static const String rejected = 'Rechazado';
}

extension ReportStatusColor on String {
  Color get statusColor {
    final s = toLowerCase();
    if (s.contains('revisión') || s.contains('pendiente')) {
      return AppColors.warning;
    }
    if (s.contains('atendido') || s.contains('verificado')) {
      return AppColors.success;
    }
    if (s.contains('rechazado') || s.contains('error')) {
      return AppColors.error;
    }
    // "Enviado" → design spec: info blue
    if (s.contains('enviado')) {
      return AppColors.info;
    }
    return AppColors.info;
  }

  Color get statusBackground {
    final s = toLowerCase();
    if (s.contains('revisión') || s.contains('pendiente')) {
      return AppColors.warningLight;
    }
    if (s.contains('atendido') || s.contains('verificado')) {
      return AppColors.successLight;
    }
    if (s.contains('rechazado') || s.contains('error')) {
      return AppColors.errorLight;
    }
    // "Enviado" → info light
    if (s.contains('enviado')) {
      return AppColors.infoLight;
    }
    return AppColors.infoLight;
  }
}

class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.title,
    required this.description,
    required this.status,
    required this.date,
    this.category,
    this.onTap,
  });

  final String title;
  final String description;
  final String status;
  final String date;
  final String? category;
  final VoidCallback? onTap;

  IconData _getCategoryIcon() {
    final cat = (category ?? '').toLowerCase();
    if (cat.contains('accidente')) return Icons.car_crash_rounded;
    if (cat.contains('derrumbe')) return Icons.landscape_rounded;
    if (cat.contains('semáforo')) return Icons.traffic_rounded;
    if (cat.contains('bloque')) return Icons.block_rounded;
    return Icons.warning_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // shadow-[0_4px_20px_rgba(0,0,0,0.04)]
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon Circle
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: status.statusBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getCategoryIcon(),
                    color: status.statusColor,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description.isNotEmpty ? description : (category ?? 'Sin detalles'),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                
                // Status Pill & Chevron
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: status.statusBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: status.statusColor,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.outline,
                      size: 24,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}