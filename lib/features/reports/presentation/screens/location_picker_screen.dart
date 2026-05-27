import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' show locationFromAddress;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:reportes_ai/app/theme/app_colors.dart';
import 'package:reportes_ai/core/services/location_service.dart';

/// Result returned by [LocationPickerScreen] when the user confirms a location.
class LocationPickerResult {
  final double latitude;
  final double longitude;
  final String label;

  const LocationPickerResult({
    required this.latitude,
    required this.longitude,
    required this.label,
  });
}

/// Full-screen map screen that lets the user pick any location.
///
/// The user can:
/// - Tap anywhere on the map to drop/move the marker.
/// - Drag the marker to fine-tune the position.
/// - Search for an address in the top search bar.
/// - Press "Mi ubicación" to snap to their current GPS position.
///
/// Returns a [LocationPickerResult] via [Navigator.pop] when confirmed,
/// or `null` if the user dismisses without confirming.
class LocationPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const LocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();

  GoogleMapController? _mapController;
  LatLng? _selectedPosition;
  String? _selectedLabel;
  bool _isLoadingAddress = false;
  bool _isSearching = false;
  bool _isGettingGps = false;

  // Default map center: Pasto, Colombia
  static const LatLng _defaultCenter = LatLng(1.2136, -77.2811);

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedPosition = LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
      _resolveAddress(_selectedPosition!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Future<void> _resolveAddress(LatLng position) async {
    setState(() => _isLoadingAddress = true);
    final address = await _locationService.getReadableAddress(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    if (!mounted) return;
    setState(() {
      _selectedLabel =
          address ??
          'Lat ${position.latitude.toStringAsFixed(5)}, '
              'Lng ${position.longitude.toStringAsFixed(5)}';
      _isLoadingAddress = false;
    });
  }

  // ─── Interactions ───────────────────────────────────────────────────────────

  Future<void> _onMapTap(LatLng position) async {
    setState(() {
      _selectedPosition = position;
      _selectedLabel = null;
    });
    await _resolveAddress(position);
  }

  Future<void> _onMarkerDragEnd(LatLng position) async {
    setState(() {
      _selectedPosition = position;
      _selectedLabel = null;
    });
    await _resolveAddress(position);
  }

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSearching = true);
    try {
      final locations = await locationFromAddress(query);
      if (!mounted) return;
      if (locations.isEmpty) {
        _showSnack('No se encontró esa dirección');
        return;
      }
      final loc = locations.first;
      final position = LatLng(loc.latitude, loc.longitude);
      setState(() => _selectedPosition = position);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(position, 15),
      );
      await _resolveAddress(position);
    } catch (_) {
      if (!mounted) return;
      _showSnack('No se encontró esa dirección. Intenta con más detalles.');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isGettingGps = true);
    try {
      final position = await _locationService.getCurrentLocation();
      if (!mounted) return;
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() => _selectedPosition = latLng);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, 15),
      );
      await _resolveAddress(latLng);
    } catch (e) {
      if (!mounted) return;
      _showSnack('No se pudo obtener ubicación: $e');
    } finally {
      if (mounted) setState(() => _isGettingGps = false);
    }
  }

  void _confirmLocation() {
    if (_selectedPosition == null || _selectedLabel == null) return;
    Navigator.pop(
      context,
      LocationPickerResult(
        latitude: _selectedPosition!.latitude,
        longitude: _selectedPosition!.longitude,
        label: _selectedLabel!,
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark;
    final primaryTone = isDark ? AppColors.primaryLight : AppColors.primary;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final surfaceLow =
        isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceContainerLow;

    final canConfirm =
        _selectedPosition != null &&
        _selectedLabel != null &&
        !_isLoadingAddress;

    final initialTarget = _selectedPosition ?? _defaultCenter;

    return Scaffold(
      body: Stack(
        children: [
          // ── Full-screen map ────────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: 14,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTap,
            markers: _selectedPosition != null
                ? {
                    Marker(
                      markerId: const MarkerId('selected_location'),
                      position: _selectedPosition!,
                      draggable: true,
                      onDragEnd: _onMarkerDragEnd,
                    ),
                  }
                : {},
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
          ),

          // ── Top search bar ─────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  // Back button
                  _MapOverlayButton(
                    isDark: isDark,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: textPrimary,
                      size: 20,
                    ),
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  // Search field
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 60 : 28),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Buscar dirección o lugar...',
                                hintStyle: TextStyle(
                                  color: textSecondary,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 13,
                                ),
                              ),
                              onSubmitted: (_) => _searchAddress(),
                              textInputAction: TextInputAction.search,
                            ),
                          ),
                          if (_isSearching)
                            Padding(
                              padding: const EdgeInsets.only(right: 14),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryTone,
                                ),
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: _searchAddress,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 14),
                                child: Icon(
                                  Icons.search_rounded,
                                  color: primaryTone,
                                  size: 22,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Hint label when nothing selected ──────────────────────────────
          if (_selectedPosition == null)
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: surfaceColor.withAlpha(230),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 50 : 20),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 16,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Toca el mapa para marcar el lugar del incidente',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Bottom confirmation panel ──────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border(
                    top: BorderSide(color: borderColor),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 90 : 32),
                      blurRadius: 24,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    // Selected address card
                    if (_selectedPosition != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: surfaceLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: primaryTone.withAlpha(isDark ? 36 : 50),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.location_on_rounded,
                                color: primaryTone,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _isLoadingAddress
                                  ? Row(
                                      children: [
                                        SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: primaryTone,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Obteniendo dirección...',
                                          style: TextStyle(
                                            color: textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'UBICACIÓN SELECCIONADA',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: textSecondary,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _selectedLabel ?? '',
                                          style: TextStyle(
                                            color: textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),

                    // Hint text when nothing selected yet
                    if (_selectedPosition == null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(
                          'Toca el mapa, arrastra el pin o busca una dirección',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),

                    // Action buttons
                    Row(
                      children: [
                        // GPS button
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                _isGettingGps ? null : _useCurrentLocation,
                            icon: _isGettingGps
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: primaryTone,
                                    ),
                                  )
                                : Icon(
                                    Icons.my_location_rounded,
                                    size: 17,
                                    color: primaryTone,
                                  ),
                            label: Text(
                              'Mi ubicación',
                              style: TextStyle(
                                color: primaryTone,
                                fontSize: 13,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: primaryTone.withAlpha(160),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Confirm button
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: canConfirm ? _confirmLocation : null,
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Confirmar ubicación'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryTone,
                              foregroundColor: AppColors.onPrimary,
                              disabledBackgroundColor: primaryTone.withAlpha(
                                isDark ? 60 : 80,
                              ),
                              disabledForegroundColor: Colors.white
                                  .withAlpha(isDark ? 120 : 160),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular/rounded button rendered on top of the map (overlay layer).
class _MapOverlayButton extends StatelessWidget {
  final bool isDark;
  final Color surfaceColor;
  final Color borderColor;
  final Widget child;
  final VoidCallback onTap;

  const _MapOverlayButton({
    required this.isDark,
    required this.surfaceColor,
    required this.borderColor,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 60 : 28),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
