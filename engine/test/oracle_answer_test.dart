import 'package:oracle_engine/oracle_engine.dart';
import 'package:test/test.dart';

void main() {
  test('confidenceFromWidth mapeia larguras para rótulos', () {
    expect(confidenceFromWidth(0.05), equals(Confidence.alta));
    expect(confidenceFromWidth(0.10), equals(Confidence.media));
    expect(confidenceFromWidth(0.15), equals(Confidence.media));
    expect(confidenceFromWidth(0.20), equals(Confidence.baixa));
    expect(confidenceFromWidth(0.30), equals(Confidence.baixa));
  });

  test('answerAgenda monta um OracleAnswer coerente', () {
    final state = DayState(
      sleepDebt: 2.0,
      dayEnd: 18.0,
      agenda: const [
        Commitment(
          id: 'estudo',
          start: 14.0,
          planned: 2.0,
          type: 'estudo',
          priority: 2,
          aversive: true,
        ),
      ],
    );
    final ans = answerAgenda(
      state,
      TraitPriors.neutral,
      observedDays: 20,
      seed: 42,
    );
    expect(ans.estimate, inInclusiveRange(0.0, 1.0));
    expect(ans.low, lessThanOrEqualTo(ans.estimate));
    expect(ans.high, greaterThanOrEqualTo(ans.estimate));
    expect(ans.factors, isNotEmpty);
    expect(ans.limitations, isNotEmpty); // 20 dias => cita limitacao de dados
  });
}
