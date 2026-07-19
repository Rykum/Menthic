import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menthic/data/providers.dart';
import 'package:menthic/features/onboarding/onboarding_screen.dart';
import 'package:menthic/features/today/today_screen.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (c, s) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/hoje',
      name: 'hoje',
      builder: (c, s) => const TodayScreen(),
    ),
  ],
);

Future<void> _tap(WidgetTester t, String label) async {
  await t.ensureVisible(find.text(label));
  await t.pumpAndSettle();
  await t.tap(find.text(label));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('manhã/5/5 salva priors do arquétipo e vai para hoje', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'logged_in': true});
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: _router())),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('rende melhor'), findsOneWidget);
    await _tap(tester, 'manhã');
    expect(find.textContaining('adiar tarefas chatas'), findsOneWidget);
    await _tap(tester, '5');
    expect(find.textContaining('subestima'), findsOneWidget);
    await _tap(tester, '5');

    expect(find.byType(TodayScreen), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(kOnboardedKey), true);
    final j = (jsonDecode(prefs.getString(kPriorsKey)!) as Map)
        .cast<String, dynamic>();
    expect(((j['phi'] as Map)['mean'] as num).toDouble(), 10.0);
    final rho = (j['rho'] as Map).cast<String, num>();
    expect(
      rho['a']!.toDouble() / (rho['a']!.toDouble() + rho['b']!.toDouble()),
      closeTo(0.75, 1e-9),
    );
    expect(((j['o'] as Map)['mean'] as num).toDouble(), closeTo(0.25, 1e-9));
  });
}
