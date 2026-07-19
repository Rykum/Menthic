import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menthic/features/auth/cadastro_screen.dart';
import 'package:menthic/features/auth/login_screen.dart';
import 'package:menthic/features/today/today_screen.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/cadastro',
  routes: [
    GoRoute(
      path: '/cadastro',
      name: 'cadastro',
      builder: (c, s) => const CadastroScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (c, s) => const LoginScreen(),
    ),
    GoRoute(
      path: '/hoje',
      name: 'hoje',
      builder: (c, s) => const TodayScreen(),
    ),
  ],
);

Future<void> _pump(WidgetTester t) async {
  SharedPreferences.setMockInitialValues({});
  await t.pumpWidget(
    ProviderScope(child: MaterialApp.router(routerConfig: _router())),
  );
  await t.pumpAndSettle();
}

Future<void> _fill(WidgetTester t, String senha, String confirm) async {
  await t.enterText(find.byType(TextField).at(0), 'a@b.com');
  await t.enterText(find.byType(TextField).at(1), senha);
  await t.enterText(find.byType(TextField).at(2), confirm);
  await t.enterText(find.byType(TextField).at(3), '11999');
}

Future<void> _tap(WidgetTester t, String label) async {
  await t.ensureVisible(find.text(label));
  await t.pumpAndSettle();
  await t.tap(find.text(label));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('senhas divergentes bloqueiam', (tester) async {
    await _pump(tester);
    await _fill(tester, 'segredo', 'outra');
    await _tap(tester, 'Cadastar');
    expect(find.byType(CadastroScreen), findsOneWidget);
    expect(find.textContaining('não conferem'), findsOneWidget);
  });

  testWidgets('cadastro válido navega para home', (tester) async {
    await _pump(tester);
    await _fill(tester, 'segredo', 'segredo');
    await _tap(tester, 'Cadastar');
    expect(find.byType(TodayScreen), findsOneWidget);
  });

  testWidgets('"já possuo conta" vai para login', (tester) async {
    await _pump(tester);
    await _tap(tester, 'já possuo conta');
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
