# Aprendizado Bayesiano dos Traços (Fase 0.4) — Plano de Implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir o pacote Dart `oracle_learning` — atualização conjugada dos
traços observáveis (`o` via Normal-Normal, `ρ` via Beta-Bernoulli) a partir dos
eventos, produzindo um `TraitPriors` atualizado que o motor consome.

**Architecture:** Pacote Dart puro `learning/` (depende de `oracle_store` e
`oracle_engine`). Primitivas conjugadas puras; `ObservableExtractor` (eventos →
observações); `TwinLearner` (observações → `TraitPriors` aprendido). Testado com
`dart test`.

**Tech Stack:** Dart SDK ^3.8, `oracle_store` + `oracle_engine` (paths), package:test.

## Global Constraints

- **Local do pacote:** `learning/`; **nome** `oracle_learning`.
- **Dependências:** `oracle_store` (path `../store`), `oracle_engine` (path `../engine`); dev `test: ^1.25.0`.
- **Beta-Bernoulli:** `Beta(a,b).update(k,n) → Beta(a+k, b+n-k)`; `mean=a/(a+b)`; `variance=ab/((a+b)²(a+b+1))`.
- **Normal-Normal (σ² conhecida, padrão 0.25):** prior `N(μ₀,τ₀²)`, n obs média x̄ → `τ_n²=1/(1/τ₀²+n/σ²)`, `μ_n=τ_n²(μ₀/τ₀²+n·x̄/σ²)`; lista vazia → retorna o prior.
- **Observáveis:** `o = ln(dur_real/dur_prevista)` pareado por `cid` (ignora sem `dur_real` ou sem compromisso); `ρ` sobre tarefas aversivas concluídas, sucesso = `atraso_min > 0`.
- **`TwinLearner.learn`:** devolve `TraitPriors` com `o` e `rho` atualizados; `phi/p0/s/r` **idênticos ao prior**. NÃO aprende p0/φ/s/r. NÃO modifica `oracle_store`.
- **Estilo:** `dart analyze` sem issues; `dart format` limpo.

---

### Task 1: Scaffold + primitivas conjugadas (`BetaPosterior`, `NormalPosterior`)

**Files:**
- Create: `learning/pubspec.yaml`
- Create: `learning/lib/oracle_learning.dart`
- Create: `learning/lib/src/conjugate.dart`
- Test: `learning/test/conjugate_test.dart`

**Interfaces:**
- Produces:
  - `class BetaPosterior { final double a, b; const BetaPosterior(this.a, this.b); BetaPosterior update(int successes, int trials); double get mean; double get variance; }`
  - `class NormalPosterior { final double mean, variance; const NormalPosterior(this.mean, this.variance); NormalPosterior updateObservations(List<double> xs, {double sigma2 = 0.25}); }`

- [ ] **Step 1: Criar pacote, barrel, e as primitivas via TDD — escrever o teste que falha**

`learning/pubspec.yaml`:
```yaml
name: oracle_learning
description: Aprendizado Bayesiano dos traços (digital twin) do Project Oracle.
version: 0.1.0
publish_to: none
environment:
  sdk: ^3.8.0
dependencies:
  oracle_store:
    path: ../store
  oracle_engine:
    path: ../engine
dev_dependencies:
  test: ^1.25.0
```

`learning/lib/oracle_learning.dart`:
```dart
export 'src/conjugate.dart';
```

`learning/test/conjugate_test.dart`:
```dart
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
    final post = prior.updateObservations(
      const [0.40, 0.40, 0.40, 0.40],
    );
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
```

- [ ] **Step 2: Rodar o teste para vê-lo falhar**

Run: `cd learning && dart pub get && dart test test/conjugate_test.dart`
Expected: FALHA — `BetaPosterior`/`NormalPosterior` não definidos.

- [ ] **Step 3: Implementar as primitivas**

