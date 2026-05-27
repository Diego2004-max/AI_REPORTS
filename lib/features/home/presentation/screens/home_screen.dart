import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:reportes_ai/app/router/app_router.dart';
import 'package:reportes_ai/app/theme/app_colors.dart';
import 'package:reportes_ai/features/analytics/presentation/screens/hotspots_screen.dart';
import 'package:reportes_ai/features/analytics/presentation/screens/statistics_screen.dart';
import 'package:reportes_ai/features/reports/presentation/screens/report_detail_screen.dart';
import 'package:reportes_ai/features/reports/presentation/screens/report_list_screen.dart';
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

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'buenos días'
        : hour < 18
        ? 'buenas tardes'
        : 'buenas noches';

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final greetingColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.muted;
    final nameColor = isDark ? AppColors.darkTextPrimary : AppColors.text;
    final errorColor = isDark ? AppColors.darkTextSecondary : AppColors.muted;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.15),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Column(
                        key: ValueKey(firstName),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            greeting,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 11,
                              fontWeight: FontWeight.w300,
                              color: greetingColor,
                            ),
                          ),
                          Text(
                            firstName,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.italic,
                              color: nameColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // FIX: Tooltip + Semantics for accessibility; context.push for named route (Fix 9+10)
                    Tooltip(
                      message: 'Ver notificaciones',
                      child: Semantics(
                        label: 'Botón de notificaciones',
                        button: true,
                        child: GestureDetector(
                          onTap: () => context.push(AppRoutes.notifications),
                          child: UserAvatar(
                            initials: firstName.isNotEmpty
                                ? firstName[0].toUpperCase()
                                : 'U',
                            size: 38,
                          ),
                        ),
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
                      // FIX: show placeholder containers matching StatPill layout during load
                      loading: () {
                        final placeholderColor = isDark
                            ? AppColors.darkSurface
                            : AppColors.bg2;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: FractionallySizedBox(
                                widthFactor: 0.74,
                                child: Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: placeholderColor,
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      // FIX: mensaje amigable con botón de reintento en lugar de excepción cruda
                      error: (e, _) => Column(
                        children: [
                          Text(
                            'No se pudieron cargar tus estadísticas. Intenta de nuevo.',
                            style: TextStyle(color: errorColor, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () =>
                                ref.invalidate(userReportStatsProvider),
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                      data: (stats) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: FractionallySizedBox(
                              widthFactor: 0.74,
                              child: _TotalReportsCard(
                                value: '${stats.total}',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ReportListScreen(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              'Reportes registrados',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: errorColor,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          const SectionHeader(title: 'Recientes'),
                          recentAsync.when(
                            // FIX: show centered indicator while recent reports load
                            loading: () => const SizedBox(
                              height: 120,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (e, _) => Text(
                              e.toString(),
                              style: TextStyle(color: errorColor, fontSize: 13),
                            ),
                            data: (reports) {
                              if (reports.isEmpty) {
                                return const EmptyState(
                                  icon: Icons.article_outlined,
                                  title: 'Sin reportes aún',
                                  subtitle:
                                      'Crea tu primer reporte para verlo aquí.',
                                );
                              }
                              return Column(
                                children: reports
                                    .map(
                                      (report) => ReportCard(
                                        title: report.title,
                                        description: report.description,
                                        status: ReportStatusExt.fromString(
                                          report.status,
                                        ),
                                        date:
                                            '${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}',
                                        category: report.category,
                                        heroTag: 'status_${report.id}',
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ReportDetailScreen(
                                              report: report,
                                            ),
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
                                      builder: (_) => const StatisticsScreen(),
                                    ),
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
                                      builder: (_) => const HotspotsScreen(),
                                    ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.text;

    return AppCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      onTap: onTap,
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
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.playfairDisplay(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalReportsCard extends StatelessWidget {
  const _TotalReportsCard({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.text;
    final mutedColor = isDark ? AppColors.darkTextSecondary : AppColors.faint;

    return AppCard(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 44,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              color: textColor,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'TOTAL',
            style: GoogleFonts.playfairDisplay(
              fontSize: 10,
              fontWeight: FontWeight.w300,
              color: mutedColor,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
