import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oracle_store/oracle_store.dart';
import 'package:menthic/data/persistent_event_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  EventDraft sono(double horas) => EventDraft(
    ts: DateTime.utc(2026, 7, 18, 8),
    type: EventTypes.sonoRegistrado,
    payload: {'horas': horas},
  );

  test('append persiste: novo open hidrata os mesmos eventos', () async {
    final prefs = await SharedPreferences.getInstance();
    final s1 = await PersistentEventStore.open(prefs);
    await s1.append(sono(6.0));
    await s1.append(sono(7.5));

    final s2 = await PersistentEventStore.open(prefs);
    final events = await s2.all();
    expect(events.length, 2);
    expect(events.first.type, EventTypes.sonoRegistrado);
    expect((events.last.payload['horas'] as num).toDouble(), 7.5);
  });

  test('deleteById persiste', () async {
    final prefs = await SharedPreferences.getInstance();
    final s1 = await PersistentEventStore.open(prefs);
    final e = await s1.append(sono(6.0));
    await s1.deleteById(e.id);

    final s2 = await PersistentEventStore.open(prefs);
    expect(await s2.all(), isEmpty);
  });

  test('clear persiste', () async {
    final prefs = await SharedPreferences.getInstance();
    final s1 = await PersistentEventStore.open(prefs);
    await s1.append(sono(6.0));
    await s1.clear();

    final s2 = await PersistentEventStore.open(prefs);
    expect(await s2.all(), isEmpty);
  });
}
