import 'package:oracle_engine/oracle_engine.dart';
import 'package:oracle_learning/oracle_learning.dart';
import 'package:oracle_store/oracle_store.dart';
import 'providers.dart';

/// Leitura dos priors com confiança adaptativa: quanto mais tempo desde o
/// último desfecho registrado, mais o modelo regride ao prior neutro
/// (agePriors, meia-vida 90 dias). Os priors salvos nunca são reescritos.
Future<TraitPriors> loadAgedPriors(
  EventStore store,
  PriorsRepo repo, {
  DateTime? now,
}) async {
  final priors = await repo.load();
  final outcomes = await store.query(
    types: [EventTypes.tarefaConcluida, EventTypes.tarefaNaoConcluida],
  );
  if (outcomes.isEmpty) return priors;

  final last = outcomes.map((e) => e.ts).reduce((a, b) => a.isAfter(b) ? a : b);
  final days = (now ?? DateTime.now().toUtc()).difference(last).inHours / 24.0;
  return agePriors(priors, daysSinceEvidence: days);
}
