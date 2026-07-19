import 'dart:math' as math;
import 'package:oracle_engine/oracle_engine.dart';

/// Um traço do twin pronto para renderizar.
class TraitView {
  final String nome;
  final String valor;
  final String incerteza; // baixa | média | alta
  const TraitView({
    required this.nome,
    required this.valor,
    required this.incerteza,
  });
}

/// Dispersão relativa → rótulo honesto de incerteza.
String uncertaintyLabel(double rel) {
  if (rel < 0.15) return 'baixa';
  if (rel < 0.35) return 'média';
  return 'alta';
}

double betaSd(BetaPrior b) {
  final n = b.a + b.b;
  return math.sqrt(b.a * b.b / (n * n * (n + 1)));
}

String betaUncertainty(BetaPrior b) => uncertaintyLabel(betaSd(b));

/// Os 6 traços do doc 10 A.2, na ordem φ, p0, ρ, s, o, r.
List<TraitView> traitViews(TraitPriors p) {
  String pct(double v) => '${(v * 100).round()}%';
  final phiRel = p.phi.sd / 12.0; // meia-volta do relógio como escala
  final oRel = p.o.sd / 0.5;
  return [
    TraitView(
      nome: 'Pico circadiano',
      valor: '~${p.phi.mean.round()}h',
      incerteza: uncertaintyLabel(phiRel),
    ),
    TraitView(
      nome: 'Produtividade base',
      valor: pct(p.p0.a / (p.p0.a + p.p0.b)),
      incerteza: betaUncertainty(p.p0),
    ),
    TraitView(
      nome: 'Propensão a procrastinar',
      valor: pct(p.rho.a / (p.rho.a + p.rho.b)),
      incerteza: betaUncertainty(p.rho),
    ),
    TraitView(
      nome: 'Sensibilidade ao sono',
      valor: '${(p.s.shape * p.s.scale).toStringAsFixed(2)}/h de débito',
      incerteza: uncertaintyLabel(1 / math.sqrt(p.s.shape)),
    ),
    TraitView(
      nome: 'Otimismo de agenda',
      valor: '+${pct(p.o.mean)} de subestimação',
      incerteza: uncertaintyLabel(oRel),
    ),
    TraitView(
      nome: 'Taxa de recuperação',
      valor: '${(p.r.shape * p.r.scale).toStringAsFixed(2)}/h de descanso',
      incerteza: uncertaintyLabel(1 / math.sqrt(p.r.shape)),
    ),
  ];
}
