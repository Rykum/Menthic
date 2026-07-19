import 'package:flutter_test/flutter_test.dart';
import 'package:oracle_store/oracle_store.dart';
import 'package:menthic/features/calibration/pairing.dart';

Event _e(int id, DateTime ts, String type, Map<String, dynamic> payload) =>
    Event(id: id, ts: ts, type: type, payload: payload, origin: 'manual');

void main() {
  final d1 = DateTime.utc(2026, 7, 10, 9);
  final d2 = DateTime.utc(2026, 7, 11, 9);

  test('dia completo: previsão + todos prio>=2 concluídos → outcome 1', () {
    final events = [
      _e(1, d1, EventTypes.compromissoCriado, {'cid': 'a', 'prioridade': 2}),
      _e(2, d1, EventTypes.previsaoEmitida, {'estimate': 0.8}),
      _e(3, d1.add(const Duration(hours: 10)), EventTypes.tarefaConcluida, {
        'cid': 'a',
        'atraso_min': 0,
      }),
    ];
    final pairs = pairPredictions(events);
    expect(pairs.length, 1);
    expect(pairs.single.predicted, 0.8);
    expect(pairs.single.outcome, 1);
  });

  test('prio>=2 não concluída → outcome 0; prio 1 é ignorada', () {
    final events = [
      _e(1, d1, EventTypes.compromissoCriado, {'cid': 'a', 'prioridade': 2}),
      _e(2, d1, EventTypes.compromissoCriado, {'cid': 'b', 'prioridade': 1}),
      _e(3, d1, EventTypes.previsaoEmitida, {'estimate': 0.7}),
      _e(4, d1.add(const Duration(hours: 10)), EventTypes.tarefaNaoConcluida, {
        'cid': 'a',
      }),
    ];
    final pairs = pairPredictions(events);
    expect(pairs.single.outcome, 0);
  });

  test('dia sem desfecho algum é ignorado; usa a última previsão do dia', () {
    final events = [
      // d1: duas previsões, com desfecho — vale a última (0.6)
      _e(1, d1, EventTypes.compromissoCriado, {'cid': 'a', 'prioridade': 2}),
      _e(2, d1, EventTypes.previsaoEmitida, {'estimate': 0.9}),
      _e(3, d1.add(const Duration(hours: 1)), EventTypes.previsaoEmitida, {
        'estimate': 0.6,
      }),
      _e(4, d1.add(const Duration(hours: 10)), EventTypes.tarefaConcluida, {
        'cid': 'a',
        'atraso_min': 0,
      }),
      // d2: previsão sem nenhum desfecho — ignorado
      _e(5, d2, EventTypes.compromissoCriado, {'cid': 'c', 'prioridade': 2}),
      _e(6, d2, EventTypes.previsaoEmitida, {'estimate': 0.5}),
    ];
    final pairs = pairPredictions(events);
    expect(pairs.length, 1);
    expect(pairs.single.predicted, 0.6);
    expect(pairs.single.day, DateTime.utc(2026, 7, 10));
  });
}
