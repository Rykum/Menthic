import 'package:test/test.dart';
import 'package:oracle_engine/oracle_engine.dart';
import 'package:oracle_learning/oracle_learning.dart';

void main() {
  const learned = TraitPriors(
    phi: NormalPrior(10.0, 1.0), // aprendido: mais certo e deslocado do neutro
    p0: BetaPrior(6, 4),
    rho: BetaPrior(12, 4), // média 0.75, força 16 (vs neutro 2,5 força 7)
    s: GammaPrior(3, 0.05),
    o: NormalPrior(0.40, 0.05),
    r: GammaPrior(5, 0.05),
  );

  test('daysSinceEvidence <= 0 é identidade', () {
    final p = agePriors(learned, daysSinceEvidence: 0);
    expect(p.rho.a, 12);
    expect(p.rho.b, 4);
    expect(p.phi.mean, 10.0);
    expect(p.phi.sd, 1.0);
  });

  test('na meia-vida, hiperparâmetros ficam no ponto médio para o neutro', () {
    final p = agePriors(learned, daysSinceEvidence: 90, halfLifeDays: 90);
    expect(p.rho.a, closeTo((12 + 2) / 2, 1e-9));
    expect(p.rho.b, closeTo((4 + 5) / 2, 1e-9));
    expect(p.phi.mean, closeTo((10.0 + 14.0) / 2, 1e-9));
    // variância interpolada: (1 + 2.5²)/2 → sd = sqrt(3.625)
    expect(p.phi.sd * p.phi.sd, closeTo((1.0 + 6.25) / 2, 1e-9));
  });

  test('com muitos anos sem evidência, converge para o neutro', () {
    final p = agePriors(learned, daysSinceEvidence: 36500, halfLifeDays: 90);
    expect(p.rho.a, closeTo(2, 1e-6));
    expect(p.o.mean, closeTo(0.20, 1e-6));
    expect(p.o.sd, closeTo(0.10, 1e-6));
  });

  test('a incerteza reinfla (sd cresce de volta ao prior)', () {
    final p = agePriors(learned, daysSinceEvidence: 90, halfLifeDays: 90);
    expect(p.o.sd, greaterThan(0.05));
    expect(p.o.sd, lessThan(0.10));
  });
}
