import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:reportes_ai/app/theme/app_colors.dart';
import 'package:reportes_ai/app/theme/app_spacing.dart';
import 'package:reportes_ai/shared/widgets/shared_widgets.dart';
import 'package:reportes_ai/state/analytics_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: AppColors.text),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Notificaciones',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Todas las notificaciones marcadas como leídas.')),
                      ),
                      child: Text(
                        'Leer todo',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.accent,
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
                    Text(
                      'HOY',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w300,
                        color: AppColors.faint,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const NotifTile(
                      title: 'Reporte atendido',
                      message: 'Tu reporte "Hueco en la Cra 7" ha sido marcado como atendido por las autoridades.',
                      date: 'Hace 5 min',
                      status: ReportStatus.atendido,
                    ),
                    const NotifTile(
                      title: 'Reporte en revisión',
                      message: 'Las autoridades están revisando tu reporte "Semáforo dañado Av. 30". Te notificaremos cuando haya novedades.',
                      date: 'Hace 2 horas',
                      status: ReportStatus.enRevision,
                    ),
                    const NotifTile(
                      title: 'Nuevo reporte cercano',
                      message: 'Se reportó un accidente a 200 m de tu ubicación habitual en la Autopista Norte.',
                      date: 'Hace 3 horas',
                      lineColor: AppColors.accent,
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: 20),
                    Text(
                      'AYER',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w300,
                        color: AppColors.faint,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const NotifTile(
                      title: 'Reporte rechazado',
                      message: 'Tu reporte "Derrumbe vía al mar" fue revisado pero no se pudo verificar. Puedes enviar uno nuevo con más evidencia.',
                      date: 'Ayer, 4:30 PM',
                      status: ReportStatus.rechazado,
                    ),
                    const SizedBox(height: 20),
                    _RiskSummaryCard(analyticsRef: ref),
                    const SizedBox(height: 20),
                    _CategoryPredictions(analyticsRef: ref),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 12, color: AppColors.faint),
                        const SizedBox(width: 5),
                        Text(
                          'Predicciones de IA · No reemplazan a autoridades',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w300,
                            color: AppColors.faint,
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
    final analyticsAsync = analyticsRef.watch(globalAnalyticsProvider);
    return analyticsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
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
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w300,
                  color: AppColors.faint,
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
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: AppColors.muted,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.update_rounded,
                      size: 12, color: AppColors.faint),
                  const SizedBox(width: 5),
                  Text(
                    'Datos en tiempo real',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w300,
                      color: AppColors.faint,
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
  static const _riskColors = [AppColors.error, AppColors.warning, AppColors.success];

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = analyticsRef.watch(globalAnalyticsProvider);
    return analyticsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (analytics) {
        final cats = analytics.byCategory.take(3).toList();
        if (cats.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            for (int i = 0; i < cats.length; i++) ...[
              _PredictionTile(
                title: cats[i].category,
                level: _riskLabels[i % _riskLabels.length],
                levelColor: _riskColors[i % _riskColors.length],
                count: cats[i].count,
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

  const _PredictionTile({
    required this.title,
    required this.level,
    required this.levelColor,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 52,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
                color: levelColor, borderRadius: AppRadius.borderFull),
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
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.text,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: levelColor.withAlpha(25),
                        borderRadius: AppRadius.borderFull,
                      ),
                      child: Text(
                        level,
                        style: GoogleFonts.dmSans(
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
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Basado en datos históricos',
                  style: GoogleFonts.dmSans(
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
