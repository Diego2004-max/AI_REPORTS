import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:reportes_ai/app/theme/app_colors.dart';
import 'package:reportes_ai/shared/widgets/custom_app_bar.dart';
import 'package:reportes_ai/shared/widgets/shared_widgets.dart';
import 'package:reportes_ai/state/theme_provider.dart';

class ThemeScreen extends ConsumerWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.bg,
      appBar: const CustomAppBar(
        title: 'Apariencia',
        subtitle: 'Elige el tema de la app',
        showBack: true,
      ),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
          children: [
            _ThemeOption(
              mode: ThemeMode.system,
              current: current,
              title: 'Sistema',
              subtitle: 'Sigue la configuración del dispositivo',
              icon: Icons.brightness_auto_rounded,
              onTap: () => ref.read(themeProvider.notifier).setThemeMode(ThemeMode.system),
            ),
            const SizedBox(height: 12),
            _ThemeOption(
              mode: ThemeMode.light,
              current: current,
              title: 'Claro',
              subtitle: 'Interfaz con fondo blanco/gris suave',
              icon: Icons.light_mode_rounded,
              onTap: () => ref.read(themeProvider.notifier).setThemeMode(ThemeMode.light),
            ),
            const SizedBox(height: 12),
            _ThemeOption(
              mode: ThemeMode.dark,
              current: current,
              title: 'Oscuro',
              subtitle: 'Interfaz con fondo azul oscuro',
              icon: Icons.dark_mode_rounded,
              onTap: () => ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark),
            ),
            const SizedBox(height: 32),
            _PreviewCard(isDark: isDark),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final ThemeMode mode;
  final ThemeMode current;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.mode,
    required this.current,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = current == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.text;
    final mutedColor = isDark ? AppColors.darkTextSecondary : AppColors.muted;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: isDark
              ? [const BoxShadow(color: Color(0x28000000), blurRadius: 10, offset: Offset(0, 3))]
              : [
                  const BoxShadow(color: Color(0x8CAEB7CE), blurRadius: 14, offset: Offset(5, 5)),
                  const BoxShadow(color: Color(0xE6FFFFFF), blurRadius: 14, offset: Offset(-5, -5)),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.accent.withAlpha(25)
                    : (isDark ? AppColors.darkSurfaceVariant : AppColors.bg),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected ? AppColors.accent : AppColors.muted,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? AppColors.accent : textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w300,
                      color: mutedColor,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.accent : (isDark ? AppColors.darkBorder : AppColors.border),
                  width: 1.5,
                ),
                color: selected ? AppColors.accent : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final bool isDark;
  const _PreviewCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.text;
    final mutedColor = isDark ? AppColors.darkTextSecondary : AppColors.muted;

    return AppCard(
      radius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.accent, shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'VISTA PREVIA',
                style: GoogleFonts.dmSans(
                  fontSize: 10, fontWeight: FontWeight.w300,
                  color: mutedColor, letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isDark ? 'Modo oscuro activo' : 'Modo claro activo',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18, fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic, color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'El cambio se aplica inmediatamente y se guarda para tu próxima sesión.',
            style: GoogleFonts.dmSans(
              fontSize: 12, fontWeight: FontWeight.w300,
              color: mutedColor, height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
