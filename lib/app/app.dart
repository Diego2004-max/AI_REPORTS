import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:reportes_ai/app/router/app_router.dart';
import 'package:reportes_ai/app/theme/app_theme.dart';
import 'package:reportes_ai/state/session_provider.dart';
import 'package:reportes_ai/state/theme_provider.dart';

class AiReportsApp extends ConsumerStatefulWidget {
  const AiReportsApp({super.key});

  @override
  ConsumerState<AiReportsApp> createState() => _AiReportsAppState();
}

class _AiReportsAppState extends ConsumerState<AiReportsApp> {
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(
      _handleAuthStateChange,
    );
  }

  Future<void> _handleAuthStateChange(AuthState data) async {
    if (data.event != AuthChangeEvent.signedIn) return;
    final session = data.session;
    if (session == null) return;

    // Only process when local session is not yet set (OAuth flow)
    if (ref.read(sessionProvider).isAuthenticated) return;

    final user = session.user;
    final email = user.email ?? '';
    final fullName = (user.userMetadata?['full_name'] as String?) ??
        (user.userMetadata?['name'] as String?) ??
        email.split('@').first;

    try {
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'full_name': fullName,
        'email': email,
      });
    } catch (_) {}

    await ref.read(sessionProvider.notifier).saveLocalSession(
          userId: user.id,
          email: email,
          userName: fullName,
        );
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Reportes AI',
      routerConfig: router,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
    );
  }
}
