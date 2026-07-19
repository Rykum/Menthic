# UI Leva 2 — Onboarding, Hoje real e Revisão noturna (design)

**Data:** 2026-07-18 · **Status:** aprovado (conversa) · **Base:** leva 1 mergeada na main

## 1. Objetivo

Fechar o primeiro loop de valor do Project Oracle na UI: o usuário responde o
cold-start (dia 0), informa o dia (sono + agenda), vê o `OracleAnswer` real do
engine renderizado fiel ao mockup (doc 06 §6) e, à noite, registra o desfecho —
que atualiza o twin via `oracle_learning`.

Fora de escopo: Simular, Meu Twin, Calibração (telas), SQLite, Google no
onboarding, notificações.

## 2. Decisão de arquitetura: eventos como fonte da verdade

O app grava `EventDraft`s no `oracle_store` e deriva tudo deles:

- `DayState` de hoje ← `DayStateDeriver.derive(store, hoje)` (já existe; janela
  em UTC — o app grava `ts` em UTC).
- Aprendizado ← `TwinLearner.learn(store, prior: priorsSalvos)` (já existe; lê
  `compromisso_criado` + `tarefa_concluida` com `atraso_min`/`dur_real`).

**Persistência (web-friendly):** `PersistentEventStore` no app (`lib/data/`):
delega a um `InMemoryEventStore` e espelha snapshot JSON em
`shared_preferences` após cada mutação; hidrata no boot. SQLite fica para o
hardening Android. Alternativas descartadas: estado direto sem eventos (quebra
o extractor do learning) e sqlite3 wasm no Chrome (frágil agora).

**Priors do twin:** serializados em JSON próprio (`priors_codec.dart`) em
`shared_preferences` (`twin_priors`). `TraitPriors.neutral` quando ausente.

## 3. Componentes

### 3.1 `lib/data/` (novo)
- `PersistentEventStore implements EventStore` — wrapper + snapshot JSON.
- `priors_codec.dart` — `Map<String,dynamic> priorsToJson(TraitPriors)` /
  `TraitPriors priorsFromJson(...)` (6 traços, todos os hiperparâmetros).
- Providers Riverpod: `eventStoreProvider` (FutureProvider do store hidratado),
  `priorsProvider` (carrega/salva priors), `onboardedProvider` (flag).

### 3.2 Onboarding (`/onboarding`, feature `onboarding/`)
3 passos (PageView ou índice local), um card de vidro por pergunta, opções como
`NeuButton`s:
1. "Você rende melhor de manhã, à tarde ou à noite?" → μ_φ = 10 / 14 / 18.5
   (σ_φ = 2.5 mantido).
2. "Costuma adiar tarefas chatas?" (1 nunca … 5 sempre) → ρ Beta com média
   0.15·resposta e força do prior neutro (a+b = 7): a = 7m, b = 7(1−m).
3. "Ao planejar, subestima quanto as coisas demoram?" (1…5) → o Normal com
   μ = 0.05·resposta, σ = 0.10.
Demais traços: prior neutro (doc 10 A.2). Ao concluir: salva priors +
`onboarded=true` → `/hoje`.

Splash: logado+onboarded → `hoje`; logado sem onboarding → `onboarding`;
deslogado → `login`. (Cadastro/Login seguem indo para `home`→ renomeada `hoje`.)

### 3.3 Hoje (`/hoje`, feature `today/`, substitui a Home placeholder)
- **Entrada do dia** (mesma tela): sono da noite (horas, `PillField` numérico →
  evento `sono_registrado`) e compromissos (lista + botão adicionar que abre
  bottom sheet com nome/início/duração/aversivo → `compromisso_criado`;
  remover = `deleteById`).
- **Prever**: botão emite `answerAgenda(dayState, priors, observedDays: dias
  com desfecho, seed: 0)` e grava `previsao_emitida`
  (payload: estimate/low/high).
- **Render do `OracleAnswer`** (fiel ao doc 06 §6): pergunta, `~63%` grande,
  barra de faixa (`RangeBar` custom com tokens), "faixa provável 52–71%",
  confiança (alta/média/baixa), "O que mais pesou" (até 4 `Factor`s: seta
  ↑/↓ pela direção, força forte/média/fraca por |delta| ≥0.08/≥0.04/senão),
  "Limitações" (bullets). Sem LLM: os textos são fixos/formatados dos números.
- Botão "Revisão do dia" → `/revisao`.
- "Sair" permanece (AppBar/ícone).

### 3.4 Revisão noturna (`/revisao`, feature `review/`)
- Lista os compromissos de hoje com toggle feito/não feito; se feito, chips de
  atraso (0/15/30/60 min); humor 1–5 (chips).
- Salvar: por compromisso → `tarefa_concluida` (payload `cid`, `atraso_min`;
  `dur_real` omitido — sem coleta honesta ainda) ou `tarefa_nao_concluida`
  (`EventDraft` manual, tipo de `EventTypes`); humor → `humor_registrado`
  (`EventDraft` manual, payload `{'humor': n}`).
- Roda `TwinLearner.learn(store, prior: priorsAtuais)` → salva os novos priors
  → snackbar "Twin atualizado" → volta para `/hoje`.

### 3.5 Rotas
`/onboarding` (name `onboarding`), `/hoje` (name `hoje`; rota `home` morre),
`/revisao` (name `revisao`). Login/Cadastro/Splash passam a navegar para
`hoje` (ou `onboarding` na primeira vez).

## 4. Dados derivados usados na Hoje

- `observedDays` = nº de dias distintos (UTC) com evento `tarefa_concluida`
  ou `tarefa_nao_concluida`.
- Rótulo de shrinkage do doc 06 §7: se `observedDays < 7`, mostrar
  "ainda baseado mais em padrões gerais que nos seus" sob a confiança.

## 5. Testes

- `PersistentEventStore`: round-trip snapshot (append → novo store hidrata os
  mesmos eventos), delete/clear persistem.
- `priors_codec`: round-trip de `TraitPriors` (incl. arquétipos).
- Onboarding: responder manhã/5/5 gera priors esperados (μ_φ=10, ρ média 0.75,
  o μ=0.25) e navega para `hoje`.
- Hoje: com sono+2 compromissos, "Prever" mostra %, faixa e fatores; grava
  `previsao_emitida`.
- Revisão: marcar desfechos grava eventos certos e atualiza ρ (aversivo com
  atraso > 0 sobe a média de ρ).
- Splash: 3 destinos (login / onboarding / hoje).
- `flutter analyze` limpo; suíte inteira verde; verificação visual no Chrome
  (headless) como na leva 1.

## 6. Riscos e mitigação

- **Janela UTC do deriver** vs dia local: o app grava `ts` = `DateTime.now().toUtc()`
  e deriva com a data UTC de agora — consistente para o uso N=1.
- **shared_preferences com snapshot grande**: aceitável na fase 0 (eventos de
  um usuário); SQLite resolve no Android.
- **`tarefaNaoConcluida`/`humorRegistrado` sem draft helper no store**: app
  monta `EventDraft` direto com `EventTypes.*` (pacotes não são modificados).
