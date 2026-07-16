# Fase 0 — Núcleo do Motor de Decisão (Dart puro) — Plano de Implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir, em Dart puro e headless, o núcleo do Motor de Decisão que, a
partir de distribuições de traços e do estado de um dia, produz uma previsão
probabilística (formato `OracleAnswer`) e reproduz o exemplo resolvido do doc 10.

**Architecture:** Pacote Dart standalone `engine/` (sem Flutter), testável com
`dart test`. Camadas: amostragem aleatória (RNG semente + distribuições) →
traços/priors → modelo de energia/fadiga → simulação de dia (semi-Markov +
planning fallacy) → Monte Carlo aninhado (epistêmico × aleatório) → análise de
sensibilidade → montagem do `OracleAnswer`. Determinismo por semente garante que
os testes sejam reproduzíveis.

**Tech Stack:** Dart SDK ^3.8, package:test. Sem dependências de runtime externas.

## Global Constraints

- **Local do pacote:** `engine/` na raiz do repositório.
- **Nome do pacote:** `oracle_engine`.
- **Determinismo obrigatório:** toda aleatoriedade passa por `SeededRng`; mesma
  semente ⇒ mesma saída. Nunca usar `math.Random()` sem semente no código de
  produção.
- **Constantes do modelo (doc 10 A.1), exatas:** `c0=-1.0`, `cP=2.5`, `cF=2.0`,
  `A=0.6`, `f0base=0.10`, `kD=0.08`, `N=2000` (outer `K=200` × inner `m=10`),
  `n0=10`, `λ=1.0` (sem esquecimento na Fase 0).
- **Priors neutros (doc 10 A.2):** `φ~Normal(14.0,2.5)`, `p0~Beta(6,4)`,
  `ρ~Beta(2,5)`, `s~Gamma(3,0.05)`, `o~Normal(0.20,0.10)`, `r~Gamma(5,0.05)`.
- **Sem persistência, sem UI, sem aprendizado** neste plano (planos futuros). Os
  traços entram como distribuições dadas; nada é lido de disco.
- **Estilo:** `dart format` limpo; sem warnings em `dart analyze`.

---

### Task 1: Scaffold do pacote + `SeededRng` (amostradores base)

**Files:**
- Create: `engine/pubspec.yaml`
- Create: `engine/lib/oracle_engine.dart`
- Create: `engine/lib/src/rng.dart`
- Test: `engine/test/rng_test.dart`

**Interfaces:**
- Consumes: nada.
- Produces: `SeededRng(int seed)` com métodos
  `double nextUniform()`, `double nextNormal(double mean, double sd)`,
  `double nextExponential(double rate)`, `bool nextBernoulli(double p)`,
  `double nextLogNormal(double mu, double sigma)`.

- [ ] **Step 1: Criar o pacote e o barrel**

`engine/pubspec.yaml`:
```yaml
name: oracle_engine
description: Motor de decisao probabilistico do Project Oracle (Fase 0).
version: 0.1.0
publish_to: none
environment:
  sdk: ^3.8.0
dev_dependencies:
  test: ^1.25.0
```

`engine/lib/oracle_engine.dart`:
```dart
export 'src/rng.dart';
```

- [ ] **Step 2: Escrever o teste que falha**

`engine/test/rng_test.dart`:
```dart
import 'dart:math' as math;
import 'package:oracle_engine/oracle_engine.dart';
import 'package:test/test.dart';

void main() {
  test('mesma semente produz a mesma sequencia', () {
    final a = SeededRng(42);
    final b = SeededRng(42);
    for (var i = 0; i < 5; i++) {
      expect(a.nextUniform(), equals(b.nextUniform()));
    }
  });

  test('nextNormal aproxima media e desvio', () {
    final rng = SeededRng(7);
    final xs = List.generate(20000, (_) => rng.nextNormal(2.0, 0.5));
    final mean = xs.reduce((s, x) => s + x) / xs.length;
    final varc =
        xs.map((x) => (x - mean) * (x - mean)).reduce((s, x) => s + x) /
            xs.length;
    expect(mean, closeTo(2.0, 0.02));
    expect(math.sqrt(varc), closeTo(0.5, 0.02));
  });

  test('nextBernoulli aproxima a probabilidade', () {
    final rng = SeededRng(1);
    final k = List.generate(20000, (_) => rng.nextBernoulli(0.3) ? 1 : 0)
        .reduce((s, x) => s + x);
    expect(k / 20000, closeTo(0.3, 0.02));
  });
}
```

- [ ] **Step 3: Rodar o teste para vê-lo falhar**

Run: `cd engine && dart pub get && dart test test/rng_test.dart`
Expected: FALHA — `SeededRng` não definido.

- [ ] **Step 4: Implementar `SeededRng`**

`engine/lib/src/rng.dart`:
```dart
import 'dart:math' as math;

class SeededRng {
  final math.Random _r;
  SeededRng(int seed) : _r = math.Random(seed);

  double nextUniform() => _r.nextDouble();

  double nextNormal(double mean, double sd) {
    final u1 = _r.nextDouble();
    final u2 = _r.nextDouble();
    final z = math.sqrt(-2.0 * math.log(u1 <= 0 ? 1e-12 : u1)) *
        math.cos(2 * math.pi * u2);
    return mean + sd * z;
  }

  double nextExponential(double rate) {
    final u = _r.nextDouble();
    return -math.log(u <= 0 ? 1e-12 : u) / rate;
  }

  bool nextBernoulli(double p) => _r.nextDouble() < p;

  double nextLogNormal(double mu, double sigma) =>
      math.exp(nextNormal(mu, sigma));
}
```

