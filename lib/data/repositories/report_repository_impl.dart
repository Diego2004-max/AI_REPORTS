import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:reportes_ai/data/models/report_model.dart';

abstract final class UserReportStatus {
  static const String submitted = 'Enviado';
  static const String reviewing = 'En revisión';
  static const String attended = 'Atendido';
}

class ReportRepositoryImpl {
  final SupabaseClient _client = Supabase.instance.client;

  Future<ReportModel> createReport({
    required String userId,
    required String title,
    required String description,
    required String category,
    String status = UserReportStatus.submitted,
    String? locationLabel,
    double? latitude,
    double? longitude,
    List<String> imagePaths = const [],
    String? audioPath,
    String? aiCategory,
    double? aiConfidence,
    double? priorityScore,
    double? credibilityScore,
  }) async {
    try {
      final cleanDescription = description.trim();
      final cleanTitle = title.trim().isEmpty
          ? _buildFallbackTitle(cleanDescription)
          : title.trim();

      final expiresAt = DateTime.now().add(const Duration(days: 10));

      final inserted = await _client
          .from('reports')
          .insert({
            'user_id': userId,
            'title': cleanTitle,
            'description': cleanDescription,
            'category': category,
            'status': status,
            'location_label': locationLabel,
            'latitude': latitude,
            'longitude': longitude,
            'image_url': imagePaths.isNotEmpty ? imagePaths.first : null,
            'audio_url': audioPath,
            'expires_at': expiresAt.toIso8601String(),
            if (aiCategory != null) 'ai_category': aiCategory,
            if (aiConfidence != null) 'ai_confidence': aiConfidence,
            if (priorityScore != null) 'priority_score': priorityScore,
            if (credibilityScore != null) 'credibility_score': credibilityScore,
          })
          .select()
          .single();

      return _fromRow(inserted);
    } on PostgrestException catch (e) {
      throw Exception('Error al crear reporte: ${e.message}');
    } catch (e) {
      throw Exception('No se pudo guardar el reporte. Verifica tu conexión.');
    }
  }

  Future<List<ReportModel>> getReportsByUserId(String userId) async {
    try {
      final rows = await _client
          .from('reports')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (rows as List)
          .map((row) => _fromRow(Map<String, dynamic>.from(row as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener reportes: ${e.message}');
    } catch (e) {
      throw Exception('No se pudieron cargar tus reportes.');
    }
  }

  Future<List<ReportModel>> getAllReports() async {
    try {
      final rows = await _client
          .from('reports')
          .select()
          .order('created_at', ascending: false);

      return (rows as List)
          .map((row) => _fromRow(Map<String, dynamic>.from(row as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener reportes: ${e.message}');
    } catch (e) {
      throw Exception('No se pudieron cargar los reportes.');
    }
  }

  Future<void> deleteReport(String reportId) async {
    try {
      await _client.from('reports').delete().eq('id', reportId);
    } on PostgrestException catch (e) {
      throw Exception('Error al eliminar reporte: ${e.message}');
    } catch (e) {
      throw Exception('No se pudo eliminar el reporte.');
    }
  }

  Future<void> updateStatus(String reportId, String status) async {
    try {
      await _client
          .from('reports')
          .update({'status': status})
          .eq('id', reportId);
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar estado: ${e.message}');
    } catch (e) {
      throw Exception('No se pudo actualizar el estado del reporte.');
    }
  }

  ReportModel _fromRow(Map<String, dynamic> row) {
    final imageUrl = row['image_url'] as String?;

    return ReportModel(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      title: row['title'] as String,
      description: row['description'] as String,
      category: row['category'] as String,
      status: row['status'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      expiresAt: row['expires_at'] != null
          ? DateTime.parse(row['expires_at'] as String)
          : null,
      locationLabel: row['location_label'] as String?,
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
      imagePaths:
          imageUrl != null && imageUrl.isNotEmpty ? [imageUrl] : const [],
      audioPath: row['audio_url'] as String?,
      aiCategory: row['ai_category'] as String?,
      aiConfidence: (row['ai_confidence'] as num?)?.toDouble(),
      priorityScore: (row['priority_score'] as num?)?.toDouble(),
      credibilityScore: (row['credibility_score'] as num?)?.toDouble(),
    );
  }

  String _buildFallbackTitle(String description) {
    final clean = description.trim().replaceAll('\n', ' ');

    if (clean.isEmpty) {
      return 'Reporte ciudadano';
    }

    final words =
        clean.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    final short = words.take(5).join(' ');

    if (short.isEmpty) {
      return 'Reporte ciudadano';
    }

    return short[0].toUpperCase() + short.substring(1);
  }
}
