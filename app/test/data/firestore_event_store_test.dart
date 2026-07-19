import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracle_store/oracle_store.dart';
import 'package:menthic/data/firestore_event_store.dart';

void main() {
  late FirestoreEventStore store;

  setUp(() {
    store = FirestoreEventStore(FakeFirebaseFirestore(), 'uid1');
  });

  EventDraft sono(DateTime ts, double horas) => EventDraft(
    ts: ts,
    type: EventTypes.sonoRegistrado,
    payload: {'horas': horas},
  );

  test('append + all preservam ordem, tipo e payload', () async {
    await store.append(sono(DateTime.utc(2026, 7, 10, 8), 6.0));
    await store.append(sono(DateTime.utc(2026, 7, 11, 8), 7.5));
    final events = await store.all();
    expect(events.length, 2);
    expect(events.first.ts.isBefore(events.last.ts), true);
    expect(events.first.type, EventTypes.sonoRegistrado);
    expect((events.last.payload['horas'] as num).toDouble(), 7.5);
  });

  test('query filtra por janela e por tipo', () async {
    await store.append(sono(DateTime.utc(2026, 7, 10, 8), 6.0));
    await store.append(sono(DateTime.utc(2026, 7, 11, 8), 7.0));
    await store.append(
      EventDraft(
        ts: DateTime.utc(2026, 7, 11, 9),
        type: EventTypes.compromissoCriado,
        payload: {'cid': 'x', 'inicio': 9.0, 'dur_prevista': 1.0},
      ),
    );

    final dia11 = await store.query(
      from: DateTime.utc(2026, 7, 11),
      to: DateTime.utc(2026, 7, 12),
    );
    expect(dia11.length, 2);

    final sonos = await store.query(types: [EventTypes.sonoRegistrado]);
    expect(sonos.length, 2);
  });

  test(
    'appends em rajada geram ids únicos (regressão do relógio grosso)',
    () async {
      final ids = <int>{};
      for (var i = 0; i < 50; i++) {
        final e = await store.append(sono(DateTime.utc(2026, 7, 10, 8), 6.0));
        ids.add(e.id);
      }
      expect(ids.length, 50);
    },
  );

  test('deleteById remove e clear zera', () async {
    final e = await store.append(sono(DateTime.utc(2026, 7, 10, 8), 6.0));
    await store.append(sono(DateTime.utc(2026, 7, 11, 8), 7.0));
    await store.deleteById(e.id);
    expect((await store.all()).length, 1);
    await store.clear();
    expect(await store.all(), isEmpty);
  });
}
