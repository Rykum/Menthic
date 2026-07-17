# Event Store & Data Layer (Fase 0.2) — Plano de Implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir o pacote Dart `oracle_store` — um event store (append-only) com
duas implementações (memória e SQLite) atrás de uma interface, mais uma camada de
derivação que transforma eventos no `DayState` que o motor consome.

**Architecture:** Pacote Dart puro `store/` (depende de `oracle_engine` e
`sqlite3`). Interface `EventStore` → `InMemoryEventStore` (testes) + `SqliteEventStore`
(persistência real). Um teste de contrato compartilhado roda contra as duas impls.
`DayStateDeriver` lê eventos e monta `DayState`. Testado com `dart test`.

**Tech Stack:** Dart SDK ^3.8, `sqlite3` ^2.4, `oracle_engine` (path), package:test.

## Global Constraints

- **Local do pacote:** `store/` na raiz; **nome** `oracle_store`.
- **Dependências:** `oracle_engine` (path `../engine`) e `sqlite3: ^2.4.0`; dev
  `test: ^1.25.0`.
- **`EventStore` é assíncrona** (retorna `Future`). Intervalos são **meio-abertos
  `[from, to)`**. `types` **null ou vazio = sem filtro de tipo**. Resultados de
  `query`/`all` ordenados por **`ts` asc, depois `id` asc**.
- **Paridade:** `InMemoryEventStore` e `SqliteEventStore` DEVEM passar o **mesmo**
  teste de contrato compartilhado.
- **Fora de escopo:** cripto (SQLCipher), aprendizado, time-series/feature store,
  UI. Não adicionar.
- **Estilo:** `dart format` limpo; `dart analyze` sem issues.

---

### Task 1: Scaffold do pacote + modelo `Event`/`EventDraft`

**Files:**
- Create: `store/pubspec.yaml`
- Create: `store/lib/oracle_store.dart`
- Create: `store/lib/src/event.dart`
- Test: `store/test/event_test.dart`

**Interfaces:**
- Consumes: nada.
- Produces:
  - `class Event { final int id; final DateTime ts; final String type; final Map<String,dynamic> payload; final String origin; const Event({required ...}); }`
  - `class EventDraft { final DateTime ts; final String type; final Map<String,dynamic> payload; final String origin; const EventDraft({required this.ts, required this.type, required this.payload, this.origin = 'manual'}); }`

- [ ] **Step 1: Criar pacote e barrel**

`store/pubspec.yaml`:
```yaml
name: oracle_store
description: Camada de dados (event sourcing) do Project Oracle.
version: 0.1.0
publish_to: none
environment:
  sdk: ^3.8.0
dependencies:
  oracle_engine:
    path: ../engine
  sqlite3: ^2.4.0
dev_dependencies:
  test: ^1.25.0
```

`store/lib/oracle_store.dart`:
```dart
export 'src/event.dart';
```

- [ ] **Step 2: Escrever o teste que falha**

`store/test/event_test.dart`:
```dart
import 'package:oracle_store/oracle_store.dart';
import 'package:test/test.dart';

void main() {
  test('Event guarda seus campos', () {
    final e = Event(
      id: 1,
      ts: DateTime.utc(2026, 7, 17, 8),
      type: 'sono_registrado',
      payload: const {'horas': 5.5},
      origin: 'manual',
    );
    expect(e.id, 1);
    expect(e.type, 'sono_registrado');
    expect(e.payload['horas'], 5.5);
    expect(e.origin, 'manual');
  });

  test('EventDraft tem origin padrão manual', () {
    final d = EventDraft(
      ts: DateTime.utc(2026, 7, 17),
      type: 'humor_registrado',
      payload: const {'valor': 3},
    );
    expect(d.origin, 'manual');
    expect(d.payload['valor'], 3);
  });
}
```

- [ ] **Step 3: Rodar o teste para vê-lo falhar**

Run: `cd store && dart pub get && dart test test/event_test.dart`
Expected: FALHA — `Event`/`EventDraft` não definidos.

- [ ] **Step 4: Implementar o modelo**

`store/lib/src/event.dart`:
```dart
class Event {
  final int id;
  final DateTime ts;
  final String type;
  final Map<String, dynamic> payload;
  final String origin;
  const Event({
    required this.id,
    required this.ts,
    required this.type,
    required this.payload,
    required this.origin,
  });
}

class EventDraft {
  final DateTime ts;
  final String type;
  final Map<String, dynamic> payload;
  final String origin;
  const EventDraft({
    required this.ts,
    required this.type,
    required this.payload,
    this.origin = 'manual',
  });
}
```

