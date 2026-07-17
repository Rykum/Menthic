# Loop de Calibração (Fase 0.3) — Plano de Implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir o pacote Dart `oracle_calibration` — scoring (Brier/BSS/
reliability/Murphy), veredito do gate, recalibração Platt, e integração com o
event store (logar previsões, parear com desfechos) para produzir um `CalibrationReport`.

**Architecture:** Pacote Dart puro `calibration/` (depende de `oracle_store`).
Funções puras de scoring com oráculos exatos; `evaluateGate`; `PlattCalibrator`
(regressão logística determinística); `CalibrationExtractor` (eventos→pares);
`buildReport`. Testado com `dart test`.

**Tech Stack:** Dart SDK ^3.8, `oracle_store` (path), package:test.

## Global Constraints

- **Local do pacote:** `calibration/`; **nome** `oracle_calibration`.
- **Dependências:** `oracle_store` (path `../store`); dev `test: ^1.25.0`.
- `PredOutcome(double p, int o)` com `p ∈ [0,1]`, `o ∈ {0,1}`.
- **Casos-limite:** lista vazia → funções de scoring retornam `double.nan`;
  `brierBaseline == 0` (desfechos todos iguais) → `brierSkillScore` retorna `double.nan`.
- **Reliability bins:** largura igual em [0,1]; `p == 1.0` cai no último bin; bins
  vazios têm `n == 0` e médias `NaN`.
- **Murphy:** `Brier = REL − RES + UNC` exato sobre previsões agrupadas por valor.
- **Gate:** `n < minN` → `passed=false`; senão `passed = bss ≥ minBss && cal < maxCalibration`. Padrões `minN=120, minBss=0.05, maxCalibration=0.05`.
- **Platt determinístico:** init `a=1.0, b=0.0`, iterações fixas, sem aleatoriedade;
  `apply(p) = σ(a·logit(p)+b)` com `p` clampeado em `(1e-6, 1−1e-6)`.
- **Extractor:** pareia por `(dia UTC, cid)`; previsão sem desfecho é ignorada.
- **Estilo:** `dart analyze` sem issues; `dart format` limpo.

---

### Task 1: Scaffold + `PredOutcome` + scoring básico

**Files:**
- Create: `calibration/pubspec.yaml`
- Create: `calibration/lib/oracle_calibration.dart`
- Create: `calibration/lib/src/pred_outcome.dart`
- Create: `calibration/lib/src/scoring.dart`
- Test: `calibration/test/scoring_test.dart`

**Interfaces:**
- Produces:
  - `class PredOutcome { final double p; final int o; const PredOutcome(this.p, this.o); }`
  - `double brierScore(List<PredOutcome> d)`, `double baseRate(...)`,
    `double brierBaseline(...)`, `double brierSkillScore(...)`,
    `double calibrationInTheLarge(...)`

- [ ] **Step 1: Criar pacote, barrel, e o modelo**

`calibration/pubspec.yaml`:
```yaml
name: oracle_calibration
description: Loop de calibração (Brier/BSS/Platt) do Project Oracle.
version: 0.1.0
publish_to: none
environment:
  sdk: ^3.8.0
dependencies:
  oracle_store:
    path: ../store
dev_dependencies:
  test: ^1.25.0
```

`calibration/lib/oracle_calibration.dart`:
```dart
export 'src/pred_outcome.dart';
export 'src/scoring.dart';
```

`calibration/lib/src/pred_outcome.dart`:
```dart
class PredOutcome {
  final double p;
  final int o;
  const PredOutcome(this.p, this.o);
}
```

- [ ] **Step 2: Escrever o teste que falha (oráculos exatos)**

