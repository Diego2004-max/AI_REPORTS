import 'package:reportes_ai/data/models/analytics_model.dart';

abstract class AnalyticsRepository {
  Future<AnalyticsSummary> getSummary({String? userId});
  Future<List<HotspotZone>> getHotspots();
}