`learning/lib/src/conjugate.dart`:
```dart
class BetaPosterior {
  final double a, b;
  const BetaPosterior(this.a, this.b);

  BetaPosterior update(int successes, int trials) =>
      BetaPosterior(a + successes, b + (trials - successes));

  double get mean => a / (a + b);

  double get variance {
    final s = a + b;
    return (a * b) / (s * s * (s + 1));
  }
}

class NormalPosterior {
  final double mean, variance;
  const NormalPosterior(this.mean, this.variance);

  /// Normal-Normal com variância de observação conhecida [sigma2].
  NormalPosterior updateObservations(List<double> xs, {double sigma2 = 0.25}) {
    if (xs.isEmpty) return this;
    final n = xs.length;
    final xbar = xs.reduce((s, x) => s + x) / n;
    final priorPrecision = 1.0 / variance;
    final dataPrecision = n / sigma2;
    final postVar = 1.0 / (priorPrecision + dataPrecision);
    final postMean = postVar * (mean * priorPrecision + xbar * dataPrecision);
    return NormalPosterior(postMean, postVar);
  }
}
```

- [ ] **Step 4: Rodar o teste para vê-lo passar**

Run: `cd learning && dart test test/conjugate_test.dart`
Expected: PASSA (3 testes).

- [ ] **Step 5: Commit**

```bash
git add learning/pubspec.yaml learning/lib learning/test/conjugate_test.dart
git commit -m "feat(learning): scaffold + primitivas conjugadas (Beta-Bernoulli, Normal-Normal)"
```

---

### Task 2: `ObservableExtractor` (eventos → observações de traço)

**Files:**
- Create: `learning/lib/src/observables.dart`
- Modify: `learning/lib/oracle_learning.dart`
- Test: `learning/test/observables_test.dart`

**Interfaces:**
- Consumes: `oracle_store` (`EventStore`, `EventTypes`, `InMemoryEventStore`, `EventDraft`, `compromissoCriado`).
- Produces:
  - `class TraitObservations { final List<double> o; final int rhoSucessos, rhoTentativas; const TraitObservations(this.o, this.rhoSucessos, this.rhoTentativas); }`
  - `class ObservableExtractor { const ObservableExtractor(); Future<TraitObservations> extract(EventStore store); }`

- [ ] **Step 1: Adicionar export**

Em `learning/lib/oracle_learning.dart`, adicionar:
```dart
export 'src/observables.dart';
```

- [ ] **Step 2: Escrever o teste que falha**

`learning/test/observables_test.dart`:
```dart
import 'dart:math' as math;
import 'package:oracle_learning/oracle_learning.dart';
import 'package:oracle_store/oracle_store.dart';
import 'package:test/test.dart';

void main() {
  final ts = DateTime.utc(2026, 7, 17, 8);

  EventDraft concluidaComDuracao({
    required String cid,
    required double durReal,
    required double atrasoMin,
  }) =>
      EventDraft(
        ts: ts,
        type: EventTypes.tarefaConcluida,
        payload: {'cid': cid, 'atraso_min': atrasoMin, 'dur_real': durReal},
      );

  test('extrai o = ln(dur_real/dur_prevista) e conta ρ', () async {
    final store = InMemoryEventStore();
    // tarefa aversiva, planejada 2.0, real 2.5, atrasou
    await store.append(compromissoCriado(
      ts: ts, cid: 'estudo', inicio: 14.0, durPrevista: 2.0, tipo: 'estudo',
      aversivo: true,
    ));
    await store.append(
        concluidaComDuracao(cid: 'estudo', durReal: 2.5, atrasoMin: 20));

    final obs = await const ObservableExtractor().extract(store);
    expect(obs.o.length, 1);
    expect(obs.o.first, closeTo(math.log(2.5 / 2.0), 1e-12));
    expect(obs.rhoTentativas, 1);
    expect(obs.rhoSucessos, 1); // atraso 20 > 0
  });

  test('tarefa sem dur_real é ignorada para o; não-aversiva não conta ρ', () async {
    final store = InMemoryEventStore();
    await store.append(compromissoCriado(
      ts: ts, cid: 'trab', inicio: 9.0, durPrevista: 1.0, tipo: 'trabalho',
      aversivo: false,
    ));
    // conclusão SEM dur_real (helper padrão do store)
    await store.append(tarefaConcluida(ts: ts, cid: 'trab', atrasoMin: 0));

    final obs = await const ObservableExtractor().extract(store);
    expect(obs.o, isEmpty); // sem dur_real
    expect(obs.rhoTentativas, 0); // não-aversiva
  });
}
```

