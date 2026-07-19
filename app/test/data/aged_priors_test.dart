import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menthic/data/aged_priors.dart';
import 'package:menthic/data/persistent_event_store.dart';
import 'package:menthic/data/providers.dart';

const _learnedPriors = {
  'phi': {'mean': 10.0, 'sd': 2.5},
  'p0': {'a': 6, 'b': 4},
  'rho': {'a': 12.0, 'b': 4.0},
  's': {'shape': 3, 'scale': 0.05},
  'o': {'mean': 0.40, 'sd': 0.05},
  'r': {'shape': 5, 'scale': 0.05},
};

void main() {
  test('sem desfecho nenhum: priors crus (sem decay)', () async {
    SharedPreferences.setMockInitialValues({
      kPriorsKey: jsonEncode(_learnedPriors),
    });
    final prefs = await SharedPreferences.getInstance();
    final store = await PersistentEventStore.open(prefs);
    final p = await loadAgedPriors(store, PriorsRepo());
    expect(p.rho.a, 12.0);
    expect(p.o.mean, 0.40);
  });

  test(
    'desfecho há 90 dias (meia-vida): hiperparâmetros no ponto médio',
    () async {
      final now = DateTime.utc(2026, 7, 19, 12);
      final old = now.subtract(const Duration(days: 90));
      SharedPreferences.setMockInitialValues({
        kPriorsKey: jsonEncode(_learnedPriors),
        PersistentEventStore.storageKey: jsonEncode([
          {
            'ts': old.toIso8601String(),
            'type': 'tarefa_concluida',
            'payload': {'cid': 'x', 'atraso_min': 0},
            'origin': 'manual',
          },
        ]),
      });
      final prefs = await SharedPreferences.getInstance();
      final store = await PersistentEventStore.open(prefs);
      final p = await loadAgedPriors(store, PriorsRepo(), now: now);
      expect(p.rho.a, closeTo((12 + 2) / 2, 1e-9));
      expect(p.o.mean, closeTo((0.40 + 0.20) / 2, 1e-9));
    },
  );

  test('desfecho de hoje: praticamente sem decay', () async {
    final now = DateTime.utc(2026, 7, 19, 12);
    SharedPreferences.setMockInitialValues({
      kPriorsKey: jsonEncode(_learnedPriors),
      PersistentEventStore.storageKey: jsonEncode([
        {
          'ts': now.toIso8601String(),
          'type': 'tarefa_nao_concluida',
          'payload': {'cid': 'x'},
          'origin': 'manual',
        },
      ]),
    });
    final prefs = await SharedPreferences.getInstance();
    final store = await PersistentEventStore.open(prefs);
    final p = await loadAgedPriors(store, PriorsRepo(), now: now);
    expect(p.rho.a, closeTo(12.0, 1e-6));
  });
}
