import 'package:oracle_engine/oracle_engine.dart';

/// Cold-start do doc 10 A.3: 3 respostas → priors de φ, ρ e o.
/// Demais traços partem do prior neutro (A.2).
TraitPriors archetypePriors({
  required String periodo,
  required int adiar,
  required int subestima,
}) {
  const n = TraitPriors.neutral;
  final muPhi = switch (periodo) {
    'manha' => 10.0,
    'noite' => 18.5,
    _ => 14.0,
  };
  // ρ: Beta com média 0.15·resposta, mantendo a força do prior neutro (a+b=7).
  final m = (0.15 * adiar).clamp(0.05, 0.95);
  const strength = 7.0;
  return TraitPriors(
    phi: NormalPrior(muPhi, n.phi.sd),
    p0: n.p0,
    rho: BetaPrior(strength * m, strength * (1 - m)),
    s: n.s,
    o: NormalPrior(0.05 * subestima, 0.10),
    r: n.r,
  );
}
