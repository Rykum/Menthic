import 'package:oracle_store/oracle_store.dart';
import 'pred_outcome.dart';

EventDraft previsaoEmitida({
  required DateTime ts,
  required String cid,
  required double p,
  String origin = 'motor',
}) => EventDraft(
  ts: ts,
  type: EventTypes.previsaoEmitida,
  origin: origin,
  payload: {'cid': cid, 'p': p},
);

class CalibrationExtractor {
  const CalibrationExtractor();

  String _key(DateTime ts, String cid) {
    final d = ts.toUtc();
    return '${d.year}-${d.month}-${d.day}|$cid';
  }

  Future<List<PredOutcome>> extract(EventStore store) async {
    final events = await store.all();

    final outcomes = <String, int>{};
    for (final e in events) {
      if (e.type == EventTypes.tarefaConcluida) {
        outcomes[_key(e.ts, e.payload['cid'] as String)] = 1;
      } else if (e.type == EventTypes.tarefaNaoConcluida) {
        outcomes[_key(e.ts, e.payload['cid'] as String)] = 0;
      }
    }

    final pairs = <PredOutcome>[];
    for (final e in events) {
      if (e.type == EventTypes.previsaoEmitida) {
        final o = outcomes[_key(e.ts, e.payload['cid'] as String)];
        if (o != null) {
          pairs.add(PredOutcome((e.payload['p'] as num).toDouble(), o));
        }
      }
    }
    return pairs;
  }
}
