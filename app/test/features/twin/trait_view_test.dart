import 'package:flutter_test/flutter_test.dart';
import 'package:oracle_engine/oracle_engine.dart';
import 'package:menthic/features/twin/trait_view.dart';

void main() {
  test('prior neutro gera 6 traços na ordem φ,p0,ρ,s,o,r', () {
    final views = traitViews(TraitPriors.neutral);
    expect(views.length, 6);
    expect(views[0].nome, contains('Pico'));
    expect(views[0].valor, contains('14'));
    expect(views[1].valor, contains('%'));
  });

  test('arquétipo manhã mostra pico ~10h', () {
    const p = TraitPriors(
      phi: NormalPrior(10.0, 2.5),
      p0: BetaPrior(6, 4),
      rho: BetaPrior(2, 5),
      s: GammaPrior(3, 0.05),
      o: NormalPrior(0.20, 0.10),
      r: GammaPrior(5, 0.05),
    );
    expect(traitViews(p)[0].valor, contains('10'));
  });

  test('incerteza: Beta apertada é baixa, Beta larga é alta', () {
    const apertada = BetaPrior(60, 40); // sd ~0.049 → baixa
    const larga = BetaPrior(1, 1); // sd ~0.289 → não-baixa
    expect(betaUncertainty(apertada), 'baixa');
    expect(betaUncertainty(larga), isNot('baixa'));
  });
}
