import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:reportes_ai/data/models/user_model.dart';

class AuthRepositoryImpl {
  final SupabaseClient _client = Supabase.instance.client;

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    try {
      final response = await _client.auth.signUp(
        email: normalizedEmail,
        password: password,
      );

      final authUser = response.user;
      if (authUser == null) {
        throw Exception('No se pudo registrar el usuario');
      }

      await _client.from('profiles').upsert({
        'id': authUser.id,
        'full_name': fullName.trim(),
        'email': normalizedEmail,
      });

      return UserModel(
        id: authUser.id,
        fullName: fullName.trim(),
        email: normalizedEmail,
        password: '',
        createdAt: DateTime.now(),
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('No se pudo registrar el usuario');
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    try {
      final response = await _client.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );

      final authUser = response.user;
      if (authUser == null) {
        throw Exception('Correo o contraseña incorrectos');
      }

      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', authUser.id)
          .single();

      return UserModel(
        id: authUser.id,
        fullName: profile['full_name'] as String,
        email: profile['email'] as String,
        password: '',
        createdAt: DateTime.parse(profile['created_at'] as String),
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Correo o contraseña incorrectos');
    }
  }

  Future<UserModel?> getUserById(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;

    return UserModel(
      id: data['id'] as String,
      fullName: data['full_name'] as String,
      email: data['email'] as String,
      password: '',
      createdAt: DateTime.parse(data['created_at'] as String),
    );
  }

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.example.reportesai://login-callback',
    );
  }

  Future<UserModel> updateUserName({
    required String userId,
    required String newName,
  }) async {
    await _client
        .from('profiles')
        .update({'full_name': newName.trim()})
        .eq('id', userId);

    final updated = await getUserById(userId);
    if (updated == null) {
      throw Exception('Usuario no encontrado');
    }

    return updated;
  }
}