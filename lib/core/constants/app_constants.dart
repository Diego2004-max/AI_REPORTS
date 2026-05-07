import 'package:flutter/material.dart';

// FIX: centralized incident categories — moved from _categories in create_written_report_screen.dart
abstract final class AppCategories {
  static const Map<String, IconData> all = {
    'Accidente': Icons.car_crash_rounded,
    'Derrumbe': Icons.landscape_rounded,
    'Semáforo dañado': Icons.traffic_rounded,
    'Vía bloqueada': Icons.block_rounded,
  };
  // TODO: requiere cambio en backend — sincronizar desde tabla o enum de categorías en Supabase
}