- [ ] **Step 5: Rodar o teste para vê-lo passar**

Run: `cd store && dart test test/event_test.dart`
Expected: PASSA (2 testes).

- [ ] **Step 6: Commit**

```bash
git add store/pubspec.yaml store/lib store/test/event_test.dart
git commit -m "feat(store): scaffold do pacote oracle_store e modelo Event/EventDraft"
```

---

### Task 2: Interface `EventStore` + `InMemoryEventStore` + teste de contrato

**Files:**
- Create: `store/lib/src/event_store.dart`
- Create: `store/lib/src/in_memory_event_store.dart`
- Modify: `store/lib/oracle_store.dart`
- Create: `store/test/event_store_contract.dart` (helper compartilhado, sem `main`)
- Test: `store/test/in_memory_event_store_test.dart`

**Interfaces:**
- Consumes: `Event`, `EventDraft` (Task 1).
- Produces:
  - `abstract class EventStore { Future<Event> append(EventDraft d); Future<List<Event>> query({DateTime? from, DateTime? to, List<String>? types}); Future<List<Event>> all(); Future<void> deleteById(int id); Future<void> deleteWhere({DateTime? from, DateTime? to, List<String>? types}); Future<void> clear(); }`
  - `class InMemoryEventStore implements EventStore { ... }`
  - `void runEventStoreContract(EventStore Function() create)` (em `event_store_contract.dart`)

- [ ] **Step 1: Adicionar exports**

Em `store/lib/oracle_store.dart`, adicionar:
```dart
export 'src/event_store.dart';
export 'src/in_memory_event_store.dart';
```

- [ ] **Step 2: Escrever o teste de contrato (helper) e o teste que o usa**

`store/test/event_store_contract.dart`:
```dart
import 'package:oracle_store/oracle_store.dart';
import 'package:test/test.dart';

/// Contrato compartilhado por todas as implementações de [EventStore].
void runEventStoreContract(EventStore Function() create) {
  late EventStore store;
  setUp(() => store = create());

  EventDraft draft(int hour, String type) => EventDraft(
        ts: DateTime.utc(2026, 7, 17, hour),
        type: type,
        payload: {'h': hour},
      );

  test('append atribui ids crescentes a partir de 1', () async {
    final a = await store.append(draft(8, 'a'));
    final b = await store.append(draft(9, 'b'));
    expect(a.id, 1);
    expect(b.id, 2);
    expect(a.type, 'a');
    expect(a.payload['h'], 8);
  });

  test('query/all retornam em ordem de ts', () async {
    await store.append(draft(10, 'x'));
    await store.append(draft(8, 'y'));
    await store.append(draft(9, 'z'));
    final all = await store.all();
    expect(all.map((e) => e.ts.hour), [8, 9, 10]);
  });

  test('query filtra por [from, to) meio-aberto', () async {
    await store.append(draft(8, 'x'));
    await store.append(draft(9, 'y'));
    await store.append(draft(10, 'z'));
    final r = await store.query(
      from: DateTime.utc(2026, 7, 17, 9),
      to: DateTime.utc(2026, 7, 17, 10),
    );
    expect(r.map((e) => e.ts.hour), [9]); // 10 é excluído (to exclusivo)
  });

  test('query filtra por types; null/vazio = sem filtro', () async {
    await store.append(draft(8, 'a'));
    await store.append(draft(9, 'b'));
    expect((await store.query(types: ['a'])).map((e) => e.type), ['a']);
    expect((await store.query(types: [])).length, 2);
    expect((await store.query()).length, 2);
  });

  test('deleteById remove um evento', () async {
    final a = await store.append(draft(8, 'a'));
    await store.append(draft(9, 'b'));
    await store.deleteById(a.id);
    final all = await store.all();
    expect(all.map((e) => e.type), ['b']);
  });

  test('deleteWhere remove os que casam', () async {
    await store.append(draft(8, 'a'));
    await store.append(draft(9, 'b'));
    await store.append(draft(10, 'a'));
    await store.deleteWhere(types: ['a']);
    expect((await store.all()).map((e) => e.type), ['b']);
  });

  test('clear esvazia tudo', () async {
    await store.append(draft(8, 'a'));
    await store.clear();
    expect(await store.all(), isEmpty);
  });
}
```

`store/test/in_memory_event_store_test.dart`:
```dart
import 'package:oracle_store/oracle_store.dart';
import 'event_store_contract.dart';

void main() {
  runEventStoreContract(() => InMemoryEventStore());
}
```

