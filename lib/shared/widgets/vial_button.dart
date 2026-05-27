import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class VialButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isSecondary;
  final Widget? icon;
  final bool isLoading;

  const VialButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isSecondary = false,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final enabled = onPressed != null && !isLoading;
    final disabledBg = isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.surfaceContainerHigh;
    final disabledFg = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final primaryBg = isDark ? AppColors.primaryLight : AppColors.primary;
    final primaryFg = AppColors.onPrimary;
    final secondaryBorder = isDark ? AppColors.darkBorder : AppColors.border;
    final secondaryFg = enabled
        ? (isDark ? AppColors.darkTextPrimary : AppColors.primary)
        : disabledFg;

    return SizedBox(
      height: 52,
      width: double.infinity,
      child: isSecondary
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: secondaryFg,
                disabledForegroundColor: disabledFg,
                side: BorderSide(
                  color: enabled
                      ? secondaryBorder
                      : secondaryBorder.withAlpha(90),
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _buildContent(context),
            )
          : FilledButton(
              onPressed: isLoading ? null : onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: primaryBg,
                foregroundColor: primaryFg,
                disabledBackgroundColor: disabledBg,
                disabledForegroundColor: disabledFg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _buildContent(context),
            ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: isSecondary
              ? (isDark ? AppColors.primaryLight : AppColors.primary)
              : AppColors.onPrimary,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [icon!, const SizedBox(width: 8), Text(text)],
      );
    }

    return Text(text);
  }
}
