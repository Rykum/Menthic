import 'dart:math' as math;
import 'package:oracle_learning/oracle_learning.dart';
import 'package:oracle_store/oracle_store.dart';
import 'package:test/test.dart';

void main() {
  final ts = DateTime.utc(2026, 7, 17, 8);

  EventDraft concluidaComDuracao({
    required String cid,
    required double durReal,
    required double atrasoMin,
  }) => EventDraft(
    ts: ts,
    type: EventTypes.tarefaConcluida,
    payload: {'cid': cid, 'atraso_min': atrasoMin, 'dur_real': durReal},
  );

  test('extrai o = ln(dur_real/dur_prevista) e conta ρ', () async {
    final store = InMemoryEventStore();
    // tarefa aversiva, planejada 2.0, real 2.5, atrasou
    await store.append(
      compromissoCriado(
        ts: ts,
        cid: 'estudo',
        inicio: 14.0,
        durPrevista: 2.0,
        tipo: 'estudo',
        aversivo: true,
      ),
    );
    await store.append(
      concluidaComDuracao(cid: 'estudo', durReal: 2.5, atrasoMin: 20),
    );

    final obs = await const ObservableExtractor().extract(store);
    expect(obs.o.length, 1);
    expect(obs.o.first, closeTo(math.log(2.5 / 2.0), 1e-12));
    expect(obs.rhoTentativas, 1);
    expect(obs.rhoSucessos, 1); // atraso 20 > 0
  });

  test(
    'tarefa sem dur_real é ignorada para o; não-aversiva não conta ρ',
    () async {
      final store = InMemoryEventStore();
      await store.append(
        compromissoCriado(
          ts: ts,
          cid: 'trab',
          inicio: 9.0,
          durPrevista: 1.0,
          tipo: 'trabalho',
          aversivo: false,
        ),
      );
      // conclusão SEM dur_real (helper padrão do store)
      await store.append(tarefaConcluida(ts: ts, cid: 'trab', atrasoMin: 0));

      final obs = await const ObservableExtractor().extract(store);
      expect(obs.o, isEmpty); // sem dur_real
      expect(obs.rhoTentativas, 0); // não-aversiva
    },
  );
}
