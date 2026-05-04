import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:reportes_ai/data/models/ai_classification.dart';

class AiService {
  SupabaseClient get _client => Supabase.instance.client;

  static const _fn = 'ai-report-processor';

  /// Classifies a report using Gemini Flash 2.0 via the Edge Function.
  /// [transcribedAudio] is appended to [description] when provided.
  Future<AiClassification> classifyReport({
    required String description,
    String? locationLabel,
    String? transcribedAudio,
  }) async {
    final text = (transcribedAudio != null && transcribedAudio.isNotEmpty)
        ? '$description $transcribedAudio'.trim()
        : description;

    final response = await _client.functions.invoke(
      _fn,
      body: {
        'action': 'classify',
        'description': text,
        if (locationLabel != null) 'location': locationLabel,
      },
    );

    final data = _unwrap(response);
    return AiClassification.fromEdgeFunction(data);
  }

  /// Returns a credibility score (0.0–1.0) for a report based on
  /// user history and geographic corroboration.
  Future<double> getCredibilityScore({
    required String userId,
    required String description,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _client.functions.invoke(
        _fn,
        body: {
          'action': 'credibility',
          'userId': userId,
          'description': description,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      final data = _unwrap(response);
      return (data['credibility_score'] as num?)?.toDouble() ?? 1.0;
    } catch (_) {
      return 1.0;
    }
  }

  /// Calculates a weighted priority score (0.0–1.0) using the
  /// classification result and credibility score.
  Future<double> getPriorityScore({
    required AiClassification classification,
    required double credibilityScore,
  }) async {
    try {
      final response = await _client.functions.invoke(
        _fn,
        body: {
          'action': 'priority',
          'severity': classification.rawSeverity,
          'sensitive_location': classification.sensitiveLoc,
          'road_impact': classification.roadImpact,
          'credibility_score': credibilityScore,
          'confirmations': 0,
        },
      );
      final data = _unwrap(response);
      return (data['priority_score'] as num?)?.toDouble() ?? 0.5;
    } catch (_) {
      return 0.5;
    }
  }

  Map<String, dynamic> _unwrap(FunctionResponse response) {
    final data = response.data as Map<String, dynamic>? ?? {};
    if (data.containsKey('error')) {
      throw Exception(data['error']);
    }
    return data;
  }
}
