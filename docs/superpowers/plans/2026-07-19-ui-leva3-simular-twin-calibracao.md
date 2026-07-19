# UI Leva 3 — Simular, Meu Twin e Calibração — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Materializar na UI os três pilares do RFC v2 já prontos no núcleo: exploração "E se..." (Simular), Reality Model (Meu Twin) e autoavaliação (Calibração).

**Architecture:** Três features novas (`simulate/`, `twin/`, `calibration/`) sobre o design system e os providers da leva 2; helpers puros e testáveis (`pairing.dart`, `trait_view.dart`); reuso do `AnswerCard`; `oracle_calibration` entra na UI pela primeira vez.

**Tech Stack:** Flutter 3.32.4 · pacotes oracle_* por path · flutter_riverpod · go_router · shared_preferences.

## Global Constraints

- Pacotes `engine/`, `store/`, `calibration/`, `learning/` não são modificados.
- Nenhum hex direto — só tokens de `design/tokens.dart`.
- `flutter analyze` limpo e `dart format .` ao fim de cada task.
- Simular **não grava eventos**; `ts` de leitura em UTC como na leva 2.

---

### Task 1: Helpers puros — `pairing.dart` e `trait_view.dart`

**Files:** Create `app/lib/features/calibration/pairing.dart`, `app/lib/features/twin/trait_view.dart` · Tests `app/test/features/calibration/pairing_test.dart`, `app/test/features/twin/trait_view_test.dart`

**Interfaces:**
- `List<DayPair> pairPredictions(List<Event> events)` — `DayPair {DateTime day; double predicted; int outcome;}`; por dia UTC: última `previsao_emitida` + desfecho = todos compromissos prio ≥2 com `tarefa_concluida`; dias sem previsão ou sem desfecho algum são ignorados.
- `List<TraitView> traitViews(TraitPriors p)` — `TraitView {String nome; String valor; String incerteza;}` (6 itens, ordem φ,p0,ρ,s,o,r); incerteza por dispersão relativa: baixa <0.15, média <0.35, alta ≥0.35 (Normal: sd/escala típica; Beta: sd da Beta; Gamma: 1/√shape).

- [ ] Testes → red → implementar → green → format+analyze → commit `feat(app): helpers de pareamento previsao×desfecho e visao dos tracos`

### Task 2: Rotas novas + atalhos na Hoje (placeholders)

**Files:** Create telas placeholder `simulate/simulate_screen.dart`, `twin/twin_screen.dart`, `calibration/calibration_screen.dart` · Modify `router.dart` (9 rotas: + `simular`/`twin`/`calibracao`), `today_screen.dart` (linha de atalhos com 3 NeuButtons) · Update `test/router_test.dart` (9 nomes) e `test/features/today/today_test.dart` (atalho navega)

- [ ] Testes → red → implementar → suíte inteira green → commit `feat(app): rotas simular/twin/calibracao + atalhos na Hoje`

### Task 3: Tela Simular

**Files:** Replace `simulate/simulate_screen.dart` · Test `test/features/simulate/simulate_test.dart`

**Interfaces:** consome `eventStoreProvider` (só leitura p/ estado inicial), `priorsRepoProvider`, `answerAgenda`, `AnswerCard`. Estado local: sono + lista de compromissos hipotéticos; recalcula ao editar; banner "cenário hipotético · nada foi salvo".

- [ ] Teste (editar sono → card recalcula; snapshot do store inalterado) → red → implementar → green → commit `feat(simulate): tela Simular — E se... sem gravar eventos`

### Task 4: Tela Meu Twin

**Files:** Replace `twin/twin_screen.dart` · Test `test/features/twin/twin_test.dart`

**Interfaces:** consome `priorsRepoProvider.load()`, `traitViews`, contagem de dias com desfecho (como na Hoje). Render: card por traço (nome, valor, incerteza) + cabeçalho de evidência.

- [ ] Teste (arquétipo manhã → "10" no pico; 6 cards) → red → implementar → green → commit `feat(twin): tela Meu Twin — Reality Model com incerteza`

### Task 5: Tela Calibração

**Files:** Replace `calibration/calibration_screen.dart` · Test `test/features/calibration/calibration_test.dart`

**Interfaces:** consome `eventStoreProvider.all()`, `pairPredictions`, `brierScore`/`baseRate` de `oracle_calibration`. Render: n, Brier, "previsto em média P% · aconteceu em Q%", lista (data · previsto% · ✓/✗), aviso se n < 10.

- [ ] Teste (2 dias seedados → 2 pares, Brier na tela) → red → implementar → green → suíte inteira → commit `feat(calibration): tela Calibracao — Brier e pares previsao×realidade`

### Task 6: Verificação Chrome + READMEs + finalização

- [ ] `flutter run -d web-server` + driver puppeteer (padrão scratchpad) nas 3 telas; olhar screenshots
- [ ] READMEs (app + raiz): estado da leva 3
- [ ] Suíte inteira + analyze + build web → merge `--no-ff` na main → testes no merge → push → apagar branch
