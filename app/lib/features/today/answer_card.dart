import 'package:flutter/material.dart';
import 'package:oracle_engine/oracle_engine.dart';
import '../../design/design.dart';

/// Render fiel do OracleAnswer (doc 06 §6). Nenhum número inventado:
/// tudo vem do engine; aqui só formatamos.
class AnswerCard extends StatelessWidget {
  final OracleAnswer answer;
  final int observedDays;
  const AnswerCard({
    super.key,
    required this.answer,
    required this.observedDays,
  });

  String get _confLabel => switch (answer.confidence) {
    Confidence.alta => 'alta',
    Confidence.media => 'média',
    Confidence.baixa => 'baixa',
  };

  String _forca(double d) {
    final a = d.abs();
    if (a >= 0.08) return 'forte';
    if (a >= 0.04) return 'média';
    return 'fraca';
  }

  TextStyle get _body => nunito(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: MColors.mintDeep,
  );

  TextStyle get _section => fredoka(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: MColors.mintDeep,
  );

  @override
  Widget build(BuildContext context) {
    final pct = (answer.estimate * 100).round();
    final lo = (answer.low * 100).round();
    final hi = (answer.high * 100).round();
    final factors = [...answer.factors]
      ..sort((a, b) => b.delta.abs().compareTo(a.delta.abs()));

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cumprir a agenda de hoje', style: _section),
          const SizedBox(height: MSpace.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('~$pct%', style: displayTitleStyle(44)),
              const SizedBox(width: MSpace.md),
              Expanded(
                child: RangeBar(low: answer.low, high: answer.high),
              ),
            ],
          ),
          const SizedBox(height: MSpace.xs),
          Text('faixa provável $lo–$hi%', style: _body),
          Text(
            'confiança: $_confLabel · $observedDays dia(s) com desfecho seus',
            style: _body,
          ),
          if (observedDays < 7)
            Text(
              'ainda baseado mais em padrões gerais que nos seus',
              style: _body.copyWith(color: MColors.neutralGray),
            ),
          if (factors.isNotEmpty) ...[
            const SizedBox(height: MSpace.md),
            Text('O que mais pesou', style: _section),
            const SizedBox(height: MSpace.xs),
            for (final f in factors.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${f.delta >= 0 ? '↑' : '↓'} ${f.label}'
                  '   ${_forca(f.delta)}',
                  style: _body,
                ),
              ),
          ],
          const SizedBox(height: MSpace.md),
          Text('Limitações', style: _section),
          const SizedBox(height: MSpace.xs),
          for (final l in answer.limitations) Text('• $l', style: _body),
        ],
      ),
    );
  }
}

/// Barra da faixa provável: trilho claro + segmento mint entre low e high.
class RangeBar extends StatelessWidget {
  final double low;
  final double high;
  const RangeBar({super.key, required this.low, required this.high});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          return Stack(
            children: [
              Container(
                width: w,
                height: 14,
                decoration: BoxDecoration(
                  color: MColors.highlight,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              Positioned(
                left: w * low,
                child: Container(
                  width: w * (high - low),
                  height: 14,
                  decoration: BoxDecoration(
                    color: MColors.mint,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
