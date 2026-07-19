import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oracle_store/oracle_store.dart';

/// EventStore no Firestore (`users/{uid}/events`), offline-first: o cache do
/// SDK mantém leitura/escrita sem rede e sincroniza sozinho. O motor continua
/// no dispositivo — a nuvem só guarda e sincroniza os eventos.
class FirestoreEventStore implements EventStore {
  final FirebaseFirestore _db;
  final String uid;
  FirestoreEventStore(this._db, this.uid);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(uid).collection('events');

  // O relógio do Windows tem resolução grossa: dois appends no mesmo tick
  // receberiam o mesmo microsecondsSinceEpoch (e deleteById apagaria ambos).
  int _lastId = 0;
  int _nextId() {
    var id = DateTime.now().microsecondsSinceEpoch;
    if (id <= _lastId) id = _lastId + 1;
    _lastId = id;
    return id;
  }

  Event _fromDoc(Map<String, dynamic> d) => Event(
    id: (d['id'] as num).toInt(),
    ts: (d['ts'] as Timestamp).toDate().toUtc(),
    type: d['type'] as String,
    payload: (d['payload'] as Map).cast<String, dynamic>(),
    origin: d['origin'] as String,
  );

  @override
  Future<Event> append(EventDraft draft) async {
    final id = _nextId();
    final ts = draft.ts.toUtc();
    await _col.add({
      'id': id,
      'ts': Timestamp.fromDate(ts),
      'type': draft.type,
      'payload': draft.payload,
      'origin': draft.origin,
    });
    return Event(
      id: id,
      ts: ts,
      type: draft.type,
      payload: draft.payload,
      origin: draft.origin,
    );
  }

  @override
  Future<List<Event>> query({
    DateTime? from,
    DateTime? to,
    List<String>? types,
  }) async {
    // Volume N=1: busca ordenada e filtra no cliente (sem índices compostos).
    final snap = await _col.orderBy('ts').get();
    final events = [for (final doc in snap.docs) _fromDoc(doc.data())];
    return [
      for (final e in events)
        if ((from == null || !e.ts.isBefore(from)) &&
            (to == null || e.ts.isBefore(to)) &&
            (types == null || types.isEmpty || types.contains(e.type)))
          e,
    ];
  }

  @override
  Future<List<Event>> all() => query();

  @override
  Future<void> deleteById(int id) async {
    final snap = await _col.where('id', isEqualTo: id).get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Future<void> deleteWhere({
    DateTime? from,
    DateTime? to,
    List<String>? types,
  }) async {
    final matches = await query(from: from, to: to, types: types);
    for (final e in matches) {
      await deleteById(e.id);
    }
  }

  @override
  Future<void> clear() async {
    final snap = await _col.get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Future<void> close() async {}
}
