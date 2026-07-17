import 'rng.dart';
import 'traits.dart';
import 'day.dart';

class Prediction {
  final double estimate; // media da prob de cumprir a agenda
  final double low; // quantil 10 (banda epistemica)
  final double high; // quantil 90
  final Map<String, double> perCommitment; // id -> prob de conclusao
  const Prediction(this.estimate, this.low, this.high, this.perCommitment);
}

double quantile(List<double> xs, double q) {
  if (xs.isEmpty) return double.nan;
  final s = [...xs]..sort();
  if (s.length == 1) return s.first;
  final pos = q * (s.length - 1);
  final lo = pos.floor();
  final hi = pos.ceil();
  if (lo == hi) return s[lo];
  final frac = pos - lo;
  return s[lo] * (1 - frac) + s[hi] * frac;
}

Prediction predict(
  DayState state,
  TraitPriors priors, {
  int outerK = 200,
  int innerM = 10,
  int seed = 0,
}) {
  assert(outerK > 0 && innerM > 0, 'outerK e innerM devem ser > 0');
  final rng = SeededRng(seed);
  final metRatesPerTheta = <double>[]; // prob epistemica de cumprir a agenda
  final perCommitmentSum = <String, double>{
    for (final c in state.agenda) c.id: 0.0,
  };

  for (var k = 0; k < outerK; k++) {
    final tr = priors.sample(rng); // incerteza EPISTEMICA (1 theta)
    var metInner = 0;
    final commitInner = <String, int>{for (final c in state.agenda) c.id: 0};
    for (var m = 0; m < innerM; m++) {
      final out = simulateDay(state, tr, rng); // incerteza ALEATORIA
      if (out.metAgenda) metInner++;
      for (final c in state.agenda) {
        if (out.completed[c.id] == true) {
          commitInner[c.id] = commitInner[c.id]! + 1;
        }
      }
    }
    metRatesPerTheta.add(metInner / innerM);
    for (final c in state.agenda) {
      perCommitmentSum[c.id] =
          perCommitmentSum[c.id]! + commitInner[c.id]! / innerM;
    }
  }

  final estimate =
      metRatesPerTheta.reduce((s, x) => s + x) / metRatesPerTheta.length;
  final low = quantile(metRatesPerTheta, 0.10);
  final high = quantile(metRatesPerTheta, 0.90);
  final perCommitment = {
    for (final c in state.agenda) c.id: perCommitmentSum[c.id]! / outerK,
  };
  return Prediction(estimate, low, high, perCommitment);
}
