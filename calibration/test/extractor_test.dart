import 'package:oracle_calibration/oracle_calibration.dart';
import 'package:oracle_store/oracle_store.dart';
import 'package:test/test.dart';

void main() {
  final day = DateTime.utc(2026, 7, 17, 8);

  test('pareia previsão com desfecho por (cid, dia)', () async {
    final store = InMemoryEventStore();
    await store.append(previsaoEmitida(ts: day, cid: 'estudo', p: 0.7));
    await store.append(tarefaConcluida(ts: day, cid: 'estudo', atrasoMin: 0));
    await store.append(previsaoEmitida(ts: day, cid: 'treino', p: 0.4));
    await store.append(
      EventDraft(
        ts: day,
        type: EventTypes.tarefaNaoConcluida,
        payload: const {'cid': 'treino'},
      ),
    );

    final pairs = await const CalibrationExtractor().extract(store);
    expect(pairs.length, 2);
    final estudo = pairs.firstWhere((x) => x.p == 0.7);
    expect(estudo.o, 1);
    final treino = pairs.firstWhere((x) => x.p == 0.4);
    expect(treino.o, 0);
  });

  test('previsão sem desfecho é ignorada', () async {
    final store = InMemoryEventStore();
    await store.append(previsaoEmitida(ts: day, cid: 'estudo', p: 0.7));
    final pairs = await const CalibrationExtractor().extract(store);
    expect(pairs, isEmpty);
  });

  test('previsaoEmitida monta o draft correto', () {
    final d = previsaoEmitida(ts: day, cid: 'estudo', p: 0.63);
    expect(d.type, EventTypes.previsaoEmitida);
    expect(d.payload['cid'], 'estudo');
    expect(d.payload['p'], 0.63);
    expect(d.origin, 'motor');
  });
}
