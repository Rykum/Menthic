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

  test('desempata ts igual por id (ordem de append)', () async {
    final ts = DateTime.utc(2026, 7, 17, 8);
    final first = await store.append(
      EventDraft(ts: ts, type: 'a', payload: const {'n': 1}),
    );
    final second = await store.append(
      EventDraft(ts: ts, type: 'b', payload: const {'n': 2}),
    );
    final all = await store.all();
    expect(all.map((e) => e.id), [first.id, second.id]);
    expect(all.map((e) => e.type), ['a', 'b']);
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
