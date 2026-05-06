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

