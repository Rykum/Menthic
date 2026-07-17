import 'package:oracle_calibration/oracle_calibration.dart';
import 'package:test/test.dart';

void main() {
  test('buildReport agrega scoring, decomposição e gate', () {
    const d = [
      PredOutcome(0.8, 1),
      PredOutcome(0.6, 0),
      PredOutcome(0.3, 0),
      PredOutcome(0.9, 1),
    ];
    final r = buildReport(d);
    expect(r.n, 4);
    expect(r.brier, closeTo(0.125, 1e-12));
    expect(r.bss, closeTo(0.5, 1e-12));
    expect(r.reliability.length, 10);
    expect(r.gate.passed, isFalse); // n < 120
    expect(r.gate.reason, contains('insuficiente'));
  });
}
