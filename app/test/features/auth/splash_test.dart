import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menthic/features/auth/splash_screen.dart';
import 'package:menthic/features/auth/login_screen.dart';
import 'package:menthic/features/onboarding/onboarding_screen.dart';
import 'package:menthic/features/today/today_screen.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', name: 'splash', builder: (c, s) => const SplashScreen()),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (c, s) => const LoginScreen(),
    ),
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

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(child: MaterialApp.router(routerConfig: _router())),
  );
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('deslogado → login', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _pump(tester);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('logado sem onboarding → onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({'logged_in': true});
    await _pump(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('logado e onboarded → hoje', (tester) async {
    SharedPreferences.setMockInitialValues({
      'logged_in': true,
      'onboarded': true,
    });
    await _pump(tester);
    expect(find.byType(TodayScreen), findsOneWidget);
  });
}