- [ ] **Step 5: Rodar o teste para vê-lo passar**

Run: `cd engine && dart test test/rng_test.dart`
Expected: PASSA (3 testes).

- [ ] **Step 6: Commit**

```bash
git add engine/pubspec.yaml engine/lib engine/test/rng_test.dart
git commit -m "feat(engine): scaffold do pacote e SeededRng com amostradores base"
```

---

### Task 2: Amostradores Gamma e Beta (Marsaglia-Tsang)

**Files:**
- Modify: `engine/lib/src/rng.dart`
- Test: `engine/test/rng_gamma_beta_test.dart`

**Interfaces:**
- Consumes: `SeededRng` (Task 1).
- Produces: `double SeededRng.nextGamma(double shape, double scale)`,
  `double SeededRng.nextBeta(double a, double b)`.

- [ ] **Step 1: Escrever o teste que falha**

`engine/test/rng_gamma_beta_test.dart`:
```dart
import 'package:oracle_engine/oracle_engine.dart';
import 'package:test/test.dart';

double mean(List<double> xs) => xs.reduce((s, x) => s + x) / xs.length;

void main() {
  test('Gamma(3, 0.05) tem media ~0.15', () {
    final rng = SeededRng(11);
    final xs = List.generate(40000, (_) => rng.nextGamma(3, 0.05));
    expect(mean(xs), closeTo(0.15, 0.005));
    expect(xs.every((x) => x >= 0), isTrue);
  });

  test('Gamma com shape<1 funciona', () {
    final rng = SeededRng(2);
    final xs = List.generate(40000, (_) => rng.nextGamma(0.5, 2.0));
    expect(mean(xs), closeTo(1.0, 0.05)); // media = shape*scale
  });

  test('Beta(6,4) tem media ~0.6 e fica em (0,1)', () {
    final rng = SeededRng(5);
    final xs = List.generate(40000, (_) => rng.nextBeta(6, 4));
    expect(mean(xs), closeTo(0.6, 0.01));
    expect(xs.every((x) => x > 0 && x < 1), isTrue);
  });
}
```

- [ ] **Step 2: Rodar o teste para vê-lo falhar**

Run: `cd engine && dart test test/rng_gamma_beta_test.dart`
Expected: FALHA — `nextGamma` não definido.

- [ ] **Step 3: Implementar Gamma e Beta**

Adicionar ao final da classe `SeededRng` em `engine/lib/src/rng.dart` (antes da
chave de fechamento da classe):
```dart
  // Marsaglia-Tsang para shape >= 1; recursao para shape < 1.
  double nextGamma(double shape, double scale) {
    if (shape < 1.0) {
      final u = _r.nextDouble();
      return nextGamma(shape + 1.0, scale) *
          math.pow(u <= 0 ? 1e-12 : u, 1.0 / shape).toDouble();
    }
    final d = shape - 1.0 / 3.0;
    final c = 1.0 / math.sqrt(9.0 * d);
    while (true) {
      double x, v;
      do {
        x = nextNormal(0.0, 1.0);
        v = 1.0 + c * x;
      } while (v <= 0);
      v = v * v * v;
      final u = _r.nextDouble();
      if (u < 1.0 - 0.0331 * x * x * x * x) return d * v * scale;
      if (math.log(u <= 0 ? 1e-12 : u) <
          0.5 * x * x + d * (1.0 - v + math.log(v))) {
        return d * v * scale;
      }
    }
  }

  double nextBeta(double a, double b) {
    final x = nextGamma(a, 1.0);
    final y = nextGamma(b, 1.0);
    return x / (x + y);
  }
```

- [ ] **Step 4: Rodar o teste para vê-lo passar**

Run: `cd engine && dart test test/rng_gamma_beta_test.dart`
Expected: PASSA (3 testes).

- [ ] **Step 5: Commit**

```bash
git add engine/lib/src/rng.dart engine/test/rng_gamma_beta_test.dart
git commit -m "feat(engine): amostradores Gamma (Marsaglia-Tsang) e Beta"
```

---

### Task 3: Traços, priors e amostragem

**Files:**
- Create: `engine/lib/src/traits.dart`
- Modify: `engine/lib/oracle_engine.dart`
- Test: `engine/test/traits_test.dart`

**Interfaces:**
- Consumes: `SeededRng` (Task 1-2).
- Produces:
  - `class Traits { final double phi, p0, rho, s, o, r; const Traits({...}); }`
  - `class NormalPrior { final double mean, sd; }`,
    `class BetaPrior { final double a, b; }`,
    `class GammaPrior { final double shape, scale; }`
  - `class TraitPriors { ...; static const TraitPriors neutral; Traits sample(SeededRng rng); }`

- [ ] **Step 1: Adicionar export**

Em `engine/lib/oracle_engine.dart`, adicionar a linha:
```dart
export 'src/traits.dart';
```

- [ ] **Step 2: Escrever o teste que falha**

