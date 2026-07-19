import 'package:flutter_test/flutter_test.dart';
import 'package:oracle_engine/oracle_engine.dart';
import 'package:menthic/data/priors_codec.dart';

void main() {
  test('round-trip do prior neutro', () {
    final j = priorsToJson(TraitPriors.neutral);
    final p = priorsFromJson(j);
    expect(p.phi.mean, 14.0);
    expect(p.phi.sd, 2.5);
    expect(p.p0.a, 6);
    expect(p.p0.b, 4);
    expect(p.rho.a, 2);
    expect(p.rho.b, 5);
    expect(p.s.shape, 3);
    expect(p.s.scale, 0.05);
    expect(p.o.mean, 0.20);
    expect(p.o.sd, 0.10);
    expect(p.r.shape, 5);
    expect(p.r.scale, 0.05);
  });

  test('round-trip de prior customizado', () {
    const custom = TraitPriors(
      phi: NormalPrior(10.0, 2.5),
      p0: BetaPrior(6, 4),
      rho: BetaPrior(5.25, 1.75),
      s: GammaPrior(3, 0.05),
      o: NormalPrior(0.25, 0.10),
      r: GammaPrior(5, 0.05),
    );
    final p = priorsFromJson(priorsToJson(custom));
    expect(p.phi.mean, 10.0);
    expect(p.rho.a, 5.25);
    expect(p.rho.b, 1.75);
    expect(p.o.mean, 0.25);
  });
}
