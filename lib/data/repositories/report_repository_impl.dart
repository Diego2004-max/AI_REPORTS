import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:reportes_ai/data/models/report_model.dart';

abstract final class UserReportStatus {
  static const String submitted = 'Enviado';
  static const String reviewing = 'En revisión';
  static const String attended = 'Atendido';
}

class ReportRepositoryImpl {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _evidenceBucket = 'report-evidence';

  static Duration _expiryForSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'grave':
      case 'crítico':
      case 'critico':
        return const Duration(hours: 2);
      case 'leve':
        return const Duration(minutes: 30);
      default:
        return const Duration(hours: 1);
    }
  }

  Future<void> _autoResolveExpiredReports() async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from('reports')
          .update({'status': UserReportStatus.attended})
          .lt('expires_at', now)
          .neq('status', UserReportStatus.attended);
    } catch (_) {}
  }

  Future<ReportModel> createReport({
    required String userId,
    required String title,
    required String description,
    required String category,
    String severity = 'Moderado',
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

      final expiresAt = DateTime.now().add(_expiryForSeverity(severity));
      final imageUrl = await _resolveEvidenceUrl(
        userId: userId,
        path: imagePaths.where((path) => path.trim().isNotEmpty).firstOrNull,
        type: _EvidenceType.image,
      );
      final audioUrl = await _resolveEvidenceUrl(
        userId: userId,
        path: audioPath,
        type: _EvidenceType.audio,
      );

      final payload = <String, dynamic>{
        'user_id': userId,
        'title': cleanTitle,
        'description': cleanDescription,
        'category': category,
        'severity': severity,
        'status': status,
        'location_label': locationLabel,
        'latitude': latitude,
        'longitude': longitude,
        'image_url': imageUrl,
        'audio_url': audioUrl,
        'expires_at': expiresAt.toIso8601String(),
        'ai_category': ?aiCategory,
        'ai_confidence': ?aiConfidence,
        'priority_score': ?priorityScore,
        'credibility_score': ?credibilityScore,
      };

      final inserted = await _insertReportWithCompatibility(payload);

      return _fromRow(inserted);
    } on PostgrestException catch (e) {
      throw Exception('Error al crear reporte: ${e.message}');
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      if (message.startsWith('No se pudo subir la evidencia') ||
          message.startsWith('No se encontró el archivo') ||
          message.startsWith('El archivo de')) {
        throw Exception(message);
      }

      throw Exception('No se pudo guardar el reporte. Verifica tu conexión.');
    }
  }

  Future<String?> _resolveEvidenceUrl({
    required String userId,
    required String? path,
    required _EvidenceType type,
  }) async {
    final cleanPath = path?.trim();
    if (cleanPath == null || cleanPath.isEmpty) return null;
    if (_isRemoteUrl(cleanPath)) return cleanPath;

    debugPrint('${type.debugLabel} local path antes de subir: $cleanPath');

    final file = XFile(cleanPath);
    final int length;

    try {
      length = await file.length();
    } catch (_) {
      debugPrint('${type.debugLabel} file exists: false');
      throw Exception(
        'No se encontró el archivo de ${type.userLabel} en el dispositivo.',
      );
    }

    if (length <= 0) {
      debugPrint('${type.debugLabel} file exists: false');
      throw Exception(
        'El archivo de ${type.userLabel} está vacío o no se puede leer.',
      );
    }

    debugPrint('${type.debugLabel} file exists: true');

    final bytes = await file.readAsBytes();
    final storagePath = _buildEvidenceStoragePath(
      userId: userId,
      localPath: cleanPath,
      type: type,
    );

    try {
      await _client.storage
          .from(_evidenceBucket)
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              contentType: _contentTypeFor(storagePath, type),
              upsert: false,
            ),
          );

      // The bucket must be public for this URL to render directly in the app.
      // If the bucket is private, replace this with signed URL generation.
      final publicUrl = _client.storage
          .from(_evidenceBucket)
          .getPublicUrl(storagePath);
      debugPrint('${type.debugLabel} URL final guardada: $publicUrl');
      return publicUrl;
    } catch (e) {
      if (_isBucketMissingError(e)) {
        throw Exception(
          'No se pudo subir la evidencia. Verifica que el bucket $_evidenceBucket exista en Supabase Storage.',
        );
      }

      throw Exception('No se pudo subir la evidencia: $e');
    }
  }

  bool _isRemoteUrl(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  bool _isBucketMissingError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains(_evidenceBucket.toLowerCase()) ||
        message.contains('bucket') ||
        message.contains('not found') ||
        message.contains('404');
  }

  String _buildEvidenceStoragePath({
    required String userId,
    required String localPath,
    required _EvidenceType type,
  }) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final extension = _extensionFor(localPath, type);
    return 'reports/$userId/${type.folder}/$timestamp$extension';
  }

  String _extensionFor(String path, _EvidenceType type) {
    final fileName = path.split(RegExp(r'[\\/]')).last;
    final dotIndex = fileName.lastIndexOf('.');

    if (dotIndex >= 0 && dotIndex < fileName.length - 1) {
      final extension = fileName.substring(dotIndex).toLowerCase();
      if (RegExp(r'^\.[a-z0-9]+$').hasMatch(extension)) {
        return extension;
      }
    }

    return type.defaultExtension;
  }

  String _contentTypeFor(String path, _EvidenceType type) {
    final extension = _extensionFor(path, type);
    switch (extension) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.heic':
      case '.heif':
        return 'image/heic';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.aac':
        return 'audio/aac';
      case '.m4a':
        return 'audio/mp4';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      default:
        return type == _EvidenceType.audio ? 'audio/mp4' : 'image/jpeg';
    }
  }

  Future<Map<String, dynamic>> _insertReportWithCompatibility(
    Map<String, dynamic> payload,
  ) async {
    try {
      final inserted = await _client
          .from('reports')
          .insert(payload)
          .select()
          .single();

      return Map<String, dynamic>.from(inserted as Map);
    } on PostgrestException catch (e) {
      final details = e.details?.toString() ?? '';
      final missingSeverity =
          e.message.contains('severity') || details.contains('severity');

      if (!missingSeverity || !payload.containsKey('severity')) {
        rethrow;
      }

      final fallbackPayload = Map<String, dynamic>.from(payload)
        ..remove('severity');

      final inserted = await _client
          .from('reports')
          .insert(fallbackPayload)
          .select()
          .single();

      return Map<String, dynamic>.from(inserted as Map);
    }
  }

  Future<List<ReportModel>> getReportsByUserId(String userId) async {
    await _autoResolveExpiredReports();
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
    await _autoResolveExpiredReports();
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
    final imageUrl = (row['image_url'] as String?)?.trim();
    final audioUrl = (row['audio_url'] as String?)?.trim();

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
      imagePaths: imageUrl != null && imageUrl.isNotEmpty
          ? [imageUrl]
          : const [],
      audioPath: audioUrl != null && audioUrl.isNotEmpty ? audioUrl : null,
      severity: row['severity'] as String?,
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

    final words = clean
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    final short = words.take(5).join(' ');

    if (short.isEmpty) {
      return 'Reporte ciudadano';
    }

    return short[0].toUpperCase() + short.substring(1);
  }
}

enum _EvidenceType {
  image('images', '.jpg', 'imagen', 'image'),
  audio('audio', '.m4a', 'audio', 'audio');

  const _EvidenceType(
    this.folder,
    this.defaultExtension,
    this.userLabel,
    this.debugLabel,
  );

  final String folder;
  final String defaultExtension;
  final String userLabel;
  final String debugLabel;
}