`engine/test/traits_test.dart`:
```dart
import 'package:oracle_engine/oracle_engine.dart';
import 'package:test/test.dart';

void main() {
  test('prior neutro amostra traços em faixas plausíveis', () {
    final rng = SeededRng(3);
    final xs = List.generate(20000, (_) => TraitPriors.neutral.sample(rng));
    double avg(double Function(Traits) f) =>
        xs.map(f).reduce((s, x) => s + x) / xs.length;

    expect(avg((t) => t.phi), closeTo(14.0, 0.1));
    expect(avg((t) => t.p0), closeTo(0.6, 0.01));
    expect(avg((t) => t.rho), closeTo(2 / 7, 0.01));
    expect(avg((t) => t.o), closeTo(0.20, 0.01));
    expect(xs.every((t) => t.p0 > 0 && t.p0 < 1), isTrue);
    expect(xs.every((t) => t.s >= 0 && t.r >= 0), isTrue);
  });
}
```

- [ ] **Step 3: Rodar o teste para vê-lo falhar**

Run: `cd engine && dart test test/traits_test.dart`
Expected: FALHA — `Traits`/`TraitPriors` não definidos.

- [ ] **Step 4: Implementar traços e priors**

`engine/lib/src/traits.dart`:
```dart
import 'rng.dart';

class Traits {
  final double phi; // pico circadiano (hora)
  final double p0; // baseline de produtividade 0..1
  final double rho; // propensao a procrastinar 0..1
  final double s; // sensibilidade ao sono (por hora de debito)
  final double o; // otimismo de agenda (offset log-duracao)
  final double r; // taxa de recuperacao (por hora)
  const Traits({
    required this.phi,
    required this.p0,
    required this.rho,
    required this.s,
    required this.o,
    required this.r,
  });
}

class NormalPrior {
  final double mean, sd;
  const NormalPrior(this.mean, this.sd);
}

class BetaPrior {
  final double a, b;
  const BetaPrior(this.a, this.b);
}

class GammaPrior {
  final double shape, scale;
  const GammaPrior(this.shape, this.scale);
}

class TraitPriors {
  final NormalPrior phi;
  final BetaPrior p0;
  final BetaPrior rho;
  final GammaPrior s;
  final NormalPrior o;
  final GammaPrior r;
  const TraitPriors({
    required this.phi,
    required this.p0,
    required this.rho,
    required this.s,
    required this.o,
    required this.r,
  });

  // Arquetipo neutro (doc 10 A.2)
  static const TraitPriors neutral = TraitPriors(
    phi: NormalPrior(14.0, 2.5),
    p0: BetaPrior(6, 4),
    rho: BetaPrior(2, 5),
    s: GammaPrior(3, 0.05),
    o: NormalPrior(0.20, 0.10),
    r: GammaPrior(5, 0.05),
  );

  Traits sample(SeededRng rng) => Traits(
    phi: rng.nextNormal(phi.mean, phi.sd),
    p0: rng.nextBeta(p0.a, p0.b).clamp(0.0, 1.0),
    rho: rng.nextBeta(rho.a, rho.b).clamp(0.0, 1.0),
    s: rng.nextGamma(s.shape, s.scale),
    o: rng.nextNormal(o.mean, o.sd),
    r: rng.nextGamma(r.shape, r.scale),
  );
}
```

- [ ] **Step 5: Rodar o teste para vê-lo passar**

Run: `cd engine && dart test test/traits_test.dart`
Expected: PASSA.

- [ ] **Step 6: Commit**

```bash
git add engine/lib/src/traits.dart engine/lib/oracle_engine.dart engine/test/traits_test.dart
git commit -m "feat(engine): traços, priors e amostragem do arquétipo neutro"
```

---

### Task 4: Modelo de energia e fadiga (oráculos exatos do doc 10)

**Files:**
- Create: `engine/lib/src/model.dart`
- Modify: `engine/lib/oracle_engine.dart`
- Test: `engine/test/model_test.dart`

**Interfaces:**
- Consumes: `Traits` (Task 3).
- Produces:
  - `double logistic(double x)`
  - `double energy(double t, Traits tr, double sleepDebt, double fatigue)`
  - `double initialFatigue(double sleepDebt)`
  - `double fatigueStep(double fatigue, double alpha, double recovery, double dtHours)`
  - `const Map<String,double> activityAlpha`

- [ ] **Step 1: Adicionar export**

Em `engine/lib/oracle_engine.dart`, adicionar:
```dart
export 'src/model.dart';
```

- [ ] **Step 2: Escrever o teste que falha (com os números do doc 10 §C.2)**

