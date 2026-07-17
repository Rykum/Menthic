import 'package:oracle_engine/oracle_engine.dart';
import 'package:oracle_store/oracle_store.dart';
import 'package:test/test.dart';

void main() {
  final date = DateTime.utc(2026, 7, 17);

  Future<InMemoryEventStore> seeded() async {
    final s = InMemoryEventStore();
    await s.append(
      sonoRegistrado(ts: DateTime.utc(2026, 7, 17, 7), horas: 5.0),
    );
    await s.append(
      compromissoCriado(
        ts: DateTime.utc(2026, 7, 17, 8),
        cid: 'estudo',
        inicio: 14.0,
        durPrevista: 2.0,
        tipo: 'estudo',
        prioridade: 2,
        aversivo: true,
      ),
    );
    return s;
  }

  test('deriva sleepDebt = meta - horas dormidas', () async {
    final store = await seeded();
    final ds = await const DayStateDeriver().derive(store, date);
    expect(ds.sleepDebt, closeTo(2.0, 1e-9)); // 7 - 5
  });

  test('deriva a agenda a partir dos compromissos', () async {
    final store = await seeded();
    final ds = await const DayStateDeriver().derive(store, date);
    expect(ds.agenda.length, 1);
    final Commitment c = ds.agenda.first;
    expect(c.id, 'estudo');
    expect(c.start, 14.0);
    expect(c.planned, 2.0);
    expect(c.aversive, isTrue);
  });

  test('sem sono registrado, sleepDebt = 0', () async {
    final store = InMemoryEventStore();
    final ds = await const DayStateDeriver().derive(store, date);
    expect(ds.sleepDebt, 0.0);
    expect(ds.agenda, isEmpty);
  });

  test('usa dayEnd do config', () async {
    final store = await seeded();
    final ds = await const DayStateDeriver(
      DerivationConfig(dayEnd: 18.0),
    ).derive(store, date);
    expect(ds.dayEnd, 18.0);
  });
}
