import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:menthic/router.dart';

void main() {
  test('router tem as 4 rotas nomeadas', () {
    final names = menthicRouter.configuration.routes
        .whereType<GoRoute>()
        .map((r) => r.name)
        .toSet();
    expect(names, {'splash', 'login', 'cadastro', 'home'});
  });

  testWidgets('rota inicial mostra a splash', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: menthicRouter));
    expect(find.text('splash'), findsOneWidget);
  });
}