`engine/test/model_test.dart`:
```dart
import 'package:oracle_engine/oracle_engine.dart';
import 'package:test/test.dart';

void main() {
  test('initialFatigue: 0.10 + 0.08*debito', () {
    expect(initialFatigue(2.0), closeTo(0.26, 1e-9));
    expect(initialFatigue(0.0), closeTo(0.10, 1e-9));
  });

  test('energy reproduz o valor do exemplo (doc 10 C.2 = ~0.4611)', () {
    const tr = Traits(phi: 9.6, p0: 0.60, rho: 0.31, s: 0.15, o: 0.25, r: 0.25);
    // t=14h, debito=2, fadiga=0.30
    expect(energy(14.0, tr, 2.0, 0.30), closeTo(0.4611, 1e-3));
  });

  test('energy sobe no pico e cai fora do pico', () {
    const tr = Traits(phi: 9.6, p0: 0.60, rho: 0.31, s: 0.15, o: 0.25, r: 0.25);
    final atPeak = energy(9.6, tr, 0.0, 0.0);
    final offPeak = energy(9.6 + 12.0, tr, 0.0, 0.0);
    expect(atPeak, greaterThan(offPeak));
  });

  test('fatigueStep acumula e recupera com clamp', () {
    expect(fatigueStep(0.20, 0.10, 0.0, 1.0), closeTo(0.30, 1e-9));
    expect(fatigueStep(0.20, 0.0, 0.25, 1.0), closeTo(0.0, 1e-9)); // clamp em 0
    expect(fatigueStep(0.95, 0.10, 0.0, 1.0), closeTo(1.0, 1e-9)); // clamp em 1
  });

  test('logistic(0)=0.5', () {
    expect(logistic(0.0), closeTo(0.5, 1e-12));
    expect(logistic(-0.155956), closeTo(0.4611, 1e-3));
  });
}
```

- [ ] **Step 3: Rodar o teste para vê-lo falhar**

Run: `cd engine && dart test test/model_test.dart`
Expected: FALHA — funções não definidas.

- [ ] **Step 4: Implementar o modelo**

`engine/lib/src/model.dart`:
```dart
import 'dart:math' as math;
import 'traits.dart';

class ModelConstants {
  static const double c0 = -1.0;
  static const double cP = 2.5;
  static const double cF = 2.0;
  static const double amp = 0.6;
  static const double f0base = 0.10;
  static const double kD = 0.08;
}

double logistic(double x) => 1.0 / (1.0 + math.exp(-x));

double energy(double t, Traits tr, double sleepDebt, double fatigue) {
  final circ =
      ModelConstants.amp * math.cos(2 * math.pi * (t - tr.phi) / 24.0);
  final eta = ModelConstants.c0 +
      ModelConstants.cP * tr.p0 -
      tr.s * sleepDebt -
      ModelConstants.cF * fatigue +
      circ;
  return logistic(eta);
}

double initialFatigue(double sleepDebt) =>
    (ModelConstants.f0base + ModelConstants.kD * sleepDebt).clamp(0.0, 1.0);

double fatigueStep(
    double fatigue, double alpha, double recovery, double dtHours) {
  return (fatigue + alpha * dtHours - recovery * dtHours).clamp(0.0, 1.0);
}

const Map<String, double> activityAlpha = {
  'foco': 0.10,
  'trabalho_raso': 0.06,
  'treino': 0.20,
  'deslocamento': 0.04,
  'refeicao': 0.0,
  'descanso': 0.0,
  'sono': 0.0,
};
```

- [ ] **Step 5: Rodar o teste para vê-lo passar**

Run: `cd engine && dart test test/model_test.dart`
Expected: PASSA (5 testes).

- [ ] **Step 6: Commit**

```bash
git add engine/lib/src/model.dart engine/lib/oracle_engine.dart engine/test/model_test.dart
git commit -m "feat(engine): modelo de energia/fadiga com oráculos exatos do doc 10"
```

---

### Task 5: Modelo do dia e `simulateDay`

**Files:**
- Create: `engine/lib/src/day.dart`
- Modify: `engine/lib/oracle_engine.dart`
- Test: `engine/test/day_test.dart`

**Interfaces:**
- Consumes: `SeededRng`, `Traits`, `energy`, `initialFatigue`, `fatigueStep`,
  `activityAlpha`, `logistic`.
- Produces:
  - `class Commitment { final String id; final double start; final double planned; final String type; final int priority; final bool aversive; const Commitment({...}); }`
  - `class DayState { final double sleepDebt; final double dayEnd; final List<Commitment> agenda; const DayState({...}); }`
  - `class DayOutcome { final Map<String,bool> completed; final bool metAgenda; final double finalFatigue; const DayOutcome(...); }`
  - `DayOutcome simulateDay(DayState state, Traits tr, SeededRng rng)`

- [ ] **Step 1: Adicionar export**

Em `engine/lib/oracle_engine.dart`, adicionar:
```dart
export 'src/day.dart';
```

- [ ] **Step 2: Escrever o teste que falha (invariantes + monotonicidade)**

`engine/test/day_test.dart`:
```dart
import 'package:oracle_engine/oracle_engine.dart';
import 'package:test/test.dart';

const _study = Commitment(
    id: 'estudo', start: 14.0, planned: 2.0, type: 'estudo',
    priority: 2, aversive: true);

double _completionRate(double sleepDebt, {int trials = 400, int seed = 9}) {
  final state = DayState(sleepDebt: sleepDebt, dayEnd: 18.0, agenda: [_study]);
  const tr = Traits(phi: 9.6, p0: 0.60, rho: 0.31, s: 0.15, o: 0.20, r: 0.25);
  final rng = SeededRng(seed);
  var done = 0;
  for (var i = 0; i < trials; i++) {
    if (simulateDay(state, tr, rng).completed['estudo'] == true) done++;
  }
  return done / trials;
}

void main() {
  test('simulateDay é determinístico para a mesma semente', () {
    final state = DayState(sleepDebt: 2.0, dayEnd: 18.0, agenda: [_study]);
    const tr = Traits(phi: 9.6, p0: 0.60, rho: 0.31, s: 0.15, o: 0.20, r: 0.25);
    final a = simulateDay(state, tr, SeededRng(1)).completed;
    final b = simulateDay(state, tr, SeededRng(1)).completed;
    expect(a, equals(b));
  });

  test('resultado é binário por compromisso e metAgenda coerente', () {
    final state = DayState(sleepDebt: 1.0, dayEnd: 18.0, agenda: [_study]);
    const tr = Traits(phi: 9.6, p0: 0.60, rho: 0.31, s: 0.15, o: 0.20, r: 0.25);
    final out = simulateDay(state, tr, SeededRng(4));
    expect(out.completed.containsKey('estudo'), isTrue);
    expect(out.metAgenda, equals(out.completed['estudo']));
  });

  test('menos sono => menor taxa de conclusão (monotonicidade)', () {
    expect(_completionRate(0.0), greaterThan(_completionRate(4.0)));
  });
}
```

