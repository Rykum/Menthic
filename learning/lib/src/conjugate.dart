class BetaPosterior {
  final double a, b;
  const BetaPosterior(this.a, this.b);

  BetaPosterior update(int successes, int trials) =>
      BetaPosterior(a + successes, b + (trials - successes));

  double get mean => a / (a + b);

  double get variance {
    final s = a + b;
    return (a * b) / (s * s * (s + 1));
  }
}

class NormalPosterior {
  final double mean, variance;
  const NormalPosterior(this.mean, this.variance);

  /// Normal-Normal com variância de observação conhecida [sigma2].
  /// [sigma2] é a variância de observação assumida (σ=0.5 na escala log de
  /// duração) — controla quanto cada observação puxa o posterior.
  NormalPosterior updateObservations(List<double> xs, {double sigma2 = 0.25}) {
    if (xs.isEmpty) return this;
    final n = xs.length;
    final xbar = xs.reduce((s, x) => s + x) / n;
    final priorPrecision = 1.0 / variance;
    final dataPrecision = n / sigma2;
    final postVar = 1.0 / (priorPrecision + dataPrecision);
    final postMean = postVar * (mean * priorPrecision + xbar * dataPrecision);
    return NormalPosterior(postMean, postVar);
  }
}
