import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oracle_calibration/oracle_calibration.dart';
import '../../data/providers.dart';
import '../../design/design.dart';
import 'pairing.dart';

/// Autoavaliação do sistema (honestidade radical): quão perto as previsões
/// emitidas ficaram da realidade registrada nas revisões.
class CalibrationScreen extends ConsumerStatefulWidget {
  const CalibrationScreen({super.key});
  @override
  ConsumerState<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends ConsumerState<CalibrationScreen> {
  List<DayPair>? _pairs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = await ref.read(eventStoreProvider.future);
    final events = await store.all();
    if (!mounted) return;
    setState(() => _pairs = pairPredictions(events));
  }

  TextStyle get _body => GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: MColors.mintDeep,
  );

  @override
  Widget build(BuildContext context) {
    final pairs = _pairs;
    final data = pairs == null
        ? <PredOutcome>[]
        : [for (final p in pairs) PredOutcome(p.predicted, p.outcome)];

    return MenthicScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: MSpace.sm),
            const Center(child: DisplayTitle('Calibração', size: 44)),
            const SizedBox(height: MSpace.xs),
            Center(
              child: Text(
                'quão perto as previsões ficaram da realidade',
                style: _body.copyWith(color: MColors.neutralGray),
              ),
            ),
            const SizedBox(height: MSpace.md),
            if (pairs == null)
              const SizedBox.shrink()
            else if (pairs.isEmpty)
              GlassCard(
                child: Text(
                  'Nenhuma previsão avaliada ainda. Use a Hoje para prever e '
                  'a Revisão noturna para registrar o desfecho — o sistema '
                  'se avalia sozinho a partir daí.',
                  style: _body,
                ),
              )
            else ...[
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pairs.length == 1
                          ? '1 previsão avaliada'
                          : '${pairs.length} previsões avaliadas',
                      style: displayTitleStyle(26),
                    ),
                    const SizedBox(height: MSpace.xs),
                    Text(
                      'Brier: ${brierScore(data).toStringAsFixed(2)} '
                      '(0 = perfeito · 0.25 = chute de 50%)',
                      style: _body,
                    ),
                    Text(
                      'previsto em média '
                      '${(data.map((d) => d.p).reduce((a, b) => a + b) / data.length * 100).round()}% '
                      '· aconteceu em ${(baseRate(data) * 100).round()}% dos dias',
                      style: _body,
                    ),
                    if (pairs.length < 10)
                      Padding(
                        padding: const EdgeInsets.only(top: MSpace.xs),
                        child: Text(
                          'ainda poucos dados para avaliar a calibração '
                          'com confiança',
                          style: _body.copyWith(color: MColors.neutralGray),
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
                      'Dia a dia',
                      style: GoogleFonts.fredoka(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: MColors.mintDeep,
                      ),
                    ),
                    const SizedBox(height: MSpace.xs),
                    for (final p in pairs.reversed)
                      Text(
                        '${p.day.day.toString().padLeft(2, '0')}/'
                        '${p.day.month.toString().padLeft(2, '0')} · '
                        'previsto ${(p.predicted * 100).round()}% · '
                        '${p.outcome == 1 ? 'cumpriu ✓' : 'não cumpriu ✗'}',
                        style: _body,
                      ),
                  ],
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
