import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Full-width elevated button with loading-state support.
/// Use this instead of raw [ElevatedButton] everywhere in the app.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.height,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor =
        backgroundColor ??
        (isDark ? AppColors.primaryLight : AppColors.primary);
    final fgColor = foregroundColor ?? AppColors.textOnPrimary;
    final disabledBg = isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.surfaceContainerHigh;
    final disabledFg = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return SizedBox(
      width: double.infinity,
      height: height ?? 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isLoading ? bgColor.withAlpha(180) : bgColor,
          foregroundColor: fgColor,
          disabledBackgroundColor: isLoading
              ? bgColor.withAlpha(180)
              : disabledBg,
          disabledForegroundColor: isLoading
              ? fgColor.withAlpha(180)
              : disabledFg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: fgColor,
                ),
              )
            : icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon!,
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: fgColor,
                      fontSize: 15,
                    ),
                  ),
                ],
              )
            : Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: fgColor,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }
}

/// Secondary outlined variant of [PrimaryButton].
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fgColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.primary;
    final disabledFg = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return SizedBox(
      width: double.infinity,
      height: height ?? 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: fgColor,
          disabledForegroundColor: disabledFg,
          backgroundColor: isDark ? AppColors.darkSurfaceVariant : null,
          side: BorderSide(color: borderColor, width: 1.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
              )
            : icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon!,
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: fgColor,
                      fontSize: 15,
                    ),
                  ),
                ],
              )
            : Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: fgColor,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }
}
