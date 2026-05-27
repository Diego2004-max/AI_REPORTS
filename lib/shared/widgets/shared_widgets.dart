import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reportes_ai/app/theme/app_colors.dart';
import 'package:reportes_ai/app/theme/app_spacing.dart';

// ── BACKGROUND ────────────────────────────────────────────────────────────────
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [AppColors.darkBg, AppColors.darkBg2, AppColors.darkBg]
              : const [AppColors.bg, AppColors.bg2, AppColors.bg],
        ),
      ),
      child: child,
    );
  }
}

// ── PRESSABLE CARD ────────────────────────────────────────────────────────────
class AppCard extends StatefulWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg =
        widget.color ??
        (isDark ? AppColors.darkSurface : AppColors.surfaceContainerLow);
    final shadows = isDark ? AppShadows.darkCard : AppShadows.card;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(color: borderColor),
          boxShadow: _pressed ? AppShadows.darkPressed : shadows,
        ),
        child: widget.child,
      ),
    );
  }
}

// ── BRAND MARK (CustomPaint) ──────────────────────────────────────────────────
class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.text,
        borderRadius: BorderRadius.circular(size * 0.34),
        boxShadow: AppShadows.float,
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.52, size * 0.52),
          painter: _BrandPainter(),
        ),
      ),
    );
  }
}

