import 'event.dart';

abstract class EventStore {
  Future<Event> append(EventDraft draft);
  Future<List<Event>> query({
    DateTime? from,
    DateTime? to,
    List<String>? types,
  });
  Future<List<Event>> all();
  Future<void> deleteById(int id);
  Future<void> deleteWhere({DateTime? from, DateTime? to, List<String>? types});
  Future<void> clear();
  Future<void> close();
}
