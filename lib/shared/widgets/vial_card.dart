import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class VialCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final double borderRadius;

  const VialCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.borderRadius = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkSurface : AppColors.surfaceContainerLowest;
    final shadowColor = isDark ? Colors.black26 : AppColors.shadow;

    final cardContent = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 40,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
