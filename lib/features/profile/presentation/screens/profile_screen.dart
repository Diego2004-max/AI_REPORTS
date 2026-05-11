import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:reportes_ai/app/router/app_router.dart';
import 'package:reportes_ai/app/theme/app_colors.dart';
import 'package:reportes_ai/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:reportes_ai/features/settings/presentation/screens/settings_screen.dart';
import 'package:reportes_ai/features/settings/presentation/screens/theme_screen.dart';
import 'package:reportes_ai/shared/widgets/shared_widgets.dart';
import 'package:reportes_ai/state/report_provider.dart';
import 'package:reportes_ai/state/session_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final statsAsync = ref.watch(userReportStatsProvider);
    final initials = (session.userName?.isNotEmpty ?? false)
        ? session.userName!.substring(0, 1).toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            children: [
              const SizedBox(height: 32),
              Center(child: UserAvatar(initials: initials, size: 72)),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  session.userName ?? 'Usuario',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  session.email ?? 'Sin correo',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    color: AppColors.muted,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              statsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (stats) => AppCard(
                  radius: 24,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    children: [
                      ProfileStat(value: '${stats.total}', label: 'Total'),
                      ProfileStat(value: '${stats.attended}', label: 'Atendidos'),
                      ProfileStat(value: '${stats.reviewing}', label: 'Revisión'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AppCard(
                radius: 24,
                padding: EdgeInsets.zero,
                child: Column(
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
                      // FIX: use named Go Router route instead of raw MaterialPageRoute
                      onTap: () => context.push(AppRoutes.notifications),
                    ),
                    MenuItem(
                      icon: Icons.palette_outlined,
                      label: 'Apariencia',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ThemeScreen()),
                      ),
                    ),
                    MenuItem(
                      icon: Icons.settings_outlined,
                      label: 'Ajustes',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ),
                    ),
                    MenuItem(
                      icon: Icons.logout_rounded,
                      label: 'Cerrar sesión',
                      iconColor: AppColors.error,
                      labelColor: AppColors.error,
                      showDivider: false,
                      // FIX: show confirmation dialog before executing destructive logout action
                      onTap: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Cerrar sesión'),
                            content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Cerrar sesión'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await ref.read(sessionProvider.notifier).clearSession();
                          if (context.mounted) context.go(AppRoutes.login);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
