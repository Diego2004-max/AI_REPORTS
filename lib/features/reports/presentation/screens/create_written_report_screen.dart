import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'package:reportes_ai/app/theme/app_colors.dart';
import 'package:reportes_ai/core/constants/app_constants.dart';
import 'package:reportes_ai/core/services/ai_service.dart';
import 'package:reportes_ai/core/services/location_service.dart';
import 'package:reportes_ai/core/utils/validators.dart';
import 'package:reportes_ai/data/models/ai_classification.dart';
import 'package:reportes_ai/shared/widgets/ai_classification_card.dart';
import 'package:reportes_ai/state/report_provider.dart';
import 'package:reportes_ai/state/session_provider.dart';
import 'package:reportes_ai/shared/widgets/vial_card.dart';
import 'package:reportes_ai/shared/widgets/vial_button.dart';

class CreateWrittenReportScreen extends ConsumerStatefulWidget {
  const CreateWrittenReportScreen({super.key});

  @override
  ConsumerState<CreateWrittenReportScreen> createState() =>
      _CreateWrittenReportScreenState();
}

class _CreateWrittenReportScreenState
    extends ConsumerState<CreateWrittenReportScreen> {
  final _descriptionController = TextEditingController();

  final LocationService _locationService = LocationService();
  final ImagePicker _imagePicker = ImagePicker();
  final AiService _aiService = AiService();

  bool _isLoading = false;
  bool _isGettingLocation = false;
  bool _isPickingImage = false;
  bool _isAnalyzing = false;
  bool _descriptionError = false;
  String? _descriptionErrorText;
  AiClassification? _aiResult;

  // FIX: category and severity start empty — populated automatically by AI analysis
  String _selectedCategory = '';
  String _selectedSeverity = '';

  Position? _currentPosition;
  String? _locationLabel;

  String? _imagePath;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      final position = await _locationService.getCurrentLocation();
      final address = await _locationService.getReadableAddress(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _locationLabel = address ??
            'Lat ${position.latitude.toStringAsFixed(5)}, Lng ${position.longitude.toStringAsFixed(5)}';
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo obtener ubicación: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isPickingImage = true);

      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1600,
      );

      if (file == null) {
        if (mounted) setState(() => _isPickingImage = false);
        return;
      }

      final bytes = await file.readAsBytes();

      if (!mounted) return;

      const maxBytes = 5 * 1024 * 1024; // 5 MB
      if (bytes.length > maxBytes) {
        setState(() => _isPickingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La imagen supera el límite de 5 MB')),
        );
        return;
      }

      setState(() {
        _imagePath = file.path;
        _imageBytes = bytes;
        _isPickingImage = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPickingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar la imagen: $e')),
      );
    }
  }

  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: AppColors.textPrimary),
                  title: const Text('Seleccionar de galería', style: TextStyle(color: AppColors.textPrimary)),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined, color: AppColors.textPrimary),
                  title: const Text('Tomar foto', style: TextStyle(color: AppColors.textPrimary)),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _analyzeWithAi() async {
    final text = _descriptionController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe una descripción primero')),
      );
      return;
    }
    setState(() {
      _isAnalyzing = true;
      _aiResult = null;
    });
    try {
      final result = await _aiService.classifyReport(
        description: text,
        locationLabel: _locationLabel,
      );
      if (!mounted) return;
      setState(() {
        _aiResult = result;
        // FIX: always pre-fill both fields from AI — no confidence threshold required
        _selectedCategory = result.suggestedCategory;
        _selectedSeverity = result.suggestedSeverity;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error IA: $e')),
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  // FIX: bottom sheet so user can override the AI-assigned category
  Future<void> _showCategoryEditSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Text('Cambiar categoría',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: AppCategories.all.entries.map((entry) {
                    final isSelected = _selectedCategory == entry.key;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedCategory = entry.key);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(entry.value, size: 18,
                                color: isSelected ? AppColors.onPrimary : AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(entry.key,
                                style: TextStyle(fontSize: 14,
                                    color: isSelected ? AppColors.onPrimary : AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // FIX: bottom sheet so user can override the AI-assigned severity
  Future<void> _showSeverityEditSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Text('Cambiar severidad',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildSeverityOption('Leve', AppColors.success, ctx),
                    const SizedBox(width: 8),
                    _buildSeverityOption('Moderado', AppColors.warning, ctx),
                    const SizedBox(width: 8),
                    _buildSeverityOption('Crítico', AppColors.error, ctx),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSeverityOption(String severity, Color color, BuildContext ctx) {
    final isSelected = _selectedSeverity == severity;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedSeverity = severity);
          Navigator.pop(ctx);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withAlpha(30) : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: color, width: 1.5) : null,
          ),
          child: Column(
            children: [
              Container(width: 8, height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(height: 6),
              Text(severity,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                      color: isSelected ? color : AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    final session = ref.read(sessionProvider);
    final userId = session.userId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión')),
      );
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes capturar la ubicación del reporte')),
      );
      return;
    }

    final description = _descriptionController.text.trim();
    final descError = AppValidators.reportDescription(description);
    if (descError != null) {
      setState(() {
        _descriptionError = true;
        _descriptionErrorText = descError;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(descError)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final generatedTitle = '$_selectedCategory - $_selectedSeverity';

      // Run AI pipeline (non-blocking: failures are silently skipped)
      AiClassification? aiResult = _aiResult;
      double credibilityScore = 1.0;
      double priorityScore = 0.5;

      try {
        if (aiResult == null && description.isNotEmpty) {
          aiResult = await _aiService.classifyReport(
            description: description,
            locationLabel: _locationLabel,
          );
          if (mounted) setState(() => _aiResult = aiResult);
        }

        if (aiResult != null) {
          credibilityScore = await _aiService.getCredibilityScore(
            userId: userId,
            description: description,
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
          );
          priorityScore = await _aiService.getPriorityScore(
            classification: aiResult,
            credibilityScore: credibilityScore,
          );
        }
      } catch (_) {
        // AI is optional — save report without AI fields on failure
      }

      await ref.read(reportRepositoryProvider).createReport(
            userId: userId,
            title: generatedTitle,
            description: description,
            category: _selectedCategory,
            severity: _selectedSeverity,
            locationLabel: _locationLabel,
            latitude: _currentPosition?.latitude,
            longitude: _currentPosition?.longitude,
            imagePaths: _imagePath != null ? [_imagePath!] : const [],
            aiCategory: aiResult?.rawAiCategory.isNotEmpty == true
                ? aiResult!.rawAiCategory
                : null,
            aiConfidence: aiResult?.confidence,
            priorityScore: priorityScore,
            credibilityScore: credibilityScore,
          );

      refreshReports(ref);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporte enviado correctamente')),
      );

      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    // FIX: submit disabled until AI analysis has classified the report
    final canSubmit = _aiResult != null &&
        _selectedCategory.isNotEmpty &&
        _selectedSeverity.isNotEmpty;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest.withAlpha(200),
            border: Border(bottom: BorderSide(color: AppColors.surfaceContainerHighest)),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nuevo reporte',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // FIX 1 — paso 1: Descripción + botón "Analizar con IA"
              VialCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Descripción *',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                        if (_isAnalyzing)
                          const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          GestureDetector(
                            onTap: _analyzeWithAi,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.primary.withAlpha(60)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome_rounded,
                                      size: 13, color: AppColors.primary),
                                  SizedBox(width: 4),
                                  Text('Analizar con IA',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: _descriptionError
                            ? Border.all(color: AppColors.error, width: 1.5)
                            : null,
                      ),
                      child: TextField(
                        controller: _descriptionController,
                        maxLines: 4,
                        onChanged: (_) {
                          if (_descriptionError) {
                            setState(() {
                              _descriptionError = false;
                              _descriptionErrorText = null;
                            });
                          }
                          // Reset AI result when description changes
                          if (_aiResult != null) {
                            setState(() {
                              _aiResult = null;
                              _selectedCategory = '';
                              _selectedSeverity = '';
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          hintText: 'Describe el incidente con detalle para que la IA lo clasifique correctamente...',
                          hintStyle: TextStyle(color: AppColors.outline, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      ),
                    ),
                    if (_descriptionError && _descriptionErrorText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Text(
                          _descriptionErrorText!,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    if (_aiResult == null && !_isAnalyzing)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          'Toca "Analizar con IA" para que el sistema clasifique el reporte.',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary.withAlpha(180),
                              fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // FIX 1 — paso 2: AiClassificationCard (categoría + severidad pre-llenadas, editables)
              // FIX 5: siempre accepted=true porque los valores se auto-aplican al correr el análisis
              if (_aiResult != null) ...[
                AiClassificationCard(
                  classification: _aiResult!,
                  categoryAccepted: true,
                  severityAccepted: true,
                  onAcceptCategory: _showCategoryEditSheet,
                  onAcceptSeverity: _showSeverityEditSheet,
                ),
                const SizedBox(height: 24),
              ],

              // FIX 1 — paso 3: Ubicación (informativa, auto-capturada)
              VialCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // FIX 2: GoogleMap miniatura dinámica — reemplaza NetworkImage hardcodeada
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _isGettingLocation
                            ? const Center(child: CircularProgressIndicator())
                            : _currentPosition != null
                                ? AbsorbPointer(
                                    child: GoogleMap(
                                      initialCameraPosition: CameraPosition(
                                        target: LatLng(
                                          _currentPosition!.latitude,
                                          _currentPosition!.longitude,
                                        ),
                                        zoom: 15,
                                      ),
                                      markers: {
                                        Marker(
                                          markerId: const MarkerId('report_location'),
                                          position: LatLng(
                                            _currentPosition!.latitude,
                                            _currentPosition!.longitude,
                                          ),
                                        ),
                                      },
                                      zoomControlsEnabled: false,
                                      scrollGesturesEnabled: false,
                                      zoomGesturesEnabled: false,
                                      rotateGesturesEnabled: false,
                                      tiltGesturesEnabled: false,
                                      myLocationButtonEnabled: false,
                                      compassEnabled: false,
                                      mapToolbarEnabled: false,
                                      liteModeEnabled: true,
                                    ),
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.location_off_outlined,
                                            size: 32, color: AppColors.outline),
                                        const SizedBox(height: 8),
                                        Text('Ubicación no disponible',
                                            style: TextStyle(
                                                fontSize: 12, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withAlpha(50),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_on_rounded,
                                color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'UBICACIÓN ACTUAL',
                                  style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary, letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                _isGettingLocation
                                    ? const SizedBox(
                                        height: 14, width: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Text(
                                        _locationLabel ?? 'Buscando...',
                                        style: const TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                      ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _isGettingLocation ? null : _loadCurrentLocation,
                            child: const Text('Actualizar',
                                style: TextStyle(color: AppColors.primary)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // FIX 1 — paso 4: Foto (opcional)
              VialCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Evidencia visual',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        if (_imageBytes != null)
                          TextButton(
                            onPressed: () => setState(() {
                              _imagePath = null;
                              _imageBytes = null;
                            }),
                            child: const Text('Quitar',
                                style: TextStyle(color: AppColors.error)),
                          )
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _isPickingImage ? null : _showImageSourceSheet,
                      child: Container(
                        height: _imageBytes == null ? 140 : 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow.withAlpha(150),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.border.withAlpha(100),
                              width: 2,
                              strokeAlign: BorderSide.strokeAlignOutside),
                        ),
                        child: _isPickingImage
                            ? const Center(child: CircularProgressIndicator())
                            : _imageBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 48, height: 48,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryContainer.withAlpha(25),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.photo_camera_rounded,
                                            color: AppColors.primary, size: 24),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text('Tomar foto o subir',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500, fontSize: 14)),
                                      const SizedBox(height: 4),
                                      const Text('Formatos JPG, PNG (Max 5MB)',
                                          style: TextStyle(
                                              fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                  ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // FIX 1 — paso 5: Enviar (deshabilitado hasta que IA clasifique)
              VialButton(
                onPressed: canSubmit ? _submitReport : null,
                text: canSubmit ? 'Enviar reporte' : 'Analiza con IA para enviar',
                isLoading: _isLoading,
                icon: Icon(
                  canSubmit ? Icons.send_rounded : Icons.lock_outline_rounded,
                  size: 20,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
