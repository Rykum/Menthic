import 'package:oracle_calibration/oracle_calibration.dart';
import 'package:test/test.dart';

void main() {
  // Exemplo com valores exatos calculados à mão.
  const d = [
    PredOutcome(0.8, 1),
    PredOutcome(0.6, 0),
    PredOutcome(0.3, 0),
    PredOutcome(0.9, 1),
  ];

  test('brierScore = 0.125', () {
    expect(brierScore(d), closeTo(0.125, 1e-12));
  });

  test('baseRate = 0.5', () {
    expect(baseRate(d), closeTo(0.5, 1e-12));
  });

  test('brierBaseline = 0.25', () {
    expect(brierBaseline(d), closeTo(0.25, 1e-12));
  });

  test('brierSkillScore = 0.5', () {
    expect(brierSkillScore(d), closeTo(0.5, 1e-12));
  });

  test('calibrationInTheLarge = 0.15', () {
    expect(calibrationInTheLarge(d), closeTo(0.15, 1e-12));
  });

  test('lista vazia => NaN; baseline 0 => BSS NaN', () {
    expect(brierScore(const []), isNaN);
    // todos os desfechos iguais => baseline 0 => BSS indefinido
    expect(
      brierSkillScore(const [PredOutcome(0.4, 1), PredOutcome(0.6, 1)]),
      isNaN,
    );
  });
}