`calibration/test/scoring_test.dart`:
```dart
import 'package:oracle_calibration/oracle_calibration.dart';
import 'package:test/test.dart';

void main() {
  // Exemplo com valores exatos calculados à mão.
  const d = [
    PredOutcome(0.8, 1),
    PredOutcome(0.6, 0),
    PredOutcome(0.3, 0),
    PredOutcome(0.9, 1),
  ];

  test('brierScore = 0.125', () {
    expect(brierScore(d), closeTo(0.125, 1e-12));
  });

  test('baseRate = 0.5', () {
    expect(baseRate(d), closeTo(0.5, 1e-12));
  });

  test('brierBaseline = 0.25', () {
    expect(brierBaseline(d), closeTo(0.25, 1e-12));
  });

  test('brierSkillScore = 0.5', () {
    expect(brierSkillScore(d), closeTo(0.5, 1e-12));
  });

  test('calibrationInTheLarge = 0.15', () {
    expect(calibrationInTheLarge(d), closeTo(0.15, 1e-12));
  });

  test('lista vazia => NaN; baseline 0 => BSS NaN', () {
    expect(brierScore(const []), isNaN);
    // todos os desfechos iguais => baseline 0 => BSS indefinido
    expect(brierSkillScore(const [PredOutcome(0.4, 1), PredOutcome(0.6, 1)]),
        isNaN);
  });
}
```

- [ ] **Step 3: Rodar o teste para vê-lo falhar**

Run: `cd calibration && dart pub get && dart test test/scoring_test.dart`
Expected: FALHA — funções não definidas.

- [ ] **Step 4: Implementar o scoring básico**

`calibration/lib/src/scoring.dart`:
```dart
import 'pred_outcome.dart';

double brierScore(List<PredOutcome> d) {
  if (d.isEmpty) return double.nan;
  var s = 0.0;
  for (final x in d) {
    final diff = x.p - x.o;
    s += diff * diff;
  }
  return s / d.length;
}

double baseRate(List<PredOutcome> d) {
  if (d.isEmpty) return double.nan;
  var s = 0;
  for (final x in d) {
    s += x.o;
  }
  return s / d.length;
}

double brierBaseline(List<PredOutcome> d) {
  if (d.isEmpty) return double.nan;
  final r = baseRate(d);
  var s = 0.0;
  for (final x in d) {
    final diff = r - x.o;
    s += diff * diff;
  }
  return s / d.length;
}

double brierSkillScore(List<PredOutcome> d) {
  final base = brierBaseline(d);
  if (base == 0.0) return double.nan;
  return 1 - brierScore(d) / base;
}

double calibrationInTheLarge(List<PredOutcome> d) {
  if (d.isEmpty) return double.nan;
  var sp = 0.0;
  var so = 0;
  for (final x in d) {
    sp += x.p;
    so += x.o;
  }
  return ((sp / d.length) - (so / d.length)).abs();
}
```

- [ ] **Step 5: Rodar o teste para vê-lo passar**

Run: `cd calibration && dart test test/scoring_test.dart`
Expected: PASSA (6 testes).

- [ ] **Step 6: Commit**

```bash
git add calibration/pubspec.yaml calibration/lib calibration/test/scoring_test.dart
git commit -m "feat(calibration): scaffold + PredOutcome + scoring básico (Brier/BSS)"
```

---

### Task 2: Diagrama de confiabilidade + decomposição de Murphy

**Files:**
- Modify: `calibration/lib/src/scoring.dart`
- Modify: `calibration/lib/oracle_calibration.dart` (nada a mudar — mesmo arquivo já exportado)
- Test: `calibration/test/murphy_test.dart`

**Interfaces:**
- Consumes: `PredOutcome`, `baseRate` (Task 1).
- Produces:
  - `class ReliabilityBin { final double lo, hi; final int n; final double meanPredicted, observedFreq; const ReliabilityBin(...); }`
  - `List<ReliabilityBin> reliabilityDiagram(List<PredOutcome> d, {int bins = 10})`
  - `class MurphyDecomposition { final double reliability, resolution, uncertainty; const MurphyDecomposition(...); }`
  - `MurphyDecomposition murphy(List<PredOutcome> d, {int bins = 10})`

