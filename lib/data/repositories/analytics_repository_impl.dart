import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:reportes_ai/data/models/analytics_model.dart';
import 'package:reportes_ai/data/models/report_model.dart';
import 'package:reportes_ai/domain/repositories/analytics_repository.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final SupabaseClient _client;

  AnalyticsRepositoryImpl(this._client);

  @override
  Future<AnalyticsSummary> getSummary({String? userId}) async {
    var query = _client.from('reports').select();
    if (userId != null) {
      query = query.eq('user_id', userId);
    }
    final data = await query;
    final reports = (data as List)
        .map((m) => ReportModel.fromMap(m as Map<String, dynamic>))
        .toList();

    return _compute(reports);
  }

  @override
  Future<List<HotspotZone>> getHotspots() async {
    final data = await _client
        .from('reports')
        .select('latitude, longitude, category, priority_score');

    // Group by ~500m grid (~0.005 degrees per 500m at equator)
    final zones = <String, Map<String, dynamic>>{};
    for (final row in (data as List)) {
      final lat = (row['latitude'] as num?)?.toDouble();
      final lng = (row['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      // Grid key: round to 2 decimal places (~1.1km grid)
      final gridLat = (lat * 100).round() / 100;
      final gridLng = (lng * 100).round() / 100;
      final key = '${gridLat}_$gridLng';

      final entry = zones.putIfAbsent(key, () => {
            'lat': gridLat,
            'lng': gridLng,
            'count': 0,
            'cats': <String, int>{},
            'prioritySum': 0.0,
          });

      entry['count'] = (entry['count'] as int) + 1;

      final cats = entry['cats'] as Map<String, int>;
      final cat = (row['category'] as String?) ?? 'Otro';
      cats[cat] = (cats[cat] ?? 0) + 1;

      // Accumulate priority score for risk calculation
      final ps = (row['priority_score'] as num?)?.toDouble() ?? 0.5;
      entry['prioritySum'] = (entry['prioritySum'] as double) + ps;
    }

    if (zones.isEmpty) return [];

    final maxCount = zones.values
        .map((z) => z['count'] as int)
        .reduce((a, b) => a > b ? a : b);

    final result = zones.values.map((z) {
      final cats = z['cats'] as Map<String, int>;
      final top =
          cats.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      final count = z['count'] as int;
      final prioritySum = z['prioritySum'] as double;

      // riskScore: weighted average of priority scores, boosted by density
      final avgPriority = count > 0 ? prioritySum / count : 0.5;
      final densityBoost = (count / maxCount) * 0.3;
      final riskScore = (avgPriority * 0.7 + densityBoost).clamp(0.0, 1.0);

      return HotspotZone(
        lat: z['lat'] as double,
        lng: z['lng'] as double,
        count: count,
        topCategory: top,
        riskScore: riskScore,
      );
    }).toList()
      ..sort((a, b) => b.riskScore.compareTo(a.riskScore));

    return result;
  }

  AnalyticsSummary _compute(List<ReportModel> reports) {
    final pending = reports.where((r) => r.status == 'Enviado').length;
    final reviewing = reports.where((r) => r.status == 'En revisión').length;
    final attended = reports.where((r) => r.status == 'Atendido').length;

    final categoryMap = <String, int>{};
    for (final r in reports) {
      categoryMap[r.category] = (categoryMap[r.category] ?? 0) + 1;
    }
    final byCategory = categoryMap.entries
        .map((e) => CategoryStat(category: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final now = DateTime.now();
    final last7Days = List.generate(7, (i) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - i));
      final count = reports.where((r) {
        return r.createdAt.year == day.year &&
            r.createdAt.month == day.month &&
            r.createdAt.day == day.day;
      }).length;
      return DailyStat(date: day, count: count);
    });

    return AnalyticsSummary(
      totalReports: reports.length,
      pendingCount: pending,
      reviewingCount: reviewing,
      attendedCount: attended,
      byCategory: byCategory,
      last7Days: last7Days,
    );
  }
}
