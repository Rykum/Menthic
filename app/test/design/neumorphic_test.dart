import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menthic/design/neumorphic.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('NeuButton chama onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(NeuButton(onTap: () => taps++, child: const Text('ok'))),
    );
    await tester.tap(find.text('ok'));
    expect(taps, 1);
  });

  testWidgets('NeuInset renderiza o filho', (tester) async {
    await tester.pumpWidget(_host(const NeuInset(child: Text('dentro'))));
    expect(find.text('dentro'), findsOneWidget);
  });
}
