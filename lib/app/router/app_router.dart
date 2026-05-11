import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:reportes_ai/features/auth/presentation/screens/login_screen.dart';
import 'package:reportes_ai/features/auth/presentation/screens/register_screen.dart';
import 'package:reportes_ai/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:reportes_ai/features/shell/presentation/screens/main_screen.dart';
import 'package:reportes_ai/state/session_provider.dart';

abstract final class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String app = '/app';
  // FIX: named route for notifications screen (Fix 9)
  static const String notifications = '/notifications';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionProvider);
  final isAuthenticated = session.isAuthenticated;

  return GoRouter(
    initialLocation: AppRoutes.login,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.app,
        name: 'app',
        builder: (context, state) => const MainScreen(),
      ),
      // FIX: notifications is now a named route navigable via context.push (Fix 9)
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthRoute =
          location == AppRoutes.login || location == AppRoutes.register;

      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }

      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.app;
      }

      return null;
    },
  );
});