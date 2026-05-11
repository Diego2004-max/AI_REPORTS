

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';


import 'package:reportes_ai/app/theme/app_colors.dart';
import 'package:reportes_ai/core/services/ai_service.dart';
import 'package:reportes_ai/core/services/location_service.dart';
import 'package:reportes_ai/core/services/voice_service.dart';
import 'package:reportes_ai/core/services/speech_service.dart';
import 'package:reportes_ai/data/models/ai_classification.dart';
import 'package:reportes_ai/shared/widgets/ai_classification_card.dart';
import 'package:reportes_ai/state/report_provider.dart';
import 'package:reportes_ai/state/session_provider.dart';
import 'package:reportes_ai/shared/widgets/vial_card.dart';
import 'package:reportes_ai/shared/widgets/vial_button.dart';
<<<<<<< Updated upstream
=======

>>>>>>> Stashed changes

class CreateAudioReportScreen extends ConsumerStatefulWidget {
  const CreateAudioReportScreen({super.key});

  @override
  ConsumerState<CreateAudioReportScreen> createState() =>
      _CreateAudioReportScreenState();
}

class _CreateAudioReportScreenState extends ConsumerState<CreateAudioReportScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;
  final _descriptionController = TextEditingController();

  final LocationService _locationService = LocationService();
  final VoiceService _voiceService = VoiceService();
  final SpeechService _speechService = SpeechService();
  final AiService _aiService = AiService();


  bool _isLoading = false;
  bool _isGettingLocation = false;

  bool _isRecording = false;
  bool _isAnalyzing = false;
  String _transcription = '';
  AiClassification? _aiResult;

  String _selectedCategory = 'Accidente';
  final String _selectedSeverity = 'Moderado';

  Position? _currentPosition;
  String? _locationLabel;

  String? _imagePath;

  
  String? _audioPath;

  final Map<String, IconData> _categories = {
    'Accidente': Icons.car_crash_rounded,
    'Derrumbe': Icons.landscape_rounded,
    'Semáforo dañado': Icons.traffic_rounded,
    'Vía bloqueada': Icons.block_rounded,
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
        _locationLabel = address ??
            'Lat ${position.latitude.toStringAsFixed(5)}, Lng ${position.longitude.toStringAsFixed(5)}';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo obtener ubicación: $e')));
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _startRecording() async {
    try {
      await _voiceService.startRecording();
      _pulseController.repeat(reverse: true);
      setState(() {
        _isRecording = true;
        _audioPath = null;
        _transcription = '';
      });
      // Speech-to-text runs in parallel to transcribe while recording
      _speechService.startListening(
        onResult: (text, isFinal) {
          if (!mounted) return;
          setState(() => _transcription = text);
          if (isFinal && text.isNotEmpty && _descriptionController.text.isEmpty) {
            _descriptionController.text = text;
          }
        },
      ).catchError((_) {}); // speech may be unavailable on some devices
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo grabar el audio: $e')));
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _voiceService.stopRecording();
      await _speechService.stopListening();
      _pulseController.stop();
      _pulseController.reset();
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _audioPath = path;
        if (_transcription.isNotEmpty && _descriptionController.text.isEmpty) {
          _descriptionController.text = _transcription;
        }
      });
      // Auto-analyze with AI if transcription is available
      if (_transcription.isNotEmpty) {
        _analyzeWithAi(_transcription);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRecording = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo detener la grabación: $e')));
    }
  }

  Future<void> _analyzeWithAi(String text) async {
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
      if (!mounted) return;
      setState(() {
        _aiResult = result;
        // Auto-apply category when confidence is high
        if (result.confidence > 0.7 &&
            _categories.containsKey(result.suggestedCategory)) {
          _selectedCategory = result.suggestedCategory;
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
      await _speechService.cancelListening();
      _pulseController.stop();
      _pulseController.reset();
    }
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _audioPath = null;
      _transcription = '';
    });
  }

  Future<void> _submitReport() async {
    final session = ref.read(sessionProvider);
    final userId = session.userId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes iniciar sesión')));
      return;
    }
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes capturar ubicación')));
      return;
    }
    if (_isRecording) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Detén la grabación antes de enviar')));
      return;
    }
    if (_audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes grabar un audio obligatoriamente')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final description = _descriptionController.text.trim().isEmpty
          ? 'Reporte enviado por audio'
          : _descriptionController.text.trim();
      final generatedTitle = '$_selectedCategory - $_selectedSeverity - Audio';

      // Run AI pipeline (non-blocking: failures are silently skipped)
      AiClassification? aiResult = _aiResult;
      double credibilityScore = 1.0;
      double priorityScore = 0.5;

      try {
        if (aiResult == null && _transcription.isNotEmpty) {
          aiResult = await _aiService.classifyReport(
            description: description,
            locationLabel: _locationLabel,
            transcribedAudio: _transcription,
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reporte de audio enviado')));
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
          'Nuevo reporte por IA',
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
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                        image: const DecorationImage(
                          image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuBRLPziqvS-V0M__jJtPlk4A9i4IIO0CJK2o-LSbppCLO-KBvBWiQfEgPsk4tF1O9jg4UBA5rLFg0u283CsalSFUxP8MP8Y4w8hjtOV2qX_StEBn5QGgVK5hKAmTRKr7pDp4cql3cibZaJxNuZBIH5QD_MQKV9CBvWKbJGogUYtflv00oD1yAiGDGeF5Ztc3_VHERaBGr6eMN-9CGHASm08cRiLp51c19fdEHAaDKaqT_ncxaCiPD3MEkuipkeszpMWdALNbo767H4'),
                          fit: BoxFit.cover, opacity: 0.8,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(color: AppColors.primary.withAlpha(50), shape: BoxShape.circle),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(color: AppColors.primaryContainer.withAlpha(50), shape: BoxShape.circle),
                            child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('UBICACIÓN ACTUAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0)),
                                _isGettingLocation
                                    ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                    : Text(_locationLabel ?? 'Buscando...', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1),
                              ],
                            ),
                          ),
                          TextButton(onPressed: _isGettingLocation ? null : _loadCurrentLocation, child: const Text('Actualizar')),
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
                    const Text('Categoría inicial', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _categories.entries.map((entry) {
                        final isSelected = _selectedCategory == entry.key;
                        return InkWell(
                          onTap: () => setState(() => _selectedCategory = entry.key),
                          borderRadius: BorderRadius.circular(24),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withAlpha(50), blurRadius: 10, offset: const Offset(0, 2))] : [],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(entry.value, size: 18, color: isSelected ? AppColors.onPrimary : AppColors.textSecondary),
                                const SizedBox(width: 8),
                                Text(entry.key, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isSelected ? AppColors.onPrimary : AppColors.textSecondary)),
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

              // 3. Severity selector
              VialCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Severidad', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        {'label': 'Leve', 'color': AppColors.success},
                        {'label': 'Moderado', 'color': AppColors.warning},
                        {'label': 'Grave', 'color': AppColors.error},
                      ].map((item) {
                        final label = item['label'] as String;
                        final color = item['color'] as Color;
                        final isSelected = _selectedSeverity == label;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedSeverity = label),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? color.withAlpha(30) : AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? color : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? color : AppColors.textSecondary,
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
              VialCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('Habla con el asistente de emergencia VialAI', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _isRecording ? _stopRecording : _startRecording,
                      child: SizedBox(
                        width: 160,
                        height: 160,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_isRecording) ...[
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, _) => Transform.scale(
                                  scale: _pulseScale.value,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.error.withAlpha(
                                        (_pulseOpacity.value * 80).round(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, _) => Transform.scale(
                                  scale: 1.0 + (_pulseScale.value - 1.0) * 0.5,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.error.withAlpha(
                                        (_pulseOpacity.value * 130).round(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: _isRecording ? 100 : 80,
                              height: _isRecording ? 100 : 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isRecording ? AppColors.error : AppColors.primaryContainer.withAlpha(50),
                                boxShadow: _isRecording
                                    ? [BoxShadow(color: AppColors.error.withAlpha(100), blurRadius: 20, spreadRadius: 10)]
                                    : [],
                              ),
                              child: Icon(
                                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                                size: 40,
                                color: _isRecording ? AppColors.onPrimary : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isRecording ? 'Grabando narración...' : (_audioPath != null ? 'Audio capturado.' : 'Presiona para grabar detalles por voz'),
                      style: TextStyle(
                        color: _isRecording ? AppColors.error : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_isRecording && _transcription.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _transcription,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    if (_isAnalyzing)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 14, height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 8),
                            Text('Analizando con IA...',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    if (_aiResult != null && !_isRecording) ...[
                      const SizedBox(height: 12),
                      AiClassificationCard(
                        classification: _aiResult!,
                        onAcceptCategory: () =>
                            setState(() => _selectedCategory = _aiResult!.suggestedCategory),
                      ),
                    ],
                    if (_audioPath != null && !_isRecording)
                       TextButton(onPressed: _deleteAudio, child: const Text('Eliminar y rehacer', style: TextStyle(color: AppColors.error))),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. Description Input
              VialCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Transcripción / Peticiones especiales (Opcional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
                      child: TextField(
                        controller: _descriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Se auto-llena al grabar, o escribe manualmente...',
                          hintStyle: TextStyle(color: AppColors.outline, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              VialButton(
                onPressed: _submitReport,
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