- [ ] **Step 1: Escrever o teste que falha (identidade exata)**

`calibration/test/murphy_test.dart`:
```dart
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
    expect(m.reliability - m.resolution + m.uncertainty,
        closeTo(brierScore(d), 1e-12)); // = 0.2291666667
  });

  test('p == 1.0 cai no último bin', () {
    final bins = reliabilityDiagram(const [PredOutcome(1.0, 1)]);
    expect(bins[9].n, 1);
  });
}
```

- [ ] **Step 2: Rodar o teste para vê-lo falhar**

Run: `cd calibration && dart test test/murphy_test.dart`
Expected: FALHA — `reliabilityDiagram`/`murphy` não definidos.

- [ ] **Step 3: Implementar reliability + Murphy**

Adicionar ao final de `calibration/lib/src/scoring.dart`:
```dart
class ReliabilityBin {
  final double lo, hi;
  final int n;
  final double meanPredicted; // NaN se n == 0
  final double observedFreq; // NaN se n == 0
  const ReliabilityBin(
    this.lo,
    this.hi,
    this.n,
    this.meanPredicted,
    this.observedFreq,
  );
}

List<ReliabilityBin> reliabilityDiagram(List<PredOutcome> d, {int bins = 10}) {
  final width = 1.0 / bins;
  final sumsP = List.filled(bins, 0.0);
  final sumsO = List.filled(bins, 0.0);
  final counts = List.filled(bins, 0);
  for (final x in d) {
    // multiplica (mais estável que dividir por width em ponto flutuante)
    var idx = (x.p * bins).floor();
    if (idx >= bins) idx = bins - 1; // p == 1.0 vai para o último bin
    if (idx < 0) idx = 0;
    sumsP[idx] += x.p;
    sumsO[idx] += x.o;
    counts[idx] += 1;
  }
  return List.generate(bins, (k) {
    final n = counts[k];
    return ReliabilityBin(
      k * width,
      (k + 1) * width,
      n,
      n == 0 ? double.nan : sumsP[k] / n,
      n == 0 ? double.nan : sumsO[k] / n,
    );
  });
}

class MurphyDecomposition {
  final double reliability, resolution, uncertainty;
  const MurphyDecomposition(
    this.reliability,
    this.resolution,
    this.uncertainty,
  );
}

MurphyDecomposition murphy(List<PredOutcome> d, {int bins = 10}) {
  final n = d.length;
  if (n == 0) {
    return const MurphyDecomposition(double.nan, double.nan, double.nan);
  }
  final obar = baseRate(d);
  final diagram = reliabilityDiagram(d, bins: bins);
  var rel = 0.0, res = 0.0;
  for (final b in diagram) {
    if (b.n == 0) continue;
    rel += b.n * (b.meanPredicted - b.observedFreq) * (b.meanPredicted - b.observedFreq);
    res += b.n * (b.observedFreq - obar) * (b.observedFreq - obar);
  }
  return MurphyDecomposition(rel / n, res / n, obar * (1 - obar));
}
```

Em `calibration/lib/oracle_calibration.dart` — nenhuma mudança (o `scoring.dart`
já é exportado). Se o export não existir por algum motivo, garanta
`export 'src/scoring.dart';`.

- [ ] **Step 4: Rodar o teste para vê-lo passar**

Run: `cd calibration && dart test test/murphy_test.dart`
Expected: PASSA (3 testes).

- [ ] **Step 5: Commit**

```bash
git add calibration/lib/src/scoring.dart calibration/test/murphy_test.dart
git commit -m "feat(calibration): diagrama de confiabilidade e decomposição de Murphy"
```

---

### Task 3: Veredito do gate

**Files:**
- Create: `calibration/lib/src/gate.dart`
- Modify: `calibration/lib/oracle_calibration.dart`
- Test: `calibration/test/gate_test.dart`

