import 'package:flutter_test/flutter_test.dart';
import 'package:menthic/features/onboarding/archetype.dart';

void main() {
  test('manhã/5/5 → μ_φ=10, ρ média 0.75, o μ=0.25', () {
    final p = archetypePriors(periodo: 'manha', adiar: 5, subestima: 5);
    expect(p.phi.mean, 10.0);
    expect(p.phi.sd, 2.5);
    expect(p.rho.a / (p.rho.a + p.rho.b), closeTo(0.75, 1e-9));
    expect(p.rho.a + p.rho.b, closeTo(7.0, 1e-9));
    expect(p.o.mean, closeTo(0.25, 1e-9));
    expect(p.o.sd, 0.10);
  });

  test('tarde/1/1 → μ_φ=14, ρ média 0.15, o μ=0.05', () {
    final p = archetypePriors(periodo: 'tarde', adiar: 1, subestima: 1);
    expect(p.phi.mean, 14.0);
    expect(p.rho.a / (p.rho.a + p.rho.b), closeTo(0.15, 1e-9));
    expect(p.o.mean, closeTo(0.05, 1e-9));
  });

  test('noite → μ_φ=18.5; demais traços seguem o neutro', () {
    final p = archetypePriors(periodo: 'noite', adiar: 3, subestima: 3);
    expect(p.phi.mean, 18.5);
    expect(p.p0.a, 6);
    expect(p.p0.b, 4);
    expect(p.s.shape, 3);
    expect(p.r.shape, 5);
  });
}