- [ ] **Step 3: Rodar o teste para vê-lo falhar**

Run: `cd learning && dart test test/observables_test.dart`
Expected: FALHA — `ObservableExtractor`/`TraitObservations` não definidos.

- [ ] **Step 4: Implementar o extractor**

`learning/lib/src/observables.dart`:
```dart
import 'dart:math' as math;
import 'package:oracle_store/oracle_store.dart';

class TraitObservations {
  final List<double> o;
  final int rhoSucessos, rhoTentativas;
  const TraitObservations(this.o, this.rhoSucessos, this.rhoTentativas);
}

class ObservableExtractor {
  const ObservableExtractor();

  Future<TraitObservations> extract(EventStore store) async {
    final events = await store.all();

    final planned = <String, double>{};
    final aversive = <String, bool>{};
    for (final e in events) {
      if (e.type == EventTypes.compromissoCriado) {
        final cid = e.payload['cid'] as String;
        planned[cid] = (e.payload['dur_prevista'] as num).toDouble();
        aversive[cid] = (e.payload['aversivo'] as bool?) ?? false;
      }
    }

    final oObs = <double>[];
    var rhoSucessos = 0, rhoTentativas = 0;
    for (final e in events) {
      if (e.type != EventTypes.tarefaConcluida) continue;
      final cid = e.payload['cid'] as String;

      final durReal = e.payload['dur_real'];
      final dp = planned[cid];
      if (durReal != null && dp != null) {
        final dr = (durReal as num).toDouble();
        if (dr > 0 && dp > 0) oObs.add(math.log(dr / dp));
      }

      if (aversive[cid] == true) {
        rhoTentativas += 1;
        final atraso = (e.payload['atraso_min'] as num?)?.toDouble() ?? 0.0;
        if (atraso > 0) rhoSucessos += 1;
      }
    }
    return TraitObservations(oObs, rhoSucessos, rhoTentativas);
  }
}
```

- [ ] **Step 5: Rodar o teste para vê-lo passar**

Run: `cd learning && dart test test/observables_test.dart`
Expected: PASSA (2 testes).

- [ ] **Step 6: Commit**

```bash
git add learning/lib/src/observables.dart learning/lib/oracle_learning.dart learning/test/observables_test.dart
git commit -m "feat(learning): ObservableExtractor (eventos -> observações de o e ρ)"
```

---

### Task 3: `TwinLearner` (observações → `TraitPriors` aprendido)

**Files:**
- Create: `learning/lib/src/twin_learner.dart`
- Modify: `learning/lib/oracle_learning.dart`
- Test: `learning/test/twin_learner_test.dart`

**Interfaces:**
- Consumes: `oracle_engine` (`TraitPriors`, `NormalPrior`, `BetaPrior`), `oracle_store` (`EventStore`), `BetaPosterior`, `NormalPosterior`, `ObservableExtractor`.
- Produces:
  - `class TwinLearner { const TwinLearner(); Future<TraitPriors> learn(EventStore store, {TraitPriors prior = TraitPriors.neutral, double sigma2 = 0.25}); }`

- [ ] **Step 1: Adicionar export**

Em `learning/lib/oracle_learning.dart`, adicionar:
```dart
export 'src/twin_learner.dart';
```

- [ ] **Step 2: Escrever o teste que falha (oráculo exato)**

