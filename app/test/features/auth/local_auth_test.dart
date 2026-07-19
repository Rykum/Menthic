import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menthic/features/auth/local_auth.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('estado inicial: não logado', () async {
    expect(await LocalAuth().isLoggedIn(), false);
  });

  test('signIn válido loga e guarda email', () async {
    final auth = LocalAuth();
    await auth.signIn('a@b.com', 'segredo');
    expect(await auth.isLoggedIn(), true);
    expect(await auth.currentEmail(), 'a@b.com');
  });

  test('signIn com senha curta lança AuthException', () async {
    expect(
      () => LocalAuth().signIn('a@b.com', '123'),
      throwsA(isA<AuthException>()),
    );
  });

  test('signUp com confirmação divergente lança AuthException', () async {
    expect(
      () => LocalAuth().signUp(
        email: 'a@b.com',
        password: 'segredo',
        confirm: 'outra',
        phone: '11999',
      ),
      throwsA(isA<AuthException>()),
    );
  });

  test('signUp válido loga', () async {
    final auth = LocalAuth();
    await auth.signUp(
      email: 'a@b.com',
      password: 'segredo',
      confirm: 'segredo',
      phone: '11999',
    );
    expect(await auth.isLoggedIn(), true);
  });

  test('signOut desloga', () async {
    final auth = LocalAuth();
    await auth.signIn('a@b.com', 'segredo');
    await auth.signOut();
    expect(await auth.isLoggedIn(), false);
  });
}