**Interfaces:**
- Consumes: `PredOutcome`, `brierSkillScore`, `calibrationInTheLarge`.
- Produces:
  - `class GateResult { final bool passed; final double bss; final double calibrationInTheLarge; final int n; final String reason; const GateResult({required ...}); }`
  - `GateResult evaluateGate(List<PredOutcome> d, {int minN = 120, double minBss = 0.05, double maxCalibration = 0.05})`

- [ ] **Step 1: Adicionar export**

Em `calibration/lib/oracle_calibration.dart`, adicionar:
```dart
export 'src/gate.dart';
```

- [ ] **Step 2: Escrever o teste que falha**

`calibration/test/gate_test.dart`:
```dart
import 'package:oracle_calibration/oracle_calibration.dart';
import 'package:test/test.dart';

void main() {
  test('n < minN => não julga', () {
    final r = evaluateGate(const [PredOutcome(0.9, 1), PredOutcome(0.1, 0)]);
    expect(r.passed, isFalse);
    expect(r.n, 2);
    expect(r.reason, contains('insuficiente'));
  });

  test('caso que PASSA (skillful e calibrado, n>=120)', () {
    final d = [
      ...List.filled(60, const PredOutcome(0.9, 1)),
      ...List.filled(60, const PredOutcome(0.1, 0)),
    ];
    final r = evaluateGate(d);
    expect(r.n, 120);
    expect(r.bss, greaterThanOrEqualTo(0.05));
    expect(r.calibrationInTheLarge, lessThan(0.05));
    expect(r.passed, isTrue);
  });

  test('caso que FALHA (sem skill, n>=120)', () {
    final d = [
      ...List.filled(60, const PredOutcome(0.5, 1)),
      ...List.filled(60, const PredOutcome(0.5, 0)),
    ];
    final r = evaluateGate(d);
    expect(r.n, 120);
    expect(r.bss, lessThan(0.05)); // BSS = 0
    expect(r.passed, isFalse);
  });
}
```

- [ ] **Step 3: Rodar o teste para vê-lo falhar**

Run: `cd calibration && dart test test/gate_test.dart`
Expected: FALHA — `evaluateGate`/`GateResult` não definidos.

- [ ] **Step 4: Implementar o gate**

`calibration/lib/src/gate.dart`:
```dart
import 'pred_outcome.dart';
import 'scoring.dart';

class GateResult {
  final bool passed;
  final double bss;
  final double calibrationInTheLarge;
  final int n;
  final String reason;
  const GateResult({
    required this.passed,
    required this.bss,
    required this.calibrationInTheLarge,
    required this.n,
    required this.reason,
  });
}

GateResult evaluateGate(
  List<PredOutcome> d, {
  int minN = 120,
  double minBss = 0.05,
  double maxCalibration = 0.05,
}) {
  final n = d.length;
  final bss = brierSkillScore(d);
  final cal = calibrationInTheLarge(d);
  if (n < minN) {
    return GateResult(
      passed: false,
      bss: bss,
      calibrationInTheLarge: cal,
      n: n,
      reason: 'amostra insuficiente (n=$n < $minN)',
    );
  }
  final passed = bss >= minBss && cal < maxCalibration;
  return GateResult(
    passed: passed,
    bss: bss,
    calibrationInTheLarge: cal,
    n: n,
    reason: passed
        ? 'passou'
        : 'BSS=${bss.toStringAsFixed(3)} calibração=${cal.toStringAsFixed(3)}',
  );
}
```

- [ ] **Step 5: Rodar o teste para vê-lo passar**

Run: `cd calibration && dart test test/gate_test.dart`
Expected: PASSA (3 testes).

- [ ] **Step 6: Commit**

```bash
git add calibration/lib/src/gate.dart calibration/lib/oracle_calibration.dart calibration/test/gate_test.dart
git commit -m "feat(calibration): veredito do gate (BSS + calibração-no-todo + n mínimo)"
```

---

### Task 4: Recalibração Platt

