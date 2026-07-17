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
