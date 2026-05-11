import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:reportes_ai/app/theme/app_colors.dart';
import 'package:reportes_ai/data/models/analytics_model.dart';
import 'package:reportes_ai/shared/widgets/shared_widgets.dart';
import 'package:reportes_ai/state/analytics_provider.dart';

class HotspotsScreen extends ConsumerStatefulWidget {
  const HotspotsScreen({super.key});

  @override
  ConsumerState<HotspotsScreen> createState() => _HotspotsScreenState();
}

class _HotspotsScreenState extends ConsumerState<HotspotsScreen> {
  GoogleMapController? _mapController;

  static const _initialPosition = CameraPosition(
    target: LatLng(1.2136, -77.2811),
    zoom: 12,
  );

  Set<Circle> _buildCircles(List<HotspotZone> zones) {
    final maxCount = zones.isEmpty
        ? 1
        : zones.map((z) => z.count).reduce((a, b) => a > b ? a : b);

    return zones.asMap().entries.map((entry) {
      final z = entry.value;
      final color = _riskColor(z.riskScore);
      final radius = (80 + (z.count / maxCount) * 320).clamp(80.0, 400.0);
      return Circle(
        circleId: CircleId('zone_${entry.key}'),
        center: LatLng(z.lat, z.lng),
        radius: radius,
        fillColor: color.withAlpha(70),
        strokeColor: color.withAlpha(200),
        strokeWidth: 2,
        consumeTapEvents: true,
        onTap: () => _showZoneSheet(z),
      );
    }).toSet();
  }

  Color _riskColor(double risk) {
    if (risk >= 0.7) return AppColors.error;
    if (risk >= 0.4) return AppColors.warning;
    return AppColors.success;
  }

  void _showZoneSheet(HotspotZone zone) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ZoneBottomSheet(zone: zone),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hotspotsAsync = ref.watch(hotspotsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _Header(
                onRefresh: () => ref.invalidate(hotspotsProvider),
              ),
              Expanded(
                child: hotspotsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Error al cargar zonas: $e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
                  ),
                  data: (zones) => Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: _initialPosition,
                        circles: _buildCircles(zones),
                        onMapCreated: (c) => _mapController = c,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: _InfoPanel(zones: zones),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onRefresh;
  const _Header({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: AppColors.text),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Zonas de riesgo',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                color: AppColors.text,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRefresh,
            child: const Icon(Icons.refresh_rounded,
                size: 20, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final List<HotspotZone> zones;
  const _InfoPanel({required this.zones});

  @override
  Widget build(BuildContext context) {
    final totalZones = zones.length;
    final topZone = zones.isNotEmpty ? zones.first : null;

    return AppCard(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Resumen de incidentes',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const Spacer(),
              Text(
                '$totalZones zonas activas',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          if (topZone != null) ...[
            const SizedBox(height: 10),
            _TopZoneRow(zone: topZone),
          ],
          const SizedBox(height: 12),
          const _Legend(),
        ],
      ),
    );
  }
}

class _TopZoneRow extends StatelessWidget {
  final HotspotZone zone;
  const _TopZoneRow({required this.zone});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.errorSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.location_on_rounded,
              size: 14, color: AppColors.error),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Zona más activa · ${zone.count} reportes',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
              Text(
                zone.topCategory,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LegendItem(color: AppColors.success, label: 'Riesgo bajo'),
        const SizedBox(width: 12),
        _LegendItem(color: AppColors.warning, label: 'Riesgo medio'),
        const SizedBox(width: 12),
        _LegendItem(color: AppColors.error, label: 'Riesgo alto'),
      ],
    );
  }
}

class _ZoneBottomSheet extends StatelessWidget {
  final HotspotZone zone;
  const _ZoneBottomSheet({required this.zone});

  @override
  Widget build(BuildContext context) {
    final riskLabel = zone.riskScore >= 0.7
        ? 'Alto'
        : zone.riskScore >= 0.4
            ? 'Medio'
            : 'Bajo';
    final riskColor = zone.riskScore >= 0.7
        ? AppColors.error
        : zone.riskScore >= 0.4
            ? AppColors.warning
            : AppColors.success;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: riskColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.location_on_rounded,
                    color: riskColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${zone.count} reporte${zone.count == 1 ? '' : 's'} en esta zona',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Más frecuente: ${zone.topCategory}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _InfoChip(label: 'Riesgo', value: riskLabel, color: riskColor),
              const SizedBox(width: 12),
              _InfoChip(
                label: 'Score',
                value: '${(zone.riskScore * 100).toStringAsFixed(0)}%',
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              _InfoChip(
                label: 'Reportes',
                value: '${zone.count}',
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
                fontSize: 14, color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}
