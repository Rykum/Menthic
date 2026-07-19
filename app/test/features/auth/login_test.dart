import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menthic/features/auth/login_screen.dart';
import 'package:menthic/features/auth/cadastro_screen.dart';
import 'package:menthic/features/home/home_screen.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (c, s) => const LoginScreen(),
    ),
    GoRoute(
      path: '/cadastro',
      name: 'cadastro',
      builder: (c, s) => const CadastroScreen(),
    ),
    GoRoute(path: '/home', name: 'home', builder: (c, s) => const HomeScreen()),
  ],
);

Future<void> _pump(WidgetTester t) async {
  SharedPreferences.setMockInitialValues({});
  await t.pumpWidget(
    ProviderScope(child: MaterialApp.router(routerConfig: _router())),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets('login válido navega para home', (tester) async {
    await _pump(tester);
    await tester.enterText(find.byType(TextField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextField).at(1), 'segredo');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('link "Não possuo conta" vai para cadastro', (tester) async {
    await _pump(tester);
    await tester.ensureVisible(find.text('Não possuo conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Não possuo conta'));
    await tester.pumpAndSettle();
    expect(find.byType(CadastroScreen), findsOneWidget);
  });

  testWidgets('senha curta mostra erro e não navega', (tester) async {
    await _pump(tester);
    await tester.enterText(find.byType(TextField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextField).at(1), '123');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.textContaining('6 caracteres'), findsOneWidget);
  });
}