**Files:**
- Create: `calibration/lib/src/platt.dart`
- Modify: `calibration/lib/oracle_calibration.dart`
- Test: `calibration/test/platt_test.dart`

**Interfaces:**
- Consumes: `PredOutcome`, `calibrationInTheLarge`.
- Produces:
  - `class PlattCalibrator { final double a, b; const PlattCalibrator(this.a, this.b); static PlattCalibrator fit(List<PredOutcome> d, {int iters = 200, double lr = 0.3}); double apply(double p); }`

- [ ] **Step 1: Adicionar export**

Em `calibration/lib/oracle_calibration.dart`, adicionar:
```dart
export 'src/platt.dart';
```

- [ ] **Step 2: Escrever o teste que falha**

`calibration/test/platt_test.dart`:
```dart
import 'package:oracle_calibration/oracle_calibration.dart';
import 'package:test/test.dart';

void main() {
  test('apply é monótona em p (a=1,b=0)', () {
    const c = PlattCalibrator(1.0, 0.0);
    expect(c.apply(0.2), lessThan(c.apply(0.8)));
    expect(c.apply(0.5), inInclusiveRange(0.0, 1.0));
  });

  test('fit é determinístico', () {
    final d = [
      ...List.filled(50, const PredOutcome(0.8, 1)),
      ...List.filled(50, const PredOutcome(0.8, 0)),
    ];
    final a = PlattCalibrator.fit(d);
    final b = PlattCalibrator.fit(d);
    expect(a.a, equals(b.a));
    expect(a.b, equals(b.b));
  });

  test('recalibração reduz o viés sistemático', () {
    // Todas as previsões dizem 0.8, mas a taxa real é 0.5 (viés de +0.3).
    final d = [
      ...List.filled(50, const PredOutcome(0.8, 1)),
      ...List.filled(50, const PredOutcome(0.8, 0)),
    ];
    final cal = PlattCalibrator.fit(d);
    final recal = d.map((x) => PredOutcome(cal.apply(x.p), x.o)).toList();
    expect(
      calibrationInTheLarge(recal),
      lessThan(calibrationInTheLarge(d)),
    );
  });
}
```

- [ ] **Step 3: Rodar o teste para vê-lo falhar**

Run: `cd calibration && dart test test/platt_test.dart`
Expected: FALHA — `PlattCalibrator` não definido.

- [ ] **Step 4: Implementar Platt (regressão logística determinística)**

`calibration/lib/src/platt.dart`:
```dart
import 'dart:math' as math;
import 'pred_outcome.dart';

double _clampP(double p) {
  const eps = 1e-6;
  if (p < eps) return eps;
  if (p > 1 - eps) return 1 - eps;
  return p;
}

double _logit(double p) {
  final c = _clampP(p);
  return math.log(c / (1 - c));
}

double _sigmoid(double x) => 1.0 / (1.0 + math.exp(-x));

class PlattCalibrator {
  final double a, b;
  const PlattCalibrator(this.a, this.b);

  /// Ajusta a,b por gradiente descendente (log-loss), início fixo => determinístico.
  static PlattCalibrator fit(List<PredOutcome> d, {int iters = 200, double lr = 0.3}) {
    var a = 1.0, b = 0.0;
    if (d.isEmpty) return PlattCalibrator(a, b);
    final nInv = 1.0 / d.length;
    for (var it = 0; it < iters; it++) {
      var ga = 0.0, gb = 0.0;
      for (final x in d) {
        final z = _logit(x.p);
        final pred = _sigmoid(a * z + b);
        final err = pred - x.o;
        ga += err * z;
        gb += err;
      }
      a -= lr * ga * nInv;
      b -= lr * gb * nInv;
    }
    return PlattCalibrator(a, b);
  }

  double apply(double p) => _sigmoid(a * _logit(p) + b);
}
```

- [ ] **Step 5: Rodar o teste para vê-lo passar**

Run: `cd calibration && dart test test/platt_test.dart`
Expected: PASSA (3 testes).

