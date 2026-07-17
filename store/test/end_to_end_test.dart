import 'package:oracle_engine/oracle_engine.dart';
import 'package:oracle_store/oracle_store.dart';
import 'package:test/test.dart';

void main() {
  final date = DateTime.utc(2026, 7, 17);

  Future<InMemoryEventStore> seeded() async {
    final s = InMemoryEventStore();
    await s.append(sonoRegistrado(ts: DateTime.utc(2026, 7, 17, 7), horas: 5.0));
    await s.append(compromissoCriado(
      ts: DateTime.utc(2026, 7, 17, 8),
      cid: 'estudo',
      inicio: 14.0,
      durPrevista: 2.0,
      tipo: 'estudo',
      prioridade: 2,
      aversivo: true,
    ));
    return s;
  }

  test('pipeline eventos -> derivação -> motor -> OracleAnswer', () async {
    final store = await seeded();
    final ds = await const DayStateDeriver(DerivationConfig(dayEnd: 18.0))
        .derive(store, date);
    final ans = answerAgenda(ds, TraitPriors.neutral, observedDays: 20, seed: 42);

    expect(ds.sleepDebt, closeTo(2.0, 1e-9));
    expect(ans.estimate, inInclusiveRange(0.0, 1.0));
    expect(ans.low, lessThanOrEqualTo(ans.estimate));
    expect(ans.high, greaterThanOrEqualTo(ans.estimate));
    expect(ans.confidence, isA<Confidence>());
  });

  test('right-to-forget: apagar sono e re-derivar zera o sleepDebt', () async {
    final store = await seeded();
    await store.deleteWhere(types: [EventTypes.sonoRegistrado]);
    final ds = await const DayStateDeriver().derive(store, date);
    expect(ds.sleepDebt, 0.0);
    expect(ds.agenda.length, 1); // compromisso permanece
  });

  test('paridade: SQLite produz o mesmo DayState que memória', () async {
    final mem = await seeded();
    final sq = SqliteEventStore.memory();
    await sq.append(sonoRegistrado(ts: DateTime.utc(2026, 7, 17, 7), horas: 5.0));
    await sq.append(compromissoCriado(
      ts: DateTime.utc(2026, 7, 17, 8),
      cid: 'estudo',
      inicio: 14.0,
      durPrevista: 2.0,
      tipo: 'estudo',
      prioridade: 2,
      aversivo: true,
    ));
    final a = await const DayStateDeriver().derive(mem, date);
    final b = await const DayStateDeriver().derive(sq, date);
    expect(a.sleepDebt, b.sleepDebt);
    expect(a.agenda.length, b.agenda.length);
    expect(a.agenda.first.id, b.agenda.first.id);
    sq.dispose();
  });
}
