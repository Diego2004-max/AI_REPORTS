import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:reportes_ai/app/theme/app_spacing.dart';
import 'package:reportes_ai/core/services/location_service.dart';
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

  bool _isLoadingLocation = false;
  bool _locationEnabled = false;

  // Cached custom marker icons per severity level
  final Map<String, BitmapDescriptor> _severityMarkers = {};

  @override
  void initState() {
    super.initState();
    _initSeverityMarkers();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // ── Severity marker icon generation ─────────────────────────────────────────

  Future<void> _initSeverityMarkers() async {
    try {
      final results = await Future.wait([
        _buildSeverityMarker('leve', const Color(0xFF34C989)),
        _buildSeverityMarker('moderado', const Color(0xFFDC963C)),
        _buildSeverityMarker('critico', const Color(0xFFE05555)),
        _buildSeverityMarker('default', const Color(0xFF2B4BFF)),
      ]);
      if (!mounted) return;
      setState(() {
        _severityMarkers['leve'] = results[0];
        _severityMarkers['moderado'] = results[1];
        _severityMarkers['critico'] = results[2];
        _severityMarkers['default'] = results[3];
      });
    } catch (_) {
      // Silently fall back to default Google Maps pin if generation fails.
    }
  }

  /// Draws a circular pin icon whose interior symbol communicates severity.
  ///
  /// • Leve     (green)  — checkmark ✓
  /// • Moderado (orange) — warning triangle ▲
  /// • Crítico  (red)    — exclamation mark !
  /// • Default  (blue)   — info dot •
  static Future<BitmapDescriptor> _buildSeverityMarker(
      String key, Color color) async {
    const double size = 64.0;
    const double cx = size / 2;
    const double cy = size / 2;
    const double r = size / 2 - 3;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

    // Drop shadow
    canvas.drawCircle(
      Offset(cx + 1.5, cy + 2.5),
      r,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter =
            const ui.MaskFilter.blur(ui.BlurStyle.normal, 5),
    );

    // Filled circle
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = color);

    // White border ring
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    // Inner semi-transparent circle
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.56,
      Paint()..color = Colors.white.withValues(alpha: 0.20),
    );

    // ── Icon ──────────────────────────────────────────────────────────────────
    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (key) {
      case 'leve':
        // Checkmark ✓
        canvas.drawLine(
            Offset(cx - 8, cy + 1), Offset(cx - 2, cy + 7), linePaint);
        canvas.drawLine(
            Offset(cx - 2, cy + 7), Offset(cx + 9, cy - 5), linePaint);
        break;

      case 'moderado':
        // Warning triangle ▲ (outline)
        final triPath = Path()
          ..moveTo(cx, cy - 9)
          ..lineTo(cx + 9, cy + 7)
          ..lineTo(cx - 9, cy + 7)
          ..close();
        canvas.drawPath(triPath, linePaint);
        // Dot inside triangle
        canvas.drawCircle(
          Offset(cx, cy + 3.5),
          2.0,
          Paint()..color = Colors.white,
        );
        break;

      case 'critico':
        // Exclamation mark !
        canvas.drawLine(Offset(cx, cy - 9), Offset(cx, cy + 1), linePaint);
        canvas.drawCircle(
          Offset(cx, cy + 6.5),
          2.5,
          Paint()..color = Colors.white,
        );
        break;

      default:
        // Info dot •
        canvas.drawLine(Offset(cx, cy - 5), Offset(cx, cy + 5), linePaint);
        canvas.drawCircle(
          Offset(cx, cy - 9),
          2.0,
          Paint()..color = Colors.white,
        );
        break;
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(
        byteData!.buffer.asUint8List());
  }

  BitmapDescriptor _markerForSeverity(String? severity) {
    if (_severityMarkers.isEmpty) return BitmapDescriptor.defaultMarker;
    final key = _normalizeSeverity(severity);
    return _severityMarkers[key] ?? _severityMarkers['default']!;
  }

  static String _normalizeSeverity(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'leve':
        return 'leve';
      case 'moderado':
        return 'moderado';
      case 'crítico':
      case 'critico':
      case 'grave':
        return 'critico';
      default:
        return 'default';
    }
  }

  // ── Map helpers ──────────────────────────────────────────────────────────────

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

  // ── Build ────────────────────────────────────────────────────────────────────

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

          final markers = reportsWithCoords
              .map(
                (report) => Marker(
                  markerId: MarkerId(report.id),
                  position: LatLng(report.latitude!, report.longitude!),
                  icon: _markerForSeverity(report.severity),
                  infoWindow: InfoWindow(
                    title: report.title,
                    snippet:
                        '${report.category} · ${report.severity ?? report.status}',
                  ),
                ),
              )
              .toSet();

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
                              style:
                                  Theme.of(context).textTheme.titleMedium,
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
                                    strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location_rounded),
                      ),
                    ],
                  ),
                ),
              ),
              // Legend
              if (_severityMarkers.isNotEmpty)
                Positioned(
                  bottom: AppSpacing.xl,
                  left: AppSpacing.screenH,
                  child: _SeverityLegend(
                    leve: _severityMarkers['leve']!,
                    moderado: _severityMarkers['moderado']!,
                    critico: _severityMarkers['critico']!,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Severity legend ───────────────────────────────────────────────────────────

class _SeverityLegend extends StatelessWidget {
  final BitmapDescriptor leve;
  final BitmapDescriptor moderado;
  final BitmapDescriptor critico;

  const _SeverityLegend({
    required this.leve,
    required this.moderado,
    required this.critico,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? const Color(0xFF252B40).withValues(alpha: 0.95)
        : Colors.white.withValues(alpha: 0.95);
    final textColor =
        isDark ? const Color(0xFFF0F2FA) : const Color(0xFF1C2033);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendItem(
              color: const Color(0xFF34C989),
              label: 'Leve',
              textColor: textColor),
          const SizedBox(height: 6),
          _LegendItem(
              color: const Color(0xFFDC963C),
              label: 'Moderado',
              textColor: textColor),
          const SizedBox(height: 6),
          _LegendItem(
              color: const Color(0xFFE05555),
              label: 'Crítico',
              textColor: textColor),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final Color textColor;

  const _LegendItem(
      {required this.color,
      required this.label,
      required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textColor,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
