import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menthic/design/design.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('MenthicScaffold + GlassCard renderizam o filho', (tester) async {
    await tester.pumpWidget(
      _host(const MenthicScaffold(child: GlassCard(child: Text('conteúdo')))),
    );
    expect(find.text('conteúdo'), findsOneWidget);
  });

  testWidgets('DisplayTitle mostra o texto', (tester) async {
    await tester.pumpWidget(_host(const DisplayTitle('Menthic')));
    expect(find.text('Menthic'), findsOneWidget);
  });

  testWidgets('PillField digita e obscurece', (tester) async {
    final ctrl = TextEditingController();
    await tester.pumpWidget(
      _host(PillField(label: 'senha:', controller: ctrl, obscure: true)),
    );
    await tester.enterText(find.byType(TextField), 'segredo');
    expect(ctrl.text, 'segredo');
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.obscureText, true);
  });

  testWidgets('GoogleButton chama onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(GoogleButton(onTap: () => taps++)));
    await tester.tap(find.textContaining('Google'));
    expect(taps, 1);
  });
}
