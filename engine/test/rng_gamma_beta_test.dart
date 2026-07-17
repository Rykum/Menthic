import 'package:oracle_engine/oracle_engine.dart';
import 'package:test/test.dart';

double mean(List<double> xs) => xs.reduce((s, x) => s + x) / xs.length;

void main() {
  test('Gamma(3, 0.05) tem media ~0.15', () {
    final rng = SeededRng(11);
    final xs = List.generate(40000, (_) => rng.nextGamma(3, 0.05));
    expect(mean(xs), closeTo(0.15, 0.005));
    expect(xs.every((x) => x >= 0), isTrue);
  });

  test('Gamma com shape<1 funciona', () {
    final rng = SeededRng(2);
    final xs = List.generate(40000, (_) => rng.nextGamma(0.5, 2.0));
    expect(mean(xs), closeTo(1.0, 0.05)); // media = shape*scale
  });

  test('Beta(6,4) tem media ~0.6 e fica em (0,1)', () {
    final rng = SeededRng(5);
    final xs = List.generate(40000, (_) => rng.nextBeta(6, 4));
    expect(mean(xs), closeTo(0.6, 0.01));
    expect(xs.every((x) => x > 0 && x < 1), isTrue);
  });
}
