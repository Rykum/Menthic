import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';
import 'event.dart';
import 'event_store.dart';

class SqliteEventStore implements EventStore {
  final Database _db;
  SqliteEventStore._(this._db) {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS events(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ts INTEGER NOT NULL,
        type TEXT NOT NULL,
        payload TEXT NOT NULL,
        origin TEXT NOT NULL
      );
    ''');
  }

  factory SqliteEventStore.open(String path) =>
      SqliteEventStore._(sqlite3.open(path));
  factory SqliteEventStore.memory() =>
      SqliteEventStore._(sqlite3.openInMemory());

  void dispose() => _db.dispose();

  Event _row(Row r) => Event(
    id: r['id'] as int,
    ts: DateTime.fromMillisecondsSinceEpoch(r['ts'] as int, isUtc: true),
    type: r['type'] as String,
    payload: (jsonDecode(r['payload'] as String) as Map)
        .cast<String, dynamic>(),
    origin: r['origin'] as String,
  );

  (String, List<Object?>) _whereClause(
    DateTime? from,
    DateTime? to,
    List<String>? types,
  ) {
    final where = <String>[];
    final args = <Object?>[];
    if (from != null) {
      where.add('ts >= ?');
      args.add(from.millisecondsSinceEpoch);
    }
    if (to != null) {
      where.add('ts < ?');
      args.add(to.millisecondsSinceEpoch);
    }
    if (types != null && types.isNotEmpty) {
      where.add('type IN (${List.filled(types.length, '?').join(',')})');
      args.addAll(types);
    }
    final clause = where.isEmpty ? '' : ' WHERE ${where.join(' AND ')}';
    return (clause, args);
  }

  @override
  Future<Event> append(EventDraft d) async {
    _db.execute(
      'INSERT INTO events(ts, type, payload, origin) VALUES (?, ?, ?, ?);',
      [d.ts.millisecondsSinceEpoch, d.type, jsonEncode(d.payload), d.origin],
    );
    return Event(
      id: _db.lastInsertRowId,
      ts: d.ts,
      type: d.type,
      payload: d.payload,
      origin: d.origin,
    );
  }

  @override
  Future<List<Event>> query({
    DateTime? from,
    DateTime? to,
    List<String>? types,
  }) async {
    final (clause, args) = _whereClause(from, to, types);
    final rs = _db.select(
      'SELECT * FROM events$clause ORDER BY ts ASC, id ASC;',
      args,
    );
    return rs.map(_row).toList();
  }

  @override
  Future<List<Event>> all() => query();

  @override
  Future<void> deleteById(int id) async {
    _db.execute('DELETE FROM events WHERE id = ?;', [id]);
  }

  @override
  Future<void> deleteWhere({
    DateTime? from,
    DateTime? to,
    List<String>? types,
  }) async {
    final (clause, args) = _whereClause(from, to, types);
    _db.execute('DELETE FROM events$clause;', args);
  }

  @override
  Future<void> clear() async {
    _db.execute('DELETE FROM events;');
  }
}