- [ ] **Step 3: Rodar o teste para vê-lo falhar**

Run: `cd engine && dart test test/day_test.dart`
Expected: FALHA — tipos não definidos.

- [ ] **Step 4: Implementar o modelo do dia**

`engine/lib/src/day.dart`:
```dart
import 'dart:math' as math;
import 'rng.dart';
import 'traits.dart';
import 'model.dart';

class Commitment {
  final String id;
  final double start;
  final double planned;
  final String type;
  final int priority;
  final bool aversive;
  const Commitment({
    required this.id,
    required this.start,
    required this.planned,
    required this.type,
    this.priority = 2,
    this.aversive = false,
  });
}

class DayState {
  final double sleepDebt;
  final double dayEnd;
  final List<Commitment> agenda;
  const DayState({
    required this.sleepDebt,
    this.dayEnd = 24.0,
    required this.agenda,
  });
}

class DayOutcome {
  final Map<String, bool> completed;
  final bool metAgenda;
  final double finalFatigue;
  const DayOutcome(this.completed, this.metAgenda, this.finalFatigue);
}

DayOutcome simulateDay(DayState state, Traits tr, SeededRng rng) {
  final agenda = [...state.agenda]
    ..sort((a, b) => a.start.compareTo(b.start));
  var fatigue = initialFatigue(state.sleepDebt);
  final completed = <String, bool>{};

  for (var i = 0; i < agenda.length; i++) {
    final c = agenda[i];
    final windowEnd = (i + 1 < agenda.length) ? agenda[i + 1].start : state.dayEnd;
    var t = c.start;

    // Procrastinacao: tarefa aversiva atrasa o inicio (media 30 min).
    if (c.aversive && rng.nextBernoulli(tr.rho)) {
      t += rng.nextExponential(2.0);
    }

    final effortNeeded = c.planned * math.exp(tr.o);
    var work = 0.0;
    var focusing = true;

    while (t < windowEnd && work < effortNeeded) {
      final e = energy(t, tr, state.sleepDebt, fatigue);
      if (focusing) {
        final dur = math.min(
            rng.nextLogNormal(math.log(0.5), 0.5), windowEnd - t);
        work += tr.p0 * e * dur;
        fatigue = fatigueStep(fatigue, activityAlpha['foco']!, 0.0, dur);
        t += dur;
        final pDistract = logistic(-1.0 + 2.0 * (1.0 - e));
        focusing = !rng.nextBernoulli(pDistract);
      } else {
        final dur = math.min(
            rng.nextLogNormal(math.log(8.0 / 60.0), 0.5), windowEnd - t);
        fatigue = fatigueStep(fatigue, 0.0, tr.r, dur);
        t += dur;
        focusing = true;
      }
    }
    completed[c.id] = work >= effortNeeded;
  }

  final metAgenda = agenda
      .where((c) => c.priority >= 2)
      .every((c) => completed[c.id] ?? false);
  return DayOutcome(completed, metAgenda, fatigue);
}
```

- [ ] **Step 5: Rodar o teste para vê-lo passar**

Run: `cd engine && dart test test/day_test.dart`
Expected: PASSA (3 testes).

- [ ] **Step 6: Commit**

```bash
git add engine/lib/src/day.dart engine/lib/oracle_engine.dart engine/test/day_test.dart
git commit -m "feat(engine): modelo do dia e simulateDay (semi-Markov + planning fallacy)"
```

---

### Task 6: Monte Carlo aninhado `predict` (epistêmico × aleatório)

**Files:**
- Create: `engine/lib/src/engine.dart`
- Modify: `engine/lib/oracle_engine.dart`
- Test: `engine/test/predict_test.dart`

**Interfaces:**
- Consumes: `DayState`, `TraitPriors`, `simulateDay`, `SeededRng`.
- Produces:
  - `class Prediction { final double estimate; final double low; final double high; final Map<String,double> perCommitment; const Prediction(...); }`
  - `Prediction predict(DayState state, TraitPriors priors, {int outerK = 200, int innerM = 10, int seed = 0})`
  - `double quantile(List<double> xs, double q)` (helper exportado)

- [ ] **Step 1: Adicionar export**

Em `engine/lib/oracle_engine.dart`, adicionar:
```dart
export 'src/engine.dart';
```

- [ ] **Step 2: Escrever o teste que falha**

