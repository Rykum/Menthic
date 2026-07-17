import 'dart:math' as math;
import 'pred_outcome.dart';

double _clampP(double p) {
  const eps = 1e-6;
  if (p < eps) return eps;
  if (p > 1 - eps) return 1 - eps;
  return p;
}

double _logit(double p) {
  final c = _clampP(p);
  return math.log(c / (1 - c));
}

double _sigmoid(double x) => 1.0 / (1.0 + math.exp(-x));

class PlattCalibrator {
  final double a, b;
  const PlattCalibrator(this.a, this.b);

  /// Ajusta a,b por gradiente descendente (log-loss), início fixo => determinístico.
  static PlattCalibrator fit(
    List<PredOutcome> d, {
    int iters = 200,
    double lr = 0.3,
  }) {
    var a = 1.0, b = 0.0;
    if (d.isEmpty) return PlattCalibrator(a, b);
    final nInv = 1.0 / d.length;
    for (var it = 0; it < iters; it++) {
      var ga = 0.0, gb = 0.0;
      for (final x in d) {
        final z = _logit(x.p);
        final pred = _sigmoid(a * z + b);
        final err = pred - x.o;
        ga += err * z;
        gb += err;
      }
      a -= lr * ga * nInv;
      b -= lr * gb * nInv;
    }
    return PlattCalibrator(a, b);
  }

  double apply(double p) => _sigmoid(a * _logit(p) + b);
}
