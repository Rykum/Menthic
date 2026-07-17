import 'package:oracle_engine/oracle_engine.dart';
import 'package:test/test.dart';

const _study = Commitment(
  id: 'estudo',
  start: 14.0,
  planned: 2.0,
  type: 'estudo',
  priority: 2,
  aversive: true,
);

Prediction _run(double sleepDebt, {int seed = 42}) => predict(
  DayState(sleepDebt: sleepDebt, dayEnd: 18.0, agenda: [_study]),
  TraitPriors.neutral,
  outerK: 200,
  innerM: 10,
  seed: seed,
);

void main() {
  test('quantile interpola corretamente', () {
    final xs = [0.0, 0.25, 0.5, 0.75, 1.0];
    expect(quantile(xs, 0.0), closeTo(0.0, 1e-9));
    expect(quantile(xs, 1.0), closeTo(1.0, 1e-9));
    expect(quantile(xs, 0.5), closeTo(0.5, 1e-9));
  });

  test('predict é determinístico para a mesma semente', () {
    final a = _run(2.0);
    final b = _run(2.0);
    expect(a.estimate, equals(b.estimate));
    expect(a.low, equals(b.low));
    expect(a.high, equals(b.high));
  });

  test('estimativa e faixa ficam em [0,1] e low<=estimate<=high', () {
    final p = _run(2.0);
    expect(p.estimate, inInclusiveRange(0.0, 1.0));
    expect(p.low, lessThanOrEqualTo(p.estimate));
    expect(p.high, greaterThanOrEqualTo(p.estimate));
    expect(p.perCommitment['estudo'], isNotNull);
  });

  test('mais débito de sono reduz a estimativa (monotonicidade)', () {
    expect(_run(0.0).estimate, greaterThan(_run(4.0).estimate));
  });
}
