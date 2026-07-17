import 'package:oracle_engine/oracle_engine.dart';
import 'event_store.dart';
import 'events_phase0.dart';

class DerivationConfig {
  final double metaSonoHoras;
  final double dayEnd;
  const DerivationConfig({this.metaSonoHoras = 7.0, this.dayEnd = 24.0});
}

class DayStateDeriver {
  final DerivationConfig config;
  const DayStateDeriver([this.config = const DerivationConfig()]);

  Future<DayState> derive(EventStore store, DateTime date) async {
    final from = DateTime.utc(date.year, date.month, date.day);
    final to = from.add(const Duration(days: 1));
    final events = await store.query(from: from, to: to);

    var sleepDebt = 0.0;
    final sonos = events
        .where((e) => e.type == EventTypes.sonoRegistrado)
        .toList();
    if (sonos.isNotEmpty) {
      final horas = (sonos.last.payload['horas'] as num).toDouble();
      final debt = config.metaSonoHoras - horas;
      sleepDebt = debt < 0 ? 0.0 : debt;
    }

    final agenda = events
        .where((e) => e.type == EventTypes.compromissoCriado)
        .map((e) {
          final p = e.payload;
          return Commitment(
            id: p['cid'] as String,
            start: (p['inicio'] as num).toDouble(),
            planned: (p['dur_prevista'] as num).toDouble(),
            type: p['tipo'] as String,
            priority: (p['prioridade'] as num?)?.toInt() ?? 2,
            aversive: (p['aversivo'] as bool?) ?? false,
          );
        })
        .toList();

    return DayState(
      sleepDebt: sleepDebt,
      dayEnd: config.dayEnd,
      agenda: agenda,
    );
  }
}
