import 'package:oracle_learning/oracle_learning.dart';
import 'package:test/test.dart';

void main() {
  test('Beta-Bernoulli: Beta(2,5)+3/10 => Beta(5,12), variância encolhe', () {
    const prior = BetaPosterior(2, 5);
    final post = prior.update(3, 10);
    expect(post.a, 5);
    expect(post.b, 12);
    expect(post.mean, closeTo(5 / 17, 1e-12));
    expect(post.variance, lessThan(prior.variance));
  });

  test('Normal-Normal: N(0.20,0.01)+4 obs média 0.40 (σ²=0.25)', () {
    const prior = NormalPosterior(0.20, 0.01);
    final post = prior.updateObservations(const [0.40, 0.40, 0.40, 0.40]);
    expect(post.variance, closeTo(1 / 116, 1e-12)); // 1/(100 + 16)
    expect(post.mean, closeTo(26.4 / 116, 1e-12)); // (20 + 6.4)/116
    expect(post.variance, lessThan(0.01)); // encolheu
  });

  test('lista vazia => posterior = prior', () {
    const prior = NormalPosterior(0.20, 0.01);
    final post = prior.updateObservations(const []);
    expect(post.mean, 0.20);
    expect(post.variance, 0.01);
  });
}
