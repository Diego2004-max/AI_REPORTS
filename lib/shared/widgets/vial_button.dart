import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

// FIX (Fix 8): VialButton — primary action button for the Vial design system.
// Use for: form submissions, main CTAs (e.g., "Enviar reporte").
// Has two variants: filled primary (default) and outlined secondary (isSecondary: true).
// Prefer this over PrimaryButton (primary_button.dart) for standard in-app actions.
class VialButton extends StatelessWidget {
  // FIX: nullable onPressed so callers can disable the button by passing null
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
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: isSecondary
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _buildContent(context),
            )
          : FilledButton(
              onPressed: isLoading ? null : onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
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
      return SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: isSecondary ? AppColors.primary : AppColors.onPrimary,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Text(text);
  }
}
