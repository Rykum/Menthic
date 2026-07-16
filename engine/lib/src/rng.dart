import 'dart:math' as math;

class SeededRng {
  final math.Random _r;
  SeededRng(int seed) : _r = math.Random(seed);

  double nextUniform() => _r.nextDouble();

  double nextNormal(double mean, double sd) {
    final u1 = _r.nextDouble();
    final u2 = _r.nextDouble();
    final z =
        math.sqrt(-2.0 * math.log(u1 <= 0 ? 1e-12 : u1)) *
        math.cos(2 * math.pi * u2);
    return mean + sd * z;
  }

  double nextExponential(double rate) {
    final u = _r.nextDouble();
    return -math.log(u <= 0 ? 1e-12 : u) / rate;
  }

  bool nextBernoulli(double p) => _r.nextDouble() < p;

  double nextLogNormal(double mu, double sigma) =>
      math.exp(nextNormal(mu, sigma));

  // Marsaglia-Tsang para shape >= 1; recursao para shape < 1.
  double nextGamma(double shape, double scale) {
    if (shape < 1.0) {
      final u = _r.nextDouble();
      return nextGamma(shape + 1.0, scale) *
          math.pow(u <= 0 ? 1e-12 : u, 1.0 / shape).toDouble();
    }
    final d = shape - 1.0 / 3.0;
    final c = 1.0 / math.sqrt(9.0 * d);
    while (true) {
      double x, v;
      do {
        x = nextNormal(0.0, 1.0);
        v = 1.0 + c * x;
      } while (v <= 0);
      v = v * v * v;
      final u = _r.nextDouble();
      if (u < 1.0 - 0.0331 * x * x * x * x) return d * v * scale;
      if (math.log(u <= 0 ? 1e-12 : u) <
          0.5 * x * x + d * (1.0 - v + math.log(v))) {
        return d * v * scale;
      }
    }
  }

  double nextBeta(double a, double b) {
    final x = nextGamma(a, 1.0);
    final y = nextGamma(b, 1.0);
    return x / (x + y);
  }
}
