import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menthic/data/providers.dart';
import 'package:menthic/features/review/review_screen.dart';
import 'package:menthic/features/today/today_screen.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/revisao',
  routes: [
    GoRoute(
      path: '/revisao',
      name: 'revisao',
      builder: (c, s) => const ReviewScreen(),
    ),
    GoRoute(
      path: '/hoje',
      name: 'hoje',
      builder: (c, s) => const TodayScreen(),
    ),
  ],
);

String _seedStore() {
  final now = DateTime.now().toUtc();
  return jsonEncode([
    {
      'ts': now.toIso8601String(),
      'type': 'compromisso_criado',
      'payload': {
        'cid': 'estudo',
        'inicio': 9.0,
        'dur_prevista': 2.0,
        'tipo': 'foco',
        'prioridade': 2,
        'aversivo': true,
      },
      'origin': 'manual',
    },
  ]);
}

Future<void> _tap(WidgetTester t, String label) async {
  await t.ensureVisible(find.text(label).first);
  await t.pumpAndSettle();
  await t.tap(find.text(label).first);
  await t.pumpAndSettle();
}

void main() {
  testWidgets('marcar aversiva feita com atraso grava eventos e atualiza rho', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'logged_in': true,
      'event_store_v1': _seedStore(),
    });
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: _router())),
    );
    await tester.pumpAndSettle();

    expect(find.text('estudo'), findsOneWidget);
    await _tap(tester, 'feito');
    await _tap(tester, '30 min');
    await _tap(tester, 'Salvar revisão');

    expect(find.byType(TodayScreen), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    final events = jsonDecode(prefs.getString('event_store_v1')!) as List;
    final types = [for (final e in events) (e as Map)['type']];
    expect(types, contains('tarefa_concluida'));
    expect(types, contains('humor_registrado'));

    // rho: Beta(2,5) + 1 tentativa aversiva com atraso>0 => Beta(3,5).
    final j = (jsonDecode(prefs.getString(kPriorsKey)!) as Map)
        .cast<String, dynamic>();
    final rho = (j['rho'] as Map).cast<String, num>();
    expect(rho['a']!.toDouble(), closeTo(3.0, 1e-9));
    expect(rho['b']!.toDouble(), closeTo(5.0, 1e-9));
  });

  testWidgets('durou: mais → dur_real = 1.5×prevista e o otimismo aprende', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'logged_in': true,
      'event_store_v1': _seedStore(),
    });
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: _router())),
    );
    await tester.pumpAndSettle();

    await _tap(tester, 'feito');
    await _tap(tester, 'mais');
    await _tap(tester, 'Salvar revisão');

    final prefs = await SharedPreferences.getInstance();
    final events = jsonDecode(prefs.getString('event_store_v1')!) as List;
    final done = events.cast<Map>().firstWhere(
      (e) => e['type'] == 'tarefa_concluida',
    );
    expect(
      ((done['payload'] as Map)['dur_real'] as num).toDouble(),
      closeTo(3.0, 1e-9),
    );

    // o: prior N(0.20, 0.10²) + obs ln(1.5) → média posterior sobe.
    final j = (jsonDecode(prefs.getString(kPriorsKey)!) as Map)
        .cast<String, dynamic>();
    final oMean = (((j['o'] as Map)['mean']) as num).toDouble();
    expect(oMean, greaterThan(0.20));
  });

  testWidgets('não feito grava tarefa_nao_concluida', (tester) async {
    SharedPreferences.setMockInitialValues({
      'logged_in': true,
      'event_store_v1': _seedStore(),
    });
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: _router())),
    );
    await tester.pumpAndSettle();

    await _tap(tester, 'Salvar revisão');

    final prefs = await SharedPreferences.getInstance();
    final events = jsonDecode(prefs.getString('event_store_v1')!) as List;
    final types = [for (final e in events) (e as Map)['type']];
    expect(types, contains('tarefa_nao_concluida'));
  });
}
