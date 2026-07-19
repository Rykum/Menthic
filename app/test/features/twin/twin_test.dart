import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menthic/features/twin/twin_screen.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/twin',
  routes: [
    GoRoute(path: '/twin', name: 'twin', builder: (c, s) => const TwinScreen()),
  ],
);

void main() {
  testWidgets('mostra os 6 traços com os priors salvos (arquétipo manhã)', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'logged_in': true,
      'twin_priors_v1': jsonEncode({
        'phi': {'mean': 10.0, 'sd': 2.5},
        'p0': {'a': 6, 'b': 4},
        'rho': {'a': 5.25, 'b': 1.75},
        's': {'shape': 3, 'scale': 0.05},
        'o': {'mean': 0.25, 'sd': 0.10},
        'r': {'shape': 5, 'scale': 0.05},
      }),
    });
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: _router())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pico circadiano'), findsOneWidget);
    expect(find.textContaining('10h'), findsOneWidget);
    expect(find.text('Propensão a procrastinar'), findsOneWidget);
    expect(find.textContaining('75%'), findsOneWidget);
    expect(find.textContaining('incerteza'), findsNWidgets(6));
    expect(find.textContaining('dia(s) com desfecho'), findsOneWidget);
  });
}
