import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:reportes_ai/app/theme/app_colors.dart';
import 'package:reportes_ai/data/models/report_model.dart';
import 'package:reportes_ai/shared/widgets/shared_widgets.dart';
import 'package:reportes_ai/state/report_provider.dart';

import 'report_detail_screen.dart';

class ReportListScreen extends ConsumerStatefulWidget {
  const ReportListScreen({super.key});

  @override
  ConsumerState<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends ConsumerState<ReportListScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedFilter = 'Todos';
  String _searchQuery = '';

  static const List<String> _filters = ['Todos', 'Enviados', 'En revisión', 'Atendidos'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  ReportStatus _toStatus(String s) => ReportStatusExt.fromString(s);

  List<ReportModel> _applyFilters(List<ReportModel> reports) {
    return reports.where((report) {
      bool matchesFilter = true;
      if (_selectedFilter != 'Todos') {
        final status = _toStatus(report.status);
        matchesFilter = switch (_selectedFilter) {
          'Enviados'    => status == ReportStatus.enviado,
          'En revisión' => status == ReportStatus.enRevision,
          'Atendidos'   => status == ReportStatus.atendido,
          _             => true,
        };
      }
      final query = _searchQuery.toLowerCase().trim();
      final matchesSearch = query.isEmpty ||
          report.title.toLowerCase().contains(query) ||
          report.category.toLowerCase().contains(query) ||
          report.description.toLowerCase().contains(query) ||
          (report.locationLabel?.toLowerCase().contains(query) ?? false);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(allReportsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
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
                        color: AppColors.text,
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
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                  loading: () => const Center(child: CircularProgressIndicator()),
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
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final report = filtered[i];
                          return ReportCard(
                            title: report.title,
                            description: report.locationLabel ?? report.description,
                            status: _toStatus(report.status),
                            date: '${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}',
                            category: report.category,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReportDetailScreen(report: report),
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
