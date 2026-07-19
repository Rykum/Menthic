# Leva 6 — Motor de Estratégias — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `suggestStrategies` no engine (busca local sobre o simulador, comparação pareada por seed) + seção "Se seu objetivo é terminar tudo" no AnswerCard, com log de aceitação (`estrategia_aceita`).

**Architecture:** `engine/lib/src/strategies.dart` (novo, exportado no barrel) gera até 3 candidatos (mover p/ pico, cortar menor prioridade, −1h de débito) avaliados por `answerAgenda` com o mesmo seed do baseline. UI: `AnswerCard(strategies:, onStrategyTap:)`; Hoje computa+loga; Simular só mostra.

## Global Constraints
- Mudança de núcleo: só `oracle_engine` (novo arquivo + export). Store/learning/calibration intactos.
- Baseline e candidatos com o mesmo `seed`; só `delta > 0.01`; máx. 3, ordenadas por delta desc.
- `dart format` + analyze limpos em `engine/` e `app/`.

### Task 1: engine — `Strategy` + `suggestStrategies`
**Files:** Create `engine/lib/src/strategies.dart`, `engine/test/strategies_test.dart` · Modify `engine/lib/oracle_engine.dart` (export)
- [ ] testes red (débito alto+foco fora do pico → mover_pico/menos_debito_sono com delta>0; sem débito+1 compromisso → sem essas; determinismo; máx. 3) → implementar → green → format+analyze → commit `feat(engine): suggestStrategies — busca local de estrategias sobre o simulador`

### Task 2: AnswerCard com estratégias + Hoje loga aceitação
**Files:** Modify `app/lib/features/today/answer_card.dart` (params opcionais + seção), `app/lib/features/today/today_screen.dart` (`_compute` gera estratégias; tap grava `estrategia_aceita`) · Modify `app/test/features/today/today_test.dart`
- [ ] teste red (fluxo prever → seção visível; tap na estratégia grava evento) → implementar → green → commit `feat(today): estrategias sugeridas no card + log de aceitacao`

### Task 3: Simular mostra estratégias (sem gravar)
**Files:** Modify `app/lib/features/simulate/simulate_screen.dart` · Modify `app/test/features/simulate/simulate_test.dart`
- [ ] teste red (cenário com débito → seção presente; snapshot do store inalterado) → implementar → green → commit `feat(simulate): estrategias no cenario hipotetico`

### Task 4: finalização
- [ ] suítes engine+app, analyze, build web → README do app (nota) → merge --no-ff na main → suíte no merge → push → apagar branch
