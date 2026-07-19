import 'package:oracle_store/oracle_store.dart';

/// Um dia com previsão emitida e desfecho observado.
class DayPair {
  final DateTime day; // meia-noite UTC
  final double predicted;
  final int outcome; // 1 = cumpriu a agenda (prio >= 2), 0 = não
  const DayPair({
    required this.day,
    required this.predicted,
    required this.outcome,
  });
}

/// Pareia, por dia UTC, a última `previsao_emitida` com o desfecho real:
/// cumpriu = todo compromisso de prioridade >= 2 do dia tem `tarefa_concluida`.
/// Dias sem previsão ou sem nenhum evento de desfecho são ignorados.
List<DayPair> pairPredictions(List<Event> events) {
  DateTime dayOf(Event e) {
    final ts = e.ts.toUtc();
    return DateTime.utc(ts.year, ts.month, ts.day);
  }

  final byDay = <DateTime, List<Event>>{};
  for (final e in events) {
    byDay.putIfAbsent(dayOf(e), () => []).add(e);
  }

  final pairs = <DayPair>[];
  final days = byDay.keys.toList()..sort();
  for (final day in days) {
    final dayEvents = byDay[day]!..sort((a, b) => a.ts.compareTo(b.ts));

    Event? lastPrediction;
    final required = <String>{};
    final concluded = <String>{};
    var hasOutcome = false;
    for (final e in dayEvents) {
      switch (e.type) {
        case EventTypes.previsaoEmitida:
          lastPrediction = e;
        case EventTypes.compromissoCriado:
          final prio = (e.payload['prioridade'] as num?)?.toInt() ?? 2;
          if (prio >= 2) required.add(e.payload['cid'] as String);
        case EventTypes.tarefaConcluida:
          concluded.add(e.payload['cid'] as String);
          hasOutcome = true;
        case EventTypes.tarefaNaoConcluida:
          hasOutcome = true;
      }
    }
    if (lastPrediction == null || !hasOutcome) continue;

    final met = required.every(concluded.contains);
    pairs.add(
      DayPair(
        day: day,
        predicted: (lastPrediction.payload['estimate'] as num).toDouble(),
        outcome: met ? 1 : 0,
      ),
    );
  }
  return pairs;
}