- [ ] **Step 6: Commit**

```bash
git add calibration/lib/src/platt.dart calibration/lib/oracle_calibration.dart calibration/test/platt_test.dart
git commit -m "feat(calibration): recalibração Platt (regressão logística determinística)"
```

---

### Task 5: `CalibrationExtractor` + helper `previsaoEmitida`

**Files:**
- Create: `calibration/lib/src/extractor.dart`
- Modify: `calibration/lib/oracle_calibration.dart`
- Test: `calibration/test/extractor_test.dart`

**Interfaces:**
- Consumes: `PredOutcome`, `oracle_store` (`EventStore`, `EventDraft`, `EventTypes`, `InMemoryEventStore`, `tarefaConcluida`).
- Produces:
  - `EventDraft previsaoEmitida({required DateTime ts, required String cid, required double p, String origin = 'motor'})`
  - `class CalibrationExtractor { const CalibrationExtractor(); Future<List<PredOutcome>> extract(EventStore store); }`

- [ ] **Step 1: Adicionar export**

Em `calibration/lib/oracle_calibration.dart`, adicionar:
```dart
export 'src/extractor.dart';
```

- [ ] **Step 2: Escrever o teste que falha**

`calibration/test/extractor_test.dart`:
```dart
import 'package:oracle_calibration/oracle_calibration.dart';
import 'package:oracle_store/oracle_store.dart';
import 'package:test/test.dart';

void main() {
  final day = DateTime.utc(2026, 7, 17, 8);

  test('pareia previsão com desfecho por (cid, dia)', () async {
    final store = InMemoryEventStore();
    await store.append(previsaoEmitida(ts: day, cid: 'estudo', p: 0.7));
    await store.append(tarefaConcluida(ts: day, cid: 'estudo', atrasoMin: 0));
    await store.append(previsaoEmitida(ts: day, cid: 'treino', p: 0.4));
    await store.append(EventDraft(
      ts: day,
      type: EventTypes.tarefaNaoConcluida,
      payload: const {'cid': 'treino'},
    ));

    final pairs = await const CalibrationExtractor().extract(store);
    expect(pairs.length, 2);
    final estudo = pairs.firstWhere((x) => x.p == 0.7);
    expect(estudo.o, 1);
    final treino = pairs.firstWhere((x) => x.p == 0.4);
    expect(treino.o, 0);
  });

  test('previsão sem desfecho é ignorada', () async {
    final store = InMemoryEventStore();
    await store.append(previsaoEmitida(ts: day, cid: 'estudo', p: 0.7));
    final pairs = await const CalibrationExtractor().extract(store);
    expect(pairs, isEmpty);
  });

  test('previsaoEmitida monta o draft correto', () {
    final d = previsaoEmitida(ts: day, cid: 'estudo', p: 0.63);
    expect(d.type, EventTypes.previsaoEmitida);
    expect(d.payload['cid'], 'estudo');
    expect(d.payload['p'], 0.63);
    expect(d.origin, 'motor');
  });
}
```

- [ ] **Step 3: Rodar o teste para vê-lo falhar**

Run: `cd calibration && dart test test/extractor_test.dart`
Expected: FALHA — `previsaoEmitida`/`CalibrationExtractor` não definidos.

- [ ] **Step 4: Implementar o extractor**

