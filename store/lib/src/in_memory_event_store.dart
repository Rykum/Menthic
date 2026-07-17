import 'event.dart';
import 'event_store.dart';

class InMemoryEventStore implements EventStore {
  final List<Event> _events = [];
  int _nextId = 1;

  bool _match(Event e, DateTime? from, DateTime? to, List<String>? types) {
    if (from != null && e.ts.isBefore(from)) return false;
    if (to != null && !e.ts.isBefore(to)) return false; // to exclusivo
    if (types != null && types.isNotEmpty && !types.contains(e.type)) {
      return false;
    }
    return true;
  }

  @override
  Future<Event> append(EventDraft d) async {
    final e = Event(
      id: _nextId++,
      ts: d.ts,
      type: d.type,
      payload: d.payload,
      origin: d.origin,
    );
    _events.add(e);
    return e;
  }

  @override
  Future<List<Event>> query({
    DateTime? from,
    DateTime? to,
    List<String>? types,
  }) async {
    final r = _events.where((e) => _match(e, from, to, types)).toList()
      ..sort((a, b) {
        final c = a.ts.compareTo(b.ts);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
    return r;
  }

  @override
  Future<List<Event>> all() => query();

  @override
  Future<void> deleteById(int id) async {
    _events.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> deleteWhere({
    DateTime? from,
    DateTime? to,
    List<String>? types,
  }) async {
    _events.removeWhere((e) => _match(e, from, to, types));
  }

  @override
  Future<void> clear() async => _events.clear();
}
