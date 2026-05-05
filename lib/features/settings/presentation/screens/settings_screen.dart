import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:reportes_ai/app/router/app_router.dart';
import 'package:reportes_ai/app/theme/app_colors.dart';
import 'package:reportes_ai/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:reportes_ai/features/settings/presentation/screens/theme_screen.dart';
import 'package:reportes_ai/shared/widgets/custom_app_bar.dart';
import 'package:reportes_ai/shared/widgets/shared_widgets.dart';
import 'package:reportes_ai/state/session_provider.dart';
import 'package:reportes_ai/state/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final themeModeLabel = switch (themeMode) {
      ThemeMode.light => 'Claro',
      ThemeMode.dark => 'Oscuro',
      ThemeMode.system => 'Sistema',
    };

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.bg,
      appBar: const CustomAppBar(
        title: 'Ajustes',
        showBack: true,
      ),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
          children: [
            _SettingsSection(
              title: 'Cuenta',
              children: [
                MenuItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Mi información',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  ),
                ),
                MenuItem(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notificaciones',
                  onTap: () {},
                ),
                MenuItem(
                  icon: Icons.shield_outlined,
                  label: 'Privacidad',
                  showDivider: false,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SettingsSection(
              title: 'Apariencia',
              children: [
                _ThemeMenuItem(
                  currentLabel: themeModeLabel,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ThemeScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SettingsSection(
              title: 'App',
              children: [
                MenuItem(
                  icon: Icons.info_outline_rounded,
                  label: 'Acerca de Reportes AI',
                  onTap: () => _showAbout(context),
                ),
                MenuItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Ayuda y soporte',
                  showDivider: false,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 32),
            AppCard(
              radius: 16,
              padding: EdgeInsets.zero,
              child: MenuItem(
                icon: Icons.logout_rounded,
                label: 'Cerrar sesión',
                iconColor: AppColors.error,
                labelColor: AppColors.error,
                showDivider: false,
                onTap: () async {
                  await ref.read(sessionProvider.notifier).clearSession();
                  if (context.mounted) context.go(AppRoutes.login);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reportes AI'),
        content: const Text(
          'v1.0.0\n\nApp ciudadana de reportes viales para Pasto, Colombia.\nPowered by IA + Supabase.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.darkTextSecondary : AppColors.faint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w300,
              color: mutedColor,
              letterSpacing: 0.8,
            ),
          ),
        ),
        AppCard(
          radius: 16,
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ThemeMenuItem extends StatelessWidget {
  final String currentLabel;
  final VoidCallback onTap;

  const _ThemeMenuItem({required this.currentLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = isDark ? AppColors.darkSurfaceVariant : AppColors.bg;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.text;
    final mutedColor = isDark ? AppColors.darkTextSecondary : AppColors.muted;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.palette_outlined, size: 15, color: AppColors.muted),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Tema',
                style: GoogleFonts.dmSans(
                  fontSize: 13, fontWeight: FontWeight.w300, color: textColor,
                ),
              ),
            ),
            Text(
              currentLabel,
              style: GoogleFonts.dmSans(
                fontSize: 12, fontWeight: FontWeight.w400, color: mutedColor,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_ios, size: 12, color: mutedColor.withAlpha(128)),
          ],
        ),
      ),
    );
  }
}
