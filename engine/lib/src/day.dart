import 'dart:math' as math;
import 'rng.dart';
import 'traits.dart';
import 'model.dart';

class Commitment {
  final String id;
  final double start;
  final double planned;
  final String type;
  final int priority;
  final bool aversive;
  const Commitment({
    required this.id,
    required this.start,
    required this.planned,
    required this.type,
    this.priority = 2,
    this.aversive = false,
  });
}

class DayState {
  final double sleepDebt;
  final double dayEnd;
  final List<Commitment> agenda;
  const DayState({
    required this.sleepDebt,
    this.dayEnd = 24.0,
    required this.agenda,
  });
}

class DayOutcome {
  final Map<String, bool> completed;
  final bool metAgenda;
  final double finalFatigue;
  const DayOutcome(this.completed, this.metAgenda, this.finalFatigue);
}

DayOutcome simulateDay(DayState state, Traits tr, SeededRng rng) {
  final agenda = [...state.agenda]..sort((a, b) => a.start.compareTo(b.start));
  var fatigue = initialFatigue(state.sleepDebt);
  final completed = <String, bool>{};

  for (var i = 0; i < agenda.length; i++) {
    final c = agenda[i];
    final windowEnd = (i + 1 < agenda.length)
        ? agenda[i + 1].start
        : state.dayEnd;
    var t = c.start;

    // Procrastinacao: tarefa aversiva atrasa o inicio (media 30 min).
    if (c.aversive && rng.nextBernoulli(tr.rho)) {
      t += rng.nextExponential(2.0);
    }

    final effortNeeded = c.planned * math.exp(tr.o);
    var work = 0.0;
    var focusing = true;

    while (t < windowEnd && work < effortNeeded) {
      final e = energy(t, tr, state.sleepDebt, fatigue);
      if (focusing) {
        final dur = math.min(
          rng.nextLogNormal(math.log(0.5), 0.5),
          windowEnd - t,
        );
        work += ModelConstants.kWork * tr.p0 * e * dur;
        fatigue = fatigueStep(fatigue, activityAlpha['foco']!, 0.0, dur);
        t += dur;
        final pDistract = logistic(-1.0 + 2.0 * (1.0 - e));
        focusing = !rng.nextBernoulli(pDistract);
      } else {
        final dur = math.min(
          rng.nextLogNormal(math.log(8.0 / 60.0), 0.5),
          windowEnd - t,
        );
        fatigue = fatigueStep(fatigue, 0.0, tr.r, dur);
        t += dur;
        focusing = true;
      }
    }
    completed[c.id] = work >= effortNeeded;
  }

  final metAgenda = agenda
      .where((c) => c.priority >= 2)
      .every((c) => completed[c.id] ?? false);
  return DayOutcome(completed, metAgenda, fatigue);
}