class _BrandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width / 34;
    final h = size.height / 34;
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = Colors.white.withValues(alpha: 0.7);
    canvas.drawRRect(
      RRect.fromLTRBR(2 * w, 18 * h, 9 * w, 32 * h, const Radius.circular(2)),
      paint,
    );

    paint.color = Colors.white;
    canvas.drawRRect(
      RRect.fromLTRBR(
        13.5 * w,
        10 * h,
        20.5 * w,
        32 * h,
        const Radius.circular(2),
      ),
      paint,
    );

    paint.color = Colors.white.withValues(alpha: 0.7);
    canvas.drawRRect(
      RRect.fromLTRBR(25 * w, 2 * h, 32 * w, 32 * h, const Radius.circular(2)),
      paint,
    );

    // Accent dot — single color highlight
    paint.color = AppColors.success;
    canvas.drawCircle(Offset(29 * w, 3 * h), 3.5 * w, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── REPORT STATUS ENUM ────────────────────────────────────────────────────────
enum ReportStatus { active, atendido }

extension ReportStatusExt on ReportStatus {
  String get label {
    switch (this) {
      case ReportStatus.atendido:
        return 'Atendido';
      case ReportStatus.active:
        return 'Activo';
    }
  }

  Color get dotColor {
    switch (this) {
      case ReportStatus.atendido:
        return AppColors.success;
      case ReportStatus.active:
        return AppColors.accent;
    }
  }

  static ReportStatus fromString(String s) {
    final lower = s.toLowerCase();
    if (lower.contains('atendido') || lower.contains('verific')) {
      return ReportStatus.atendido;
    }
    return ReportStatus.active;
  }
}

// ── STATUS BADGE ──────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final ReportStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.dotColor.withValues(alpha: 0.08),
        borderRadius: AppRadius.borderFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: status.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: GoogleFonts.playfairDisplay(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: status.dotColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── STAT PILL CARD ────────────────────────────────────────────────────────────
class StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color dotColor;
  // FIX: onTap enables navigation from stat pills to a filtered report list
  final VoidCallback? onTap;

  const StatPill({
    super.key,
    required this.value,
    required this.label,
    this.dotColor = AppColors.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.text;
    final mutedColor = isDark ? AppColors.darkTextSecondary : AppColors.faint;

    return Expanded(
      child: AppCard(
        radius: 28,
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.playfairDisplay(
                fontSize: 42,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                color: textColor,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.playfairDisplay(
                fontSize: 10,
                fontWeight: FontWeight.w300,
                color: mutedColor,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── RESOLUTION PROGRESS BAR ───────────────────────────────────────────────────
class ResolutionBar extends StatelessWidget {
  final int total;
  final int resolved;

  const ResolutionBar({super.key, required this.total, required this.resolved});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (resolved / total).clamp(0.0, 1.0) : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppColors.darkTextDisabled : AppColors.faint;
    final percentColor = isDark ? AppColors.darkTextPrimary : AppColors.text;
    final trackColor = isDark ? AppColors.darkSurfaceVariant : AppColors.bg2;
    final fillColor = isDark ? AppColors.darkTextPrimary : AppColors.text;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Tasa de resolución',
              style: GoogleFonts.playfairDisplay(
                fontSize: 10,
                fontWeight: FontWeight.w300,
                color: labelColor,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            Text(
              '${(pct * 100).round()}%',
              style: GoogleFonts.playfairDisplay(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                color: percentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: AppRadius.borderFull,
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: trackColor,
              borderRadius: AppRadius.borderFull,
              boxShadow: isDark
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x50AEB7CE),
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                      BoxShadow(
                        color: Color(0xE6FFFFFF),
                        blurRadius: 4,
                        offset: Offset(-2, -2),
                      ),
                    ],
            ),
            child: FractionallySizedBox(
              widthFactor: pct,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: AppRadius.borderFull,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── SECTION HEADER ────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.darkTextSecondary : AppColors.faint;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.playfairDisplay(
              fontSize: 10,
              fontWeight: FontWeight.w300,
              color: mutedColor,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: AppColors.accent,
                  letterSpacing: 0.2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── REPORT CARD ───────────────────────────────────────────────────────────────
class ReportCard extends StatelessWidget {
  final String title;
  final String? description;
  final ReportStatus status;
  final String date;
  final String? category;
  final VoidCallback? onTap;
  final String? heroTag;

  const ReportCard({
    super.key,
    required this.title,
    this.description,
    required this.status,
    required this.date,
    this.category,
    this.onTap,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.text;
    final mutedColor = isDark ? AppColors.darkTextSecondary : AppColors.muted;
    final faintColor = isDark ? AppColors.darkTextDisabled : AppColors.faint;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        radius: 24,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: textColor,
                          height: 1.35,
                        ),
                      ),
                      if (category != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          category!,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 10,
                            fontWeight: FontWeight.w300,
                            color: faintColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (description != null) ...[
              const SizedBox(height: 10),
              Text(
                description!,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: mutedColor,
                  height: 1.55,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  date,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 10,
                    fontWeight: FontWeight.w300,
                    color: faintColor,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward, size: 14, color: faintColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── SEARCH BAR ────────────────────────────────────────────────────────────────
class AppSearchBar extends StatelessWidget {
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilter;

  const AppSearchBar({
    super.key,
    this.hint,
    this.controller,
    this.onChanged,
    this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.text;
    final hintColor = isDark ? AppColors.darkTextDisabled : AppColors.faint;
    final iconColor = isDark ? AppColors.darkTextSecondary : AppColors.faint;
    final shadows = isDark ? AppShadows.darkCard : AppShadows.soft;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.borderFull,
        boxShadow: shadows,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 18, right: 10),
            child: Icon(Icons.search, size: 16, color: iconColor),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: GoogleFonts.playfairDisplay(
                fontSize: 13,
                fontWeight: FontWeight.w300,
                color: textColor,
              ),
              decoration: InputDecoration(
                hintText: hint ?? 'Buscar...',
                hintStyle: GoogleFonts.playfairDisplay(
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  color: hintColor,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (onFilter != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: onFilter,
                child: Icon(Icons.tune, size: 16, color: iconColor),
              ),
            ),
        ],
      ),
    );
  }
}

// ── FILTER CHIP ───────────────────────────────────────────────────────────────
class AppFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBg = isDark ? AppColors.darkTextPrimary : AppColors.text;
    final unselectedBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final selectedFg = isDark ? AppColors.darkBg : Colors.white;
    final unselectedFg = isDark ? AppColors.darkTextSecondary : AppColors.muted;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? selectedBg : unselectedBg,
          borderRadius: AppRadius.borderFull,
          boxShadow: selected
              ? AppShadows.darkPressed
              : (isDark ? AppShadows.darkCard : AppShadows.soft),
        ),
        child: Text(
          label,
          style: GoogleFonts.playfairDisplay(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: selected ? selectedFg : unselectedFg,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// ── PRIMARY BUTTON ────────────────────────────────────────────────────────────
// FIX (Fix 8): PrimaryButton in shared_widgets — ghost/outlined variant for secondary or destructive actions.
// Use ghost: true for secondary/destructive actions (e.g., "Cancelar", "Eliminar").
// Use ghost: false for neumorphic-styled primary actions within the AppBackground design context.
// Prefer VialButton (vial_button.dart) for standard form CTAs outside this design context.
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool ghost;
  final bool loading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.ghost = false,
    this.loading = false,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.ghost) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final fg = isDark ? AppColors.primaryLight : AppColors.primary;
      final border = isDark ? AppColors.primaryLight : AppColors.primary;
      final bg = isDark ? AppColors.darkSurfaceVariant : Colors.transparent;
      return SizedBox(
        height: 52,
        width: double.infinity,
        child: OutlinedButton(
          onPressed: widget.loading ? null : widget.onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            side: BorderSide(color: border, width: 1.2),
            shape: const StadiumBorder(),
          ),
          child: widget.loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: fg),
                )
              : Text(
                  widget.label,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: fg,
                    letterSpacing: 0,
                  ),
                ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btnBg = isDark ? AppColors.primaryLight : AppColors.primary;
    final btnFg = AppColors.onPrimary;
    final btnShadow = isDark ? AppShadows.darkCard : AppShadows.float;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          color: btnBg,
          borderRadius: AppRadius.borderFull,
          boxShadow: _pressed ? [] : btnShadow,
        ),
        child: Center(
          child: widget.loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: btnFg,
                  ),
                )
              : Text(
                  widget.label,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: btnFg,
                    letterSpacing: 0,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── TEXT FIELD ────────────────────────────────────────────────────────────────
class AppTextField extends StatelessWidget {
  final String label;
  final String? placeholder;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? errorText;
  final Widget? suffix;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  const AppTextField({
    super.key,
    required this.label,
    this.placeholder,
    this.controller,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.errorText,
    this.suffix,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurfaceVariant : AppColors.surface;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.text;
    final labelColor = isDark ? AppColors.darkTextSecondary : AppColors.muted;
    final iconColor = isDark ? AppColors.darkTextSecondary : AppColors.muted;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.playfairDisplay(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: labelColor,
              letterSpacing: 0,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppRadius.borderLg,
            border: Border.all(color: borderColor),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted,
            validator: validator,
            style: GoogleFonts.playfairDisplay(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: textColor,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, size: 16, color: iconColor)
                  : null,
              suffixIcon: suffix,
              errorText: errorText,
              hintStyle: GoogleFonts.playfairDisplay(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── NOTIFICATION TILE ─────────────────────────────────────────────────────────
class NotifTile extends StatelessWidget {
  final String title;
  final String message;
  final String date;
  final ReportStatus? status;
  final Color? lineColor;

  const NotifTile({
    super.key,
    required this.title,
    required this.message,
    required this.date,
    this.status,
    this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = lineColor ?? status?.dotColor ?? AppColors.accent;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.darkTextPrimary : AppColors.text;
    final bodyColor = isDark ? AppColors.darkTextSecondary : AppColors.muted;
    final dateColor = isDark ? AppColors.darkTextDisabled : AppColors.faint;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        radius: 22,
        padding: const EdgeInsets.fromLTRB(0, 16, 18, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3,
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppRadius.borderFull,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: titleColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: bodyColor,
                      height: 1.55,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    date,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 10,
                      fontWeight: FontWeight.w300,
                      color: dateColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── USER AVATAR ───────────────────────────────────────────────────────────────
class UserAvatar extends StatelessWidget {
  final String? initials;
  final double size;
  final String? imageUrl;

  const UserAvatar({super.key, this.initials, this.size = 38, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.text,
        shape: BoxShape.circle,
        boxShadow: AppShadows.soft,
        image: imageUrl != null
            ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: imageUrl == null
          ? Center(
              child: Text(
                initials ?? '?',
                style: GoogleFonts.playfairDisplay(
                  fontSize: size * 0.36,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }
}

// ── BOTTOM NAVIGATION BAR ─────────────────────────────────────────────────────
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCreate;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onCreate,
  });

  static const _items = [
    _NavItem(
      icon: Icons.home_outlined,
      iconOn: Icons.home_rounded,
      label: 'Inicio',
      index: 0,
    ),
    _NavItem(
      icon: Icons.map_outlined,
      iconOn: Icons.map_rounded,
      label: 'Mapa',
      index: 1,
    ),
    _NavItem(
      icon: Icons.description_outlined,
      iconOn: Icons.description_rounded,
      label: 'Reportes',
      index: 2,
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      iconOn: Icons.person_rounded,
      label: 'Perfil',
      index: 3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final fabBg = isDark ? AppColors.darkTextPrimary : AppColors.text;
    final fabFg = isDark ? AppColors.darkBg : Colors.white;
    final navShadows = isDark ? AppShadows.darkFloat : AppShadows.float;
    final fabShadows = isDark ? AppShadows.darkCard : AppShadows.accentGlow;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: navBg,
          borderRadius: AppRadius.borderFull,
          boxShadow: navShadows,
        ),
        child: Row(
          children: [
            ..._items.sublist(0, 2).map((item) => _buildItem(context, item)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onTap: onCreate,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: fabBg,
                    shape: BoxShape.circle,
                    boxShadow: fabShadows,
                  ),
                  child: Icon(Icons.add, color: fabFg, size: 20),
                ),
              ),
            ),
            ..._items.sublist(2).map((item) => _buildItem(context, item)),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, _NavItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = currentIndex == item.index;
    final activeColor = isDark ? AppColors.darkTextPrimary : AppColors.text;
    final inactiveColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.faint;
    final itemColor = active ? activeColor : inactiveColor;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(item.index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? item.iconOn : item.icon, size: 20, color: itemColor),
            const SizedBox(height: 4),
            Text(
              item.label.toUpperCase(),
              style: GoogleFonts.playfairDisplay(
                fontSize: 9,
                fontWeight: active ? FontWeight.w400 : FontWeight.w300,
                color: itemColor,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData iconOn;
  final String label;
  final int index;
  const _NavItem({
    required this.icon,
    required this.iconOn,
    required this.label,
    required this.index,
  });
}

// ── EMPTY STATE ───────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final iconColor = isDark ? AppColors.darkTextSecondary : AppColors.faint;
    final titleColor = isDark ? AppColors.darkTextPrimary : AppColors.text;
    final subtitleColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.muted;
    final shadows = isDark ? AppShadows.darkFloat : AppShadows.float;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: AppRadius.borderXl,
                boxShadow: shadows,
              ),
              child: Icon(icon, size: 28, color: iconColor),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                color: titleColor,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.playfairDisplay(
                fontSize: 12,
                fontWeight: FontWeight.w300,
                color: subtitleColor,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── PROFILE STAT ──────────────────────────────────────────────────────────────
class ProfileStat extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const ProfileStat({
    super.key,
    required this.value,
    required this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultValueColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.text;
    final labelColor = isDark ? AppColors.darkTextDisabled : AppColors.faint;

    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              color: valueColor ?? defaultValueColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.playfairDisplay(
              fontSize: 10,
              fontWeight: FontWeight.w300,
              color: labelColor,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ── MENU ITEM ─────────────────────────────────────────────────────────────────
class MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? labelColor;
  final bool showDivider;

  const MenuItem({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.iconColor,
    this.labelColor,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = isDark ? AppColors.darkSurfaceVariant : AppColors.bg;
    final textColor =
        labelColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.text);
    final arrowColor =
        (labelColor ?? (isDark ? AppColors.darkTextSecondary : AppColors.faint))
            .withAlpha(128);
    final dividerColor = isDark ? AppColors.darkBorder : AppColors.border;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isDark
                        ? null
                        : const [
                            BoxShadow(
                              color: Color(0x40AEB7CE),
                              blurRadius: 6,
                              offset: Offset(2, 2),
                            ),
                            BoxShadow(
                              color: Color(0xE6FFFFFF),
                              blurRadius: 6,
                              offset: Offset(-2, -2),
                            ),
                          ],
                  ),
                  child: Icon(
                    icon,
                    size: 15,
                    color: iconColor ?? AppColors.muted,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      color: textColor,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 12, color: arrowColor),
              ],
            ),
          ),
          if (showDivider)
            Divider(height: 1, indent: 20, endIndent: 20, color: dividerColor),
        ],
      ),
    );
  }
}
