import 'rng.dart';

class Traits {
  final double phi; // pico circadiano (hora)
  final double p0; // baseline de produtividade 0..1
  final double rho; // propensao a procrastinar 0..1
  final double s; // sensibilidade ao sono (por hora de debito)
  final double o; // otimismo de agenda (offset log-duracao)
  final double r; // taxa de recuperacao (por hora)
  const Traits({
    required this.phi,
    required this.p0,
    required this.rho,
    required this.s,
    required this.o,
    required this.r,
  });
}

class NormalPrior {
  final double mean, sd;
  const NormalPrior(this.mean, this.sd);
}

class BetaPrior {
  final double a, b;
  const BetaPrior(this.a, this.b);
}

class GammaPrior {
  final double shape, scale;
  const GammaPrior(this.shape, this.scale);
}

class TraitPriors {
  final NormalPrior phi;
  final BetaPrior p0;
  final BetaPrior rho;
  final GammaPrior s;
  final NormalPrior o;
  final GammaPrior r;
  const TraitPriors({
    required this.phi,
    required this.p0,
    required this.rho,
    required this.s,
    required this.o,
    required this.r,
  });

  // Arquetipo neutro (doc 10 A.2)
  static const TraitPriors neutral = TraitPriors(
    phi: NormalPrior(14.0, 2.5),
    p0: BetaPrior(6, 4),
    rho: BetaPrior(2, 5),
    s: GammaPrior(3, 0.05),
    o: NormalPrior(0.20, 0.10),
    r: GammaPrior(5, 0.05),
  );

  Traits sample(SeededRng rng) => Traits(
    phi: rng.nextNormal(phi.mean, phi.sd),
    p0: rng.nextBeta(p0.a, p0.b).clamp(0.0, 1.0),
    rho: rng.nextBeta(rho.a, rho.b).clamp(0.0, 1.0),
    s: rng.nextGamma(s.shape, s.scale),
    o: rng.nextNormal(o.mean, o.sd),
    r: rng.nextGamma(r.shape, r.scale),
  );
}