`learning/test/twin_learner_test.dart`:
```dart
import 'dart:math' as math;
import 'package:oracle_engine/oracle_engine.dart';
import 'package:oracle_learning/oracle_learning.dart';
import 'package:oracle_store/oracle_store.dart';
import 'package:test/test.dart';

void main() {
  final ts = DateTime.utc(2026, 7, 17, 8);

  test('learn atualiza o e ρ; mantém p0/phi/s/r do prior', () async {
    final store = InMemoryEventStore();
    // 1 tarefa aversiva planejada 2.0, real 2.0 (o obs = ln(1)=0), atraso 0
    await store.append(compromissoCriado(
      ts: ts, cid: 'e', inicio: 14.0, durPrevista: 2.0, tipo: 'estudo',
      aversivo: true,
    ));
    await store.append(EventDraft(
      ts: ts,
      type: EventTypes.tarefaConcluida,
      payload: const {'cid': 'e', 'atraso_min': 0.0, 'dur_real': 2.0},
    ));

    final learned = await const TwinLearner().learn(store);

    // o: N(0.20,0.01) + [0.0], sigma2=0.25 => postVar=1/104, postMean=20/104
    expect(learned.o.mean, closeTo(20 / 104, 1e-12));
    expect(learned.o.sd, closeTo(math.sqrt(1 / 104), 1e-12));
    expect(learned.o.sd, lessThan(0.10)); // apertou vs prior neutro

    // ρ: Beta(2,5).update(0,1) => Beta(2,6)
    expect(learned.rho.a, 2);
    expect(learned.rho.b, 6);

    // resto igual ao prior neutro
    expect(learned.p0.a, 6);
    expect(learned.p0.b, 4);
    expect(learned.phi.mean, 14.0);
    expect(learned.phi.sd, 2.5);
  });
}
```

- [ ] **Step 3: Rodar o teste para vê-lo falhar**

Run: `cd learning && dart test test/twin_learner_test.dart`
Expected: FALHA — `TwinLearner` não definido.

- [ ] **Step 4: Implementar o learner**

`learning/lib/src/twin_learner.dart`:
```dart
import 'dart:math' as math;
import 'package:oracle_engine/oracle_engine.dart';
import 'package:oracle_store/oracle_store.dart';
import 'conjugate.dart';
import 'observables.dart';

class TwinLearner {
  const TwinLearner();

  Future<TraitPriors> learn(
    EventStore store, {
    TraitPriors prior = TraitPriors.neutral,
    double sigma2 = 0.25,
  }) async {
    final obs = await const ObservableExtractor().extract(store);

    // o: Normal-Normal a partir de prior.o
    final oPrior = NormalPosterior(prior.o.mean, prior.o.sd * prior.o.sd);
    final oPost = oPrior.updateObservations(obs.o, sigma2: sigma2);
    final newO = NormalPrior(oPost.mean, math.sqrt(oPost.variance));

    // rho: Beta-Bernoulli a partir de prior.rho
    final rhoPost = BetaPosterior(prior.rho.a, prior.rho.b)
        .update(obs.rhoSucessos, obs.rhoTentativas);
    final newRho = BetaPrior(rhoPost.a, rhoPost.b);

    return TraitPriors(
      phi: prior.phi,
      p0: prior.p0,
      rho: newRho,
      s: prior.s,
      o: newO,
      r: prior.r,
    );
  }
}
```

- [ ] **Step 5: Rodar o teste para vê-lo passar**

Run: `cd learning && dart test test/twin_learner_test.dart`
Expected: PASSA.

- [ ] **Step 6: Commit**

```bash
git add learning/lib/src/twin_learner.dart learning/lib/oracle_learning.dart learning/test/twin_learner_test.dart
git commit -m "feat(learning): TwinLearner (observações -> TraitPriors aprendido)"
```

---

### Task 4: Ponta a ponta (store → learn → predict) + verificação

**Files:**
- Test: `learning/test/end_to_end_test.dart`

**Interfaces:**
- Consumes: todo o pacote + `oracle_store` + `oracle_engine` (`answerAgenda`, `predict`, `DayState`, `Commitment`).
- Produces: nada (testes de integração).

- [ ] **Step 1: Escrever o teste ponta a ponta**