`engine/test/predict_test.dart`:
```dart
import 'package:oracle_engine/oracle_engine.dart';
import 'package:test/test.dart';

const _study = Commitment(
    id: 'estudo', start: 14.0, planned: 2.0, type: 'estudo',
    priority: 2, aversive: true);

Prediction _run(double sleepDebt, {int seed = 42}) => predict(
      DayState(sleepDebt: sleepDebt, dayEnd: 18.0, agenda: [_study]),
      TraitPriors.neutral,
      outerK: 200,
      innerM: 10,
      seed: seed,
    );

void main() {
  test('quantile interpola corretamente', () {
    final xs = [0.0, 0.25, 0.5, 0.75, 1.0];
    expect(quantile(xs, 0.0), closeTo(0.0, 1e-9));
    expect(quantile(xs, 1.0), closeTo(1.0, 1e-9));
    expect(quantile(xs, 0.5), closeTo(0.5, 1e-9));
  });

  test('predict é determinístico para a mesma semente', () {
    final a = _run(2.0);
    final b = _run(2.0);
    expect(a.estimate, equals(b.estimate));
    expect(a.low, equals(b.low));
    expect(a.high, equals(b.high));
  });

  test('estimativa e faixa ficam em [0,1] e low<=estimate<=high', () {
    final p = _run(2.0);
    expect(p.estimate, inInclusiveRange(0.0, 1.0));
    expect(p.low, lessThanOrEqualTo(p.estimate));
    expect(p.high, greaterThanOrEqualTo(p.estimate));
    expect(p.perCommitment['estudo'], isNotNull);
  });

  test('mais débito de sono reduz a estimativa (monotonicidade)', () {
    expect(_run(0.0).estimate, greaterThan(_run(4.0).estimate));
  });
}
```

- [ ] **Step 3: Rodar o teste para vê-lo falhar**

Run: `cd engine && dart test test/predict_test.dart`
Expected: FALHA — `predict`/`Prediction`/`quantile` não definidos.

- [ ] **Step 4: Implementar `predict` (nested MC)**

`engine/lib/src/engine.dart`:
```dart
import 'rng.dart';
import 'traits.dart';
import 'day.dart';

class Prediction {
  final double estimate; // media da prob de cumprir a agenda
  final double low; // quantil 10 (banda epistemica)
  final double high; // quantil 90
  final Map<String, double> perCommitment; // id -> prob de conclusao
  const Prediction(this.estimate, this.low, this.high, this.perCommitment);
}

double quantile(List<double> xs, double q) {
  if (xs.isEmpty) return double.nan;
  final s = [...xs]..sort();
  if (s.length == 1) return s.first;
  final pos = q * (s.length - 1);
  final lo = pos.floor();
  final hi = pos.ceil();
  if (lo == hi) return s[lo];
  final frac = pos - lo;
  return s[lo] * (1 - frac) + s[hi] * frac;
}

Prediction predict(
  DayState state,
  TraitPriors priors, {
  int outerK = 200,
  int innerM = 10,
  int seed = 0,
}) {
  final rng = SeededRng(seed);
  final metRatesPerTheta = <double>[]; // prob epistemica de cumprir a agenda
  final perCommitmentSum = <String, double>{
    for (final c in state.agenda) c.id: 0.0
  };

  for (var k = 0; k < outerK; k++) {
    final tr = priors.sample(rng); // incerteza EPISTEMICA (1 theta)
    var metInner = 0;
    final commitInner = <String, int>{
      for (final c in state.agenda) c.id: 0
    };
    for (var m = 0; m < innerM; m++) {
      final out = simulateDay(state, tr, rng); // incerteza ALEATORIA
      if (out.metAgenda) metInner++;
      for (final c in state.agenda) {
        if (out.completed[c.id] == true) {
          commitInner[c.id] = commitInner[c.id]! + 1;
        }
      }
    }
    metRatesPerTheta.add(metInner / innerM);
    for (final c in state.agenda) {
      perCommitmentSum[c.id] =
          perCommitmentSum[c.id]! + commitInner[c.id]! / innerM;
    }
  }

  final estimate =
      metRatesPerTheta.reduce((s, x) => s + x) / metRatesPerTheta.length;
  final low = quantile(metRatesPerTheta, 0.10);
  final high = quantile(metRatesPerTheta, 0.90);
  final perCommitment = {
    for (final c in state.agenda) c.id: perCommitmentSum[c.id]! / outerK
  };
  return Prediction(estimate, low, high, perCommitment);
}
```

- [ ] **Step 5: Rodar o teste para vê-lo passar**

Run: `cd engine && dart test test/predict_test.dart`
Expected: PASSA (4 testes).

- [ ] **Step 6: Commit**

```bash
git add engine/lib/src/engine.dart engine/lib/oracle_engine.dart engine/test/predict_test.dart
git commit -m "feat(engine): Monte Carlo aninhado predict (banda epistemica x aleatoria)"
```

---

### Task 7: Análise de sensibilidade (`fatores`)

**Files:**
- Create: `engine/lib/src/sensitivity.dart`
- Modify: `engine/lib/oracle_engine.dart`
- Test: `engine/test/sensitivity_test.dart`

**Interfaces:**
- Consumes: `DayState`, `TraitPriors`, `predict`, `Prediction`.
- Produces:
  - `class Factor { final String label; final double delta; String get direction; const Factor(this.label, this.delta); }`
  - `List<Factor> sensitivity(DayState state, TraitPriors priors, {int seed = 0})`
    — perturba entradas do estado (débito de sono; adiantar 1º compromisso para o
    pico) e mede a variação da estimativa, ordenando por magnitude.

