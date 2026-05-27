import 'package:flutter/material.dart';

import 'package:reportes_ai/app/theme/app_colors.dart';

abstract final class ReportStatusLabels {
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
    if (s.contains('atendido') || s.contains('verificado')) {
      return AppColors.success;
    }
    return AppColors.info;
  }

  Color get statusBackground {
    final s = toLowerCase();
    if (s.contains('atendido') || s.contains('verificado')) {
      return AppColors.successLight;
    }
    return AppColors.infoLight;
  }
}
