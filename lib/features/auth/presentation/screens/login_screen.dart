import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:reportes_ai/app/router/app_router.dart';
import 'package:reportes_ai/app/theme/app_colors.dart';
import 'package:reportes_ai/shared/widgets/shared_widgets.dart';
import 'package:reportes_ai/state/auth_provider.dart';
import 'package:reportes_ai/state/session_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final user = await ref.read(authRepositoryProvider).login(
            email: _emailCtrl.text,
            password: _passwordCtrl.text,
          );
      await ref.read(sessionProvider.notifier).saveLocalSession(
            userId: user.id,
            email: user.email,
            userName: user.fullName,
          );
      if (!mounted) return;
      context.go(AppRoutes.app);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 56),
                  const Center(child: BrandMark(size: 64)),
                  const SizedBox(height: 28),
                  Text(
                    'Bienvenido',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 30,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inicia sesión en tu cuenta',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      color: AppColors.muted,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),
                  AppTextField(
                    label: 'Correo electrónico',
                    placeholder: 'usuario@ejemplo.com',
                    controller: _emailCtrl,
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Ingresa tu correo';
                      final emailReg = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w]{2,4}$');
                      if (!emailReg.hasMatch(value)) return 'Correo no válido';
                      return null;
                    },
                  ),
                  AppTextField(
                    label: 'Contraseña',
                    placeholder: '••••••••',
                    controller: _passwordCtrl,
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _onLogin(),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
                      if (value.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: GestureDetector(
                        onTap: () {},
                        child: Text(
                          '¿Olvidaste tu contraseña?',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            color: AppColors.faint,
                          ),
                        ),
                      ),
                    ),
                  ),
                  PrimaryButton(
                    label: 'Iniciar sesión',
                    onPressed: _onLogin,
                    loading: _isLoading,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Container(height: 1, color: AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'o',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            color: AppColors.faint,
                          ),
                        ),
                      ),
                      Expanded(child: Container(height: 1, color: AppColors.border)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    ghost: true,
                    label: 'Continuar con Google',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Google Sign-In próximamente.')),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿No tienes una cuenta? ',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          color: AppColors.muted,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.register),
                        child: Text(
                          'Regístrate',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
