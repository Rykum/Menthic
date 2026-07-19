import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menthic/features/simulate/simulate_screen.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/simular',
  routes: [
    GoRoute(
      path: '/simular',
      name: 'simular',
      builder: (c, s) => const SimulateScreen(),
    ),
  ],
);

String _seedStore() {
  final now = DateTime.now().toUtc();
  return jsonEncode([
    {
      'ts': now.toIso8601String(),
      'type': 'sono_registrado',
      'payload': {'horas': 6.0},
      'origin': 'manual',
    },
    {
      'ts': now.toIso8601String(),
      'type': 'compromisso_criado',
      'payload': {
        'cid': 'estudo',
        'inicio': 9.0,
        'dur_prevista': 2.0,
        'tipo': 'foco',
        'prioridade': 2,
        'aversivo': false,
      },
      'origin': 'manual',
    },
  ]);
}

void main() {
  testWidgets('simula o dia real, recalcula ao editar e não grava nada', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'logged_in': true,
      'event_store_v1': _seedStore(),
    });
    final before = (await SharedPreferences.getInstance()).getString(
      'event_store_v1',
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: _router())),
    );
    await tester.pumpAndSettle();

    // Carrega o dia real e já mostra um cenário calculado.
    expect(find.textContaining('cenário hipotético'), findsOneWidget);
    expect(find.text('Cumprir a agenda de hoje'), findsOneWidget);
    expect(find.textContaining('estudo'), findsOneWidget);

    // Editar o sono e recalcular.
    await tester.enterText(find.byKey(const Key('sono_hipotetico')), '2');
    await tester.ensureVisible(find.text('Recalcular'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recalcular'));
    await tester.pumpAndSettle();
    expect(find.text('Cumprir a agenda de hoje'), findsOneWidget);

    // Nada foi persistido.
    final after = (await SharedPreferences.getInstance()).getString(
      'event_store_v1',
    );
    expect(after, before);
  });
}
