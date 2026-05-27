class ReportModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final String status;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? locationLabel;
  final double? latitude;
  final double? longitude;
  final List<String> imagePaths;
  final String? audioPath;
  final String? severity;
  final String? aiCategory;
  final double? aiConfidence;
  final double? priorityScore;
  final double? credibilityScore;

  const ReportModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.createdAt,
    this.expiresAt,
    this.locationLabel,
    this.latitude,
    this.longitude,
    this.imagePaths = const [],
    this.audioPath,
    this.severity,
    this.aiCategory,
    this.aiConfidence,
    this.priorityScore,
    this.credibilityScore,
  });

  Map<String, dynamic> toMap() {
    final cleanImagePaths = imagePaths
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList();
    final cleanAudioPath = audioPath?.trim();

    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'locationLabel': locationLabel,
      'latitude': latitude,
      'longitude': longitude,
      'imagePaths': cleanImagePaths,
      'audioPath': cleanAudioPath?.isNotEmpty == true ? cleanAudioPath : null,
      'severity': severity,
      'aiCategory': aiCategory,
      'aiConfidence': aiConfidence,
      'priorityScore': priorityScore,
      'credibilityScore': credibilityScore,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    final createdAtRaw = map['createdAt'] ?? map['created_at'];
    final expiresAtRaw = map['expiresAt'] ?? map['expires_at'];
    final imageUrl = (map['image_url'] as String?)?.trim();
    final rawImagePaths =
        (map['imagePaths'] as List?)
            ?.cast<String>()
            .map((path) => path.trim())
            .where((path) => path.isNotEmpty)
            .toList() ??
        const <String>[];
    final audioUrl = ((map['audioPath'] ?? map['audio_url']) as String?)
        ?.trim();

    return ReportModel(
      id: map['id'] as String,
      userId: (map['userId'] ?? map['user_id']) as String,
      title: map['title'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      status: map['status'] as String,
      createdAt: DateTime.parse(createdAtRaw as String),
      expiresAt: expiresAtRaw != null
          ? DateTime.parse(expiresAtRaw as String)
          : null,
      locationLabel: (map['locationLabel'] ?? map['location_label']) as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      imagePaths: rawImagePaths.isNotEmpty
          ? rawImagePaths
          : (imageUrl != null && imageUrl.isNotEmpty ? [imageUrl] : const []),
      audioPath: audioUrl != null && audioUrl.isNotEmpty ? audioUrl : null,
      severity: (map['severity']) as String?,
      aiCategory: (map['aiCategory'] ?? map['ai_category']) as String?,
      aiConfidence: ((map['aiConfidence'] ?? map['ai_confidence']) as num?)
          ?.toDouble(),
      priorityScore: ((map['priorityScore'] ?? map['priority_score']) as num?)
          ?.toDouble(),
      credibilityScore:
          ((map['credibilityScore'] ?? map['credibility_score']) as num?)
              ?.toDouble(),
    );
  }
}
