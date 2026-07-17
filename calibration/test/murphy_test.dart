import 'package:oracle_calibration/oracle_calibration.dart';
import 'package:test/test.dart';

void main() {
  // Previsões agrupadas em dois valores no MIOLO dos bins (0.25 e 0.75) =>
  // sem fragilidade de fronteira e decomposição exata.
  const d = [
    PredOutcome(0.25, 0),
    PredOutcome(0.25, 0),
    PredOutcome(0.25, 1),
    PredOutcome(0.75, 1),
    PredOutcome(0.75, 1),
    PredOutcome(0.75, 0),
  ];

  test('reliabilityDiagram agrupa nos bins certos', () {
    final bins = reliabilityDiagram(d);
    expect(bins.length, 10);
    final b2 = bins[2]; // [0.2, 0.3) contém 0.25
    expect(b2.n, 3);
    expect(b2.meanPredicted, closeTo(0.25, 1e-12));
    expect(b2.observedFreq, closeTo(1 / 3, 1e-12));
    final b7 = bins[7]; // [0.7, 0.8) contém 0.75
    expect(b7.n, 3);
    expect(b7.observedFreq, closeTo(2 / 3, 1e-12));
    expect(bins[0].n, 0); // bin vazio
    expect(bins[0].meanPredicted, isNaN);
  });

  test('Murphy: componentes exatos e identidade Brier = REL - RES + UNC', () {
    final m = murphy(d);
    expect(m.uncertainty, closeTo(0.25, 1e-12)); // 0.5*0.5
    expect(m.reliability, closeTo(0.0069444444, 1e-9));
    expect(m.resolution, closeTo(0.0277777778, 1e-9));
    expect(
      m.reliability - m.resolution + m.uncertainty,
      closeTo(brierScore(d), 1e-12),
    ); // = 0.2291666667
  });

  test('p == 1.0 cai no último bin', () {
    final bins = reliabilityDiagram(const [PredOutcome(1.0, 1)]);
    expect(bins[9].n, 1);
  });

  test('murphy([]) retorna componentes NaN', () {
    final m = murphy(const []);
    expect(m.reliability, isNaN);
    expect(m.resolution, isNaN);
    expect(m.uncertainty, isNaN);
  });
}
