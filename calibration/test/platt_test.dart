import 'package:oracle_calibration/oracle_calibration.dart';
import 'package:test/test.dart';

void main() {
  test('apply é monótona em p (a=1,b=0)', () {
    const c = PlattCalibrator(1.0, 0.0);
    expect(c.apply(0.2), lessThan(c.apply(0.8)));
    expect(c.apply(0.5), inInclusiveRange(0.0, 1.0));
  });

  test('fit é determinístico', () {
    final d = [
      ...List.filled(50, const PredOutcome(0.8, 1)),
      ...List.filled(50, const PredOutcome(0.8, 0)),
    ];
    final a = PlattCalibrator.fit(d);
    final b = PlattCalibrator.fit(d);
    expect(a.a, equals(b.a));
    expect(a.b, equals(b.b));
  });

  test('recalibração reduz o viés sistemático', () {
    // Todas as previsões dizem 0.8, mas a taxa real é 0.5 (viés de +0.3).
    final d = [
      ...List.filled(50, const PredOutcome(0.8, 1)),
      ...List.filled(50, const PredOutcome(0.8, 0)),
    ];
    final cal = PlattCalibrator.fit(d);
    final recal = d.map((x) => PredOutcome(cal.apply(x.p), x.o)).toList();
    expect(calibrationInTheLarge(recal), lessThan(calibrationInTheLarge(d)));
  });
}
