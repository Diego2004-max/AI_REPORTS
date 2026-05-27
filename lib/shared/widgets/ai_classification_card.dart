import 'package:flutter/material.dart';
import 'package:reportes_ai/app/theme/app_colors.dart';
import 'package:reportes_ai/data/models/ai_classification.dart';

class AiClassificationCard extends StatelessWidget {
  final AiClassification classification;
  final VoidCallback? onAcceptCategory;
  final VoidCallback? onAcceptSeverity;
  // FIX: track whether each field is already applied to show "Editar" instead of "Aplicar"
  final bool categoryAccepted;
  final bool severityAccepted;

  const AiClassificationCard({
    super.key,
    required this.classification,
    this.onAcceptCategory,
    this.onAcceptSeverity,
    this.categoryAccepted = false,
    this.severityAccepted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryTone = isDark ? AppColors.primaryLight : AppColors.primary;
    final secondaryText = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final borderColor = isDark
        ? AppColors.primaryLight.withAlpha(80)
        : AppColors.primary.withAlpha(40);
    final headerBg = isDark
        ? AppColors.primaryLight.withAlpha(28)
        : AppColors.primary.withAlpha(20);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withAlpha(isDark ? 22 : 12),
            AppColors.info.withAlpha(isDark ? 14 : 8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: headerBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: primaryTone,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Análisis de IA',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: primaryTone,
                ),
              ),
              const Spacer(),
              _ConfidenceBadge(
                label: classification.confidenceLabel,
                confidence: classification.confidence,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Category suggestion
          _SuggestionRow(
            icon: Icons.category_rounded,
            label: 'Categoría',
            value: classification.suggestedCategory,
            onAccept: onAcceptCategory,
            isApplied: categoryAccepted,
          ),
          const SizedBox(height: 10),

          // Severity suggestion
          _SuggestionRow(
            icon: Icons.warning_amber_rounded,
            label: 'Severidad',
            value: classification.suggestedSeverity,
            valueColor: _severityColor(classification.suggestedSeverity),
            onAccept: onAcceptSeverity,
            isApplied: severityAccepted,
          ),
          const SizedBox(height: 14),

          // Priority score
          _PriorityBar(score: classification.priorityScore),

          // Entities
          if (classification.entities.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: classification.entities.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                  child: Text(
                    e,
                    style: TextStyle(fontSize: 11, color: secondaryText),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'Crítico':
        return AppColors.error;
      case 'Moderado':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }
}

class _SuggestionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onAccept;
  // FIX: when true shows "Editar" (value already applied) instead of "Aplicar"
  final bool isApplied;

  const _SuggestionRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.onAccept,
    this.isApplied = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryTone = isDark ? AppColors.primaryLight : AppColors.primary;
    final secondaryText = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final primaryText = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;

    return Row(
      children: [
        Icon(icon, size: 14, color: secondaryText),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: secondaryText)),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? primaryText,
          ),
        ),
        const Spacer(),
        if (onAccept != null)
          GestureDetector(
            onTap: onAccept,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                // FIX: "Editar" uses outline style; "Aplicar" uses filled style
                color: isApplied ? Colors.transparent : primaryTone,
                borderRadius: BorderRadius.circular(20),
                border: isApplied
                    ? Border.all(color: primaryTone.withAlpha(120))
                    : null,
              ),
              child: Text(
                isApplied ? 'Editar' : 'Aplicar',
                style: TextStyle(
                  fontSize: 11,
                  color: isApplied ? primaryTone : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PriorityBar extends StatelessWidget {
  final int score;

  const _PriorityBar({required this.score});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryText = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final normalizedScore = score.clamp(0, 100).toInt();
    final color = score >= 66
        ? AppColors.error
        : score >= 36
        ? AppColors.warning
        : AppColors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.speed_rounded, size: 14, color: secondaryText),
            const SizedBox(width: 6),
            Text(
              'Prioridad',
              style: TextStyle(fontSize: 12, color: secondaryText),
            ),
            const Spacer(),
            Text(
              '$normalizedScore / 100',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: normalizedScore / 100,
            minHeight: 6,
            backgroundColor: isDark
                ? AppColors.darkSurfaceVariant
                : AppColors.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final String label;
  final double confidence;

  const _ConfidenceBadge({required this.label, required this.confidence});

  @override
  Widget build(BuildContext context) {
    final color = confidence >= 0.85
        ? AppColors.success
        : confidence >= 0.6
        ? AppColors.warning
        : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        'Confianza $label',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
