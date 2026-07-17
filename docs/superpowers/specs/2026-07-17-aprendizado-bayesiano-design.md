# Design Spec — Aprendizado Bayesiano dos Traços (Fase 0.4)

**Data:** 2026-07-17
**Status:** Aprovado para implementação
**Depende de:** `engine/` (`oracle_engine`) e `store/` (`oracle_store`), na `main`.

---

## 1. Contexto e objetivo

O digital twin (doc 4) é a posterior `P(θ | dados)`. Na Fase 0 não havia
aprendizado — `predict` usava sempre os priors neutros largos, o que deixava a
banda de incerteza larga e a confiança fixa em "baixa" (doc 10 §A.9). Este
sub-projeto constrói o **aprendizado conjugado** dos traços diretamente
observáveis (`o` e `ρ`), produzindo um `TraitPriors` atualizado que o motor
consome. É o mecanismo que faz o twin virar "sobre você".

Decisões de enquadramento (com o usuário):

| Decisão | Escolha |
|---|---|
| Traços aprendidos | **`o` (Normal-Normal) e `ρ` (Beta-Bernoulli)** |
| `p0`, `φ`, `s`, `r` | Permanecem no prior (não diretamente observáveis na Fase 0) |
| Esquecimento (λ) | 1.0 (sem esquecimento na Fase 0) |
| Payoff da banda | Honesto: a banda **não aumenta** (encolhe parcialmente); o estreitamento pleno espera `p0` aprendível |
| Enriquecer `oracle_store` | **Não** — a extração lê `dur_real` genericamente do payload |

## 2. Pacote

Novo pacote Dart puro **`learning/`** (nome `oracle_learning`), dependendo de
`oracle_store` e `oracle_engine`. Headless, TDD, `dart analyze` limpo.

## 3. Componentes

### 3.1 Primitivas conjugadas (puras)

```
class BetaPosterior {
  final double a, b;
  const BetaPosterior(this.a, this.b);
  BetaPosterior update(int successes, int trials); // Beta(a+k, b+n-k)
  double get mean;      // a/(a+b)
  double get variance;  // ab/((a+b)²(a+b+1))
}

class NormalPosterior {
  final double mean, variance;
  const NormalPosterior(this.mean, this.variance);
  /// Normal-Normal com variância de observação conhecida sigma2.
  NormalPosterior updateObservations(List<double> xs, {double sigma2 = 0.25});
}
```

Normal-Normal (variância de observação `σ²` conhecida), prior `N(μ₀, τ₀²)`, n
observações com média `x̄`:
```
τ_n² = 1 / (1/τ₀² + n/σ²)
μ_n  = τ_n² · (μ₀/τ₀² + n·x̄/σ²)
```
O **shrinkage cai daqui**: `n=0` → posterior = prior; `n→∞` → posterior → dados.
Lista vazia → retorna o próprio prior inalterado.

### 3.2 Extração de observáveis (do event store)

```
class TraitObservations { final List<double> o; final int rhoSucessos, rhoTentativas; }
class ObservableExtractor {
  const ObservableExtractor();
  Future<TraitObservations> extract(EventStore store);
}
```
- **`o`**: para cada `tarefa_concluida` cujo `payload` tem `dur_real`, pareia com o
  `compromisso_criado` de mesmo `cid` e computa `ln(dur_real / dur_prevista)`.
  Sem `dur_real` ou sem compromisso correspondente → ignora.
- **`ρ`**: `rhoTentativas` = nº de tarefas aversivas (compromissos com `aversivo=true`
  que têm um `tarefa_concluida`); `rhoSucessos` = quantas tiveram `atraso_min > 0`.

### 3.3 `TwinLearner`

```
class TwinLearner {
  const TwinLearner();
  Future<TraitPriors> learn(EventStore store, {TraitPriors prior = TraitPriors.neutral, double sigma2 = 0.25});
}
```
Fluxo: extrai observáveis → atualiza `o` (Normal-Normal a partir de
`prior.o`) e `ρ` (Beta-Bernoulli a partir de `prior.rho`) → devolve um novo
`TraitPriors` com `o` e `rho` atualizados e `phi/p0/s/r` **iguais ao prior**.
- `o` atualizado → `NormalPrior(μ_n, sqrt(τ_n²))`.
- `rho` atualizado → `BetaPrior(a+k, b+n−k)`.

## 4. Fluxo provado (ponta a ponta)

```
eventos (compromisso_criado + tarefa_concluida com dur_real/atraso)
  → ObservableExtractor.extract → TraitObservations
  → TwinLearner.learn (conjugado, a partir do prior populacional)
  → TraitPriors atualizado (o, ρ mais estreitos)
  → oracle_engine.predict / answerAgenda  (roda com o twin aprendido)
```

## 5. Testes

- **Beta-Bernoulli** (oráculo exato): `Beta(2,5)` + 3 sucessos/10 → `Beta(5,12)`,
  média 5/17; variância menor que a do prior.
- **Normal-Normal** (oráculo exato): `N(0.20, 0.01)` + 4 obs de média 0.40, σ²=0.25
  → `τ_n²=1/116`, `μ_n=26.4/116≈0.227586`; variância menor que 0.01.
- **Shrinkage**: n pequeno → posterior ≈ prior; n grande → posterior ≈ dados.
- **Extractor**: eventos → `o` correto (ln da razão) e contagem de `ρ` correta;
  tarefas sem `dur_real` ignoradas para `o`.
- **TwinLearner**: `TraitPriors` de saída tem `o`/`rho` mais estreitos e deslocados
  para os dados; `p0`/`phi`/`s`/`r` idênticos ao prior.
- **End-to-end (honesto)**: store com histórico → `learn` → `predict` roda e produz
  `OracleAnswer` válido; a largura da banda com priors aprendidos **não é maior**
  que com o neutro. **Não** assere estreitamento forte (isso espera `p0`).

## 6. Fora de escopo (YAGNI)

Aprender `p0`/`φ`/`s`/`r`, esquecimento/non-stationarity, descoberta de padrões,
detecção de mudança, UI. Sem modificar `oracle_store`.

## 7. Critério de sucesso

A partir do histórico de eventos, o sistema produz um `TraitPriors` cujos `o` e `ρ`
são posteriors conjugados (mais estreitos, deslocados para os dados, com shrinkage
honesto), e o motor faz `predict` com esse twin aprendido — tudo testado com
oráculos exatos, `dart analyze` limpo.