- [ ] **Step 3: Rodar o teste para vê-lo falhar**

Run: `cd store && dart test test/in_memory_event_store_test.dart`
Expected: FALHA — `EventStore`/`InMemoryEventStore` não definidos.

- [ ] **Step 4: Implementar a interface e a impl em memória**

`store/lib/src/event_store.dart`:
```dart
import 'event.dart';

abstract class EventStore {
  Future<Event> append(EventDraft draft);
  Future<List<Event>> query({DateTime? from, DateTime? to, List<String>? types});
  Future<List<Event>> all();
  Future<void> deleteById(int id);
  Future<void> deleteWhere({DateTime? from, DateTime? to, List<String>? types});
  Future<void> clear();
}
```

`store/lib/src/in_memory_event_store.dart`:
```dart
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
```

- [ ] **Step 5: Rodar o teste para vê-lo passar**

Run: `cd store && dart test test/in_memory_event_store_test.dart`
Expected: PASSA (7 testes do contrato).

- [ ] **Step 6: Commit**

```bash
git add store/lib store/test/event_store_contract.dart store/test/in_memory_event_store_test.dart
git commit -m "feat(store): interface EventStore + InMemoryEventStore + teste de contrato"
```

---

### Task 3: `SqliteEventStore` (mesma paridade de contrato)

**Files:**
- Create: `store/lib/src/sqlite_event_store.dart`
- Modify: `store/lib/oracle_store.dart`
- Test: `store/test/sqlite_event_store_test.dart`

**Interfaces:**
- Consumes: `Event`, `EventDraft`, `EventStore` (Tasks 1-2), `runEventStoreContract`.
- Produces:
  - `class SqliteEventStore implements EventStore { factory SqliteEventStore.open(String path); factory SqliteEventStore.memory(); void dispose(); ... }`

- [ ] **Step 1: Adicionar export**

Em `store/lib/oracle_store.dart`, adicionar:
```dart
export 'src/sqlite_event_store.dart';
```

- [ ] **Step 2: Escrever o teste que falha (roda o MESMO contrato)**

`store/test/sqlite_event_store_test.dart`:
```dart
import 'package:oracle_store/oracle_store.dart';
import 'event_store_contract.dart';

void main() {
  runEventStoreContract(() => SqliteEventStore.memory());
}
```

- [ ] **Step 3: Rodar o teste para vê-lo falhar**

Run: `cd store && dart test test/sqlite_event_store_test.dart`
Expected: FALHA — `SqliteEventStore` não definido.

- [ ] **Step 4: Implementar sobre `sqlite3`**

`store/lib/src/sqlite_event_store.dart`:
```dart
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
      DateTime? from, DateTime? to, List<String>? types) {
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
      [
        d.ts.millisecondsSinceEpoch,
        d.type,
        jsonEncode(d.payload),
        d.origin,
      ],
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
```

- [ ] **Step 5: Rodar o teste para vê-lo passar**

Run: `cd store && dart test test/sqlite_event_store_test.dart`
Expected: PASSA (os mesmos 7 testes do contrato, agora sobre SQLite).

- [ ] **Step 6: Commit**

```bash
git add store/lib/src/sqlite_event_store.dart store/lib/oracle_store.dart store/test/sqlite_event_store_test.dart
git commit -m "feat(store): SqliteEventStore (paridade de contrato com a impl em memória)"
```

---

### Task 4: Helpers tipados dos eventos da Fase 0

**Files:**
- Create: `store/lib/src/events_phase0.dart`
- Modify: `store/lib/oracle_store.dart`
- Test: `store/test/events_phase0_test.dart`

**Interfaces:**
- Consumes: `EventDraft` (Task 1).
- Produces:
  - `class EventTypes { static const sonoRegistrado, compromissoCriado, tarefaConcluida, tarefaNaoConcluida, humorRegistrado, previsaoEmitida; }`
  - `EventDraft sonoRegistrado({required DateTime ts, required double horas, int? qualidade, String origin})`
  - `EventDraft compromissoCriado({required DateTime ts, required String cid, required double inicio, required double durPrevista, required String tipo, int prioridade, bool aversivo, String origin})`
  - `EventDraft tarefaConcluida({required DateTime ts, required String cid, required double atrasoMin, String origin})`

- [ ] **Step 1: Adicionar export**

Em `store/lib/oracle_store.dart`, adicionar:
```dart
export 'src/events_phase0.dart';
```

- [ ] **Step 2: Escrever o teste que falha**

