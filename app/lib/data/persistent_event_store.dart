import 'dart:convert';
import 'package:oracle_store/oracle_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// EventStore da fase 0 no web: delega ao InMemoryEventStore e espelha um
/// snapshot JSON em shared_preferences após cada mutação. Os ids são
/// renumerados a cada boot (hidratação re-appenda) — consumidores leem ids
/// sempre de query()/all(), nunca os guardam entre sessões.
class PersistentEventStore implements EventStore {
  static const storageKey = 'event_store_v1';
  final InMemoryEventStore _inner;
  final SharedPreferences _prefs;
  PersistentEventStore._(this._inner, this._prefs);

  static Future<PersistentEventStore> open(SharedPreferences prefs) async {
    final inner = InMemoryEventStore();
    final raw = prefs.getString(storageKey);
    if (raw != null) {
      for (final item in jsonDecode(raw) as List) {
        final m = (item as Map).cast<String, dynamic>();
        await inner.append(
          EventDraft(
            ts: DateTime.parse(m['ts'] as String),
            type: m['type'] as String,
            payload: (m['payload'] as Map).cast<String, dynamic>(),
            origin: m['origin'] as String,
          ),
        );
      }
    }
    return PersistentEventStore._(inner, prefs);
  }

  Future<void> _save() async {
    final events = await _inner.all();
    await _prefs.setString(
      storageKey,
      jsonEncode([
        for (final e in events)
          {
            'ts': e.ts.toIso8601String(),
            'type': e.type,
            'payload': e.payload,
            'origin': e.origin,
          },
      ]),
    );
  }

  @override
  Future<Event> append(EventDraft draft) async {
    final e = await _inner.append(draft);
    await _save();
    return e;
  }

  @override
  Future<List<Event>> query({
    DateTime? from,
    DateTime? to,
    List<String>? types,
  }) => _inner.query(from: from, to: to, types: types);

  @override
  Future<List<Event>> all() => _inner.all();

  @override
  Future<void> deleteById(int id) async {
    await _inner.deleteById(id);
    await _save();
  }

  @override
  Future<void> deleteWhere({
    DateTime? from,
    DateTime? to,
    List<String>? types,
  }) async {
    await _inner.deleteWhere(from: from, to: to, types: types);
    await _save();
  }

  @override
  Future<void> clear() async {
    await _inner.clear();
    await _save();
  }

  @override
  Future<void> close() => _inner.close();
}
