import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Auth stub LOCAL — sem backend, sem rede. Portão local até existir servidor.
/// Não é um sistema de segurança: não valida credenciais contra nada.
class LocalAuth {
  static const _kLogged = 'logged_in';
  static const _kEmail = 'user_email';

  Future<bool> isLoggedIn() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kLogged) ?? false;
  }

  Future<String?> currentEmail() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kEmail);
  }

  Future<void> signIn(String email, String password) async {
    if (!email.contains('@')) throw AuthException('E-mail inválido.');
    if (password.length < 6) {
      throw AuthException('Senha precisa de ao menos 6 caracteres.');
    }
    await _persist(email);
  }

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

  Future<void> signInWithGoogle() async {
    // Stub visual: sem SDK real do Google.
    await _persist('google_user@local');
  }

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

final localAuthProvider = Provider<LocalAuth>((ref) => LocalAuth());