`store/test/events_phase0_test.dart`:
```dart
import 'package:oracle_store/oracle_store.dart';
import 'package:test/test.dart';

void main() {
  final ts = DateTime.utc(2026, 7, 17, 7);

  test('sonoRegistrado monta o draft correto', () {
    final d = sonoRegistrado(ts: ts, horas: 5.5);
    expect(d.type, EventTypes.sonoRegistrado);
    expect(d.payload['horas'], 5.5);
    expect(d.origin, 'manual');
  });

  test('compromissoCriado monta o draft correto', () {
    final d = compromissoCriado(
      ts: ts,
      cid: 'estudo',
      inicio: 14.0,
      durPrevista: 2.0,
      tipo: 'estudo',
      prioridade: 2,
      aversivo: true,
    );
    expect(d.type, EventTypes.compromissoCriado);
    expect(d.payload['cid'], 'estudo');
    expect(d.payload['inicio'], 14.0);
    expect(d.payload['aversivo'], true);
  });

  test('tarefaConcluida monta o draft correto', () {
    final d = tarefaConcluida(ts: ts, cid: 'estudo', atrasoMin: 20.0);
    expect(d.type, EventTypes.tarefaConcluida);
    expect(d.payload['cid'], 'estudo');
    expect(d.payload['atraso_min'], 20.0);
  });
}
```

- [ ] **Step 3: Rodar o teste para vê-lo falhar**

Run: `cd store && dart test test/events_phase0_test.dart`
Expected: FALHA — helpers não definidos.

- [ ] **Step 4: Implementar os helpers**

`store/lib/src/events_phase0.dart`:
```dart
import 'event.dart';

class EventTypes {
  static const String sonoRegistrado = 'sono_registrado';
  static const String compromissoCriado = 'compromisso_criado';
  static const String tarefaConcluida = 'tarefa_concluida';
  static const String tarefaNaoConcluida = 'tarefa_nao_concluida';
  static const String humorRegistrado = 'humor_registrado';
  static const String previsaoEmitida = 'previsao_emitida';
}

EventDraft sonoRegistrado({
  required DateTime ts,
  required double horas,
  int? qualidade,
  String origin = 'manual',
}) =>
    EventDraft(
      ts: ts,
      type: EventTypes.sonoRegistrado,
      origin: origin,
      payload: {'horas': horas, if (qualidade != null) 'qualidade': qualidade},
    );

EventDraft compromissoCriado({
  required DateTime ts,
  required String cid,
  required double inicio,
  required double durPrevista,
  required String tipo,
  int prioridade = 2,
  bool aversivo = false,
  String origin = 'manual',
}) =>
    EventDraft(
      ts: ts,
      type: EventTypes.compromissoCriado,
      origin: origin,
      payload: {
        'cid': cid,
        'inicio': inicio,
        'dur_prevista': durPrevista,
        'tipo': tipo,
        'prioridade': prioridade,
        'aversivo': aversivo,
      },
    );

EventDraft tarefaConcluida({
  required DateTime ts,
  required String cid,
  required double atrasoMin,
  String origin = 'manual',
}) =>
    EventDraft(
      ts: ts,
      type: EventTypes.tarefaConcluida,
      origin: origin,
      payload: {'cid': cid, 'atraso_min': atrasoMin},
    );
```

- [ ] **Step 5: Rodar o teste para vê-lo passar**

Run: `cd store && dart test test/events_phase0_test.dart`
Expected: PASSA (3 testes).

- [ ] **Step 6: Commit**

```bash
git add store/lib/src/events_phase0.dart store/lib/oracle_store.dart store/test/events_phase0_test.dart
git commit -m "feat(store): helpers tipados dos eventos da Fase 0"
```

---

### Task 5: `DayStateDeriver` (eventos → DayState)

**Files:**
- Create: `store/lib/src/derivation.dart`
- Modify: `store/lib/oracle_store.dart`
- Test: `store/test/derivation_test.dart`

**Interfaces:**
- Consumes: `EventStore`, `EventTypes` (Tasks 2, 4), `sonoRegistrado`/`compromissoCriado` helpers, `oracle_engine` (`DayState`, `Commitment`).
- Produces:
  - `class DerivationConfig { final double metaSonoHoras; final double dayEnd; const DerivationConfig({this.metaSonoHoras = 7.0, this.dayEnd = 24.0}); }`
  - `class DayStateDeriver { final DerivationConfig config; const DayStateDeriver([this.config = const DerivationConfig()]); Future<DayState> derive(EventStore store, DateTime date); }`