`calibration/lib/src/extractor.dart`:
```dart
import 'package:oracle_store/oracle_store.dart';
import 'pred_outcome.dart';

EventDraft previsaoEmitida({
  required DateTime ts,
  required String cid,
  required double p,
  String origin = 'motor',
}) =>
    EventDraft(
      ts: ts,
      type: EventTypes.previsaoEmitida,
      origin: origin,
      payload: {'cid': cid, 'p': p},
    );

class CalibrationExtractor {
  const CalibrationExtractor();

  String _key(DateTime ts, String cid) {
    final d = ts.toUtc();
    return '${d.year}-${d.month}-${d.day}|$cid';
  }

  Future<List<PredOutcome>> extract(EventStore store) async {
    final events = await store.all();

    final outcomes = <String, int>{};
    for (final e in events) {
      if (e.type == EventTypes.tarefaConcluida) {
        outcomes[_key(e.ts, e.payload['cid'] as String)] = 1;
      } else if (e.type == EventTypes.tarefaNaoConcluida) {
        outcomes[_key(e.ts, e.payload['cid'] as String)] = 0;
      }
    }

    final pairs = <PredOutcome>[];
    for (final e in events) {
      if (e.type == EventTypes.previsaoEmitida) {
        final o = outcomes[_key(e.ts, e.payload['cid'] as String)];
        if (o != null) {
          pairs.add(PredOutcome((e.payload['p'] as num).toDouble(), o));
        }
      }
    }
    return pairs;
  }
}
```

- [ ] **Step 5: Rodar o teste para vê-lo passar**

Run: `cd calibration && dart test test/extractor_test.dart`
Expected: PASSA (3 testes).

- [ ] **Step 6: Commit**

```bash
git add calibration/lib/src/extractor.dart calibration/lib/oracle_calibration.dart calibration/test/extractor_test.dart
git commit -m "feat(calibration): helper previsaoEmitida + CalibrationExtractor (eventos->pares)"
```

---

### Task 6: `CalibrationReport` (buildReport) + ponta a ponta

**Files:**
- Create: `calibration/lib/src/report.dart`
- Modify: `calibration/lib/oracle_calibration.dart`
- Test: `calibration/test/report_test.dart`
- Test: `calibration/test/end_to_end_test.dart`

**Interfaces:**
- Consumes: todo o pacote + `oracle_store`.
- Produces:
  - `class CalibrationReport { final double brier, bss, calibrationInTheLarge; final int n; final List<ReliabilityBin> reliability; final MurphyDecomposition decomposition; final GateResult gate; const CalibrationReport({required ...}); }`
  - `CalibrationReport buildReport(List<PredOutcome> d, {int bins = 10, int minN = 120})`

- [ ] **Step 1: Adicionar export**

Em `calibration/lib/oracle_calibration.dart`, adicionar:
```dart
export 'src/report.dart';
```

- [ ] **Step 2: Escrever os testes que falham**

`calibration/test/report_test.dart`:
```dart
import 'package:oracle_calibration/oracle_calibration.dart';
import 'package:test/test.dart';

void main() {
  test('buildReport agrega scoring, decomposição e gate', () {
    const d = [
      PredOutcome(0.8, 1),
      PredOutcome(0.6, 0),
      PredOutcome(0.3, 0),
      PredOutcome(0.9, 1),
    ];
    final r = buildReport(d);
    expect(r.n, 4);
    expect(r.brier, closeTo(0.125, 1e-12));
    expect(r.bss, closeTo(0.5, 1e-12));
    expect(r.reliability.length, 10);
    expect(r.gate.passed, isFalse); // n < 120
    expect(r.gate.reason, contains('insuficiente'));
  });
}
```

