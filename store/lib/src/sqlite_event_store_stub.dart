import 'event.dart';
import 'event_store.dart';

/// Stub do SqliteEventStore para plataformas sem `dart:ffi` (web).
/// Mantém a API pública; qualquer uso lança UnsupportedError.
class SqliteEventStore implements EventStore {
  factory SqliteEventStore.open(String path) => throw UnsupportedError(
    'SqliteEventStore indisponível nesta plataforma (sem dart:ffi).',
  );
  factory SqliteEventStore.memory() => throw UnsupportedError(
    'SqliteEventStore indisponível nesta plataforma (sem dart:ffi).',
  );

  void dispose() {}

  @override
  Future<Event> append(EventDraft d) => throw UnsupportedError('web');

  @override
  Future<List<Event>> query({
    DateTime? from,
    DateTime? to,
    List<String>? types,
  }) => throw UnsupportedError('web');

  @override
  Future<List<Event>> all() => throw UnsupportedError('web');

  @override
  Future<void> deleteById(int id) => throw UnsupportedError('web');

  @override
  Future<void> deleteWhere({
    DateTime? from,
    DateTime? to,
    List<String>? types,
  }) => throw UnsupportedError('web');

  @override
  Future<void> clear() => throw UnsupportedError('web');

  @override
  Future<void> close() => throw UnsupportedError('web');
}
