import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:menthic/features/auth/firebase_auth_service.dart';
import 'package:menthic/features/auth/local_auth.dart';

void main() {
  test('signUp válido loga e expõe o email', () async {
    final auth = FirebaseAuthService(MockFirebaseAuth());
    await auth.signUp(
      email: 'a@b.com',
      password: 'segredo',
      confirm: 'segredo',
      phone: '11999',
    );
    expect(await auth.isLoggedIn(), true);
    expect(await auth.currentEmail(), 'a@b.com');
  });

  test('validações locais: senha curta e confirmação divergente', () async {
    final auth = FirebaseAuthService(MockFirebaseAuth());
    expect(() => auth.signIn('a@b.com', '123'), throwsA(isA<AuthException>()));
    expect(
      () => auth.signUp(
        email: 'a@b.com',
        password: 'segredo',
        confirm: 'outra',
        phone: '11999',
      ),
      throwsA(isA<AuthException>()),
    );
  });

  test('signOut desloga', () async {
    final mock = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(email: 'a@b.com'),
    );
    final auth = FirebaseAuthService(mock);
    expect(await auth.isLoggedIn(), true);
    await auth.signOut();
    expect(await auth.isLoggedIn(), false);
  });

  test('signInWithGoogle ainda não disponível → AuthException', () {
    final auth = FirebaseAuthService(MockFirebaseAuth());
    expect(() => auth.signInWithGoogle(), throwsA(isA<AuthException>()));
  });
}