`calibration/test/end_to_end_test.dart`:
```dart
import 'package:oracle_calibration/oracle_calibration.dart';
import 'package:oracle_store/oracle_store.dart';
import 'package:test/test.dart';

void main() {
  test('store com previsões+desfechos -> extract -> buildReport', () async {
    final store = InMemoryEventStore();
    final day = DateTime.utc(2026, 7, 17, 8);
    // duas previsões resolvidas
    await store.append(previsaoEmitida(ts: day, cid: 'a', p: 0.9));
    await store.append(tarefaConcluida(ts: day, cid: 'a', atrasoMin: 0));
    await store.append(previsaoEmitida(ts: day, cid: 'b', p: 0.2));
    await store.append(EventDraft(
      ts: day,
      type: EventTypes.tarefaNaoConcluida,
      payload: const {'cid': 'b'},
    ));

    final pairs = await const CalibrationExtractor().extract(store);
    final report = buildReport(pairs);
    expect(report.n, 2);
    expect(report.brier, closeTo((0.01 + 0.04) / 2, 1e-12)); // (0.9-1)^2,(0.2-0)^2
    expect(report.gate.passed, isFalse); // n < 120
  });

  test('Platt recalibra pares extraídos e reduz viés', () async {
    final store = InMemoryEventStore();
    final day = DateTime.utc(2026, 7, 17, 8);
    for (var i = 0; i < 50; i++) {
      await store.append(previsaoEmitida(ts: day, cid: 'c$i', p: 0.8));
      await store.append(tarefaConcluida(ts: day, cid: 'c$i', atrasoMin: 0));
    }
    for (var i = 0; i < 50; i++) {
      await store.append(previsaoEmitida(ts: day, cid: 'd$i', p: 0.8));
      await store.append(EventDraft(
        ts: day,
        type: EventTypes.tarefaNaoConcluida,
        payload: {'cid': 'd$i'},
      ));
    }
    final pairs = await const CalibrationExtractor().extract(store);
    final cal = PlattCalibrator.fit(pairs);
    final recal = pairs.map((x) => PredOutcome(cal.apply(x.p), x.o)).toList();
    expect(
      calibrationInTheLarge(recal),
      lessThan(calibrationInTheLarge(pairs)),
    );
  });
}
```

- [ ] **Step 3: Rodar os testes para vê-los falhar**

Run: `cd calibration && dart test test/report_test.dart`
Expected: FALHA — `buildReport`/`CalibrationReport` não definidos.

- [ ] **Step 4: Implementar o report**

`calibration/lib/src/report.dart`:
```dart
import 'pred_outcome.dart';
import 'scoring.dart';
import 'gate.dart';

class CalibrationReport {
  final double brier, bss, calibrationInTheLarge;
  final int n;
  final List<ReliabilityBin> reliability;
  final MurphyDecomposition decomposition;
  final GateResult gate;
  const CalibrationReport({
    required this.brier,
    required this.bss,
    required this.calibrationInTheLarge,
    required this.n,
    required this.reliability,
    required this.decomposition,
    required this.gate,
  });
}

CalibrationReport buildReport(List<PredOutcome> d, {int bins = 10, int minN = 120}) {
  return CalibrationReport(
    brier: brierScore(d),
    bss: brierSkillScore(d),
    calibrationInTheLarge: calibrationInTheLarge(d),
    n: d.length,
    reliability: reliabilityDiagram(d, bins: bins),
    decomposition: murphy(d, bins: bins),
    gate: evaluateGate(d, minN: minN),
  );
}
```

- [ ] **Step 5: Rodar os testes + suíte inteira + análise**

Run: `cd calibration && dart test test/report_test.dart test/end_to_end_test.dart`
Expected: PASSA. Depois:
Run: `cd calibration && dart analyze && dart test`
Expected: `No issues found!` e TODOS os testes do pacote passam.

- [ ] **Step 6: Commit**

```bash
git add calibration/lib/src/report.dart calibration/lib/oracle_calibration.dart calibration/test/report_test.dart calibration/test/end_to_end_test.dart
git commit -m "feat(calibration): CalibrationReport (buildReport) + testes ponta a ponta"
```

---

## Notas para quem executar

- `oracle_calibration` depende de `oracle_store` por path (`../store`), que por sua
  vez depende de `oracle_engine`. Rode `dart pub get` em `calibration/` antes do
  primeiro teste.
- O tipo `previsao_emitida` já existe em `EventTypes` (store), mas o **builder**
  `previsaoEmitida` é novo e vive neste pacote (Task 5).
- Pareamento de calibração é por `(dia UTC, cid)`; os testes usam `DateTime.utc`.
- Não afrouxe os oráculos exatos de scoring/Murphy — se um falhar, a fórmula está
  errada, não o teste.
