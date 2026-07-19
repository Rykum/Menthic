import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oracle_engine/oracle_engine.dart';
import 'package:menthic/data/providers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('PriorsRepo: neutro quando vazio, round-trip após save', () async {
    final repo = PriorsRepo();
    final p0 = await repo.load();
    expect(p0.phi.mean, TraitPriors.neutral.phi.mean);

    const custom = TraitPriors(
      phi: NormalPrior(10.0, 2.5),
      p0: BetaPrior(6, 4),
      rho: BetaPrior(5.25, 1.75),
      s: GammaPrior(3, 0.05),
      o: NormalPrior(0.25, 0.10),
      r: GammaPrior(5, 0.05),
    );
    await repo.save(custom);
    final p1 = await repo.load();
    expect(p1.phi.mean, 10.0);
    expect(p1.rho.a, 5.25);
  });

  test('onboarded: false por padrão, true após setOnboarded', () async {
    final repo = PriorsRepo();
    expect(await repo.onboarded(), false);
    await repo.setOnboarded();
    expect(await repo.onboarded(), true);
  });

  test('eventStoreProvider resolve um store utilizável', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = await container.read(eventStoreProvider.future);
    expect(await store.all(), isEmpty);
  });
}