- [ ] **Step 1: Adicionar export**

Em `engine/lib/oracle_engine.dart`, adicionar:
```dart
export 'src/sensitivity.dart';
```

- [ ] **Step 2: Escrever o teste que falha**

`engine/test/sensitivity_test.dart`:
```dart
import 'package:oracle_engine/oracle_engine.dart';
import 'package:test/test.dart';

void main() {
  final state = DayState(sleepDebt: 2.0, dayEnd: 18.0, agenda: const [
    Commitment(
        id: 'estudo', start: 14.0, planned: 2.0, type: 'estudo',
        priority: 2, aversive: true),
  ]);

  test('sensibilidade retorna fatores ordenados por magnitude', () {
    final fs = sensitivity(state, TraitPriors.neutral, seed: 42);
    expect(fs, isNotEmpty);
    for (var i = 1; i < fs.length; i++) {
      expect(fs[i - 1].delta.abs(), greaterThanOrEqualTo(fs[i].delta.abs()));
    }
  });

  test('remover o débito de sono tem direção positiva', () {
    final fs = sensitivity(state, TraitPriors.neutral, seed: 42);
    final sono = fs.firstWhere((f) => f.label.contains('sono'));
    expect(sono.direction, equals('positivo'));
  });
}
```

- [ ] **Step 3: Rodar o teste para vê-lo falhar**

Run: `cd engine && dart test test/sensitivity_test.dart`
Expected: FALHA — `sensitivity`/`Factor` não definidos.

- [ ] **Step 4: Implementar sensibilidade**

`engine/lib/src/sensitivity.dart`:
```dart
import 'day.dart';
import 'traits.dart';
import 'engine.dart';

class Factor {
  final String label;
  final double delta; // variacao na estimativa vs baseline
  const Factor(this.label, this.delta);
  String get direction => delta >= 0 ? 'positivo' : 'negativo';
}

List<Factor> sensitivity(DayState state, TraitPriors priors, {int seed = 0}) {
  final base = predict(state, priors, seed: seed).estimate;
  final factors = <Factor>[];

  // Perturbacao 1: zerar o debito de sono.
  if (state.sleepDebt > 0) {
    final s2 = DayState(
        sleepDebt: 0.0, dayEnd: state.dayEnd, agenda: state.agenda);
    factors.add(Factor(
        'débito de sono', predict(s2, priors, seed: seed).estimate - base));
  }

  // Perturbacao 2: adiantar o 1o compromisso para as 9h30 (proximo do pico).
  if (state.agenda.isNotEmpty) {
    final first = state.agenda.first;
    final moved = Commitment(
      id: first.id,
      start: 9.5,
      planned: first.planned,
      type: first.type,
      priority: first.priority,
      aversive: first.aversive,
    );
    final s3 = DayState(
      sleepDebt: state.sleepDebt,
      dayEnd: state.dayEnd,
      agenda: [moved, ...state.agenda.skip(1)],
    );
    factors.add(Factor('horário do compromisso',
        predict(s3, priors, seed: seed).estimate - base));
  }

  factors.sort((a, b) => b.delta.abs().compareTo(a.delta.abs()));
  return factors;
}
```

- [ ] **Step 5: Rodar o teste para vê-lo passar**

Run: `cd engine && dart test test/sensitivity_test.dart`
Expected: PASSA (2 testes).

- [ ] **Step 6: Commit**

```bash
git add engine/lib/src/sensitivity.dart engine/lib/oracle_engine.dart engine/test/sensitivity_test.dart
git commit -m "feat(engine): análise de sensibilidade (fatores do OracleAnswer)"
```

---

### Task 8: Montagem do `OracleAnswer`

**Files:**
- Create: `engine/lib/src/oracle_answer.dart`
- Modify: `engine/lib/oracle_engine.dart`
- Test: `engine/test/oracle_answer_test.dart`

**Interfaces:**
- Consumes: `DayState`, `TraitPriors`, `predict`, `Prediction`, `sensitivity`,
  `Factor`.
- Produces:
  - `enum Confidence { alta, media, baixa }`
  - `class OracleAnswer { final String question; final double estimate; final double low; final double high; final Confidence confidence; final List<Factor> factors; final List<String> limitations; const OracleAnswer({...}); }`
  - `OracleAnswer answerAgenda(DayState state, TraitPriors priors, {int observedDays = 0, int seed = 0})`
  - `Confidence confidenceFromWidth(double width)`

- [ ] **Step 1: Adicionar export**

Em `engine/lib/oracle_engine.dart`, adicionar:
```dart
export 'src/oracle_answer.dart';
```

- [ ] **Step 2: Escrever o teste que falha**

