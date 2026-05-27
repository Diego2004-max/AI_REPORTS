import 'dart:convert';

class AiClassification {
  final String suggestedCategory;
  final String suggestedSeverity;
  final double confidence;
  final List<String> entities;
  final int priorityScore;
  final bool sensitiveLoc;
  final bool roadImpact;
  final String rawAiCategory;
  final String rawSeverity;

  const AiClassification({
    required this.suggestedCategory,
    required this.suggestedSeverity,
    required this.confidence,
    required this.entities,
    required this.priorityScore,
    this.sensitiveLoc = false,
    this.roadImpact = false,
    this.rawAiCategory = '',
    this.rawSeverity = 'media',
  });

  /// Parses a raw JSON string from the old Claude Haiku format.
  factory AiClassification.fromJson(String raw) {
    final cleaned = raw
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();
    final map = jsonDecode(cleaned) as Map<String, dynamic>;
    final rawCategory = (map['category'] as String?)?.trim() ?? '';
    final rawSeverity = (map['severity'] as String?)?.trim() ?? '';

    return AiClassification(
      suggestedCategory: _normalizeCategory(rawCategory),
      suggestedSeverity: _normalizeSeverity(rawSeverity),
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.5,
      entities: (map['entities'] as List?)?.cast<String>() ?? [],
      priorityScore: (map['priority_score'] as num?)?.toInt() ?? 50,
      rawAiCategory: rawCategory,
      rawSeverity: rawSeverity.isEmpty ? 'media' : rawSeverity,
    );
  }

  /// Maps an Edge Function `classify` response to the UI model.
  factory AiClassification.fromEdgeFunction(Map<String, dynamic> data) {
    final rawCat = (data['category'] as String?)?.trim() ?? '';
    final rawSev = (data['severity'] as String?)?.trim() ?? 'media';
    final priority = (data['priority_score'] as num?)?.toDouble() ?? 0;

    return AiClassification(
      suggestedCategory: _normalizeCategory(rawCat),
      suggestedSeverity: _normalizeSeverity(rawSev),
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.7,
      entities: const [],
      priorityScore: priority <= 1
          ? (priority * 100).round()
          : priority.round(),
      sensitiveLoc: data['sensitive_location'] as bool? ?? false,
      roadImpact: data['road_impact'] as bool? ?? false,
      rawAiCategory: rawCat,
      rawSeverity: rawSev,
    );
  }

  AiClassification withPriorityScore(double score) {
    final normalizedScore = score <= 1 ? score * 100 : score;

    return AiClassification(
      suggestedCategory: suggestedCategory,
      suggestedSeverity: suggestedSeverity,
      confidence: confidence,
      entities: entities,
      priorityScore: normalizedScore.round().clamp(0, 100).toInt(),
      sensitiveLoc: sensitiveLoc,
      roadImpact: roadImpact,
      rawAiCategory: rawAiCategory,
      rawSeverity: rawSeverity,
    );
  }

  String get confidenceLabel {
    if (confidence >= 0.85) return 'Alta';
    if (confidence >= 0.6) return 'Media';
    return 'Baja';
  }

  static String _normalizeCategory(String rawCategory) {
    final raw = rawCategory.trim();
    if (raw.isEmpty) return 'Otra';

    final value = _fold(raw);

    if (value.contains('derrumbe') ||
        value.contains('deslizamiento') ||
        value.contains('talud') ||
        value.contains('infraestructura')) {
      return 'Derrumbe';
    }

    if (value.contains('semaforo') ||
        value.contains('senalizacion') ||
        value.contains('seguridad vial')) {
      return 'Semáforo dañado';
    }

    if (value.contains('via bloqueada') ||
        value.contains('via cerrada') ||
        value.contains('bloqueo') ||
        value.contains('obstruccion') ||
        value.contains('cierre') ||
        value.contains('emergencia climatica') ||
        value.contains('servicios publicos')) {
      return 'Vía bloqueada';
    }

    if (value.contains('accidente') ||
        value.contains('choque') ||
        value.contains('colision') ||
        value.contains('transito')) {
      return 'Accidente';
    }

    return raw;
  }

  static String _normalizeSeverity(String rawSeverity) {
    final value = _fold(rawSeverity.trim());
    if (value == 'baja' || value == 'leve') return 'Leve';
    if (value == 'alta' ||
        value == 'grave' ||
        value == 'critica' ||
        value == 'critico') {
      return 'Crítico';
    }
    return 'Moderado';
  }

  static String _fold(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('ã¡', 'a')
        .replaceAll('ã©', 'e')
        .replaceAll('ã­', 'i')
        .replaceAll('ã³', 'o')
        .replaceAll('ãº', 'u')
        .replaceAll('ã±', 'n');
  }
}
