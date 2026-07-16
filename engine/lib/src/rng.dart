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
}
