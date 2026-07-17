import 'package:oracle_calibration/oracle_calibration.dart';
import 'package:test/test.dart';

void main() {
  test('n < minN => não julga', () {
    final r = evaluateGate(const [PredOutcome(0.9, 1), PredOutcome(0.1, 0)]);
    expect(r.passed, isFalse);
    expect(r.n, 2);
    expect(r.reason, contains('insuficiente'));
  });

  test('caso que PASSA (skillful e calibrado, n>=120)', () {
    final d = [
      ...List.filled(60, const PredOutcome(0.9, 1)),
      ...List.filled(60, const PredOutcome(0.1, 0)),
    ];
    final r = evaluateGate(d);
    expect(r.n, 120);
    expect(r.bss, greaterThanOrEqualTo(0.05));
    expect(r.calibrationInTheLarge, lessThan(0.05));
    expect(r.passed, isTrue);
  });

  test('caso que FALHA (sem skill, n>=120)', () {
    final d = [
      ...List.filled(60, const PredOutcome(0.5, 1)),
      ...List.filled(60, const PredOutcome(0.5, 0)),
    ];
    final r = evaluateGate(d);
    expect(r.n, 120);
    expect(r.bss, lessThan(0.05)); // BSS = 0
    expect(r.passed, isFalse);
  });

  test('FALHA só por calibração (tem skill, mal calibrado, n>=120)', () {
    final d = [
      ...List.filled(60, const PredOutcome(0.7, 1)),
      ...List.filled(60, const PredOutcome(0.6, 0)),
    ];
    final r = evaluateGate(d);
    expect(r.n, 120);
    expect(r.bss, greaterThanOrEqualTo(0.05)); // tem skill (bss=0.1)
    expect(
      r.calibrationInTheLarge,
      greaterThanOrEqualTo(0.05),
    ); // mal calibrado (0.15)
    expect(r.passed, isFalse); // reprovado pela calibração, não pelo skill
  });
}
