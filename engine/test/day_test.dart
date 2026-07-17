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

double _completionRate(double sleepDebt, {int trials = 400, int seed = 9}) {
  final state = DayState(sleepDebt: sleepDebt, dayEnd: 18.0, agenda: [_study]);
  const tr = Traits(phi: 9.6, p0: 0.60, rho: 0.31, s: 0.15, o: 0.20, r: 0.25);
  final rng = SeededRng(seed);
  var done = 0;
  for (var i = 0; i < trials; i++) {
    if (simulateDay(state, tr, rng).completed['estudo'] == true) done++;
  }
  return done / trials;
}

void main() {
  test('simulateDay é determinístico para a mesma semente', () {
    final state = DayState(sleepDebt: 2.0, dayEnd: 18.0, agenda: [_study]);
    const tr = Traits(phi: 9.6, p0: 0.60, rho: 0.31, s: 0.15, o: 0.20, r: 0.25);
    final a = simulateDay(state, tr, SeededRng(1)).completed;
    final b = simulateDay(state, tr, SeededRng(1)).completed;
    expect(a, equals(b));
  });

  test('resultado é binário por compromisso e metAgenda coerente', () {
    final state = DayState(sleepDebt: 1.0, dayEnd: 18.0, agenda: [_study]);
    const tr = Traits(phi: 9.6, p0: 0.60, rho: 0.31, s: 0.15, o: 0.20, r: 0.25);
    final out = simulateDay(state, tr, SeededRng(4));
    expect(out.completed.containsKey('estudo'), isTrue);
    expect(out.metAgenda, equals(out.completed['estudo']));
  });

  test('menos sono => menor taxa de conclusão (monotonicidade)', () {
    expect(_completionRate(0.0), greaterThan(_completionRate(4.0)));
  });
}
