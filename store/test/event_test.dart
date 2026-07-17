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
