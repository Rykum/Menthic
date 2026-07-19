# Leva 4 — Aprendizado mais rico (dur_real) e Confiança Adaptativa (decay)

**Data:** 2026-07-19 · **Status:** aprovado ("faça direto") · **Base:** análise do RFC v2 §3 ("confiança adaptativa: implementável como decay nos posteriors")

## 1. Objetivo

Dois buracos do ciclo de aprendizagem, ambos apontados pelo RFC v2:

1. **O traço `o` (otimismo de agenda) nunca aprende**: o `ObservableExtractor`
   lê `dur_real` de `tarefa_concluida`, mas a Revisão noturna não coleta essa
   informação. → A Revisão ganha a pergunta "durou quanto vs o previsto?".
2. **Evidência não envelhece** (RFC: "o usuário treinava 5×/semana… há oito
   meses; a confiança diminui automaticamente"). → `agePriors` no
   `oracle_learning`: posteriors regridem ao prior neutro conforme o tempo
   desde a última evidência.

## 2. Design

### 2.1 `dur_real` na Revisão (app; sem tocar pacotes)
- Para cada compromisso marcado "feito", chips **"durou:"** com 4 opções
  relativas ao previsto: `menos` (×0.7) · `como previsto` (×1.0) ·
  `mais` (×1.5) · `muito mais` (×2.0). Default: como previsto.
- A Revisão passa a carregar também `dur_prevista` por cid (já vem no evento
  `compromisso_criado`) e grava `dur_real = dur_prevista × fator` no payload
  de `tarefa_concluida` (o draft `tarefaConcluida` do store não tem o campo —
  o app monta `EventDraft` manual com `cid`, `atraso_min`, `dur_real`).
- Efeito: `oObs = ln(dur_real/dur_prevista)` alimenta o posterior de `o`
  (Normal-Normal já implementado). "como previsto" contribui ln(1)=0 — é
  evidência real de que o plano foi realista, não ruído.

### 2.2 `agePriors` (pacote `oracle_learning`; mudança de núcleo documentada)
- `TraitPriors agePriors(TraitPriors p, {required double daysSinceEvidence, double halfLifeDays = 90, TraitPriors anchor = TraitPriors.neutral})`
- Fator de esquecimento `λ = 0.5^(days/halfLife)`; interpolação para o anchor:
  - Normal: `mean' = anchor + (mean − anchor)·λ`; `var' = anchorVar + (var − anchorVar)·λ` (a incerteza reinfla).
  - Beta/Gamma: interpola os hiperparâmetros: `a' = anchorA + (a − anchorA)·λ` etc. (pseudo-contagens derretem para o prior).
- `daysSinceEvidence <= 0` → identidade. Sem evidência nenhuma → o app nem chama.

### 2.3 Uso no app
- Helper `Future<TraitPriors> loadAgedPriors(EventStore store, PriorsRepo repo)`
  em `app/lib/data/aged_priors.dart`: carrega priors salvos; procura o último
  evento de desfecho (`tarefa_concluida`/`tarefa_nao_concluida`); se existir,
  aplica `agePriors` com os dias desde então. Usado por Hoje (`_prever`),
  Simular (`_recompute`) e Meu Twin (o que se mostra é o que se usa).
- Os priors **salvos não mudam** — o decay é aplicado na leitura (idempotente,
  sem reescrita acumulativa).

### 2.4 Cosmético
- Calibração: "1 previsões avaliadas" → singular correto.

## 3. Testes
- learning (`dart test`): λ=1 identidade; meia-vida exata → ponto médio;
  days→∞ → anchor; variância da Normal reinfla.
- Revisão: "feito" + "durou: mais" grava `dur_real = 1.5×dur_prevista` e o
  posterior de `o` se move; default "como previsto" grava `dur_real =
  dur_prevista`.
- `aged_priors`: com desfecho antigo seedado (90 dias), ρ aprendido regride à
  metade do caminho para o neutro; sem desfechos → priors intactos.
- Calibração singular; suíte inteira; analyze nos dois pacotes.

## 4. Fora de escopo
Half-life configurável na UI; decay por traço; hardening Android.
