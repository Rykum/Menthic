import 'package:oracle_engine/oracle_engine.dart';
import 'package:test/test.dart';

void main() {
  test('prior neutro amostra traços em faixas plausíveis', () {
    final rng = SeededRng(3);
    final xs = List.generate(20000, (_) => TraitPriors.neutral.sample(rng));
    double avg(double Function(Traits) f) =>
        xs.map(f).reduce((s, x) => s + x) / xs.length;

    expect(avg((t) => t.phi), closeTo(14.0, 0.1));
    expect(avg((t) => t.p0), closeTo(0.6, 0.01));
    expect(avg((t) => t.rho), closeTo(2 / 7, 0.01));
    expect(avg((t) => t.o), closeTo(0.20, 0.01));
    expect(xs.every((t) => t.p0 > 0 && t.p0 < 1), isTrue);
    expect(xs.every((t) => t.s >= 0 && t.r >= 0), isTrue);
  });
}
