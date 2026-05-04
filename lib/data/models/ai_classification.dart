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

  /// Parses a raw JSON string from the old Claude Haiku format (backward compat).
  factory AiClassification.fromJson(String raw) {
    final cleaned = raw
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();
    final map = jsonDecode(cleaned) as Map<String, dynamic>;
    return AiClassification(
      suggestedCategory: map['category'] as String? ?? 'Accidente',
      suggestedSeverity: map['severity'] as String? ?? 'Moderado',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.5,
      entities: (map['entities'] as List?)?.cast<String>() ?? [],
      priorityScore: (map['priority_score'] as num?)?.toInt() ?? 50,
    );
  }

  /// Maps an Edge Function `classify` response to the UI model.
  factory AiClassification.fromEdgeFunction(Map<String, dynamic> data) {
    const categoryMap = <String, String>{
      'Accidente de tránsito': 'Accidente',
      'Infraestructura': 'Derrumbe',
      'Seguridad': 'Semáforo dañado',
      'Emergencia climática': 'Vía bloqueada',
      'Servicios públicos': 'Vía bloqueada',
    };
    const severityMap = <String, String>{
      'baja': 'Leve',
      'media': 'Moderado',
      'alta': 'Crítico',
      'crítica': 'Crítico',
    };

    final rawCat = data['category'] as String? ?? 'Accidente de tránsito';
    final rawSev = data['severity'] as String? ?? 'media';

    return AiClassification(
      suggestedCategory: categoryMap[rawCat] ?? 'Accidente',
      suggestedSeverity: severityMap[rawSev] ?? 'Moderado',
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.7,
      entities: const [],
      priorityScore: 0,
      sensitiveLoc: data['sensitive_location'] as bool? ?? false,
      roadImpact: data['road_impact'] as bool? ?? false,
      rawAiCategory: rawCat,
      rawSeverity: rawSev,
    );
  }

  AiClassification withPriorityScore(double score) {
    return AiClassification(
      suggestedCategory: suggestedCategory,
      suggestedSeverity: suggestedSeverity,
      confidence: confidence,
      entities: entities,
      priorityScore: (score * 100).round(),
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
}
