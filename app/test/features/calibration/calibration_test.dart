import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menthic/features/calibration/calibration_screen.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/calibracao',
  routes: [
    GoRoute(
      path: '/calibracao',
      name: 'calibracao',
      builder: (c, s) => const CalibrationScreen(),
    ),
  ],
);

Map<String, dynamic> _e(
  DateTime ts,
  String type,
  Map<String, dynamic> payload,
) => {
  'ts': ts.toIso8601String(),
  'type': type,
  'payload': payload,
  'origin': 'manual',
};

String _seedStore() {
  final d1 = DateTime.utc(2026, 7, 10, 9);
  final d2 = DateTime.utc(2026, 7, 11, 9);
  return jsonEncode([
    // dia 1: previu 0.8, cumpriu → outcome 1
    _e(d1, 'compromisso_criado', {'cid': 'a', 'prioridade': 2}),
    _e(d1, 'previsao_emitida', {'estimate': 0.8}),
    _e(d1.add(const Duration(hours: 10)), 'tarefa_concluida', {
      'cid': 'a',
      'atraso_min': 0,
    }),
    // dia 2: previu 0.6, não cumpriu → outcome 0
    _e(d2, 'compromisso_criado', {'cid': 'b', 'prioridade': 2}),
    _e(d2, 'previsao_emitida', {'estimate': 0.6}),
    _e(d2.add(const Duration(hours: 10)), 'tarefa_nao_concluida', {'cid': 'b'}),
  ]);
}

void main() {
  testWidgets('mostra pares, Brier e aviso de poucos dados', (tester) async {
    SharedPreferences.setMockInitialValues({
      'logged_in': true,
      'event_store_v1': _seedStore(),
    });
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: _router())),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('2 previsões avaliadas'), findsOneWidget);
    // Brier = ((0.8-1)^2 + (0.6-0)^2) / 2 = (0.04 + 0.36)/2 = 0.20
    expect(find.textContaining('0.20'), findsOneWidget);
    expect(find.textContaining('poucos dados'), findsOneWidget);
    expect(find.textContaining('80%'), findsOneWidget);
    expect(find.textContaining('60%'), findsOneWidget);
  });

  testWidgets('sem histórico mostra estado vazio honesto', (tester) async {
    SharedPreferences.setMockInitialValues({'logged_in': true});
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: _router())),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Nenhuma previsão avaliada ainda'),
      findsOneWidget,
    );
  });
}
