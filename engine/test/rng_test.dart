import 'dart:math' as math;
import 'package:oracle_engine/oracle_engine.dart';
import 'package:test/test.dart';

void main() {
  test('mesma semente produz a mesma sequencia', () {
    final a = SeededRng(42);
    final b = SeededRng(42);
    for (var i = 0; i < 5; i++) {
      expect(a.nextUniform(), equals(b.nextUniform()));
    }
  });

  test('nextNormal aproxima media e desvio', () {
    final rng = SeededRng(7);
    final xs = List.generate(20000, (_) => rng.nextNormal(2.0, 0.5));
    final mean = xs.reduce((s, x) => s + x) / xs.length;
    final varc =
        xs.map((x) => (x - mean) * (x - mean)).reduce((s, x) => s + x) /
        xs.length;
    expect(mean, closeTo(2.0, 0.02));
    expect(math.sqrt(varc), closeTo(0.5, 0.02));
  });

  test('nextBernoulli aproxima a probabilidade', () {
    final rng = SeededRng(1);
    final k = List.generate(
      20000,
      (_) => rng.nextBernoulli(0.3) ? 1 : 0,
    ).reduce((s, x) => s + x);
    expect(k / 20000, closeTo(0.3, 0.02));
  });
}
