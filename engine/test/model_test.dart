import 'package:oracle_engine/oracle_engine.dart';
import 'package:test/test.dart';

void main() {
  test('initialFatigue: 0.10 + 0.08*debito', () {
    expect(initialFatigue(2.0), closeTo(0.26, 1e-9));
    expect(initialFatigue(0.0), closeTo(0.10, 1e-9));
  });

  test('energy reproduz o valor do exemplo (doc 10 C.2 = ~0.4611)', () {
    const tr = Traits(phi: 9.6, p0: 0.60, rho: 0.31, s: 0.15, o: 0.25, r: 0.25);
    // t=14h, debito=2, fadiga=0.30
    expect(energy(14.0, tr, 2.0, 0.30), closeTo(0.4611, 1e-3));
  });

  test('energy sobe no pico e cai fora do pico', () {
    const tr = Traits(phi: 9.6, p0: 0.60, rho: 0.31, s: 0.15, o: 0.25, r: 0.25);
    final atPeak = energy(9.6, tr, 0.0, 0.0);
    final offPeak = energy(9.6 + 12.0, tr, 0.0, 0.0);
    expect(atPeak, greaterThan(offPeak));
  });

  test('fatigueStep acumula e recupera com clamp', () {
    expect(fatigueStep(0.20, 0.10, 0.0, 1.0), closeTo(0.30, 1e-9));
    expect(fatigueStep(0.20, 0.0, 0.25, 1.0), closeTo(0.0, 1e-9)); // clamp em 0
    expect(fatigueStep(0.95, 0.10, 0.0, 1.0), closeTo(1.0, 1e-9)); // clamp em 1
  });

  test('logistic(0)=0.5', () {
    expect(logistic(0.0), closeTo(0.5, 1e-12));
    expect(logistic(-0.155956), closeTo(0.4611, 1e-3));
  });
}
