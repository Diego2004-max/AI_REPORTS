import 'package:flutter/material.dart';

abstract final class AppCategories {
  static const Map<String, IconData> all = {
    'Accidente': Icons.car_crash_rounded,
    'Derrumbe': Icons.landscape_rounded,
    'Semáforo dañado': Icons.traffic_rounded,
    'Vía bloqueada': Icons.block_rounded,
  };
}
