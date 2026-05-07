import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

// FIX (Fix 8): PrimaryButton (primary_button.dart) — elevated button with customizable colors.
// Use for: special-case CTAs that require a custom backgroundColor or foregroundColor
// (e.g., themed onboarding flows, branded partner screens).
// For standard app actions use VialButton (vial_button.dart) instead.
// TODO: confirmar con diseño — evaluate whether this and VialButton can be consolidated.

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
    final bgColor = backgroundColor ?? AppColors.primary;
    final fgColor = foregroundColor ?? AppColors.textOnPrimary;

    return SizedBox(
      width: double.infinity,
      height: height ?? 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isLoading ? bgColor.withAlpha(180) : bgColor,
          foregroundColor: fgColor,
          disabledBackgroundColor: bgColor.withAlpha(180),
          disabledForegroundColor: fgColor.withAlpha(180),
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

    return SizedBox(
      width: double.infinity,
      height: height ?? 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
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
                          color: AppColors.primary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  )
                : Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontSize: 15,
                    ),
                  ),
      ),
    );
  }
}
