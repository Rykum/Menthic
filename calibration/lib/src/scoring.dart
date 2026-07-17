import 'pred_outcome.dart';

double brierScore(List<PredOutcome> d) {
  if (d.isEmpty) return double.nan;
  var s = 0.0;
  for (final x in d) {
    final diff = x.p - x.o;
    s += diff * diff;
  }
  return s / d.length;
}

double baseRate(List<PredOutcome> d) {
  if (d.isEmpty) return double.nan;
  var s = 0;
  for (final x in d) {
    s += x.o;
  }
  return s / d.length;
}

double brierBaseline(List<PredOutcome> d) {
  if (d.isEmpty) return double.nan;
  final r = baseRate(d);
  var s = 0.0;
  for (final x in d) {
    final diff = r - x.o;
    s += diff * diff;
  }
  return s / d.length;
}

double brierSkillScore(List<PredOutcome> d) {
  final base = brierBaseline(d);
  if (base == 0.0) return double.nan;
  return 1 - brierScore(d) / base;
}

double calibrationInTheLarge(List<PredOutcome> d) {
  if (d.isEmpty) return double.nan;
  var sp = 0.0;
  var so = 0;
  for (final x in d) {
    sp += x.p;
    so += x.o;
  }
  return ((sp / d.length) - (so / d.length)).abs();
}

class ReliabilityBin {
  final double lo, hi;
  final int n;
  final double meanPredicted; // NaN se n == 0
  final double observedFreq; // NaN se n == 0
  const ReliabilityBin(
    this.lo,
    this.hi,
    this.n,
    this.meanPredicted,
    this.observedFreq,
  );
}

List<ReliabilityBin> reliabilityDiagram(List<PredOutcome> d, {int bins = 10}) {
  final width = 1.0 / bins;
  final sumsP = List.filled(bins, 0.0);
  final sumsO = List.filled(bins, 0.0);
  final counts = List.filled(bins, 0);
  for (final x in d) {
    // multiplica (mais estável que dividir por width em ponto flutuante)
    var idx = (x.p * bins).floor();
    if (idx >= bins) idx = bins - 1; // p == 1.0 vai para o último bin
    if (idx < 0) idx = 0;
    sumsP[idx] += x.p;
    sumsO[idx] += x.o;
    counts[idx] += 1;
  }
  return List.generate(bins, (k) {
    final n = counts[k];
    return ReliabilityBin(
      k * width,
      (k + 1) * width,
      n,
      n == 0 ? double.nan : sumsP[k] / n,
      n == 0 ? double.nan : sumsO[k] / n,
    );
  });
}

class MurphyDecomposition {
  final double reliability, resolution, uncertainty;
  const MurphyDecomposition(
    this.reliability,
    this.resolution,
    this.uncertainty,
  );
}

MurphyDecomposition murphy(List<PredOutcome> d, {int bins = 10}) {
  final n = d.length;
  if (n == 0) {
    return const MurphyDecomposition(double.nan, double.nan, double.nan);
  }
  final obar = baseRate(d);
  final diagram = reliabilityDiagram(d, bins: bins);
  var rel = 0.0, res = 0.0;
  for (final b in diagram) {
    if (b.n == 0) continue;
    rel +=
        b.n *
        (b.meanPredicted - b.observedFreq) *
        (b.meanPredicted - b.observedFreq);
    res += b.n * (b.observedFreq - obar) * (b.observedFreq - obar);
  }
  return MurphyDecomposition(rel / n, res / n, obar * (1 - obar));
}
