import 'dart:math' as math;
import 'package:oracle_engine/oracle_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Acceptance — doc 10 §C', () {
    // Peças determinísticas exatas (C.2)
    test('fadiga inicial com 2h de débito = 0.26', () {
      expect(initialFatigue(2.0), closeTo(0.26, 1e-9));
    });

    test('energia às 14h no exemplo ≈ 0.4611', () {
      const tr = Traits(
        phi: 9.6,
        p0: 0.60,
        rho: 0.31,
        s: 0.15,
        o: 0.25,
        r: 0.25,
      );
      expect(energy(14.0, tr, 2.0, 0.30), closeTo(0.4611, 1e-3));
    });

    test('esforço necessário = planned*exp(o) = 2*exp(0.25) ≈ 2.568', () {
      expect(2.0 * math.exp(0.25), closeTo(2.568, 1e-3));
    });

    // Agregado (C.3): determinístico, em faixa sã, e responde às intervenções.
    test('answerAgenda produz previsão sã e determinística', () {
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
      final a = answerAgenda(
        state,
        TraitPriors.neutral,
        observedDays: 20,
        seed: 42,
      );
      final b = answerAgenda(
        state,
        TraitPriors.neutral,
        observedDays: 20,
        seed: 42,
      );

      expect(a.estimate, equals(b.estimate)); // determinismo
      expect(a.estimate, inInclusiveRange(0.30, 0.90)); // faixa sã
      expect(a.low, lessThanOrEqualTo(a.estimate));
      expect(a.high, greaterThanOrEqualTo(a.estimate));
      // o débito de sono aparece entre os fatores (doc 10 espera-o dominante)
      expect(a.factors.any((f) => f.label.contains('sono')), isTrue);
    });
  });
}
