import 'dart:math' as math;
// ignore: unused_import
import 'package:oracle_engine/oracle_engine.dart';
import 'package:oracle_learning/oracle_learning.dart';
import 'package:oracle_store/oracle_store.dart';
import 'package:test/test.dart';

void main() {
  final ts = DateTime.utc(2026, 7, 17, 8);

  test('learn atualiza o e ρ; mantém p0/phi/s/r do prior', () async {
    final store = InMemoryEventStore();
    // 1 tarefa aversiva planejada 2.0, real 2.0 (o obs = ln(1)=0), atraso 0
    await store.append(
      compromissoCriado(
        ts: ts,
        cid: 'e',
        inicio: 14.0,
        durPrevista: 2.0,
        tipo: 'estudo',
        aversivo: true,
      ),
    );
    await store.append(
      EventDraft(
        ts: ts,
        type: EventTypes.tarefaConcluida,
        payload: const {'cid': 'e', 'atraso_min': 0.0, 'dur_real': 2.0},
      ),
    );

    final learned = await const TwinLearner().learn(store);

    // o: N(0.20,0.01) + [0.0], sigma2=0.25 => postVar=1/104, postMean=20/104
    expect(learned.o.mean, closeTo(20 / 104, 1e-12));
    expect(learned.o.sd, closeTo(math.sqrt(1 / 104), 1e-12));
    expect(learned.o.sd, lessThan(0.10)); // apertou vs prior neutro

    // ρ: Beta(2,5).update(0,1) => Beta(2,6)
    expect(learned.rho.a, 2);
    expect(learned.rho.b, 6);

    // resto igual ao prior neutro
    expect(learned.p0.a, 6);
    expect(learned.p0.b, 4);
    expect(learned.phi.mean, 14.0);
    expect(learned.phi.sd, 2.5);
  });
}
