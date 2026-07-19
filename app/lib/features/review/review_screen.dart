import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oracle_learning/oracle_learning.dart';
import 'package:oracle_store/oracle_store.dart';
import '../../data/providers.dart';
import '../../design/design.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});
  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewItem {
  final String cid;
  final double durPrevista;
  bool feito = false;
  int atrasoMin = 0;
  double durFator = 1.0; // durou: 0.7 menos · 1.0 como previsto · 1.5 · 2.0
  _ReviewItem(this.cid, this.durPrevista);
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  List<_ReviewItem> _items = [];
  int _humor = 3;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = await ref.read(eventStoreProvider.future);
    final now = DateTime.now().toUtc();
    final from = DateTime.utc(now.year, now.month, now.day);
    final events = await store.query(
      from: from,
      to: from.add(const Duration(days: 1)),
      types: [EventTypes.compromissoCriado],
    );
    if (!mounted) return;
    setState(() {
      _items = [
        for (final e in events)
          _ReviewItem(
            e.payload['cid'] as String,
            (e.payload['dur_prevista'] as num?)?.toDouble() ?? 1.0,
          ),
      ];
    });
  }

  Future<void> _salvar() async {
    if (_saving) return;
    setState(() => _saving = true);
    final store = await ref.read(eventStoreProvider.future);
    final now = DateTime.now().toUtc();

    for (final item in _items) {
      if (item.feito) {
        // Draft manual: o helper do store não expõe dur_real, e é ele que
        // alimenta o aprendizado do otimismo de agenda (oObs = ln(real/prev)).
        await store.append(
          EventDraft(
            ts: now,
            type: EventTypes.tarefaConcluida,
            payload: {
              'cid': item.cid,
              'atraso_min': item.atrasoMin.toDouble(),
              'dur_real': item.durPrevista * item.durFator,
            },
          ),
        );
      } else {
        await store.append(
          EventDraft(
            ts: now,
            type: EventTypes.tarefaNaoConcluida,
            payload: {'cid': item.cid},
          ),
        );
      }
    }
    await store.append(
      EventDraft(
        ts: now,
        type: EventTypes.humorRegistrado,
        payload: {'humor': _humor},
      ),
    );

    final repo = ref.read(priorsRepoProvider);
    final prior = await repo.load();
    final updated = await const TwinLearner().learn(store, prior: prior);
    await repo.save(updated);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Twin atualizado com o seu dia.')),
    );
    context.goNamed('hoje');
  }

  TextStyle get _body => GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: MColors.mintDeep,
  );

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: MSpace.xs, bottom: MSpace.xs),
    child: NeuButton(
      onTap: onTap,
      color: selected ? MColors.mint : MColors.cyanLight,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: selected ? MColors.highlight : MColors.mintDeep,
        ),
      ),
    ),
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
            const Center(child: DisplayTitle('Revisão', size: 44)),
            const SizedBox(height: MSpace.md),
            if (_items.isEmpty)
              GlassCard(
                child: Text(
                  'Nenhum compromisso registrado hoje.',
                  style: _body,
                ),
              )
            else
              for (final item in _items)
                Padding(
                  padding: const EdgeInsets.only(bottom: MSpace.sm),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.cid,
                          style: GoogleFonts.fredoka(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: MColors.mintDeep,
                          ),
                        ),
                        const SizedBox(height: MSpace.xs),
                        Row(
                          children: [
                            _chip('feito', item.feito, () {
                              setState(() => item.feito = true);
                            }),
                            _chip('não feito', !item.feito, () {
                              setState(() => item.feito = false);
                            }),
                          ],
                        ),
                        if (item.feito) ...[
                          const SizedBox(height: MSpace.xs),
                          Text('atraso:', style: _body),
                          Wrap(
                            children: [
                              for (final m in const [0, 15, 30, 60])
                                _chip('$m min', item.atrasoMin == m, () {
                                  setState(() => item.atrasoMin = m);
                                }),
                            ],
                          ),
                          const SizedBox(height: MSpace.xs),
                          Text('durou:', style: _body),
                          Wrap(
                            children: [
                              for (final (label, fator) in const [
                                ('menos', 0.7),
                                ('como previsto', 1.0),
                                ('mais', 1.5),
                                ('muito mais', 2.0),
                              ])
                                _chip(label, item.durFator == fator, () {
                                  setState(() => item.durFator = fator);
                                }),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: MSpace.sm),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Como foi o humor hoje? (1–5)', style: _body),
                  const SizedBox(height: MSpace.xs),
                  Wrap(
                    children: [
                      for (var i = 1; i <= 5; i++)
                        _chip('$i', _humor == i, () {
                          setState(() => _humor = i);
                        }),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: MSpace.md),
            Center(
              child: NeuButton(
                onTap: _salvar,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 24,
                ),
                child: Text('Salvar revisão', style: displayTitleStyle(26)),
              ),
            ),
            const SizedBox(height: MSpace.lg),
          ],
        ),
      ),
    );
  }
}
