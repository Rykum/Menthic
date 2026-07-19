import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_auth_service.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Contrato de autenticação: LocalAuth (fallback/testes) e
/// FirebaseAuthService (produção) implementam a mesma interface.
abstract class AuthService {
  Future<bool> isLoggedIn();
  Future<void> signIn(String email, String password);
  Future<void> signUp({
    required String email,
    required String password,
    required String confirm,
    required String phone,
  });
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<String?> currentEmail();
}

/// Auth stub LOCAL — sem backend, sem rede. Fallback quando o Firebase não
/// inicializou (testes, plataforma não configurada).
class LocalAuth implements AuthService {
  static const _kLogged = 'logged_in';
  static const _kEmail = 'user_email';

  @override
  Future<bool> isLoggedIn() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kLogged) ?? false;
  }

  @override
  Future<String?> currentEmail() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kEmail);
  }

  @override
  Future<void> signIn(String email, String password) async {
    if (!email.contains('@')) throw AuthException('E-mail inválido.');
    if (password.length < 6) {
      throw AuthException('Senha precisa de ao menos 6 caracteres.');
    }
    await _persist(email);
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String confirm,
    required String phone,
  }) async {
    if (!email.contains('@')) throw AuthException('E-mail inválido.');
    if (password.length < 6) {
      throw AuthException('Senha precisa de ao menos 6 caracteres.');
    }
    if (password != confirm) throw AuthException('As senhas não conferem.');
    await _persist(email);
  }

  @override
  Future<void> signInWithGoogle() async {
    // Stub visual: sem SDK real do Google.
    await _persist('google_user@local');
  }

  @override
  Future<void> signOut() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kLogged);
    await p.remove(_kEmail);
  }

  Future<void> _persist(String email) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kLogged, true);
    await p.setString(_kEmail, email);
  }
}

/// Firebase quando inicializado; senão o stub local (testes/fallback).
final authProvider = Provider<AuthService>(
  (ref) => Firebase.apps.isEmpty ? LocalAuth() : FirebaseAuthService(),
);
