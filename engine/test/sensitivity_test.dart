import 'package:oracle_engine/oracle_engine.dart';
import 'package:test/test.dart';

void main() {
  final state = DayState(
    sleepDebt: 2.0,
    dayEnd: 18.0,
    agenda: const [
      Commitment(
        id: 'estudo',
        start: 14.0,
        planned: 2.0,
        type: 'estudo',
        priority: 2,
        aversive: true,
      ),
    ],
  );

  test('sensibilidade retorna fatores ordenados por magnitude', () {
    final fs = sensitivity(state, TraitPriors.neutral, seed: 42);
    expect(fs, isNotEmpty);
    for (var i = 1; i < fs.length; i++) {
      expect(fs[i - 1].delta.abs(), greaterThanOrEqualTo(fs[i].delta.abs()));
    }
  });

  test('remover o débito de sono tem direção positiva', () {
    final fs = sensitivity(state, TraitPriors.neutral, seed: 42);
    final sono = fs.firstWhere((f) => f.label.contains('sono'));
    expect(sono.direction, equals('positivo'));
  });
}
