import 'package:flutter/material.dart';

import 'package:reportes_ai/app/theme/app_colors.dart';
import 'package:reportes_ai/app/theme/app_spacing.dart';
import 'package:reportes_ai/features/reports/presentation/screens/create_audio_report_screen.dart';
import 'package:reportes_ai/features/reports/presentation/screens/create_written_report_screen.dart';
import 'package:reportes_ai/shared/widgets/app_card.dart';
import 'package:reportes_ai/shared/widgets/primary_button.dart';

class CreateReportScreen extends StatelessWidget {
  const CreateReportScreen({super.key});

  void _openWritten(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateWrittenReportScreen()),
    );
  }

  void _openAudio(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateAudioReportScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.text;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final bgColors = isDark
        ? const [AppColors.darkBg, AppColors.darkBg2, AppColors.darkBg]
        : const [AppColors.bg, AppColors.bg2, AppColors.bg];

    final titleStyle = theme.appBarTheme.titleTextStyle?.copyWith(
      color: textPrimary,
      fontSize: 22,
    );
    final headlineStyle = theme.appBarTheme.titleTextStyle?.copyWith(
      color: textPrimary,
      fontSize: 28,
      height: 1.12,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: bgColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: textPrimary,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.darkSurface
                            : AppColors.surface,
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.border,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('Crear reporte', style: titleStyle),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('¿Cómo quieres reportar?', style: headlineStyle),
                      const SizedBox(height: 8),
                      Text(
                        'Elige el tipo de reporte que deseas enviar.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _ReportOptionCard(
                        icon: Icons.edit_note_rounded,
                        title: 'Reporte escrito',
                        description:
                            'Opción para escribir manualmente el incidente.',
                        points: const [
                          'Título obligatorio',
                          'Categoría obligatoria',
                          'Descripción opcional',
                          'Ubicación obligatoria',
                          'Imagen opcional',
                        ],
                        onTap: () => _openWritten(context),
                        button: PrimaryButton(
                          label: 'Continuar con reporte escrito',
                          onPressed: () => _openWritten(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ReportOptionCard(
                        icon: Icons.mic_none_rounded,
                        title: 'Reporte por audio',
                        description: 'Opción para enviar evidencia por audio.',
                        points: const [
                          'Título obligatorio',
                          'Categoría obligatoria',
                          'Audio obligatorio',
                          'Ubicación obligatoria',
                          'Imagen opcional',
                          'Descripción opcional',
                        ],
                        onTap: () => _openAudio(context),
                        button: PrimaryButton(
                          label: 'Continuar con reporte por audio',
                          onPressed: () => _openAudio(context),
                        ),
                      ),
                    ],
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

class _ReportOptionCard extends StatelessWidget {
  const _ReportOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.points,
    required this.onTap,
    required this.button,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<String> points;
  final VoidCallback onTap;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.text;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final iconBg = isDark
        ? AppColors.primaryLight.withAlpha(28)
        : AppColors.primary.withAlpha(18);
    final iconColor = isDark ? AppColors.primaryLight : AppColors.primary;

    return AppCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            child: Icon(icon, color: iconColor, size: 23),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: theme.appBarTheme.titleTextStyle?.copyWith(
              fontSize: 21,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          ...points.map((point) => _FlowPoint(text: point)),
          const SizedBox(height: 20),
          button,
        ],
      ),
    );
  }
}

class _FlowPoint extends StatelessWidget {
  const _FlowPoint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final dotColor = isDark ? AppColors.primaryLight : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
