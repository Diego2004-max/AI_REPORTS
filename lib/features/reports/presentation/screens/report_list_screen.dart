import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:reportes_ai/app/theme/app_colors.dart';
import 'package:reportes_ai/data/models/report_model.dart';
import 'package:reportes_ai/shared/widgets/shared_widgets.dart';
import 'package:reportes_ai/state/report_provider.dart';

import 'report_detail_screen.dart';

class ReportListScreen extends ConsumerStatefulWidget {
  const ReportListScreen({super.key, this.initialCategory, this.initialFilter});

  final String? initialCategory;
  final String? initialFilter;

  @override
  ConsumerState<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends ConsumerState<ReportListScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedFilter = 'Todos';
  String _searchQuery = '';
  String? _categoryFilter;

  static const List<String> _filters = ['Todos'];

  @override
  void initState() {
    super.initState();
    _categoryFilter = widget.initialCategory;
    if (_categoryFilter != null) {
      _searchQuery = _categoryFilter!;
      _searchCtrl.text = _categoryFilter!;
    }
    if (widget.initialFilter != null &&
        _filters.contains(widget.initialFilter)) {
      _selectedFilter = widget.initialFilter!;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  ReportStatus _toStatus(String s) => ReportStatusExt.fromString(s);

  List<ReportModel> _applyFilters(List<ReportModel> reports) {
    final filtered = reports.where((report) {
      final query = _searchQuery.toLowerCase().trim();
      final matchesSearch =
          query.isEmpty ||
          report.title.toLowerCase().contains(query) ||
          report.category.toLowerCase().contains(query) ||
          report.description.toLowerCase().contains(query) ||
          (report.locationLabel?.toLowerCase().contains(query) ?? false);
      return matchesSearch;
    }).toList();

    filtered.sort((a, b) {
      final aA = a.status.toLowerCase().contains('atendido');
      final bA = b.status.toLowerCase().contains('atendido');
      if (aA != bA) return aA ? 1 : -1;
      return b.createdAt.compareTo(a.createdAt);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(allReportsProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.darkTextPrimary : AppColors.text;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reportes',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 30,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppSearchBar(
                      hint: 'Buscar reporte...',
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => AppFilterChip(
                    label: _filters[i],
                    selected: _selectedFilter == _filters[i],
                    onTap: () => setState(() => _selectedFilter = _filters[i]),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: reportsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => EmptyState(
                    icon: Icons.error_outline,
                    title: 'Error',
                    subtitle: e.toString(),
                  ),
                  data: (reports) {
                    final filtered = _applyFilters(reports);
                    if (filtered.isEmpty) {
                      return const EmptyState(
                        icon: Icons.article_outlined,
                        title: 'Sin resultados',
                        subtitle: 'No hay reportes con estos filtros.',
                      );
                    }
                    return RefreshIndicator(
                      color: AppColors.accent,
                      onRefresh: () async => refreshReports(ref),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 8,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final report = filtered[i];
                          return ReportCard(
                            title: report.title,
                            description:
                                report.locationLabel ?? report.description,
                            status: _toStatus(report.status),
                            date:
                                '${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}',
                            category: report.category,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ReportDetailScreen(report: report),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
