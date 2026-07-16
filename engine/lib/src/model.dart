import 'dart:math' as math;
import 'traits.dart';

class ModelConstants {
  static const double c0 = -1.0;
  static const double cP = 2.5;
  static const double cF = 2.0;
  static const double amp = 0.6;
  static const double f0base = 0.10;
  static const double kD = 0.08;
}

double logistic(double x) => 1.0 / (1.0 + math.exp(-x));

double energy(double t, Traits tr, double sleepDebt, double fatigue) {
  final circ = ModelConstants.amp * math.cos(2 * math.pi * (t - tr.phi) / 24.0);
  final eta =
      ModelConstants.c0 +
      ModelConstants.cP * tr.p0 -
      tr.s * sleepDebt -
      ModelConstants.cF * fatigue +
      circ;
  return logistic(eta);
}

double initialFatigue(double sleepDebt) =>
    (ModelConstants.f0base + ModelConstants.kD * sleepDebt).clamp(0.0, 1.0);

double fatigueStep(
  double fatigue,
  double alpha,
  double recovery,
  double dtHours,
) {
  return (fatigue + alpha * dtHours - recovery * dtHours).clamp(0.0, 1.0);
}

const Map<String, double> activityAlpha = {
  'foco': 0.10,
  'trabalho_raso': 0.06,
  'treino': 0.20,
  'deslocamento': 0.04,
  'refeicao': 0.0,
  'descanso': 0.0,
  'sono': 0.0,
};
