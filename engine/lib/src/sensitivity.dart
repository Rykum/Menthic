import 'day.dart';
import 'traits.dart';
import 'engine.dart';

class Factor {
  final String label;
  final double delta; // variacao na estimativa vs baseline
  const Factor(this.label, this.delta);
  String get direction => delta >= 0 ? 'positivo' : 'negativo';
}

List<Factor> sensitivity(DayState state, TraitPriors priors, {int seed = 0}) {
  final base = predict(state, priors, seed: seed).estimate;
  final factors = <Factor>[];

  // Perturbacao 1: zerar o debito de sono.
  if (state.sleepDebt > 0) {
    final s2 = DayState(
      sleepDebt: 0.0,
      dayEnd: state.dayEnd,
      agenda: state.agenda,
    );
    factors.add(
      Factor('débito de sono', predict(s2, priors, seed: seed).estimate - base),
    );
  }

  // Perturbacao 2: adiantar o 1o compromisso para as 9h30 (proximo do pico).
  if (state.agenda.isNotEmpty) {
    final first = state.agenda.first;
    final moved = Commitment(
      id: first.id,
      start: 9.5,
      planned: first.planned,
      type: first.type,
      priority: first.priority,
      aversive: first.aversive,
    );
    final s3 = DayState(
      sleepDebt: state.sleepDebt,
      dayEnd: state.dayEnd,
      agenda: [moved, ...state.agenda.skip(1)],
    );
    factors.add(
      Factor(
        'horário do compromisso',
        predict(s3, priors, seed: seed).estimate - base,
      ),
    );
  }

  factors.sort((a, b) => b.delta.abs().compareTo(a.delta.abs()));
  return factors;
}