`engine/test/oracle_answer_test.dart`:
```dart
import 'package:oracle_engine/oracle_engine.dart';
import 'package:test/test.dart';

void main() {
  test('confidenceFromWidth mapeia larguras para rótulos', () {
    expect(confidenceFromWidth(0.05), equals(Confidence.alta));
    expect(confidenceFromWidth(0.15), equals(Confidence.media));
    expect(confidenceFromWidth(0.30), equals(Confidence.baixa));
  });

  test('answerAgenda monta um OracleAnswer coerente', () {
    final state = DayState(sleepDebt: 2.0, dayEnd: 18.0, agenda: const [
      Commitment(
          id: 'estudo', start: 14.0, planned: 2.0, type: 'estudo',
          priority: 2, aversive: true),
    ]);
    final ans = answerAgenda(state, TraitPriors.neutral, observedDays: 20, seed: 42);
    expect(ans.estimate, inInclusiveRange(0.0, 1.0));
    expect(ans.low, lessThanOrEqualTo(ans.estimate));
    expect(ans.high, greaterThanOrEqualTo(ans.estimate));
    expect(ans.factors, isNotEmpty);
    expect(ans.limitations, isNotEmpty); // 20 dias => cita limitacao de dados
  });
}
```

- [ ] **Step 3: Rodar o teste para vê-lo falhar**

Run: `cd engine && dart test test/oracle_answer_test.dart`
Expected: FALHA — tipos não definidos.

- [ ] **Step 4: Implementar a montagem**

`engine/lib/src/oracle_answer.dart`:
```dart
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
```

- [ ] **Step 5: Rodar o teste para vê-lo passar**

Run: `cd engine && dart test test/oracle_answer_test.dart`
Expected: PASSA (2 testes).

- [ ] **Step 6: Commit**

```bash
git add engine/lib/src/oracle_answer.dart engine/lib/oracle_engine.dart engine/test/oracle_answer_test.dart
git commit -m "feat(engine): montagem do OracleAnswer com confiança e limitações"
```

---

### Task 9: Teste de aceitação (doc 10 §C) + verificação final

**Files:**
- Test: `engine/test/acceptance_test.dart`

**Interfaces:**
- Consumes: todo o pacote (`answerAgenda`, `energy`, `initialFatigue`, etc.).
- Produces: nada (é o fixture de aceitação).

- [ ] **Step 1: Escrever o teste de aceitação (cenário do doc 10 §C.1)**

`engine/test/acceptance_test.dart`:
```dart
import 'dart:math' as math;
import 'package:oracle_engine/oracle_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Acceptance — doc 10 §C', () {
    // Peças determinísticas exatas (C.2)
    test('fadiga inicial com 2h de débito = 0.26', () {
      expect(initialFatigue(2.0), closeTo(0.26, 1e-9));
    });

    test('energia às 14h no exemplo ≈ 0.4611', () {
      const tr =
          Traits(phi: 9.6, p0: 0.60, rho: 0.31, s: 0.15, o: 0.25, r: 0.25);
      expect(energy(14.0, tr, 2.0, 0.30), closeTo(0.4611, 1e-3));
    });

    test('esforço necessário = planned*exp(o) = 2*exp(0.25) ≈ 2.568', () {
      expect(2.0 * math.exp(0.25), closeTo(2.568, 1e-3));
    });

    // Agregado (C.3): determinístico, em faixa sã, e responde às intervenções.
    test('answerAgenda produz previsão sã e determinística', () {
      final state = DayState(sleepDebt: 2.0, dayEnd: 18.0, agenda: const [
        Commitment(
            id: 'estudo', start: 14.0, planned: 2.0, type: 'estudo',
            priority: 2, aversive: true),
      ]);
      final a = answerAgenda(state, TraitPriors.neutral,
          observedDays: 20, seed: 42);
      final b = answerAgenda(state, TraitPriors.neutral,
          observedDays: 20, seed: 42);

      expect(a.estimate, equals(b.estimate)); // determinismo
      expect(a.estimate, inInclusiveRange(0.30, 0.90)); // faixa sã
      expect(a.low, lessThanOrEqualTo(a.estimate));
      expect(a.high, greaterThanOrEqualTo(a.estimate));
      // o débito de sono aparece entre os fatores (doc 10 espera-o dominante)
      expect(a.factors.any((f) => f.label.contains('sono')), isTrue);
    });
  });
}
```

- [ ] **Step 2: Rodar o teste de aceitação**

Run: `cd engine && dart test test/acceptance_test.dart`
Expected: PASSA. Se `a.estimate` cair fora de [0.30, 0.90], **não relaxar o
teste** — investigar as constantes/janela do modelo (doc 10 A) até a agregação
ficar sã; o teste é o detector de buracos.

- [ ] **Step 3: Rodar a suíte inteira + análise estática**

Run: `cd engine && dart analyze && dart test`
Expected: `No issues found!` e **todos** os testes passam.

- [ ] **Step 4: Commit**

```bash
git add engine/test/acceptance_test.dart
git commit -m "test(engine): fixture de aceitação do exemplo resolvido (doc 10 §C)"
```

---

## Notas de calibração do modelo (para quem executar)

O exemplo do doc 10 §C usa números **ilustrativos**. Os oráculos exatos (fadiga
0.26, energia ≈0.4611, esforço ≈2.568) **devem** bater — são fórmulas fechadas. Já
o agregado (~63%) é produto de simulação: o teste de aceitação exige apenas que a
estimativa seja **determinística, sã (0.30–0.90) e monótona** às intervenções.
Se, ao rodar, a agregação ficar destoante (ex.: ~0% ou ~100%), o ajuste correto é
na **janela de conclusão** (Task 5: `windowEnd`) ou nas constantes (doc 10 A.1) —
nunca afrouxar o teste. Documente qualquer ajuste de constante de volta no doc 10.
