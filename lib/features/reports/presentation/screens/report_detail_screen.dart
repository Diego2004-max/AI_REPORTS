import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:reportes_ai/app/theme/app_colors.dart';
import 'package:reportes_ai/app/theme/app_spacing.dart';
import 'package:reportes_ai/data/models/report_model.dart';
import 'package:reportes_ai/shared/widgets/app_card.dart';
import 'package:reportes_ai/shared/widgets/custom_app_bar.dart';
import 'package:reportes_ai/shared/widgets/primary_button.dart';
import 'package:reportes_ai/shared/widgets/status_badge.dart';
import 'package:reportes_ai/data/repositories/report_repository_impl.dart';
import 'package:reportes_ai/state/report_provider.dart';
import 'package:reportes_ai/state/session_provider.dart';

class ReportDetailScreen extends ConsumerWidget {
  const ReportDetailScreen({
    super.key,
    required this.report,
  });

  final ReportModel report;

  bool get _showSecondaryCoordinates {
    if (report.latitude == null || report.longitude == null) return false;
    if (report.locationLabel == null) return true;
    return !report.locationLabel!.startsWith('Lat ');
  }

  String _formatDate(DateTime date) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${date.day} ${months[date.month - 1]}. ${date.year}';
  }

  String _buildExpirationLabel() {
    final expiresAt = report.expiresAt;
    if (expiresAt == null) {
      return 'Este reporte no tiene fecha de eliminación configurada.';
    }

    final now = DateTime.now();
    final difference = expiresAt.difference(now);

    if (difference.inSeconds <= 0) {
      return 'Este reporte vence hoy y será eliminado automáticamente.';
    }

    final daysLeft = (difference.inHours / 24).ceil();
    if (daysLeft == 1) return 'Este reporte se elimina en 1 día.';
    return 'Este reporte se elimina en $daysLeft días.';
  }

  Future<void> _confirmResolve(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Marcar como resuelto'),
          content: const Text(
            '¿Confirmas que este problema ya fue atendido o resuelto en tu zona?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await ref
        .read(reportRepositoryProvider)
        .updateStatus(report.id, UserReportStatus.attended);
    refreshReports(ref);

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporte marcado como atendido')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar reporte'),
          content: const Text(
            '¿Seguro que quieres eliminar este reporte? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await ref.read(reportRepositoryProvider).deleteReport(report.id);
    refreshReports(ref);

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporte eliminado correctamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(sessionProvider);
    final hasImage = report.imagePaths.isNotEmpty;
    final canDelete = session.userId == report.userId;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Detalle del reporte',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header card ─────────────────────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          report.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      StatusBadge(status: report.status, showIcon: true),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.category_outlined,
                    label: report.category,
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: _formatDate(report.createdAt),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Description ─────────────────────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardLabel('Descripción'),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    report.description,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Expiration ──────────────────────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardLabel('Vigencia'),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _buildExpirationLabel(),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  if (report.expiresAt != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Padding(
                      padding: const EdgeInsets.only(left: 26),
                      child: Text(
                        'Fecha límite: ${_formatDate(report.expiresAt!)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Location ────────────────────────────────────────────────────
            if (report.locationLabel != null ||
                report.latitude != null ||
                report.longitude != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CardLabel('Ubicación'),
                    const SizedBox(height: AppSpacing.sm),
                    if (report.locationLabel != null)
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        label: report.locationLabel!,
                      ),
                    if (_showSecondaryCoordinates) ...[
                      const SizedBox(height: 6),
                      _InfoRow(
                        icon: Icons.my_location_outlined,
                        label:
                            'Lat ${report.latitude!.toStringAsFixed(5)}, Lng ${report.longitude!.toStringAsFixed(5)}',
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // ── Image ───────────────────────────────────────────────────────
            if (hasImage) ...[
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CardLabel('Imagen adjunta'),
                    const SizedBox(height: AppSpacing.sm),
                    _ReportImagePreview(imagePath: report.imagePaths.first),
                  ],
                ),
              ),
            ],

            // ── Ownership notice ─────────────────────────────────────────
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              color: canDelete
                  ? AppColors.primary.withAlpha(8)
                  : null,
              child: Row(
                children: [
                  Icon(
                    canDelete
                        ? Icons.verified_user_outlined
                        : Icons.lock_outline,
                    color: canDelete ? AppColors.primary : AppColors.outline,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      canDelete
                          ? 'Tú creaste este reporte. Puedes eliminarlo antes de su vencimiento.'
                          : 'Solo el usuario que creó este reporte puede eliminarlo.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),

            // ── Resolve button ───────────────────────────────────────────
            if (canDelete &&
                report.status != UserReportStatus.attended) ...[
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Marcar como resuelto',
                backgroundColor: AppColors.success.withAlpha(25),
                foregroundColor: AppColors.success,
                onPressed: () => _confirmResolve(context, ref),
              ),
            ],

            // ── Delete button ────────────────────────────────────────────
            if (canDelete) ...[
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Eliminar reporte',
                backgroundColor: theme.colorScheme.errorContainer,
                foregroundColor: theme.colorScheme.error,
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _CardLabel extends StatelessWidget {
  const _CardLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportImagePreview extends StatelessWidget {
  const _ReportImagePreview({required this.imagePath});

  final String imagePath;

  Future<Uint8List> _loadBytes() => XFile(imagePath).readAsBytes();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _loadBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Cargando imagen...'),
              ],
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Text('No se pudo cargar la imagen adjunta.');
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Image.memory(
            snapshot.data!,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}
