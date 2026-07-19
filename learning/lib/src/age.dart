import 'dart:math' as math;
import 'package:oracle_engine/oracle_engine.dart';

/// Confiança adaptativa (RFC v2): evidência envelhece. Sem observações novas,
/// os posteriors regridem para o prior âncora com meia-vida em dias — a média
/// volta ao neutro e a incerteza reinfla. Aplicar na LEITURA; nunca reescrever
/// os priors salvos com o resultado.
TraitPriors agePriors(
  TraitPriors p, {
  required double daysSinceEvidence,
  double halfLifeDays = 90,
  TraitPriors anchor = TraitPriors.neutral,
}) {
  if (daysSinceEvidence <= 0) return p;
  final lambda = math.pow(0.5, daysSinceEvidence / halfLifeDays).toDouble();

  double mix(double a, double b) => a + (b - a) * (1 - lambda);

  NormalPrior normal(NormalPrior x, NormalPrior a) => NormalPrior(
    mix(x.mean, a.mean),
    math.sqrt(mix(x.sd * x.sd, a.sd * a.sd)),
  );
  BetaPrior beta(BetaPrior x, BetaPrior a) =>
      BetaPrior(mix(x.a, a.a), mix(x.b, a.b));
  GammaPrior gamma(GammaPrior x, GammaPrior a) =>
      GammaPrior(mix(x.shape, a.shape), mix(x.scale, a.scale));

  return TraitPriors(
    phi: normal(p.phi, anchor.phi),
    p0: beta(p.p0, anchor.p0),
    rho: beta(p.rho, anchor.rho),
    s: gamma(p.s, anchor.s),
    o: normal(p.o, anchor.o),
    r: gamma(p.r, anchor.r),
  );
}
