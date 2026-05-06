import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:reportes_ai/data/models/analytics_model.dart';
import 'package:reportes_ai/data/repositories/analytics_repository_impl.dart';
import 'package:reportes_ai/state/report_provider.dart';
import 'package:reportes_ai/state/session_provider.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepositoryImpl>((ref) {
  return AnalyticsRepositoryImpl(Supabase.instance.client);
});

/// Statistics for all reports in the system.
final globalAnalyticsProvider = FutureProvider<AnalyticsSummary>((ref) {
  ref.watch(reportRefreshProvider);
  return ref.read(analyticsRepositoryProvider).getSummary();
});

/// Statistics for the authenticated user only.
final userAnalyticsProvider = FutureProvider<AnalyticsSummary>((ref) {
  ref.watch(reportRefreshProvider);
  final userId = ref.watch(sessionProvider).userId;
  if (userId == null) throw Exception('No autenticado');
  return ref.read(analyticsRepositoryProvider).getSummary(userId: userId);
});

/// Hotspot zones grouped by report density.
final hotspotsProvider = FutureProvider<List<HotspotZone>>((ref) {
  ref.watch(reportRefreshProvider);
  return ref.read(analyticsRepositoryProvider).getHotspots();
});
