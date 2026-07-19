# Leva 5 — Hardening Android — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fontes embutidas (fim do google_fonts), Hoje re-hidrata a previsão do dia, `flutter build apk --debug` verde.

**Architecture:** TTFs estáticos baixados por script commitado; helpers `fredoka`/`nunito` em `design/fonts.dart` com a mesma assinatura dos call sites atuais; recompute determinístico na Hoje sem novo evento.

## Global Constraints
- Pacotes core intactos. Banco futuro = Firebase (decisão do usuário); snapshot shared_preferences permanece.
- `dart format` + analyze limpos; suíte verde ao fim de cada task.

### Task 1: baixar e declarar as fontes
**Files:** Create `scripts/fetch_fonts.mjs`, `app/assets/fonts/*.ttf` (6 arquivos) · Modify `app/pubspec.yaml` (fonts + remove google_fonts)
- [ ] script (css2 API, UA simples, regex ttf) → rodar → 6 TTFs > 50KB → declarar famílias → commit `chore(app): fontes Fredoka/Nunito embutidas (offline)`

### Task 2: refatorar para os helpers locais
**Files:** Create `app/lib/design/fonts.dart` · Modify `design/theme.dart`, `design/widgets.dart` e todas as telas que usam `GoogleFonts.*` (troca de import + prefixo)
**Interfaces:** `TextStyle fredoka({double? fontSize, FontWeight? fontWeight, Color? color, TextDecoration? decoration, List<Shadow>? shadows})`; `nunito` idem; export no barrel `design/design.dart`.
- [ ] refatorar → `flutter pub get` (sem google_fonts) → suíte inteira verde → analyze → commit `refactor(design): fontes locais no lugar do google_fonts`

### Task 3: Hoje re-hidrata a previsão do dia
**Files:** Modify `app/lib/features/today/today_screen.dart` · Modify `app/test/features/today/today_test.dart`
**Interfaces:** `_reload` detecta `previsao_emitida` na janela de hoje e chama `_compute(persist: false)`; `_prever` = `_compute(persist: true)`.
- [ ] teste red (seed com previsão de hoje → card visível ao abrir; nº de `previsao_emitida` não muda) → implementar → green → commit `feat(today): re-hidrata a previsao do dia apos reload`

### Task 4: builds + finalização
- [ ] `flutter build web --no-tree-shake-icons` e `flutter build apk --debug` verdes → READMEs (nota Firebase como banco futuro) → merge --no-ff na main → suíte no merge → push → apagar branch
