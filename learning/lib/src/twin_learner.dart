import 'dart:math' as math;
import 'package:oracle_engine/oracle_engine.dart';
import 'package:oracle_store/oracle_store.dart';
import 'conjugate.dart';
import 'observables.dart';

class TwinLearner {
  const TwinLearner();

  Future<TraitPriors> learn(
    EventStore store, {
    TraitPriors prior = TraitPriors.neutral,
    double sigma2 = 0.25,
  }) async {
    final obs = await const ObservableExtractor().extract(store);

    // o: Normal-Normal a partir de prior.o
    final oPrior = NormalPosterior(prior.o.mean, prior.o.sd * prior.o.sd);
    final oPost = oPrior.updateObservations(obs.o, sigma2: sigma2);
    final newO = NormalPrior(oPost.mean, math.sqrt(oPost.variance));

    // rho: Beta-Bernoulli a partir de prior.rho
    final rhoPost = BetaPosterior(
      prior.rho.a,
      prior.rho.b,
    ).update(obs.rhoSucessos, obs.rhoTentativas);
    final newRho = BetaPrior(rhoPost.a, rhoPost.b);

    return TraitPriors(
      phi: prior.phi,
      p0: prior.p0,
      rho: newRho,
      s: prior.s,
      o: newO,
      r: prior.r,
    );
  }
}
