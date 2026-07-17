import 'day.dart';
import 'traits.dart';
import 'engine.dart';
import 'sensitivity.dart';

enum Confidence { alta, media, baixa }

Confidence confidenceFromWidth(double width) {
  if (width < 0.10) return Confidence.alta;
  if (width < 0.20) return Confidence.media;
  return Confidence.baixa;
}

class OracleAnswer {
  final String question;
  final double estimate;
  final double low;
  final double high;
  final Confidence confidence;
  final List<Factor> factors;
  final List<String> limitations;
  const OracleAnswer({
    required this.question,
    required this.estimate,
    required this.low,
    required this.high,
    required this.confidence,
    required this.factors,
    required this.limitations,
  });
}

OracleAnswer answerAgenda(
  DayState state,
  TraitPriors priors, {
  int observedDays = 0,
  int seed = 0,
}) {
  final p = predict(state, priors, seed: seed);
  final factors = sensitivity(state, priors, seed: seed);
  final confidence = confidenceFromWidth(p.high - p.low);

  final limitations = <String>[];
  if (observedDays < 30) {
    limitations.add('poucos dados: $observedDays dias observados');
  }
  if ((p.high - p.low) >= 0.20) {
    limitations.add('alta incerteza (faixa larga)');
  }
  if (limitations.isEmpty) {
    limitations.add('modelo sempre sujeito a contexto não informado');
  }

  return OracleAnswer(
    question: 'Cumprir a agenda de hoje',
    estimate: p.estimate,
    low: p.low,
    high: p.high,
    confidence: confidence,
    factors: factors,
    limitations: limitations,
  );
}
