import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:reportes_ai/app/theme/app_colors.dart';
import 'package:reportes_ai/app/theme/app_spacing.dart';
import 'package:reportes_ai/features/reports/presentation/screens/report_list_screen.dart';
import 'package:reportes_ai/shared/widgets/shared_widgets.dart';
import 'package:reportes_ai/state/analytics_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.text;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final faintColor = isDark ? AppColors.darkTextDisabled : AppColors.faint;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      color: textPrimary,
                      onPressed: () => Navigator.of(context).maybePop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Notificaciones',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    // FIX: "Leer todo" deshabilitado (gris + tooltip) hasta integrar notificaciones en tiempo real
                    Tooltip(
                      message: 'Disponible pronto',
                      child: Text(
                        'Leer todo',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: faintColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  children: [
                    // FIX: eliminados los 4 NotifTile con datos inventados
                    // REQUISITO PENDIENTE: módulo de notificaciones en tiempo real — agente separado
                    const EmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'Sin notificaciones',
                      subtitle:
                          'Las notificaciones aparecerán aquí cuando se integre el módulo en tiempo real.',
                    ),
                    const SizedBox(height: 20),
                    _RiskSummaryCard(analyticsRef: ref),
                    const SizedBox(height: 20),
                    _CategoryPredictions(analyticsRef: ref),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 12,
                          color: faintColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Predicciones de IA · No reemplazan a autoridades',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 10,
                            fontWeight: FontWeight.w300,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RiskSummaryCard extends StatelessWidget {
  final WidgetRef analyticsRef;
  const _RiskSummaryCard({required this.analyticsRef});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final labelColor = isDark ? AppColors.darkTextDisabled : AppColors.faint;
    final bodyColor = isDark ? AppColors.darkTextSecondary : AppColors.muted;

    final analyticsAsync = analyticsRef.watch(globalAnalyticsProvider);
    return analyticsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (analytics) {
        final topCategory = analytics.mostActiveCategory;
        final total = analytics.totalReports;
        final riskLevel = total >= 20
            ? 'Alto'
            : total >= 8
            ? 'Moderado'
            : 'Bajo';
        final riskColor = total >= 20
            ? AppColors.error
            : total >= 8
            ? AppColors.warning
            : AppColors.success;
        return AppCard(
          radius: 24,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RIESGO EN TU ZONA',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 10,
                  fontWeight: FontWeight.w300,
                  color: labelColor,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                riskLevel,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: riskColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Se registraron $total reportes en la zona. '
                'El tipo de incidente más frecuente es "$topCategory".',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: bodyColor,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.update_rounded, size: 12, color: labelColor),
                  const SizedBox(width: 5),
                  Text(
                    'Basado en datos recientes',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 11,
                      fontWeight: FontWeight.w300,
                      color: labelColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryPredictions extends StatelessWidget {
  final WidgetRef analyticsRef;
  const _CategoryPredictions({required this.analyticsRef});

  static const _riskLabels = ['Riesgo alto', 'Riesgo medio', 'Bajo riesgo'];
  static const _riskColors = [
    AppColors.error,
    AppColors.warning,
    AppColors.success,
  ];

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = analyticsRef.watch(globalAnalyticsProvider);
    return analyticsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (analytics) {
        final cats = analytics.byCategory.take(3).toList();
        if (cats.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            for (int i = 0; i < cats.length; i++) ...[
              // FIX: onTap navega a ReportListScreen con la categoría como filtro preseleccionado
              _PredictionTile(
                title: cats[i].category,
                level: _riskLabels[i % _riskLabels.length],
                levelColor: _riskColors[i % _riskColors.length],
                count: cats[i].count,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ReportListScreen(initialCategory: cats[i].category),
                  ),
                ),
              ),
              if (i < cats.length - 1) const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _PredictionTile extends StatelessWidget {
  final String title;
  final String level;
  final Color levelColor;
  final int count;
  // FIX: onTap para navegar a ReportListScreen con categoría filtrada
  final VoidCallback? onTap;

  const _PredictionTile({
    required this.title,
    required this.level,
    required this.levelColor,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.text;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.muted;

    return AppCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 52,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: levelColor,
              borderRadius: AppRadius.borderFull,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: levelColor.withAlpha(25),
                        borderRadius: AppRadius.borderFull,
                      ),
                      child: Text(
                        level,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: levelColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$count reportes registrados',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Basado en datos históricos',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 10,
                    fontWeight: FontWeight.w300,
                    color: AppColors.accent,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
