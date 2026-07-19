import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oracle_store/oracle_store.dart';
import '../../data/providers.dart';
import '../../design/design.dart';
import 'trait_view.dart';

/// Reality Model visível: o que o sistema acredita saber sobre o usuário —
/// sempre com incerteza junto do valor, nunca como verdade absoluta.
class TwinScreen extends ConsumerStatefulWidget {
  const TwinScreen({super.key});
  @override
  ConsumerState<TwinScreen> createState() => _TwinScreenState();
}

class _TwinScreenState extends ConsumerState<TwinScreen> {
  List<TraitView> _views = [];
  int _observedDays = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final priors = await ref.read(priorsRepoProvider).load();
    final store = await ref.read(eventStoreProvider.future);
    final outcomes = await store.query(
      types: [EventTypes.tarefaConcluida, EventTypes.tarefaNaoConcluida],
    );
    final days = outcomes
        .map((e) => '${e.ts.year}-${e.ts.month}-${e.ts.day}')
        .toSet()
        .length;
    if (!mounted) return;
    setState(() {
      _views = traitViews(priors);
      _observedDays = days;
    });
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
            const Center(child: DisplayTitle('Meu Twin', size: 44)),
            const SizedBox(height: MSpace.xs),
            Center(
              child: Text(
                'hipóteses do modelo — nada aqui é verdade absoluta',
                style: _body.copyWith(color: MColors.neutralGray),
              ),
            ),
            const SizedBox(height: MSpace.sm),
            Center(
              child: Text(
                'evidência: $_observedDays dia(s) com desfecho',
                style: _body,
              ),
            ),
            const SizedBox(height: MSpace.md),
            for (final v in _views)
              Padding(
                padding: const EdgeInsets.only(bottom: MSpace.sm),
                child: GlassCard(
                  padding: const EdgeInsets.all(MSpace.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.nome,
                        style: GoogleFonts.fredoka(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: MColors.mintDeep,
                        ),
                      ),
                      const SizedBox(height: MSpace.xs),
                      Text(v.valor, style: displayTitleStyle(26)),
                      const SizedBox(height: MSpace.xs),
                      Text('incerteza ${v.incerteza}', style: _body),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: MSpace.lg),
          ],
        ),
      ),
    );
  }
}
