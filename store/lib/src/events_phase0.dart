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
}) => EventDraft(
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
}) => EventDraft(
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
}) => EventDraft(
  ts: ts,
  type: EventTypes.tarefaConcluida,
  origin: origin,
  payload: {'cid': cid, 'atraso_min': atrasoMin},
);
