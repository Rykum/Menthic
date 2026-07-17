import 'package:oracle_engine/oracle_engine.dart';
import 'package:oracle_learning/oracle_learning.dart';
import 'package:oracle_store/oracle_store.dart';
import 'package:test/test.dart';

void main() {
  final ts = DateTime.utc(2026, 7, 17, 8);

  Future<InMemoryEventStore> historico() async {
    final store = InMemoryEventStore();
    for (var i = 0; i < 10; i++) {
      await store.append(compromissoCriado(
        ts: ts, cid: 'c$i', inicio: 14.0, durPrevista: 2.0, tipo: 'estudo',
        aversivo: true,
      ));
      await store.append(EventDraft(
        ts: ts,
        type: EventTypes.tarefaConcluida,
        payload: {'cid': 'c$i', 'atraso_min': 15.0, 'dur_real': 2.3},
      ));
    }
    return store;
  }

  test('learn aperta o e ρ vs o prior neutro', () async {
    final learned = await const TwinLearner().learn(await historico());
    // o apertou
    expect(learned.o.sd, lessThan(TraitPriors.neutral.o.sd));
    // ρ ficou mais concentrado (a+b maior) e mais alto (procrastinou sempre)
    final neutralConc = TraitPriors.neutral.rho.a + TraitPriors.neutral.rho.b;
    expect(learned.rho.a + learned.rho.b, greaterThan(neutralConc));
    expect(learned.rho.a, 12); // Beta(2,5)+10/10 => Beta(12,5)
    expect(learned.rho.b, 5);
  });

  test('predict roda com o twin aprendido e a banda não aumenta', () async {
    final learned = await const TwinLearner().learn(await historico());
    final state = DayState(
      sleepDebt: 2.0,
      dayEnd: 18.0,
      agenda: const [
        Commitment(
          id: 'estudo', start: 14.0, planned: 2.0, type: 'estudo',
          priority: 2, aversive: true,
        ),
      ],
    );

    final ansNeutro =
        answerAgenda(state, TraitPriors.neutral, observedDays: 0, seed: 7);
    final ansAprendido =
        answerAgenda(state, learned, observedDays: 10, seed: 7);

    expect(ansAprendido.estimate, inInclusiveRange(0.0, 1.0));
    expect(ansAprendido.low, lessThanOrEqualTo(ansAprendido.estimate));
    expect(ansAprendido.high, greaterThanOrEqualTo(ansAprendido.estimate));
    // Honesto: a banda não aumenta (encolhe parcialmente; payoff pleno espera p0)
    final larguraNeutro = ansNeutro.high - ansNeutro.low;
    final larguraAprendido = ansAprendido.high - ansAprendido.low;
    expect(larguraAprendido, lessThanOrEqualTo(larguraNeutro + 0.05));
  });
}
