import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oracle_engine/oracle_engine.dart';
import 'package:oracle_store/oracle_store.dart';
import '../../data/aged_priors.dart';
import '../../data/providers.dart';
import '../../design/design.dart';
import '../auth/local_auth.dart';
import 'answer_card.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});
  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _CommitmentRow {
  final int eventId;
  final String nome;
  final double inicio;
  final double duracao;
  final bool aversivo;
  const _CommitmentRow({
    required this.eventId,
    required this.nome,
    required this.inicio,
    required this.duracao,
    required this.aversivo,
  });
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  final _sono = TextEditingController();
  double? _sonoHoje;
  List<_CommitmentRow> _agenda = [];
  OracleAnswer? _answer;
  int _observedDays = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _sono.dispose();
    super.dispose();
  }

  (DateTime, DateTime) _todayWindow() {
    final now = DateTime.now().toUtc();
    final from = DateTime.utc(now.year, now.month, now.day);
    return (from, from.add(const Duration(days: 1)));
  }

  Future<void> _reload() async {
    final store = await ref.read(eventStoreProvider.future);
    final (from, to) = _todayWindow();
    final events = await store.query(from: from, to: to);

    double? sono;
    var previsaoHoje = false;
    final agenda = <_CommitmentRow>[];
    for (final e in events) {
      if (e.type == EventTypes.sonoRegistrado) {
        sono = (e.payload['horas'] as num).toDouble();
      }
      if (e.type == EventTypes.previsaoEmitida) {
        previsaoHoje = true;
      }
      if (e.type == EventTypes.compromissoCriado) {
        agenda.add(
          _CommitmentRow(
            eventId: e.id,
            nome: e.payload['cid'] as String,
            inicio: (e.payload['inicio'] as num).toDouble(),
            duracao: (e.payload['dur_prevista'] as num).toDouble(),
            aversivo: (e.payload['aversivo'] as bool?) ?? false,
          ),
        );
      }
    }
    if (!mounted) return;
    setState(() {
      _sonoHoje = sono;
      _agenda = agenda;
    });
    // Já houve previsão hoje: re-hidrata o card recomputando com os mesmos
    // inputs (determinístico, seed 0) — sem emitir novo evento.
    if (previsaoHoje && _answer == null) {
      await _compute(persist: false);
    }
  }

  double? _num(String raw) => double.tryParse(raw.replaceAll(',', '.'));

  Future<void> _registrarSono() async {
    final horas = _num(_sono.text);
    if (horas == null) return;
    final store = await ref.read(eventStoreProvider.future);
    await store.append(
      sonoRegistrado(ts: DateTime.now().toUtc(), horas: horas),
    );
    _sono.clear();
    await _reload();
  }

  Future<void> _removerCompromisso(int eventId) async {
    final store = await ref.read(eventStoreProvider.future);
    await store.deleteById(eventId);
    await _reload();
  }

  Future<void> _prever() => _compute(persist: true);

  Future<void> _compute({required bool persist}) async {
    final store = await ref.read(eventStoreProvider.future);
    final priors = await loadAgedPriors(store, ref.read(priorsRepoProvider));
    final now = DateTime.now().toUtc();
    final state = await const DayStateDeriver().derive(store, now);

    final outcomes = await store.query(
      types: [EventTypes.tarefaConcluida, EventTypes.tarefaNaoConcluida],
    );
    final days = outcomes
        .map((e) => '${e.ts.year}-${e.ts.month}-${e.ts.day}')
        .toSet();

    final answer = answerAgenda(
      state,
      priors,
      observedDays: days.length,
      seed: 0,
    );
    if (persist) {
      await store.append(
        EventDraft(
          ts: now,
          type: EventTypes.previsaoEmitida,
          payload: {
            'estimate': answer.estimate,
            'low': answer.low,
            'high': answer.high,
          },
        ),
      );
    }
    if (!mounted) return;
    setState(() {
      _answer = answer;
      _observedDays = days.length;
    });
  }

  Future<void> _abrirSheetCompromisso() async {
    final nome = TextEditingController();
    final inicio = TextEditingController();
    final duracao = TextEditingController();
    var aversivo = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MColors.cyanLight,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (sheetContext, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PillField(
                key: const Key('nome'),
                label: 'nome:',
                controller: nome,
              ),
              const SizedBox(height: MSpace.sm),
              PillField(
                key: const Key('inicio'),
                label: 'início (hora 0–24):',
                controller: inicio,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: MSpace.sm),
              PillField(
                key: const Key('duracao'),
                label: 'duração (horas):',
                controller: duracao,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: MSpace.sm),
              Row(
                children: [
                  Switch(
                    value: aversivo,
                    activeColor: MColors.mintDeep,
                    onChanged: (v) => setSheetState(() => aversivo = v),
                  ),
                  Text(
                    'tarefa chata (aversiva)',
                    style: nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: MColors.mintDeep,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MSpace.md),
              Center(
                child: NeuButton(
                  onTap: () async {
                    final ini = _num(inicio.text);
                    final dur = _num(duracao.text);
                    if (nome.text.isEmpty || ini == null || dur == null) {
                      return;
                    }
                    final store = await ref.read(eventStoreProvider.future);
                    await store.append(
                      compromissoCriado(
                        ts: DateTime.now().toUtc(),
                        cid: nome.text,
                        inicio: ini,
                        durPrevista: dur,
                        tipo: 'foco',
                        aversivo: aversivo,
                      ),
                    );
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                  child: Text('Salvar', style: displayTitleStyle(24)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // Controllers do sheet não são descartados aqui: a animação de saída
    // ainda os referencia; são efêmeros e coletados com o sheet.
    await _reload();
  }

  TextStyle get _body => nunito(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: MColors.mintDeep,
  );

  @override
  Widget build(BuildContext context) {
    return MenthicScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: MSpace.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const DisplayTitle('Hoje', size: 44),
                IconButton(
                  icon: const Icon(Icons.logout, color: MColors.mintDeep),
                  onPressed: () async {
                    await ref.read(localAuthProvider).signOut();
                    if (context.mounted) context.goNamed('login');
                  },
                ),
              ],
            ),
            const SizedBox(height: MSpace.sm),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: MSpace.sm,
              runSpacing: MSpace.xs,
              children: [
                for (final (label, route) in const [
                  ('Simular', 'simular'),
                  ('Meu Twin', 'twin'),
                  ('Calibração', 'calibracao'),
                ])
                  NeuButton(
                    onTap: () => context.goNamed(route),
                    color: MColors.cyanLight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Text(
                      label,
                      style: fredoka(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: MColors.mintDeep,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: MSpace.sm),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_sonoHoje != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: MSpace.sm),
                      child: Text(
                        'Sono de hoje: ${_sonoHoje!.toStringAsFixed(1)}h',
                        style: _body,
                      ),
                    ),
                  PillField(
                    key: const Key('sono'),
                    label: 'dormi (horas):',
                    controller: _sono,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: MSpace.sm),
                  Center(
                    child: NeuButton(
                      onTap: _registrarSono,
                      child: Text(
                        'Registrar sono',
                        style: displayTitleStyle(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MSpace.md),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Compromissos de hoje',
                    style: fredoka(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: MColors.mintDeep,
                    ),
                  ),
                  const SizedBox(height: MSpace.sm),
                  if (_agenda.isEmpty)
                    Text('nenhum ainda', style: _body)
                  else
                    for (final c in _agenda)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${c.nome} · ${c.inicio.toStringAsFixed(0)}h · '
                              '${c.duracao.toStringAsFixed(1)}h'
                              '${c.aversivo ? ' · chata' : ''}',
                              style: _body,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: MColors.neutralGray,
                              size: 20,
                            ),
                            onPressed: () => _removerCompromisso(c.eventId),
                          ),
                        ],
                      ),
                  const SizedBox(height: MSpace.sm),
                  Center(
                    child: NeuButton(
                      onTap: _abrirSheetCompromisso,
                      color: MColors.cyanLight,
                      child: Text(
                        'Adicionar compromisso',
                        style: fredoka(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: MColors.mintDeep,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MSpace.md),
            Center(
              child: NeuButton(
                onTap: _prever,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 24,
                ),
                child: Text('Prever meu dia', style: displayTitleStyle(28)),
              ),
            ),
            if (_answer != null) ...[
              const SizedBox(height: MSpace.md),
              AnswerCard(answer: _answer!, observedDays: _observedDays),
              const SizedBox(height: MSpace.md),
              Center(
                child: NeuButton(
                  onTap: () => context.goNamed('revisao'),
                  color: MColors.cyanLight,
                  child: Text(
                    'Revisão do dia',
                    style: fredoka(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: MColors.mintDeep,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: MSpace.lg),
          ],
        ),
      ),
    );
  }
}
