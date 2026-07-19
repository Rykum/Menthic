import 'package:oracle_engine/oracle_engine.dart';

/// Serialização dos hiperparâmetros do twin (shared_preferences, fase 0).
Map<String, dynamic> priorsToJson(TraitPriors p) => {
  'phi': {'mean': p.phi.mean, 'sd': p.phi.sd},
  'p0': {'a': p.p0.a, 'b': p.p0.b},
  'rho': {'a': p.rho.a, 'b': p.rho.b},
  's': {'shape': p.s.shape, 'scale': p.s.scale},
  'o': {'mean': p.o.mean, 'sd': p.o.sd},
  'r': {'shape': p.r.shape, 'scale': p.r.scale},
};

double _d(Map<String, dynamic> m, String k) => (m[k] as num).toDouble();

TraitPriors priorsFromJson(Map<String, dynamic> j) {
  Map<String, dynamic> sub(String k) => (j[k] as Map).cast<String, dynamic>();
  return TraitPriors(
    phi: NormalPrior(_d(sub('phi'), 'mean'), _d(sub('phi'), 'sd')),
    p0: BetaPrior(_d(sub('p0'), 'a'), _d(sub('p0'), 'b')),
    rho: BetaPrior(_d(sub('rho'), 'a'), _d(sub('rho'), 'b')),
    s: GammaPrior(_d(sub('s'), 'shape'), _d(sub('s'), 'scale')),
    o: NormalPrior(_d(sub('o'), 'mean'), _d(sub('o'), 'sd')),
    r: GammaPrior(_d(sub('r'), 'shape'), _d(sub('r'), 'scale')),
  );
}
