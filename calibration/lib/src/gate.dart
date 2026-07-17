import 'pred_outcome.dart';
import 'scoring.dart';

class GateResult {
  final bool passed;
  final double bss;
  final double calibrationInTheLarge;
  final int n;
  final String reason;
  const GateResult({
    required this.passed,
    required this.bss,
    required this.calibrationInTheLarge,
    required this.n,
    required this.reason,
  });
}

GateResult evaluateGate(
  List<PredOutcome> d, {
  int minN = 120,
  double minBss = 0.05,
  double maxCalibration = 0.05,
}) {
  final n = d.length;
  final bss = brierSkillScore(d);
  final cal = calibrationInTheLarge(d);
  if (n < minN) {
    return GateResult(
      passed: false,
      bss: bss,
      calibrationInTheLarge: cal,
      n: n,
      reason: 'amostra insuficiente (n=$n < $minN)',
    );
  }
  final passed = bss >= minBss && cal < maxCalibration;
  return GateResult(
    passed: passed,
    bss: bss,
    calibrationInTheLarge: cal,
    n: n,
    reason: passed
        ? 'passou'
        : 'BSS=${bss.toStringAsFixed(3)} calibração=${cal.toStringAsFixed(3)}',
  );
}
