# Design Spec — Loop de Calibração (Fase 0.3)

**Data:** 2026-07-17
**Status:** Aprovado para implementação
**Depende de:** `engine/` (`oracle_engine`) e `store/` (`oracle_store`), ambos na `main`.

---

## 1. Contexto e objetivo

O gate falsificável da Fase 0 (doc 8; doc 10 Parte B) exige medir se o motor
**prevê melhor que o trivial** e se está **calibrado**. Este sub-projeto constrói
essa máquina: registra previsões, pareia com desfechos, pontua (Brier/BSS,
diagrama de confiabilidade, decomposição de Murphy), dá o **veredito do gate** e
**recalibra** (Platt) previsões enviesadas. É o que valida o produto inteiro.

Decisões de enquadramento (com o usuário):

| Decisão | Escolha |
|---|---|
| Escopo | Medição + gate + integração com o store + recalibração **Platt** |
| Recalibração isotônica | **Fora** (depois) |
| Unidade de previsão | **Por compromisso** (doc 10 B.1) |
| Aprendizado dos traços / UI | **Fora** (sub-projetos futuros) |

## 2. Pacote

Novo pacote Dart puro **`calibration/`** (nome `oracle_calibration`), dependendo
de `oracle_store` (path) — e, por transitividade, `oracle_engine`. Headless,
testável com `dart test`, `dart analyze` limpo, TDD.

## 3. Componentes

### 3.1 Modelo de par

```
class PredOutcome { final double p; final int o; const PredOutcome(this.p, this.o); }
```
`p ∈ [0,1]` previsto; `o ∈ {0,1}` desfecho real.

### 3.2 Scoring (funções puras)

```
double brierScore(List<PredOutcome> d)        // (1/N) Σ (p−o)²
double baseRate(List<PredOutcome> d)           // ō = (1/N) Σ o
double brierBaseline(List<PredOutcome> d)      // (1/N) Σ (ō−o)²  = ō(1−ō)
double brierSkillScore(List<PredOutcome> d)    // 1 − Brier/Baseline
double calibrationInTheLarge(List<PredOutcome> d) // |média(p) − ō|
List<ReliabilityBin> reliabilityDiagram(List<PredOutcome> d, {int bins = 10})
MurphyDecomposition murphy(List<PredOutcome> d, {int bins = 10})
```

- `ReliabilityBin { double lo, hi; int n; double meanPredicted; double observedFreq; }`
  (bins iguais em [0,1]; o último inclui 1.0; bins vazios reportam n=0).
- `MurphyDecomposition { double reliability, resolution, uncertainty; }` com
  `uncertainty = ō(1−ō)`, `reliability = (1/N)Σ_k n_k(p̄_k−ō_k)²`,
  `resolution = (1/N)Σ_k n_k(ō_k−ō)²`. Identidade `Brier = REL − RES + UNC`
  (exata sobre previsões agrupadas por valor).
- Casos-limite: lista vazia → Brier/decomposição retornam `NaN`/vazio de forma
  definida; `baseline == 0` (desfechos todos iguais) → `BSS` retorna `NaN`
  (indefinido) — documentado e testado.

### 3.3 Veredito do gate

```
class GateResult { bool passed; double bss; double calibrationInTheLarge; int n; String reason; }
GateResult evaluateGate(List<PredOutcome> d, {int minN = 120, double minBss = 0.05, double maxCalibration = 0.05})
```
Regra (doc 10 B.5): se `n < minN` → `passed=false`, `reason` = "amostra
insuficiente". Senão, `passed = bss ≥ minBss && calibrationInTheLarge < maxCalibration`.

### 3.4 Recalibração Platt

```
class PlattCalibrator {
  final double a, b;
  static PlattCalibrator fit(List<PredOutcome> d, {int iters = 100});
  double apply(double p);   // σ(a·logit(p) + b)
}
```
`logit(p) = ln(p/(1−p))` com `p` clampeado em `(ε, 1−ε)`. `fit` ajusta `a,b` por
**regressão logística** (Newton ou gradiente, iterações fixas → determinístico)
minimizando log-loss sobre `(logit(p_i), o_i)`. Corrige viés sistemático.

### 3.5 Integração com o event store

- **Helper `previsaoEmitida`** (o tipo `previsao_emitida` já existe no store; falta
  o builder): `EventDraft previsaoEmitida({required DateTime ts, required String cid, required double p, String origin = 'motor'})`, payload `{cid, p}`.
- **`CalibrationExtractor.extract(EventStore) → Future<List<PredOutcome>>`**: lê os
  `previsao_emitida` e os pareia, por `(cid, dia)`, com o desfecho do mesmo
  compromisso — `tarefa_concluida` → `o=1`, `tarefa_nao_concluida` → `o=0`.
  Previsão sem desfecho correspondente é **ignorada** (não resolvida).

### 3.6 `CalibrationReport`

```
class CalibrationReport { double brier, bss, calibrationInTheLarge; int n;
  List<ReliabilityBin> reliability; MurphyDecomposition decomposition; GateResult gate; }
CalibrationReport buildReport(List<PredOutcome> d);
```

## 4. Fluxo provado (ponta a ponta)

```
motor → perCommitment → log previsao_emitida no store
desfechos (tarefa_concluida/nao_concluida) chegam
CalibrationExtractor.extract → List<PredOutcome>
buildReport → Brier/BSS/reliability/Murphy + GateResult
PlattCalibrator.fit(pares).apply(p) → p recalibrado (viés menor)
```

## 5. Testes

- **Scoring** com oráculos exatos (Brier, baseline, BSS, calibração-no-todo,
  Murphy num exemplo pequeno onde `Brier = REL − RES + UNC` fecha).
- **Gate**: `n<120` não julga; um caso que passa e um que falha.
- **Extractor**: eventos → pares corretos; pareamento por `(cid, dia)`; desfecho
  ausente ignorado; ambos os tipos de desfecho.
- **Platt**: em dados enviesados (excesso de confiança), a recalibração **reduz** a
  calibração-no-todo; determinístico; `apply` é monótona em `p`.
- **End-to-end**: store com previsões + desfechos → `CalibrationReport` coerente.

## 6. Fora de escopo (YAGNI)

Recalibração isotônica, aprendizado dos traços, UI, streams reativos. A interface
deixa tudo plugável.

## 7. Critério de sucesso

A partir de eventos de previsão e desfecho no store, o sistema produz um
`CalibrationReport` correto (Brier/BSS/reliability/Murphy/gate) e a recalibração
Platt reduz o viés sistemático — tudo testado com oráculos exatos onde possível,
`dart analyze` limpo.
