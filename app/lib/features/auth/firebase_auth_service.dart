import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'local_auth.dart';

/// Autenticação real (Firebase Auth, e-mail/senha). Erros do Firebase são
/// traduzidos para AuthException em pt-BR — as telas não conhecem o Firebase.
class FirebaseAuthService implements AuthService {
  final fb.FirebaseAuth _auth;
  FirebaseAuthService([fb.FirebaseAuth? auth])
    : _auth = auth ?? fb.FirebaseAuth.instance;

  @override
  Future<bool> isLoggedIn() async => _auth.currentUser != null;

  @override
  Future<String?> currentEmail() async => _auth.currentUser?.email;

  Never _mapError(fb.FirebaseAuthException e) {
    final msg = switch (e.code) {
      'invalid-email' => 'E-mail inválido.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'E-mail ou senha incorretos.',
      'email-already-in-use' => 'Este e-mail já tem conta — use Entrar.',
      'weak-password' => 'Senha precisa de ao menos 6 caracteres.',
      'network-request-failed' => 'Sem conexão — tente de novo.',
      _ => 'Falha de autenticação (${e.code}).',
    };
    throw AuthException(msg);
  }

  void _validate(String email, String password) {
    if (!email.contains('@')) throw AuthException('E-mail inválido.');
    if (password.length < 6) {
      throw AuthException('Senha precisa de ao menos 6 caracteres.');
    }
  }

  @override
  Future<void> signIn(String email, String password) async {
    _validate(email, password);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on fb.FirebaseAuthException catch (e) {
      _mapError(e);
    }
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String confirm,
    required String phone,
  }) async {
    _validate(email, password);
    if (password != confirm) throw AuthException('As senhas não conferem.');
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on fb.FirebaseAuthException catch (e) {
      _mapError(e);
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    throw AuthException('Entrar com Google ainda não está disponível.');
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
