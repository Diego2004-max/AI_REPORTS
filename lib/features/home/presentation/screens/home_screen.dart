import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:reportes_ai/app/theme/app_colors.dart';
import 'package:reportes_ai/features/analytics/presentation/screens/hotspots_screen.dart';
import 'package:reportes_ai/features/analytics/presentation/screens/statistics_screen.dart';
import 'package:reportes_ai/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:reportes_ai/features/reports/presentation/screens/report_detail_screen.dart';
import 'package:reportes_ai/shared/widgets/shared_widgets.dart';
import 'package:reportes_ai/state/report_provider.dart';
import 'package:reportes_ai/state/session_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final statsAsync = ref.watch(userReportStatsProvider);
    final recentAsync = ref.watch(recentUserReportsProvider(3));
    final firstName = session.userName?.split(' ').first ?? 'Usuario';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'buenos días',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                              color: AppColors.muted,
                            ),
                          ),
                          Text(
                            firstName,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 24,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.italic,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      ),
                      child: UserAvatar(
                        initials: firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                        size: 38,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Content
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: () async => refreshReports(ref),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                    child: statsAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (e, _) => Text(e.toString()),
                      data: (stats) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              StatPill(
                                value: '${stats.total}',
                                label: 'Total',
                                dotColor: AppColors.accent,
                              ),
                              const SizedBox(width: 12),
                              StatPill(
                                value: '${stats.attended}',
                                label: 'Atendidos',
                                dotColor: AppColors.success,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ResolutionBar(total: stats.total, resolved: stats.attended),
                          const SizedBox(height: 28),
                          const SectionHeader(title: 'Recientes'),
                          recentAsync.when(
                            loading: () => const SizedBox.shrink(),
                            error: (e, _) => Text(e.toString()),
                            data: (reports) {
                              if (reports.isEmpty) {
                                return const EmptyState(
                                  icon: Icons.article_outlined,
                                  title: 'Sin reportes aún',
                                  subtitle: 'Crea tu primer reporte para verlo aquí.',
                                );
                              }
                              return Column(
                                children: reports
                                    .map(
                                      (report) => ReportCard(
                                        title: report.title,
                                        description: report.description,
                                        status: ReportStatusExt.fromString(report.status),
                                        date: '${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}',
                                        category: report.category,
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ReportDetailScreen(report: report),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          const SectionHeader(title: 'Analítica IA'),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _AnalyticsShortcut(
                                  icon: Icons.bar_chart_rounded,
                                  label: 'Estadísticas',
                                  color: AppColors.accent,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const StatisticsScreen()),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _AnalyticsShortcut(
                                  icon: Icons.location_on_rounded,
                                  label: 'Zonas de riesgo',
                                  color: AppColors.error,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const HotspotsScreen()),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsShortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AnalyticsShortcut({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        radius: 16,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
