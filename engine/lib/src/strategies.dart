import 'day.dart';
import 'traits.dart';
import 'oracle_answer.dart';

/// Uma estratégia sugerida: perturbação do dia avaliada pelo próprio
/// simulador. Nenhum número inventado — `answer` é um OracleAnswer completo.
class Strategy {
  final String id;
  final String label;
  final OracleAnswer answer;
  final double delta; // answer.estimate − baseline.estimate
  const Strategy({
    required this.id,
    required this.label,
    required this.answer,
    required this.delta,
  });
}

/// Busca local sobre o simulador (doc 06 §6, "Se seu objetivo é terminar
/// tudo"): candidatos gerados por heurísticas, avaliados por answerAgenda
/// com o MESMO seed do baseline (comparação pareada → deltas determinísticos
/// e com menos ruído Monte Carlo). Só entram deltas > 0.01; máx. [max].
List<Strategy> suggestStrategies(
  DayState state,
  TraitPriors priors, {
  int observedDays = 0,
  int seed = 0,
  int max = 3,
}) {
  final baseline = answerAgenda(
    state,
    priors,
    observedDays: observedDays,
    seed: seed,
  );

  final candidates = <(String, String, DayState)>[];

  DayState withAgenda(List<Commitment> agenda) => DayState(
    sleepDebt: state.sleepDebt,
    dayEnd: state.dayEnd,
    agenda: agenda,
  );

  // 1. Mover o foco mais longo para o pico circadiano do usuário.
  Commitment? focus;
  for (final c in state.agenda) {
    if (c.type == 'foco' && (focus == null || c.planned > focus.planned)) {
      focus = c;
    }
  }
  if (focus != null) {
    final peak = priors.phi.mean;
    if ((focus.start - peak).abs() >= 1.0) {
      final moved = [
        for (final c in state.agenda)
          if (c.id == focus.id)
            Commitment(
              id: c.id,
              start: peak,
              planned: c.planned,
              type: c.type,
              priority: c.priority,
              aversive: c.aversive,
            )
          else
            c,
      ];
      candidates.add((
        'mover_pico',
        "mover '${focus.id}' para ~${peak.round()}h",
        withAgenda(moved),
      ));
    }
  }

  // 2. Cortar o compromisso de menor prioridade (se não for essencial).
  if (state.agenda.length >= 2) {
    var lowest = state.agenda.first;
    var maxPrio = state.agenda.first.priority;
    for (final c in state.agenda) {
      if (c.priority < lowest.priority) lowest = c;
      if (c.priority > maxPrio) maxPrio = c.priority;
    }
    if (lowest.priority < maxPrio) {
      final cut = [
        for (final c in state.agenda)
          if (c.id != lowest.id) c,
      ];
      candidates.add((
        'cortar_menor_prioridade',
        "cortar '${lowest.id}'",
        withAgenda(cut),
      ));
    }
  }

  // 3. Uma hora a menos de débito de sono.
  if (state.sleepDebt >= 1.0) {
    candidates.add((
      'menos_debito_sono',
      'com 1h a menos de débito de sono',
      DayState(
        sleepDebt: state.sleepDebt - 1.0,
        dayEnd: state.dayEnd,
        agenda: state.agenda,
      ),
    ));
  }

  final out = <Strategy>[];
  for (final (id, label, s) in candidates) {
    final answer = answerAgenda(
      s,
      priors,
      observedDays: observedDays,
      seed: seed,
    );
    final delta = answer.estimate - baseline.estimate;
    if (delta > 0.01) {
      out.add(Strategy(id: id, label: label, answer: answer, delta: delta));
    }
  }
  out.sort((a, b) => b.delta.compareTo(a.delta));
  return out.take(max).toList();
}
