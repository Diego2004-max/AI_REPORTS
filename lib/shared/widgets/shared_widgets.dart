import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reportes_ai/app/theme/app_colors.dart';
import 'package:reportes_ai/app/theme/app_spacing.dart';

// ══════════════════════════════════════════════════════════════════════════════
// REPORTIA — Shared Widgets v3
// Estilo: Minimal Elegant · Neumórfico suave · Sin emojis
// Tipografía: Playfair Display + DM Sans w200–300
// ══════════════════════════════════════════════════════════════════════════════

// ── FONDO BASE ────────────────────────────────────────────────────────────────
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8ECF3), Color(0xFFDFE4EE), Color(0xFFE8ECF3)],
        ),
      ),
      child: child,
    );
  }
}

// ── NEUMORPHIC PRESSABLE CARD ─────────────────────────────────────────────────
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
          color: widget.color ?? AppColors.surface,
          borderRadius: BorderRadius.circular(widget.radius),
          boxShadow: _pressed
              ? [const BoxShadow(color: Color(0x30AEB7CE), blurRadius: 6, offset: Offset(2, 2))]
              : AppShadows.card,
        ),
        child: widget.child,
      ),
    );
  }
}

// ── BRAND MARK ────────────────────────────────────────────────────────────────
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

    paint.color = Colors.white.withOpacity(0.7);
    canvas.drawRRect(RRect.fromLTRBR(2 * w, 18 * h, 9 * w, 32 * h, const Radius.circular(2)), paint);

    paint.color = Colors.white;
    canvas.drawRRect(RRect.fromLTRBR(13.5 * w, 10 * h, 20.5 * w, 32 * h, const Radius.circular(2)), paint);

    paint.color = Colors.white.withOpacity(0.7);
    canvas.drawRRect(RRect.fromLTRBR(25 * w, 2 * h, 32 * w, 32 * h, const Radius.circular(2)), paint);

    // Accent dot — único toque de color
    paint.color = AppColors.success;
    canvas.drawCircle(Offset(29 * w, 3 * h), 3.5 * w, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── REPORT STATUS ─────────────────────────────────────────────────────────────
enum ReportStatus { enviado, enRevision, atendido, rechazado }

extension ReportStatusExt on ReportStatus {
  String get label {
    switch (this) {
      case ReportStatus.enviado:    return 'Enviado';
      case ReportStatus.enRevision: return 'En revisión';
      case ReportStatus.atendido:   return 'Atendido';
      case ReportStatus.rechazado:  return 'Rechazado';
    }
  }

  Color get dotColor {
    switch (this) {
      case ReportStatus.enviado:    return AppColors.accent;
      case ReportStatus.enRevision: return AppColors.warning;
      case ReportStatus.atendido:   return AppColors.success;
      case ReportStatus.rechazado:  return AppColors.error;
    }
  }

  static ReportStatus fromString(String s) {
    final lower = s.toLowerCase();
    if (lower.contains('atendido') || lower.contains('verific')) return ReportStatus.atendido;
    if (lower.contains('rechaz') || lower.contains('error'))    return ReportStatus.rechazado;
    if (lower.contains('revisión') || lower.contains('revision') || lower.contains('pendiente')) {
      return ReportStatus.enRevision;
    }
    return ReportStatus.enviado;
  }
}

// ── STATUS BADGE — punto de color + texto silenciado ──────────────────────────
class StatusBadge extends StatelessWidget {
  final ReportStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.dotColor.withOpacity(0.08),
        borderRadius: AppRadius.borderFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: status.dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: GoogleFonts.dmSans(
              fontSize: 10, fontWeight: FontWeight.w400,
              color: status.dotColor, letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── STAT PILL ─────────────────────────────────────────────────────────────────
class StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color dotColor;

  const StatPill({
    super.key,
    required this.value,
    required this.label,
    this.dotColor = AppColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        radius: 28,
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.playfairDisplay(
                fontSize: 42, fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic, color: AppColors.text, height: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.dmSans(
                fontSize: 10, fontWeight: FontWeight.w300,
                color: AppColors.faint, letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── RESOLUTION BAR ────────────────────────────────────────────────────────────
class ResolutionBar extends StatelessWidget {
  final int total;
  final int resolved;

  const ResolutionBar({super.key, required this.total, required this.resolved});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (resolved / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Tasa de resolución',
              style: GoogleFonts.dmSans(
                fontSize: 10, fontWeight: FontWeight.w300,
                color: AppColors.faint, letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            Text(
              '${(pct * 100).round()}%',
              style: GoogleFonts.playfairDisplay(
                fontSize: 15, fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic, color: AppColors.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: AppRadius.borderFull,
          child: Container(
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFDFE4EE),
              borderRadius: AppRadius.borderFull,
              boxShadow: [
                BoxShadow(color: Color(0x50AEB7CE), blurRadius: 4, offset: Offset(2, 2)),
                BoxShadow(color: Color(0xE6FFFFFF), blurRadius: 4, offset: Offset(-2, -2)),
              ],
            ),
            child: FractionallySizedBox(
              widthFactor: pct,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.text,
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

  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.dmSans(
              fontSize: 10, fontWeight: FontWeight.w300,
              color: AppColors.faint, letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: GoogleFonts.dmSans(
                  fontSize: 10, fontWeight: FontWeight.w400,
                  color: AppColors.accent, letterSpacing: 0.2,
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

  const ReportCard({
    super.key,
    required this.title,
    this.description,
    required this.status,
    required this.date,
    this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                        style: GoogleFonts.dmSans(
                          fontSize: 15, fontWeight: FontWeight.w400,
                          color: AppColors.text, height: 1.35,
                        ),
                      ),
                      if (category != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          category!,
                          style: GoogleFonts.dmSans(
                            fontSize: 10, fontWeight: FontWeight.w300,
                            color: AppColors.faint, letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                StatusBadge(status: status),
              ],
            ),
            if (description != null) ...[
              const SizedBox(height: 10),
              Text(
                description!,
                style: GoogleFonts.dmSans(
                  fontSize: 12, fontWeight: FontWeight.w300,
                  color: AppColors.muted, height: 1.55,
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
                  style: GoogleFonts.dmSans(
                    fontSize: 10, fontWeight: FontWeight.w300,
                    color: AppColors.faint, letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward, size: 14, color: AppColors.faint),
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
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderFull,
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 18, right: 10),
            child: Icon(Icons.search, size: 16, color: AppColors.faint),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: GoogleFonts.dmSans(
                fontSize: 13, fontWeight: FontWeight.w300, color: AppColors.text,
              ),
              decoration: InputDecoration(
                hintText: hint ?? 'Buscar...',
                hintStyle: GoogleFonts.dmSans(
                  fontSize: 13, fontWeight: FontWeight.w300, color: AppColors.faint,
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
                child: const Icon(Icons.tune, size: 16, color: AppColors.faint),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.text : AppColors.surface,
          borderRadius: AppRadius.borderFull,
          boxShadow: selected
              ? [const BoxShadow(color: Color(0x401C2033), blurRadius: 14, offset: Offset(0, 4))]
              : AppShadows.soft,
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12, fontWeight: FontWeight.w300,
            color: selected ? Colors.white : AppColors.muted,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// ── PRIMARY BUTTON ────────────────────────────────────────────────────────────
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
      return SizedBox(
        height: 52,
        width: double.infinity,
        child: OutlinedButton(
          onPressed: widget.loading ? null : widget.onPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.border, width: 1),
            shape: const StadiumBorder(),
          ),
          child: widget.loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.muted),
                )
              : Text(
                  widget.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 14, fontWeight: FontWeight.w300,
                    color: AppColors.muted, letterSpacing: 0.3,
                  ),
                ),
        ),
      );
    }

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
          color: AppColors.text,
          borderRadius: AppRadius.borderFull,
          boxShadow: _pressed
              ? []
              : [const BoxShadow(color: Color(0x401C2033), blurRadius: 24, offset: Offset(0, 8))],
        ),
        child: Center(
          child: widget.loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                )
              : Text(
                  widget.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 14, fontWeight: FontWeight.w300,
                    color: Colors.white, letterSpacing: 0.6,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.dmSans(
              fontSize: 10, fontWeight: FontWeight.w300,
              color: AppColors.faint, letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.borderLg,
            boxShadow: AppShadows.soft,
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted,
            validator: validator,
            style: GoogleFonts.dmSans(
              fontSize: 13, fontWeight: FontWeight.w300, color: AppColors.text,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, size: 16, color: AppColors.faint)
                  : null,
              suffixIcon: suffix,
              errorText: errorText,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── NOTIFICATION TILE — línea lateral de color ────────────────────────────────
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
              decoration: BoxDecoration(color: color, borderRadius: AppRadius.borderFull),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.w400,
                      color: AppColors.text, letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message,
                    style: GoogleFonts.dmSans(
                      fontSize: 12, fontWeight: FontWeight.w300,
                      color: AppColors.muted, height: 1.55,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    date,
                    style: GoogleFonts.dmSans(
                      fontSize: 10, fontWeight: FontWeight.w300,
                      color: AppColors.faint, letterSpacing: 0.3,
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

// ── BOTTOM NAV — pill flotante, FAB oscuro ────────────────────────────────────
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
    _NavItem(icon: Icons.home_outlined, iconOn: Icons.home_rounded, label: 'Inicio', index: 0),
    _NavItem(icon: Icons.map_outlined, iconOn: Icons.map_rounded, label: 'Mapa', index: 1),
    _NavItem(icon: Icons.description_outlined, iconOn: Icons.description_rounded, label: 'Reportes', index: 2),
    _NavItem(icon: Icons.person_outline_rounded, iconOn: Icons.person_rounded, label: 'Perfil', index: 3),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.borderFull,
          boxShadow: AppShadows.float,
        ),
        child: Row(
          children: [
            ..._items.sublist(0, 2).map(_buildItem),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onTap: onCreate,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: AppColors.text,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0x401C2033), blurRadius: 18, offset: Offset(0, 6)),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ),
            ..._items.sublist(2).map(_buildItem),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(_NavItem item) {
    final active = currentIndex == item.index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(item.index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? item.iconOn : item.icon,
              size: 20,
              color: active ? AppColors.text : AppColors.faint,
            ),
            const SizedBox(height: 4),
            Text(
              item.label.toUpperCase(),
              style: GoogleFonts.dmSans(
                fontSize: 9,
                fontWeight: active ? FontWeight.w400 : FontWeight.w300,
                color: active ? AppColors.text : AppColors.faint,
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
  const _NavItem({required this.icon, required this.iconOn, required this.label, required this.index});
}

// ── EMPTY STATE ───────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
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
                color: AppColors.surface,
                borderRadius: AppRadius.borderXl,
                boxShadow: AppShadows.float,
              ),
              child: Icon(icon, size: 28, color: AppColors.faint),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22, fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic, color: AppColors.text, height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.dmSans(
                fontSize: 12, fontWeight: FontWeight.w300,
                color: AppColors.muted, height: 1.55,
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

  const ProfileStat({super.key, required this.value, required this.label, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22, fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic, color: valueColor ?? AppColors.text, height: 1.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.dmSans(
              fontSize: 10, fontWeight: FontWeight.w300,
              color: AppColors.faint, letterSpacing: 0.8,
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
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(color: Color(0x40AEB7CE), blurRadius: 6, offset: Offset(2, 2)),
                      BoxShadow(color: Color(0xE6FFFFFF), blurRadius: 6, offset: Offset(-2, -2)),
                    ],
                  ),
                  child: Icon(icon, size: 15, color: iconColor ?? AppColors.muted),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.w300,
                      color: labelColor ?? AppColors.text,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: (labelColor ?? AppColors.faint).withOpacity(0.5),
                ),
              ],
            ),
          ),
          if (showDivider)
            const Divider(height: 1, indent: 20, endIndent: 20, color: AppColors.border),
        ],
      ),
    );
  }
}
