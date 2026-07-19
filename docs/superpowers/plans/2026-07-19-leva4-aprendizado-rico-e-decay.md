# Leva 4 — dur_real na Revisão + agePriors (decay) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** O traço `o` passa a aprender (coleta de `dur_real` na Revisão) e a evidência envelhece (`agePriors` no oracle_learning, aplicado na leitura dos priors).

**Architecture:** `agePriors` é função pura no pacote `oracle_learning` (única mudança de núcleo, testada com `dart test`). No app: `aged_priors.dart` centraliza a leitura envelhecida; Revisão ganha os chips "durou:"; Hoje/Simular/Twin passam a usar `loadAgedPriors`.

**Tech Stack:** como levas anteriores.

## Global Constraints
- Única mudança de pacote: `learning/lib/src/age.dart` (+ export no barrel + teste). Engine/store/calibration intactos.
- Priors salvos nunca são reescritos pelo decay — só a leitura envelhece.
- `dart format` + analyze limpos em `app/` e `learning/` ao fim de cada task.

### Task 1: `agePriors` no oracle_learning
**Files:** Create `learning/lib/src/age.dart`, `learning/test/age_test.dart` · Modify `learning/lib/oracle_learning.dart` (export)
**Interfaces:** `TraitPriors agePriors(TraitPriors p, {required double daysSinceEvidence, double halfLifeDays = 90, TraitPriors anchor = TraitPriors.neutral})` — λ = 0.5^(days/halfLife); Normal: média e variância interpoladas; Beta/Gamma: hiperparâmetros interpolados; days <= 0 → identidade.
- [ ] teste red → implementar → green → format+analyze → commit `feat(learning): agePriors — confianca adaptativa por meia-vida`

### Task 2: chips "durou:" na Revisão (o aprende)
**Files:** Modify `app/lib/features/review/review_screen.dart` · Modify `app/test/features/review/review_test.dart`
**Interfaces:** `_ReviewItem` ganha `durPrevista` (lida do evento) e `durFator` (0.7/1.0/1.5/2.0, default 1.0); `_salvar` grava `EventDraft` manual de `tarefa_concluida` com `dur_real = durPrevista × durFator`.
- [ ] teste red ("durou: mais" → dur_real 3.0 p/ prevista 2.0; posterior de o se move) → implementar → green → commit `feat(review): coleta dur_real — o otimismo de agenda passa a aprender`

### Task 3: `loadAgedPriors` no app + uso em Hoje/Simular/Twin
**Files:** Create `app/lib/data/aged_priors.dart`, `app/test/data/aged_priors_test.dart` · Modify `today_screen.dart`, `simulate_screen.dart`, `twin_screen.dart` (trocar `priorsRepoProvider.load()` por `loadAgedPriors`) · Fix singular na `calibration_screen.dart`
**Interfaces:** `Future<TraitPriors> loadAgedPriors(EventStore store, PriorsRepo repo, {DateTime? now})` — último desfecho → dias → agePriors; sem desfecho → priors crus.
- [ ] testes red (desfecho há 90 dias → ρ no ponto médio p/ neutro; sem desfecho → intacto) → implementar → suíte inteira green → commit `feat(data): leitura de priors com decay + singular na Calibracao`

### Task 4: finalização
- [ ] `dart test` no learning + suíte app + analyze ambos + build web → READMEs (nota do decay) → merge --no-ff na main → teste no merge → push → apagar branch
