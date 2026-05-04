import 'package:flutter/material.dart';

class HotspotZone {
  final double lat;
  final double lng;
  final int count;
  final String topCategory;
  final double riskScore;

  const HotspotZone({
    required this.lat,
    required this.lng,
    required this.count,
    required this.topCategory,
    this.riskScore = 0.5,
  });
}

class CategoryStat {
  final String category;
  final int count;
  const CategoryStat({required this.category, required this.count});
}

class DailyStat {
  final DateTime date;
  final int count;
  const DailyStat({required this.date, required this.count});
}

class AnalyticsSummary {
  final int totalReports;
  final int pendingCount;
  final int reviewingCount;
  final int attendedCount;
  final List<CategoryStat> byCategory;
  final List<DailyStat> last7Days;

  const AnalyticsSummary({
    required this.totalReports,
    required this.pendingCount,
    required this.reviewingCount,
    required this.attendedCount,
    required this.byCategory,
    required this.last7Days,
  });

  String get mostActiveCategory =>
      byCategory.isNotEmpty ? byCategory.first.category : '-';

  int get maxDailyCount {
    if (last7Days.isEmpty) return 1;
    final m = last7Days.map((d) => d.count).reduce((a, b) => a > b ? a : b);
    return m == 0 ? 1 : m;
  }

  static Color colorForIndex(int i) {
    const colors = [
      Color(0xFFBA1A1A),
      Color(0xFFEF9F27),
      Color(0xFF378ADD),
      Color(0xFF1D9E75),
      Color(0xFF9C27B0),
    ];
    return colors[i % colors.length];
  }
}

/// Result from the Edge Function `classify` action (for storing in Supabase).
class AiClassificationResult {
  final String category;
  final double confidence;
  final String severity;
  final bool sensitiveLoc;
  final bool roadImpact;

  const AiClassificationResult({
    required this.category,
    required this.confidence,
    required this.severity,
    required this.sensitiveLoc,
    required this.roadImpact,
  });
}

/// Aggregated analytics for a set of reports.
class ReportAnalytics {
  final Map<String, int> countByCategory;
  final Map<String, int> countByStatus;
  final double avgPriorityScore;
  final List<HotspotZone> hotspots;

  const ReportAnalytics({
    required this.countByCategory,
    required this.countByStatus,
    required this.avgPriorityScore,
    required this.hotspots,
  });
}
