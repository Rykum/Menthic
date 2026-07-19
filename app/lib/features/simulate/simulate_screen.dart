import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oracle_engine/oracle_engine.dart';
import 'package:oracle_store/oracle_store.dart';
import '../../data/providers.dart';
import '../../design/design.dart';
import '../today/answer_card.dart';

/// Modo Exploração "E se...": edita um dia hipotético e vê o OracleAnswer
/// recalcular. NADA é gravado no event store.
class SimulateScreen extends ConsumerStatefulWidget {
  const SimulateScreen({super.key});
  @override
  ConsumerState<SimulateScreen> createState() => _SimulateScreenState();
}

class _Hypo {
  final String nome;
  final double inicio;
  final double duracao;
  final bool aversivo;
  const _Hypo(this.nome, this.inicio, this.duracao, this.aversivo);
}

class _SimulateScreenState extends ConsumerState<SimulateScreen> {
  final _sono = TextEditingController(text: '7');
  List<_Hypo> _agenda = [];
  OracleAnswer? _answer;
  int _observedDays = 0;

  @override
  void initState() {
    super.initState();
    _loadFromToday();
  }

  @override
  void dispose() {
    _sono.dispose();
    super.dispose();
  }

  double? _num(String raw) => double.tryParse(raw.replaceAll(',', '.'));

  Future<void> _loadFromToday() async {
    final store = await ref.read(eventStoreProvider.future);
    final now = DateTime.now().toUtc();
    final from = DateTime.utc(now.year, now.month, now.day);
    final events = await store.query(
      from: from,
      to: from.add(const Duration(days: 1)),
    );

    final agenda = <_Hypo>[];
    for (final e in events) {
      if (e.type == EventTypes.sonoRegistrado) {
        _sono.text = (e.payload['horas'] as num).toString();
      }
      if (e.type == EventTypes.compromissoCriado) {
        agenda.add(
          _Hypo(
            e.payload['cid'] as String,
            (e.payload['inicio'] as num).toDouble(),
            (e.payload['dur_prevista'] as num).toDouble(),
            (e.payload['aversivo'] as bool?) ?? false,
          ),
        );
      }
    }

    final outcomes = await store.query(
      types: [EventTypes.tarefaConcluida, EventTypes.tarefaNaoConcluida],
    );
    _observedDays = outcomes
        .map((e) => '${e.ts.year}-${e.ts.month}-${e.ts.day}')
        .toSet()
        .length;

    if (!mounted) return;
    setState(() => _agenda = agenda);
    await _recompute();
  }

  Future<void> _recompute() async {
    final horas = _num(_sono.text) ?? 7.0;
    final debt = (7.0 - horas).clamp(0.0, 24.0);
    final priors = await ref.read(priorsRepoProvider).load();
    final state = DayState(
      sleepDebt: debt,
      agenda: [
        for (final (i, h) in _agenda.indexed)
          Commitment(
            id: 'h$i-${h.nome}',
            start: h.inicio,
            planned: h.duracao,
            type: 'foco',
            aversive: h.aversivo,
          ),
      ],
    );
    final answer = answerAgenda(
      state,
      priors,
      observedDays: _observedDays,
      seed: 0,
    );
    if (!mounted) return;
    setState(() => _answer = answer);
  }

  Future<void> _abrirSheet() async {
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
                    style: GoogleFonts.nunito(
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
                  onTap: () {
                    final ini = _num(inicio.text);
                    final dur = _num(duracao.text);
                    if (nome.text.isEmpty || ini == null || dur == null) {
                      return;
                    }
                    setState(() {
                      _agenda = [
                        ..._agenda,
                        _Hypo(nome.text, ini, dur, aversivo),
                      ];
                    });
                    Navigator.of(sheetContext).pop();
                  },
                  child: Text('Adicionar', style: displayTitleStyle(24)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await _recompute();
  }

  TextStyle get _body => GoogleFonts.nunito(
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
            const Center(child: DisplayTitle('Simular', size: 44)),
            const SizedBox(height: MSpace.xs),
            Center(
              child: Text(
                'cenário hipotético · nada foi salvo',
                style: _body.copyWith(color: MColors.neutralGray),
              ),
            ),
            const SizedBox(height: MSpace.md),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PillField(
                    key: const Key('sono_hipotetico'),
                    label: 'e se eu dormir (horas):',
                    controller: _sono,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: MSpace.sm),
                  Text('Agenda hipotética', style: _body),
                  const SizedBox(height: MSpace.xs),
                  if (_agenda.isEmpty)
                    Text('vazia', style: _body)
                  else
                    for (final (i, h) in _agenda.indexed)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${h.nome} · ${h.inicio.toStringAsFixed(0)}h · '
                              '${h.duracao.toStringAsFixed(1)}h'
                              '${h.aversivo ? ' · chata' : ''}',
                              style: _body,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: MColors.neutralGray,
                              size: 20,
                            ),
                            onPressed: () async {
                              setState(() {
                                _agenda = [..._agenda]..removeAt(i);
                              });
                              await _recompute();
                            },
                          ),
                        ],
                      ),
                  const SizedBox(height: MSpace.sm),
                  Center(
                    child: Wrap(
                      spacing: MSpace.sm,
                      runSpacing: MSpace.xs,
                      children: [
                        NeuButton(
                          onTap: _abrirSheet,
                          color: MColors.cyanLight,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Text(
                            'Adicionar compromisso',
                            style: GoogleFonts.fredoka(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: MColors.mintDeep,
                            ),
                          ),
                        ),
                        NeuButton(
                          onTap: _recompute,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Text(
                            'Recalcular',
                            style: GoogleFonts.fredoka(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: MColors.highlight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_answer != null) ...[
              const SizedBox(height: MSpace.md),
              AnswerCard(answer: _answer!, observedDays: _observedDays),
            ],
            const SizedBox(height: MSpace.lg),
          ],
        ),
      ),
    );
  }
}
