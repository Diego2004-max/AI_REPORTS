import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:reportes_ai/app/theme/app_colors.dart';
import 'package:reportes_ai/app/theme/app_spacing.dart';
import 'package:reportes_ai/data/models/analytics_model.dart';
import 'package:reportes_ai/shared/widgets/app_card.dart';
import 'package:reportes_ai/shared/widgets/custom_app_bar.dart';
import 'package:reportes_ai/state/analytics_provider.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  bool _showGlobal = true;

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = _showGlobal
        ? ref.watch(globalAnalyticsProvider)
        : ref.watch(userAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Estadísticas',
        subtitle: 'Análisis de reportes',
      ),
      body: Column(
        children: [
          _ScopeToggle(
            isGlobal: _showGlobal,
            onChanged: (v) => setState(() => _showGlobal = v),
          ),
          Expanded(
            child: analyticsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (summary) => _Body(summary: summary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scope toggle ────────────────────────────────────────────────────────────

class _ScopeToggle extends StatelessWidget {
  final bool isGlobal;
  final ValueChanged<bool> onChanged;

  const _ScopeToggle({required this.isGlobal, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenH, vertical: AppSpacing.md),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _Tab(label: 'Global', active: isGlobal, onTap: () => onChanged(true)),
            _Tab(label: 'Mis reportes', active: !isGlobal, onTap: () => onChanged(false)),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? AppColors.surfaceContainerLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Body ────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final AnalyticsSummary summary;

  const _Body({required this.summary});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenH, vertical: AppSpacing.sm),
      children: [
        _SummaryCards(summary: summary),
        const SizedBox(height: AppSpacing.xl),
        _SectionTitle(title: 'Actividad últimos 7 días'),
        const SizedBox(height: AppSpacing.md),
        _BarChart(stats: summary.last7Days, maxValue: summary.maxDailyCount),
        const SizedBox(height: AppSpacing.xl),
        _SectionTitle(title: 'Reportes por categoría'),
        const SizedBox(height: AppSpacing.md),
        _CategoryBreakdown(categories: summary.byCategory, total: summary.totalReports),
        const SizedBox(height: AppSpacing.xl),
        if (summary.byCategory.isNotEmpty) _HighlightCard(summary: summary),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

// ─── Summary cards ────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final AnalyticsSummary summary;

  const _SummaryCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(value: '${summary.totalReports}', label: 'Total', color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        _StatCard(value: '${summary.pendingCount}', label: 'Enviados', color: AppColors.info),
        const SizedBox(width: AppSpacing.sm),
        _StatCard(value: '${summary.reviewingCount}', label: 'Revisión', color: AppColors.warning),
        const SizedBox(width: AppSpacing.sm),
        _StatCard(value: '${summary.attendedCount}', label: 'Atendidos', color: AppColors.success),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCard({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bar chart ────────────────────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  final List<DailyStat> stats;
  final int maxValue;

  const _BarChart({required this.stats, required this.maxValue});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: stats.map((s) {
                final ratio = s.count / maxValue;
                final isToday = _isToday(s.date);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (s.count > 0)
                          Text(
                            '${s.count}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isToday ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          height: ratio * 90,
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.primary
                                : AppColors.primary.withAlpha(80),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: stats.map((s) {
              final isToday = _isToday(s.date);
              return Expanded(
                child: Text(
                  DateFormat('E', 'es').format(s.date).substring(0, 2).toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                    color: isToday ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

// ─── Category breakdown ───────────────────────────────────────────────────────

class _CategoryBreakdown extends StatelessWidget {
  final List<CategoryStat> categories;
  final int total;

  const _CategoryBreakdown({required this.categories, required this.total});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const AppCard(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: Text('Sin datos de categorías aún',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: categories.asMap().entries.map((entry) {
          final i = entry.key;
          final stat = entry.value;
          final pct = total > 0 ? stat.count / total : 0.0;
          final color = AnalyticsSummary.colorForIndex(i);

          return Padding(
            padding: EdgeInsets.only(bottom: i < categories.length - 1 ? 16 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(stat.category,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary)),
                    ),
                    Text(
                      '${stat.count}  ${(pct * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Highlight card ───────────────────────────────────────────────────────────

class _HighlightCard extends StatelessWidget {
  final AnalyticsSummary summary;

  const _HighlightCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.emoji_events_rounded,
                color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Categoría más reportada',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  summary.mostActiveCategory,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          Text(
            '${summary.byCategory.first.count} reportes',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ─── Section title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
    );
  }
}
