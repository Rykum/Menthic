import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menthic/features/today/today_screen.dart';
import 'package:menthic/features/auth/login_screen.dart';
import 'package:menthic/features/review/review_screen.dart';
import 'package:menthic/features/simulate/simulate_screen.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/hoje',
  routes: [
    GoRoute(
      path: '/hoje',
      name: 'hoje',
      builder: (c, s) => const TodayScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (c, s) => const LoginScreen(),
    ),
    GoRoute(
      path: '/revisao',
      name: 'revisao',
      builder: (c, s) => const ReviewScreen(),
    ),
    GoRoute(
      path: '/simular',
      name: 'simular',
      builder: (c, s) => const SimulateScreen(),
    ),
  ],
);

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(child: MaterialApp.router(routerConfig: _router())),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester t, String label) async {
  await t.ensureVisible(find.text(label).first);
  await t.pumpAndSettle();
  await t.tap(find.text(label).first);
  await t.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'logged_in': true}));

  testWidgets('registra sono, adiciona compromisso e prevê o dia', (
    tester,
  ) async {
    await _pump(tester);

    await tester.enterText(find.byKey(const Key('sono')), '6');
    await _tap(tester, 'Registrar sono');
    expect(find.textContaining('Sono de hoje: 6'), findsOneWidget);

    await _tap(tester, 'Adicionar compromisso');
    await tester.enterText(find.byKey(const Key('nome')), 'estudo');
    await tester.enterText(find.byKey(const Key('inicio')), '9');
    await tester.enterText(find.byKey(const Key('duracao')), '2');
    await _tap(tester, 'Salvar');
    expect(find.textContaining('estudo'), findsOneWidget);

    await _tap(tester, 'Prever meu dia');
    expect(find.text('Cumprir a agenda de hoje'), findsOneWidget);
    expect(find.textContaining('faixa provável'), findsOneWidget);
    expect(find.textContaining('confiança'), findsOneWidget);
    expect(find.text('Limitações'), findsOneWidget);
  });

  testWidgets('atalho Simular navega', (tester) async {
    await _pump(tester);
    await _tap(tester, 'Simular');
    expect(find.byType(SimulateScreen), findsOneWidget);
  });

  testWidgets('Sair desloga e volta ao login', (tester) async {
    await _pump(tester);
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
