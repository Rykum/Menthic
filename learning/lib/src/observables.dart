import 'dart:math' as math;
import 'package:oracle_store/oracle_store.dart';

class TraitObservations {
  final List<double> o;
  final int rhoSucessos, rhoTentativas;
  const TraitObservations(this.o, this.rhoSucessos, this.rhoTentativas);
}

class ObservableExtractor {
  const ObservableExtractor();

  Future<TraitObservations> extract(EventStore store) async {
    final events = await store.all();

    final planned = <String, double>{};
    final aversive = <String, bool>{};
    for (final e in events) {
      if (e.type == EventTypes.compromissoCriado) {
        final cid = e.payload['cid'] as String;
        planned[cid] = (e.payload['dur_prevista'] as num).toDouble();
        aversive[cid] = (e.payload['aversivo'] as bool?) ?? false;
      }
    }

    final oObs = <double>[];
    var rhoSucessos = 0, rhoTentativas = 0;
    for (final e in events) {
      if (e.type != EventTypes.tarefaConcluida) continue;
      final cid = e.payload['cid'] as String;

      final durReal = e.payload['dur_real'];
      final dp = planned[cid];
      if (durReal != null && dp != null) {
        final dr = (durReal as num).toDouble();
        if (dr > 0 && dp > 0) oObs.add(math.log(dr / dp));
      }

      if (aversive[cid] == true) {
        rhoTentativas += 1;
        final atraso = (e.payload['atraso_min'] as num?)?.toDouble() ?? 0.0;
        if (atraso > 0) rhoSucessos += 1;
      }
    }
    return TraitObservations(oObs, rhoSucessos, rhoTentativas);
  }
}
