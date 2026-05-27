import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:reportes_ai/app/theme/app_colors.dart';
import 'package:reportes_ai/app/theme/app_spacing.dart';
import 'package:reportes_ai/core/services/location_service.dart';
import 'package:reportes_ai/data/models/report_model.dart';
import 'package:reportes_ai/shared/widgets/app_card.dart';
import 'package:reportes_ai/state/report_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();

  static const LatLng _initialPosition = LatLng(1.2136, -77.2811);
  static const List<String> _severityKeys = ['leve', 'moderado', 'critico'];
  static const List<String> _categoryKeys = [
    'accidente',
    'derrumbe',
    'semaforo',
    'via_bloqueada',
    'otra',
  ];

  bool _isLoadingLocation = false;
  bool _locationEnabled = false;

  final Map<String, BitmapDescriptor> _reportMarkers = {};

  @override
  void initState() {
    super.initState();
    _initReportMarkers();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initReportMarkers() async {
    try {
      final futures = <String, Future<BitmapDescriptor>>{};

      for (final severity in _severityKeys) {
        for (final category in _categoryKeys) {
          futures[_markerCacheKey(severity, category)] = _buildReportMarker(
            color: _severityColor(severity),
            icon: _categoryIconForKey(category),
          );
        }
      }

      final entries = await Future.wait(
        futures.entries.map(
          (entry) async => MapEntry(entry.key, await entry.value),
        ),
      );

      if (!mounted) return;
      setState(() {
        _reportMarkers
          ..clear()
          ..addEntries(entries);
      });
    } catch (_) {
      // If canvas generation fails, markers fall back to compact amber pins.
    }
  }

  static String _markerCacheKey(String severity, String category) {
    return '$severity:$category';
  }

  static Future<BitmapDescriptor> _buildReportMarker({
    required Color color,
    required IconData icon,
  }) async {
    const double size = 42;
    const double center = size / 2;
    const double radius = 17;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

    canvas.drawCircle(
      const Offset(center, center + 2),
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3.5),
    );

    canvas.drawCircle(
      const Offset(center, center),
      radius,
      Paint()..color = color,
    );
    canvas.drawCircle(
      const Offset(center, center),
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      const Offset(center, center),
      radius * 0.58,
      Paint()..color = Colors.white.withValues(alpha: 0.14),
    );

    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    iconPainter.paint(
      canvas,
      Offset(center - iconPainter.width / 2, center - iconPainter.height / 2),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  BitmapDescriptor _markerForReport(ReportModel report) {
    final severity = _resolveReportSeverity(report);
    final category = _categoryKey(report.category);
    final markerKey = _markerCacheKey(severity, category);
    final fallbackKey = _markerCacheKey(severity, 'otra');

    return _reportMarkers[markerKey] ??
        _reportMarkers[fallbackKey] ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
  }

  static String _resolveReportSeverity(ReportModel report) {
    final rawSeverity = report.severity?.trim();
    if (rawSeverity != null && rawSeverity.isNotEmpty) {
      return _normalizeSeverity(rawSeverity);
    }

    for (final source in [report.title, report.description, report.status]) {
      final severity = _tryNormalizeSeverity(source);
      if (severity != null) return severity;
    }

    return 'moderado';
  }

  static String _normalizeSeverity(String value) {
    return _tryNormalizeSeverity(value) ?? 'moderado';
  }

  static String? _tryNormalizeSeverity(String value) {
    final text = _foldSeverity(value);
    if (text.contains('critico') ||
        text.contains('grave') ||
        text.contains('alta') ||
        text.contains('alto')) {
      return 'critico';
    }
    if (text.contains('leve') ||
        text.contains('baja') ||
        text.contains('bajo')) {
      return 'leve';
    }
    if (text.contains('moderado') ||
        text.contains('media') ||
        text.contains('medio')) {
      return 'moderado';
    }
    return null;
  }

  static String _foldSeverity(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('Ã¡', 'a')
        .replaceAll('Ã©', 'e')
        .replaceAll('Ã­', 'i')
        .replaceAll('Ã³', 'o')
        .replaceAll('Ãº', 'u');
  }

  static Color _severityColor(String severity) {
    return switch (severity) {
      'leve' => AppColors.success,
      'critico' => AppColors.error,
      _ => AppColors.warning,
    };
  }

  static String _severityLabel(String severity) {
    return switch (severity) {
      'leve' => 'Leve',
      'critico' => 'Crítico',
      _ => 'Moderado',
    };
  }

  static String _categoryKey(String category) {
    final value = category.toLowerCase();
    if (value.contains('accidente') ||
        value.contains('choque') ||
        value.contains('colisión') ||
        value.contains('colision')) {
      return 'accidente';
    }
    if (value.contains('derrumbe') ||
        value.contains('deslizamiento') ||
        value.contains('talud')) {
      return 'derrumbe';
    }
    if (value.contains('semáforo') || value.contains('semaforo')) {
      return 'semaforo';
    }
    if (value.contains('vía bloqueada') ||
        value.contains('via bloqueada') ||
        value.contains('bloque')) {
      return 'via_bloqueada';
    }
    return 'otra';
  }

  static IconData _categoryIconForKey(String categoryKey) {
    return switch (categoryKey) {
      'accidente' => Icons.directions_car_filled_rounded,
      'derrumbe' => Icons.terrain_rounded,
      'semaforo' => Icons.traffic_rounded,
      'via_bloqueada' => Icons.block_rounded,
      _ => Icons.report_problem_rounded,
    };
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final position = await _locationService.getCurrentLocation();
      final currentLatLng = LatLng(position.latitude, position.longitude);

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: currentLatLng, zoom: 16),
        ),
      );

      setState(() => _locationEnabled = true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo obtener la ubicación: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(allReportsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        data: (reports) {
          final reportsWithCoords = reports
              .where((r) => r.latitude != null && r.longitude != null)
              .toList();

          final markers = reportsWithCoords.map((report) {
            final severity = _resolveReportSeverity(report);

            return Marker(
              markerId: MarkerId(report.id),
              position: LatLng(report.latitude!, report.longitude!),
              icon: _markerForReport(report),
              infoWindow: InfoWindow(
                title: report.title,
                snippet: '${report.category} · ${_severityLabel(severity)}',
              ),
            );
          }).toSet();

          return Stack(
            children: [
              Positioned.fill(
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: const CameraPosition(
                    target: _initialPosition,
                    zoom: 14,
                  ),
                  markers: markers,
                  zoomControlsEnabled: false,
                  myLocationEnabled: _locationEnabled,
                  myLocationButtonEnabled: false,
                  compassEnabled: true,
                  mapToolbarEnabled: false,
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + AppSpacing.md,
                left: AppSpacing.screenH,
                right: AppSpacing.screenH,
                child: AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mapa de reportes',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              markers.isEmpty
                                  ? 'Sin reportes aún. Crea uno para verlo aquí.'
                                  : 'Mostrando ${markers.length} reportes con ubicación',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _isLoadingLocation
                            ? null
                            : _goToCurrentLocation,
                        icon: _isLoadingLocation
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location_rounded),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: AppSpacing.bottomNavHeight + AppSpacing.xl,
                left: AppSpacing.screenH,
                child: const _SeverityLegend(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SeverityLegend extends StatelessWidget {
  const _SeverityLegend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.95)
        : AppColors.surface.withValues(alpha: 0.95);
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.text;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendItem(
            color: AppColors.success,
            label: 'Leve',
            textColor: textColor,
          ),
          const SizedBox(height: 6),
          _LegendItem(
            color: AppColors.warning,
            label: 'Moderado',
            textColor: textColor,
          ),
          const SizedBox(height: 6),
          _LegendItem(
            color: AppColors.error,
            label: 'Crítico',
            textColor: textColor,
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.textColor,
  });

  final Color color;
  final String label;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
