import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menthic/features/auth/splash_screen.dart';
import 'package:menthic/features/auth/login_screen.dart';
import 'package:menthic/features/home/home_screen.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', name: 'splash', builder: (c, s) => const SplashScreen()),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (c, s) => const LoginScreen(),
    ),
    GoRoute(path: '/home', name: 'home', builder: (c, s) => const HomeScreen()),
  ],
);

void main() {
  testWidgets('deslogado → vai para login', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: _router())),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('logado → vai para home', (tester) async {
    SharedPreferences.setMockInitialValues({'logged_in': true});
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: _router())),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