- [ ] **Step 1: Adicionar export**

Em `store/lib/oracle_store.dart`, adicionar:
```dart
export 'src/derivation.dart';
```

- [ ] **Step 2: Escrever o teste que falha**

`store/test/derivation_test.dart`:
```dart
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
    final ds = await const DayStateDeriver(DerivationConfig(dayEnd: 18.0))
        .derive(store, date);
    expect(ds.dayEnd, 18.0);
  });
}
```

- [ ] **Step 3: Rodar o teste para vê-lo falhar**

Run: `cd store && dart test test/derivation_test.dart`
Expected: FALHA — `DayStateDeriver`/`DerivationConfig` não definidos.

- [ ] **Step 4: Implementar a derivação**

`store/lib/src/derivation.dart`:
```dart
import 'package:oracle_engine/oracle_engine.dart';
import 'event_store.dart';
import 'events_phase0.dart';

class DerivationConfig {
  final double metaSonoHoras;
  final double dayEnd;
  const DerivationConfig({this.metaSonoHoras = 7.0, this.dayEnd = 24.0});
}

class DayStateDeriver {
  final DerivationConfig config;
  const DayStateDeriver([this.config = const DerivationConfig()]);

  Future<DayState> derive(EventStore store, DateTime date) async {
    final from = DateTime.utc(date.year, date.month, date.day);
    final to = from.add(const Duration(days: 1));
    final events = await store.query(from: from, to: to);

    var sleepDebt = 0.0;
    final sonos =
        events.where((e) => e.type == EventTypes.sonoRegistrado).toList();
    if (sonos.isNotEmpty) {
      final horas = (sonos.last.payload['horas'] as num).toDouble();
      final debt = config.metaSonoHoras - horas;
      sleepDebt = debt < 0 ? 0.0 : debt;
    }

    final agenda = events
        .where((e) => e.type == EventTypes.compromissoCriado)
        .map((e) {
      final p = e.payload;
      return Commitment(
        id: p['cid'] as String,
        start: (p['inicio'] as num).toDouble(),
        planned: (p['dur_prevista'] as num).toDouble(),
        type: p['tipo'] as String,
        priority: (p['prioridade'] as num?)?.toInt() ?? 2,
        aversive: (p['aversivo'] as bool?) ?? false,
      );
    }).toList();

    return DayState(
      sleepDebt: sleepDebt,
      dayEnd: config.dayEnd,
      agenda: agenda,
    );
  }
}
```

- [ ] **Step 5: Rodar o teste para vê-lo passar**

Run: `cd store && dart test test/derivation_test.dart`
Expected: PASSA (4 testes).

- [ ] **Step 6: Commit**

```bash
git add store/lib/src/derivation.dart store/lib/oracle_store.dart store/test/derivation_test.dart
git commit -m "feat(store): DayStateDeriver (eventos -> DayState)"
```

---

### Task 6: Ponta a ponta (eventos → motor) + right-to-forget + verificação

**Files:**
- Test: `store/test/end_to_end_test.dart`

**Interfaces:**
- Consumes: todo o pacote `oracle_store` + `oracle_engine` (`answerAgenda`, `TraitPriors`, `Confidence`).
- Produces: nada (testes de integração da pipeline).

- [ ] **Step 1: Escrever o teste ponta a ponta e o de right-to-forget**

`store/test/end_to_end_test.dart`:
```dart
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
```

- [ ] **Step 2: Rodar o teste ponta a ponta**

Run: `cd store && dart test test/end_to_end_test.dart`
Expected: PASSA (3 testes).

- [ ] **Step 3: Rodar a suíte inteira + análise estática**

Run: `cd store && dart analyze && dart test`
Expected: `No issues found!` e **todos** os testes do pacote passam.

- [ ] **Step 4: Commit**

```bash
git add store/test/end_to_end_test.dart
git commit -m "test(store): pipeline eventos->motor, right-to-forget e paridade SQLite"
```

---

## Notas para quem executar

- O pacote `oracle_store` depende de `oracle_engine` por path (`../engine`). O
  `dart pub get` em `store/` resolve o pacote local — rode-o antes do primeiro teste.
- `sqlite3` já foi verificado funcionando neste ambiente (Windows) — os testes de
  SQLite usam `openInMemory()`, sem arquivo nem DLL adicional.
- Intervalos `[from, to)` são meio-abertos e `ts` é comparado em UTC; os testes
  usam `DateTime.utc(...)` de propósito — mantenha UTC para evitar ambiguidade de
  fuso.
