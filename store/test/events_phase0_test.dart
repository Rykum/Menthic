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
    expect(d.payload['dur_prevista'], 2.0);
    expect(d.payload['tipo'], 'estudo');
    expect(d.payload['prioridade'], 2);
  });

  test('tarefaConcluida monta o draft correto', () {
    final d = tarefaConcluida(ts: ts, cid: 'estudo', atrasoMin: 20.0);
    expect(d.type, EventTypes.tarefaConcluida);
    expect(d.payload['cid'], 'estudo');
    expect(d.payload['atraso_min'], 20.0);
  });

  test('EventTypes usa as strings de wire corretas', () {
    expect(EventTypes.sonoRegistrado, 'sono_registrado');
    expect(EventTypes.compromissoCriado, 'compromisso_criado');
    expect(EventTypes.tarefaConcluida, 'tarefa_concluida');
    expect(EventTypes.tarefaNaoConcluida, 'tarefa_nao_concluida');
    expect(EventTypes.humorRegistrado, 'humor_registrado');
    expect(EventTypes.previsaoEmitida, 'previsao_emitida');
  });
}
