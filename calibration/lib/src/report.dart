import 'pred_outcome.dart';
import 'scoring.dart';
import 'gate.dart';

class CalibrationReport {
  final double brier, bss, calibrationInTheLarge;
  final int n;
  final List<ReliabilityBin> reliability;
  final MurphyDecomposition decomposition;
  final GateResult gate;
  const CalibrationReport({
    required this.brier,
    required this.bss,
    required this.calibrationInTheLarge,
    required this.n,
    required this.reliability,
    required this.decomposition,
    required this.gate,
  });
}

CalibrationReport buildReport(List<PredOutcome> d, {int bins = 10, int minN = 120}) {
  return CalibrationReport(
    brier: brierScore(d),
    bss: brierSkillScore(d),
    calibrationInTheLarge: calibrationInTheLarge(d),
    n: d.length,
    reliability: reliabilityDiagram(d, bins: bins),
    decomposition: murphy(d, bins: bins),
    gate: evaluateGate(d, minN: minN),
  );
}
