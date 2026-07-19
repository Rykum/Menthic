import 'package:test/test.dart';
import 'package:oracle_engine/oracle_engine.dart';

void main() {
  // Dia ruim de propósito: débito de sono alto (a energia decide a conclusão)
  // e o foco principal às 18h, longe do pico ~14h do prior neutro.
  const badDay = DayState(
    sleepDebt: 4.0,
    agenda: [
      Commitment(
        id: 'opcional',
        start: 10.0,
        planned: 1.0,
        type: 'foco',
        priority: 1,
      ),
      Commitment(id: 'estudo', start: 18.0, planned: 2.5, type: 'foco'),
    ],
  );

  test('dia ruim gera estratégias com delta positivo e labels prontos', () {
    final s = suggestStrategies(badDay, TraitPriors.neutral);
    expect(s, isNotEmpty);
    expect(s.length, lessThanOrEqualTo(3));
    for (final st in s) {
      expect(st.delta, greaterThan(0.01));
      expect(st.label, isNotEmpty);
    }
    final ids = s.map((x) => x.id).toSet();
    expect(ids, contains('mover_pico'));
    expect(ids, contains('menos_debito_sono'));
  });

  test('ordenadas por delta desc', () {
    final s = suggestStrategies(badDay, TraitPriors.neutral);
    for (var i = 1; i < s.length; i++) {
      expect(s[i - 1].delta, greaterThanOrEqualTo(s[i].delta));
    }
  });

  test('determinístico com o mesmo seed', () {
    final a = suggestStrategies(badDay, TraitPriors.neutral, seed: 7);
    final b = suggestStrategies(badDay, TraitPriors.neutral, seed: 7);
    expect(a.length, b.length);
    for (var i = 0; i < a.length; i++) {
      expect(a[i].id, b[i].id);
      expect(a[i].delta, b[i].delta);
    }
  });

  test('sem débito e com um único compromisso, não sugere sono nem corte', () {
    const okDay = DayState(
      sleepDebt: 0.0,
      agenda: [
        Commitment(id: 'estudo', start: 14.0, planned: 2.0, type: 'foco'),
      ],
    );
    final s = suggestStrategies(okDay, TraitPriors.neutral);
    final ids = s.map((x) => x.id).toSet();
    expect(ids.contains('menos_debito_sono'), false);
    expect(ids.contains('cortar_menor_prioridade'), false);
  });

  test('agenda vazia não explode e não sugere mover/cortar', () {
    const empty = DayState(sleepDebt: 2.0, agenda: []);
    final s = suggestStrategies(empty, TraitPriors.neutral);
    final ids = s.map((x) => x.id).toSet();
    expect(ids.contains('mover_pico'), false);
    expect(ids.contains('cortar_menor_prioridade'), false);
  });
}
