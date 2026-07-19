import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:menthic/features/auth/splash_screen.dart';
import 'package:menthic/router.dart';

void main() {
  test('router tem as 9 rotas nomeadas', () {
    final names = menthicRouter.configuration.routes
        .whereType<GoRoute>()
        .map((r) => r.name)
        .toSet();
    expect(names, {
      'splash',
      'login',
      'cadastro',
      'onboarding',
      'hoje',
      'revisao',
      'simular',
      'twin',
      'calibracao',
    });
  });

  testWidgets('rota inicial mostra a splash', (tester) async {
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: menthicRouter)),
    );
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