`learning/test/end_to_end_test.dart`:
```dart
import 'package:oracle_engine/oracle_engine.dart';
import 'package:oracle_learning/oracle_learning.dart';
import 'package:oracle_store/oracle_store.dart';
import 'package:test/test.dart';

void main() {
  final ts = DateTime.utc(2026, 7, 17, 8);

  Future<InMemoryEventStore> historico() async {
    final store = InMemoryEventStore();
    for (var i = 0; i < 10; i++) {
      await store.append(compromissoCriado(
        ts: ts, cid: 'c$i', inicio: 14.0, durPrevista: 2.0, tipo: 'estudo',
        aversivo: true,
      ));
      await store.append(EventDraft(
        ts: ts,
        type: EventTypes.tarefaConcluida,
        payload: {'cid': 'c$i', 'atraso_min': 15.0, 'dur_real': 2.3},
      ));
    }
    return store;
  }

  test('learn aperta o e ρ vs o prior neutro', () async {
    final learned = await const TwinLearner().learn(await historico());
    // o apertou
    expect(learned.o.sd, lessThan(TraitPriors.neutral.o.sd));
    // ρ ficou mais concentrado (a+b maior) e mais alto (procrastinou sempre)
    final neutralConc = TraitPriors.neutral.rho.a + TraitPriors.neutral.rho.b;
    expect(learned.rho.a + learned.rho.b, greaterThan(neutralConc));
    expect(learned.rho.a, 12); // Beta(2,5)+10/10 => Beta(12,5)
    expect(learned.rho.b, 5);
  });

  test('predict roda com o twin aprendido e a banda não aumenta', () async {
    final learned = await const TwinLearner().learn(await historico());
    final state = DayState(
      sleepDebt: 2.0,
      dayEnd: 18.0,
      agenda: const [
        Commitment(
          id: 'estudo', start: 14.0, planned: 2.0, type: 'estudo',
          priority: 2, aversive: true,
        ),
      ],
    );

    final ansNeutro =
        answerAgenda(state, TraitPriors.neutral, observedDays: 0, seed: 7);
    final ansAprendido =
        answerAgenda(state, learned, observedDays: 10, seed: 7);

    expect(ansAprendido.estimate, inInclusiveRange(0.0, 1.0));
    expect(ansAprendido.low, lessThanOrEqualTo(ansAprendido.estimate));
    expect(ansAprendido.high, greaterThanOrEqualTo(ansAprendido.estimate));
    // Honesto: a banda não aumenta (encolhe parcialmente; payoff pleno espera p0)
    final larguraNeutro = ansNeutro.high - ansNeutro.low;
    final larguraAprendido = ansAprendido.high - ansAprendido.low;
    expect(larguraAprendido, lessThanOrEqualTo(larguraNeutro + 0.05));
  });
}
```

- [ ] **Step 2: Rodar o teste ponta a ponta**

Run: `cd learning && dart test test/end_to_end_test.dart`
Expected: PASSA (2 testes).

- [ ] **Step 3: Rodar a suíte inteira + análise estática**

Run: `cd learning && dart analyze && dart test`
Expected: `No issues found!` e TODOS os testes do pacote passam.

- [ ] **Step 4: Commit**

```bash
git add learning/test/end_to_end_test.dart
git commit -m "test(learning): ponta a ponta store->learn->predict (honesto sobre a banda)"
```

---

## Notas para quem executar

- `oracle_learning` depende de `oracle_store` E `oracle_engine` por path. Rode
  `dart pub get` em `learning/` antes do primeiro teste.
- A conclusão com `dur_real` é logada via `EventDraft` genérico (payload com
  `dur_real`); **não** modificamos o `oracle_store`.
- Não afrouxe os oráculos exatos conjugados — se falharem, a fórmula (precisão do
  Normal-Normal ou contagem do Beta) está errada, não o teste.
- O teste de banda é **intencionalmente honesto**: só garante que não aumenta
  (tolerância 0.05), porque o estreitamento pleno depende de aprender `p0`
  (fora do escopo desta fase).
