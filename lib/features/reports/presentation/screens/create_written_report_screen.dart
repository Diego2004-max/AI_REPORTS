import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import 'package:reportes_ai/app/theme/app_colors.dart';
import 'package:reportes_ai/core/services/ai_service.dart';
import 'package:reportes_ai/core/services/location_service.dart';
import 'package:reportes_ai/data/models/ai_classification.dart';
import 'package:reportes_ai/shared/widgets/ai_classification_card.dart';
import 'package:reportes_ai/state/report_provider.dart';
import 'package:reportes_ai/state/session_provider.dart';
import 'package:reportes_ai/shared/widgets/vial_card.dart';
import 'package:reportes_ai/shared/widgets/vial_button.dart';
import 'package:reportes_ai/shared/widgets/vial_text_field.dart';

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
  AiClassification? _aiResult;

  String _selectedCategory = 'Accidente';
  String _selectedSeverity = 'Moderado';

  Position? _currentPosition;
  String? _locationLabel;

  String? _imagePath;
  Uint8List? _imageBytes;

  final Map<String, IconData> _categories = {
    'Accidente': Icons.car_crash_rounded,
    'Derrumbe': Icons.landscape_rounded,
    'Semáforo dañado': Icons.traffic_rounded,
    'Vía bloqueada': Icons.block_rounded,
  };

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
        // Auto-apply category when confidence is high
        if (result.confidence > 0.7 &&
            _categories.containsKey(result.suggestedCategory)) {
          _selectedCategory = result.suggestedCategory;
        }
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

    setState(() => _isLoading = true);

    try {
      final description = _descriptionController.text.trim();
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Let gradient handle it or keep solid
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
              // 1. Map Preview Card
              VialCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                        image: const DecorationImage(
                          image: NetworkImage(
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuBRLPziqvS-V0M__jJtPlk4A9i4IIO0CJK2o-LSbppCLO-KBvBWiQfEgPsk4tF1O9jg4UBA5rLFg0u283CsalSFUxP8MP8Y4w8hjtOV2qX_StEBn5QGgVK5hKAmTRKr7pDp4cql3cibZaJxNuZBIH5QD_MQKV9CBvWKbJGogUYtflv00oD1yAiGDGeF5Ztc3_VHERaBGr6eMN-9CGHASm08cRiLp51c19fdEHAaDKaqT_ncxaCiPD3MEkuipkeszpMWdALNbo767H4'),
                          fit: BoxFit.cover,
                          opacity: 0.8,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(50),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                              ),
                            ),
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
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withAlpha(50),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'UBICACIÓN ACTUAL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                _isGettingLocation
                                    ? const SizedBox(
                                        height: 14,
                                        width: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Text(
                                        _locationLabel ?? 'Buscando...',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _isGettingLocation ? null : _loadCurrentLocation,
                            child: const Text('Actualizar', style: TextStyle(color: AppColors.primary)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Type Selector
              VialCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tipo de incidente', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _categories.entries.map((entry) {
                        final isSelected = _selectedCategory == entry.key;
                        return InkWell(
                          onTap: () {
                            setState(() => _selectedCategory = entry.key);
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: AppColors.primary.withAlpha(50), blurRadius: 10, offset: const Offset(0, 2))]
                                  : [],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  entry.value,
                                  size: 18,
                                  color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Severity Toggle
              VialCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Severidad', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          _buildSeverityButton('Leve', const Color(0xFF1D9E75)),
                          _buildSeverityButton('Moderado', const Color(0xFFEF9F27)),
                          _buildSeverityButton('Crítico', const Color(0xFFE24B4A)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Description Input + AI Analysis
              VialCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Descripción (Opcional)',
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
                      ),
                      child: TextField(
                        controller: _descriptionController,
                        maxLines: 3,
                        onChanged: (_) {
                          if (_aiResult != null) setState(() => _aiResult = null);
                        },
                        decoration: const InputDecoration(
                          hintText: 'Añade detalles relevantes sobre el incidente...',
                          hintStyle: TextStyle(color: AppColors.outline, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      ),
                    ),
                    if (_aiResult != null) ...[
                      const SizedBox(height: 16),
                      AiClassificationCard(
                        classification: _aiResult!,
                        onAcceptCategory: () => setState(
                            () => _selectedCategory = _aiResult!.suggestedCategory),
                        onAcceptSeverity: () => setState(
                            () => _selectedSeverity = _aiResult!.suggestedSeverity),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. Photo Upload Area
              VialCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Evidencia visual', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        if (_imageBytes != null)
                          TextButton(
                            onPressed: () => setState(() {
                              _imagePath = null;
                              _imageBytes = null;
                            }),
                            child: const Text('Quitar', style: TextStyle(color: AppColors.error)),
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
                          border: Border.all(color: AppColors.border.withAlpha(100), width: 2, strokeAlign: BorderSide.strokeAlignOutside),
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
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryContainer.withAlpha(25),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.photo_camera_rounded, color: AppColors.primary, size: 24),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text('Tomar foto o subir', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                                      const SizedBox(height: 4),
                                      const Text('Formatos JPG, PNG (Max 5MB)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                  ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 6. Submit Button
              VialButton(
                onPressed: _submitReport,
                text: 'Enviar reporte',
                isLoading: _isLoading,
                icon: const Icon(Icons.send_rounded, size: 20),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityButton(String severity, Color color) {
    final isSelected = _selectedSeverity == severity;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSeverity = severity),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2))] : [],
            border: isSelected ? Border.all(color: AppColors.border.withAlpha(40)) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                severity,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}