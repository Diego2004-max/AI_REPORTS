import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:reportes_ai/app/theme/app_colors.dart';
import 'package:reportes_ai/core/constants/app_constants.dart';
import 'package:reportes_ai/core/services/ai_service.dart';
import 'package:reportes_ai/core/services/location_service.dart';
import 'package:reportes_ai/core/services/voice_service.dart';
import 'package:reportes_ai/core/services/speech_service.dart';
import 'package:reportes_ai/data/models/ai_classification.dart';
import 'package:reportes_ai/shared/widgets/ai_classification_card.dart';
import 'package:reportes_ai/state/report_provider.dart';
import 'package:reportes_ai/state/session_provider.dart';
import 'package:reportes_ai/shared/widgets/app_card.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:reportes_ai/shared/widgets/vial_button.dart';

class CreateAudioReportScreen extends ConsumerStatefulWidget {
  const CreateAudioReportScreen({super.key});

  @override
  ConsumerState<CreateAudioReportScreen> createState() =>
      _CreateAudioReportScreenState();
}

class _CreateAudioReportScreenState
    extends ConsumerState<CreateAudioReportScreen> {
  final _descriptionController = TextEditingController();

  final LocationService _locationService = LocationService();
  final VoiceService _voiceService = VoiceService();
  final SpeechService _speechService = SpeechService();
  final AiService _aiService = AiService();

  bool _isLoading = false;
  bool _isGettingLocation = false;

  bool _isRecording = false;
  bool _isDictating = false;
  bool _isAnalyzing = false;
  String _transcription = '';
  AiClassification? _aiResult;

  String _selectedCategory = 'Accidente';
  String _selectedSeverity = 'Moderado';

  Position? _currentPosition;
  String? _locationLabel;

  String? _imagePath;

  String? _audioPath;

  static const List<String> _severityOptions = ['Leve', 'Moderado', 'Crítico'];

  bool get _selectedCategoryIsCustom =>
      _selectedCategory.isNotEmpty &&
      !AppCategories.all.containsKey(_selectedCategory);

  String get _reportDescription {
    final text = _descriptionController.text.trim();

    if (text.isNotEmpty) return text;
    return 'Reporte enviado por audio';
  }

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _surfaceLowest(BuildContext context) => _isDark(context)
      ? AppColors.darkSurface
      : AppColors.surfaceContainerLowest;

  Color _surfaceLow(BuildContext context) => _isDark(context)
      ? AppColors.darkSurfaceVariant
      : AppColors.surfaceContainerLow;

  Color _inputSurface(BuildContext context) =>
      _isDark(context) ? AppColors.darkSurfaceVariant : AppColors.surface;

  Color _softBorder(BuildContext context) =>
      _isDark(context) ? AppColors.darkBorder : AppColors.border.withAlpha(150);

  Color _textPrimary(BuildContext context) =>
      _isDark(context) ? AppColors.darkTextPrimary : AppColors.textPrimary;

  Color _textSecondary(BuildContext context) =>
      _isDark(context) ? AppColors.darkTextSecondary : AppColors.textSecondary;

  TextStyle _fieldTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: _textPrimary(context),
          height: 1.45,
        ) ??
        TextStyle(color: _textPrimary(context));
  }

  TextStyle _hintTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: _isDark(context)
              ? AppColors.darkTextSecondary.withAlpha(210)
              : AppColors.textSecondary.withAlpha(210),
          height: 1.45,
        ) ??
        TextStyle(color: _textSecondary(context));
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _voiceService.dispose();
    _speechService.cancelListening();
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
        _locationLabel =
            address ??
            'Lat ${position.latitude.toStringAsFixed(5)}, Lng ${position.longitude.toStringAsFixed(5)}';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo obtener ubicación: $e')),
      );
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _startRecording() async {
    if (_isDictating) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Detén el dictado antes de grabar audio')),
      );
      return;
    }

    final status = await Permission.microphone.request();
    if (!mounted) return;

    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se necesita permiso de micrófono para grabar'),
        ),
      );
      return;
    }
    try {
      await _voiceService.startRecording();
      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _audioPath = null;
        _transcription = '';
        _aiResult = null;
      });
      _descriptionController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo grabar el audio: $e')));
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _voiceService.stopRecording();
      if (path == null || path.isEmpty) {
        throw Exception('No se obtuvo el archivo de audio');
      }
      debugPrint('audio local path capturado: $path');
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _audioPath = path;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRecording = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo detener la grabación: $e')),
      );
    }
  }

  Future<void> _toggleVoiceCapture() async {
    if (_isRecording) {
      await _stopRecording();
      if (!mounted || _audioPath == null) return;
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      await _startDictation();
      return;
    }

    if (_isDictating) {
      await _stopDictation();
      return;
    }

    if (_audioPath == null) {
      await _startRecording();
      return;
    }

    await _startDictation();
  }

  Future<void> _startDictation() async {
    if (_isRecording) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Detén la grabación antes de dictar')),
      );
      return;
    }

    if (_audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Graba el audio antes de dictar')),
      );
      return;
    }

    final status = await Permission.microphone.request();
    if (!mounted) return;

    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se necesita permiso de micrófono para dictar'),
        ),
      );
      return;
    }

    setState(() {
      _isDictating = true;
    });

    try {
      await _speechService.startListening(
        onResult: (text, isFinal) {
          if (!mounted) return;
          setState(() {
            _transcription = text;
            _descriptionController.text = text;
            _descriptionController.selection = TextSelection.collapsed(
              offset: text.length,
            );
            _aiResult = null;
          });
          if (isFinal && text.trim().isNotEmpty) {
            Future.microtask(() {
              if (mounted && _isDictating) {
                _stopDictation();
              }
            });
          }
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isDictating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La transcripción no está disponible en este dispositivo. Puedes escribir la descripción manualmente.',
          ),
        ),
      );
    }
  }

  Future<void> _stopDictation({bool analyze = true}) async {
    await _speechService.stopListening();
    if (!mounted) return;

    setState(() => _isDictating = false);

    final text = _descriptionController.text.trim();
    if (analyze && text.isNotEmpty) {
      await _analyzeWithAi(text);
    }
  }

  Future<void> _analyzeWithAi(String text) async {
    if (!mounted) return;
    setState(() {
      _isAnalyzing = true;
      _aiResult = null;
    });
    try {
      final result = await _aiService.classifyReport(
        description: text,
        locationLabel: _locationLabel,
        transcribedAudio: _transcription.isNotEmpty ? _transcription : null,
      );
      final priorityScore = await _aiService.getPriorityScore(
        classification: result,
        credibilityScore: 1.0,
      );
      final resultWithPriority = result.withPriorityScore(priorityScore);
      if (!mounted) return;
      setState(() {
        _aiResult = resultWithPriority;
        final suggestedCategory = resultWithPriority.suggestedCategory.trim();
        if (suggestedCategory.isNotEmpty) {
          _selectedCategory = suggestedCategory;
        }
        if (_severityOptions.contains(resultWithPriority.suggestedSeverity)) {
          _selectedSeverity = resultWithPriority.suggestedSeverity;
        }
      });
    } catch (_) {
      // AI analysis is optional; silently skip on error
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _deleteAudio() async {
    if (_isRecording) {
      await _voiceService.cancelRecording();
    }
    if (_isDictating) {
      await _speechService.cancelListening();
    }
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _isDictating = false;
      _audioPath = null;
      _transcription = '';
      _aiResult = null;
    });
    _descriptionController.clear();
  }

  Future<void> _showCustomCategoryDialog() async {
    final controller = TextEditingController(
      text: _selectedCategoryIsCustom ? _selectedCategory : '',
    );

    final category = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Otra categoría'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Escribe la categoría'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (!mounted || category == null || category.isEmpty) return;
    setState(() => _selectedCategory = category);
  }

  Future<void> _showCategoryEditSheet() async {
    final selectedCategory = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _surfaceLowest(context),
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
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _softBorder(ctx),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Text(
                  'Cambiar categoría',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary(ctx),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ...AppCategories.all.entries.map((entry) {
                      final isSelected = _selectedCategory == entry.key;
                      return _CategoryChip(
                        label: entry.key,
                        icon: entry.value,
                        isSelected: isSelected,
                        onTap: () => Navigator.pop(ctx, entry.key),
                      );
                    }),
                    _CategoryChip(
                      label: _selectedCategoryIsCustom
                          ? _selectedCategory
                          : 'Otra',
                      icon: Icons.edit_rounded,
                      isSelected: _selectedCategoryIsCustom,
                      onTap: () => Navigator.pop(ctx, '__custom__'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selectedCategory == null) return;
    if (selectedCategory == '__custom__') {
      await _showCustomCategoryDialog();
      return;
    }

    if (!mounted) return;
    setState(() => _selectedCategory = selectedCategory);
  }

  Future<void> _showSeverityEditSheet() async {
    final selectedSeverity = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _surfaceLowest(context),
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
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _softBorder(ctx),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Text(
                  'Cambiar severidad',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary(ctx),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: _severityOptions.map((severity) {
                    final color = _severityColor(severity);
                    final isSelected = _selectedSeverity == severity;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx, severity),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withAlpha(30)
                                  : _surfaceLow(ctx),
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(color: color, width: 1.5)
                                  : Border.all(color: _softBorder(ctx)),
                            ),
                            child: Text(
                              severity,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? color : _textSecondary(ctx),
                              ),
                            ),
                          ),
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

    if (!mounted || selectedSeverity == null) return;
    setState(() => _selectedSeverity = selectedSeverity);
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'Leve':
        return AppColors.success;
      case 'Crítico':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  Future<void> _submitReport() async {
    if (_isLoading) return;

    final session = ref.read(sessionProvider);
    final userId = session.userId;

    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Debes iniciar sesión')));
      return;
    }
    if (_currentPosition == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Debes capturar ubicación')));
      return;
    }
    if (_isRecording) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Detén la grabación antes de enviar')),
      );
      return;
    }
    if (_isDictating) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Detén el dictado antes de enviar')),
      );
      return;
    }
    if (_audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes grabar un audio obligatoriamente')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final description = _reportDescription;
      debugPrint('audio local path antes de enviar: $_audioPath');

      // Run AI pipeline (non-blocking: failures are silently skipped)
      AiClassification? aiResult = _aiResult;
      double? credibilityScore;
      double? priorityScore;

      try {
        if (aiResult == null && description != 'Reporte enviado por audio') {
          aiResult = await _aiService.classifyReport(
            description: description,
            locationLabel: _locationLabel,
            transcribedAudio: _transcription.isNotEmpty ? _transcription : null,
          );
          if (!mounted) return;
          setState(() {
            _aiResult = aiResult;
            final suggestedCategory = aiResult!.suggestedCategory.trim();
            if (suggestedCategory.isNotEmpty) {
              _selectedCategory = suggestedCategory;
            }
            if (_severityOptions.contains(aiResult.suggestedSeverity)) {
              _selectedSeverity = aiResult.suggestedSeverity;
            }
          });
        }

        if (aiResult != null) {
          credibilityScore = await _aiService.getCredibilityScore(
            userId: userId,
            description: description,
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
          );
          if (!mounted) return;
          priorityScore = await _aiService.getPriorityScore(
            classification: aiResult,
            credibilityScore: credibilityScore,
          );
          if (!mounted) return;
        }
      } catch (_) {
        // AI is optional — save report without AI fields on failure
      }

      final finalCategory = _selectedCategory.trim().isEmpty
          ? 'Otra'
          : _selectedCategory.trim();
      final finalSeverity = _selectedSeverity.trim().isEmpty
          ? 'Moderado'
          : _selectedSeverity.trim();
      final generatedTitle = '$finalCategory - $finalSeverity - Audio';

      await ref
          .read(reportRepositoryProvider)
          .createReport(
            userId: userId,
            title: generatedTitle,
            description: description,
            category: finalCategory,
            severity: finalSeverity,
            locationLabel: _locationLabel,
            latitude: _currentPosition?.latitude,
            longitude: _currentPosition?.longitude,
            imagePaths: _imagePath != null ? [_imagePath!] : const [],
            audioPath: _audioPath,
            aiCategory: aiResult?.rawAiCategory.isNotEmpty == true
                ? aiResult!.rawAiCategory
                : null,
            aiConfidence: aiResult?.confidence,
            priorityScore: priorityScore,
            credibilityScore: credibilityScore,
          );

      refreshReports(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reporte de audio enviado')));
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo enviar el reporte: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryTone = isDark ? AppColors.primaryLight : AppColors.primary;
    final canSubmit =
        !_isLoading && _audioPath != null && _currentPosition != null;
    final transcriptionText = _descriptionController.text.trim();
    final canAnalyze =
        transcriptionText.isNotEmpty && !_isAnalyzing && !_isDictating;
    final voiceButtonText = _isRecording
        ? 'Detener y transcribir'
        : _isDictating
        ? 'Detener transcripción'
        : _audioPath == null
        ? 'Grabar y transcribir reporte'
        : 'Transcribir / dictar descripción';
    final voiceStatusText = _isRecording
        ? 'Grabando audio de evidencia...'
        : _isDictating
        ? 'Transcribiendo en vivo...'
        : _audioPath != null
        ? 'Audio capturado. Puedes editar la descripción o analizar con IA.'
        : 'Toca el botón para grabar el audio real del reporte.';
    final voiceButtonIcon = _isRecording
        ? Icons.stop_rounded
        : _isDictating
        ? Icons.record_voice_over_rounded
        : Icons.mic_rounded;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: _surfaceLowest(context).withAlpha(isDark ? 240 : 220),
            border: Border(bottom: BorderSide(color: _softBorder(context))),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: primaryTone),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nuevo reporte por IA',
          style:
              (theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge)
                  ?.copyWith(
                    color: primaryTone,
                    fontSize: 20,
                    letterSpacing: 0,
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
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _surfaceLow(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _softBorder(context)),
                      ),
                      child: Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: primaryTone.withAlpha(isDark ? 36 : 50),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: primaryTone,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _inputSurface(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _softBorder(context)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: primaryTone.withAlpha(isDark ? 32 : 50),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'UBICACIÓN ACTUAL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _textSecondary(context),
                                    letterSpacing: 0,
                                  ),
                                ),
                                _isGettingLocation
                                    ? const SizedBox(
                                        height: 14,
                                        width: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _locationLabel ?? 'Buscando...',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _textPrimary(context),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _isGettingLocation
                                ? null
                                : _loadCurrentLocation,
                            child: const Text('Actualizar'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Type Selector
              AppCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Categoría inicial',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ...AppCategories.all.entries.map((entry) {
                          final isSelected = _selectedCategory == entry.key;
                          return _CategoryChip(
                            label: entry.key,
                            icon: entry.value,
                            isSelected: isSelected,
                            onTap: () =>
                                setState(() => _selectedCategory = entry.key),
                          );
                        }),
                        _CategoryChip(
                          label: _selectedCategoryIsCustom
                              ? _selectedCategory
                              : 'Otra',
                          icon: Icons.edit_rounded,
                          isSelected: _selectedCategoryIsCustom,
                          onTap: _showCustomCategoryDialog,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Severity selector
              AppCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Severidad',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: _severityOptions.map((label) {
                        final color = _severityColor(label);
                        final isSelected = _selectedSeverity == label;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedSeverity = label),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? color.withAlpha(30)
                                      : _surfaceLow(context),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? color
                                        : _softBorder(context),
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? color
                                        : _textSecondary(context),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Microphone specific Area
              AppCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Habla con el asistente de emergencia VialAI',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: primaryTone.withAlpha(isDark ? 34 : 24),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryTone.withAlpha(isDark ? 130 : 90),
                        ),
                      ),
                      child: Icon(
                        voiceButtonIcon,
                        color: primaryTone,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 16),
                    VialButton(
                      onPressed: _toggleVoiceCapture,
                      text: voiceButtonText,
                      icon: Icon(voiceButtonIcon, size: 20),
                      isSecondary: _audioPath != null && !_isRecording,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      voiceStatusText,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _isRecording
                            ? AppColors.error
                            : _textSecondary(context),
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                    if (_isDictating && _transcription.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _surfaceLow(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _softBorder(context)),
                          ),
                          child: Text(
                            _transcription,
                            style: TextStyle(
                              fontSize: 13,
                              color: _textSecondary(context),
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    if (_isAnalyzing)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Analizando con IA...',
                              style: TextStyle(
                                fontSize: 12,
                                color: _textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_aiResult != null && !_isRecording) ...[
                      const SizedBox(height: 12),
                      AiClassificationCard(
                        classification: _aiResult!,
                        categoryAccepted: true,
                        severityAccepted: true,
                        onAcceptCategory: _showCategoryEditSheet,
                        onAcceptSeverity: _showSeverityEditSheet,
                      ),
                    ],
                    if (_audioPath != null && !_isRecording)
                      TextButton(
                        onPressed: _deleteAudio,
                        child: const Text(
                          'Eliminar y rehacer',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. Description Input
              AppCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Transcripción / descripción editable',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary(context),
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: canAnalyze
                              ? () => _analyzeWithAi(transcriptionText)
                              : null,
                          icon: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                          ),
                          label: const Text('Analizar con IA'),
                          style: TextButton.styleFrom(
                            foregroundColor: primaryTone,
                            disabledForegroundColor: _textSecondary(
                              context,
                            ).withAlpha(175),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: _surfaceLow(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _softBorder(context)),
                      ),
                      child: TextField(
                        controller: _descriptionController,
                        maxLines: 3,
                        cursorColor: primaryTone,
                        onChanged: (value) {
                          setState(() {
                            _transcription = value;
                            _aiResult = null;
                          });
                        },
                        decoration: InputDecoration(
                          hintText:
                              'Dicta un resumen del reporte o escribe la descripción manualmente...',
                          hintStyle: _hintTextStyle(
                            context,
                          ).copyWith(fontSize: 14),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        style: _fieldTextStyle(context).copyWith(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              VialButton(
                onPressed: canSubmit ? _submitReport : null,
                text: 'Enviar reporte inteligente',
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
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryTone = isDark ? AppColors.primaryLight : AppColors.primary;
    final idleColor = isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.surfaceContainerLow;
    final idleText = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final borderColor = isDark
        ? AppColors.darkBorder
        : AppColors.border.withAlpha(140);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryTone : idleColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? primaryTone.withAlpha(130) : borderColor,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryTone.withAlpha(isDark ? 36 : 50),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.onPrimary : idleText,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.onPrimary : idleText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
