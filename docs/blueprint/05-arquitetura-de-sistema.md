# 05 — Arquitetura de Sistema

**Project Oracle — Decision Intelligence Platform pessoal**
Documento 5 do dossiê técnico · 2026-07-16 · Profundidade: implementável

> Como o produto é construído em software. Parte do princípio **local-first /
> on-device** (LGPD como arquitetura, não capítulo), define as **camadas**, a
> **escolha de runtime do motor** (Dart vs Rust-FFI vs backend), **onde o LLM
> entra sem violar a privacidade**, a **camada de dados** (event sourcing +
> time-series + feature store), o **pipeline de simulação**, e onde **RAG/agentes**
> fazem sentido (e onde são overkill). Stack concreta, com trade-offs.

---

## 1. Princípio arquitetural: local-first por padrão

Os dados do Oracle são os mais íntimos possíveis (sono, humor, finanças, rotina).
A pesquisa de ética do digital twin (doc 1 §3.1, doc 4 §9) e a LGPD empurram para
uma conclusão de **arquitetura**, não de política:

> **O modelo do usuário e seus dados brutos vivem no dispositivo. A nuvem é
> opcional, e nunca vê dados brutos íntimos.**

Consequências que atravessam tudo abaixo:
- **Source of truth = dispositivo.** Sync é uma otimização, não um requisito.
- **A nuvem só recebe agregados/anônimos** (para priors populacionais, §8) ou
  **estruturas já computadas** (para explicação por LLM, §4) — nunca o log bruto.
- **Right-to-forget é trivial:** apagar local = apagar de verdade (doc 4 §7).

## 2. As camadas

```
┌──────────────────────────────────────────────────────────────┐
│  APRESENTAÇÃO  — Flutter (UI, XAI, painel do twin)            │
│  render do OracleAnswer, faixas/incerteza, progressive disclos│
├──────────────────────────────────────────────────────────────┤
│  ORQUESTRAÇÃO  — Dart (application layer)                     │
│  monta estado, chama o motor, chama LLM p/ prosa, loga previsão│
├──────────────────────────────────────────────────────────────┤
│  MOTOR  — núcleo de cálculo (Rust via FFI  [recomendado])     │
│  Monte Carlo, semi-Markov, Bayes, sensibilidade, calibração   │
├──────────────────────────────────────────────────────────────┤
│  DADOS (on-device)                                            │
│  Event Store (append-only) · Time-series · Feature Store      │
│  cripto em repouso (SQLCipher) · chaves no keychain do OS     │
├───────────────────────────────┬──────────────────────────────┤
│  NUVEM OPCIONAL (consentida)   │                              │
│  • LLM API (só vê estrutura)   │  • Priors populacionais      │
│  • Sync cifrado E2E            │    (agregados / federado)    │
└───────────────────────────────┴──────────────────────────────┘
```

Cada camada tem uma fronteira clara (princípio de isolamento): a UI não conhece
matemática; o motor não conhece UI nem rede; a orquestração é a única que fala
com a nuvem.

## 3. Runtime do motor — a escolha de engenharia central

O motor (doc 3) é cálculo numérico intenso (milhares de simulações). Onde ele roda?

| Opção | Prós | Contras | Veredito |
|---|---|---|---|
| **Dart puro (isolates)** | Zero FFI, um só idioma, deploy simples, bom p/ MVP | Numérico mais lento; sem libs científicas maduras | **Fase 0 / protótipo** |
| **Rust via FFI** (`flutter_rust_bridge`) | Rápido, determinístico, portátil (mesmo core em iOS/Android/desktop), libs (`nalgebra`, `rand`, `statrs`) | Complexidade de build, ponte FFI | **Recomendado p/ produção** |
| **Backend Python (nuvem)** | Ecossistema científico (PyMC, NumPyro) | **Viola local-first**; latência; custo; privacidade | **Rejeitado** p/ o motor |

**Recomendação:** começar o protótipo em **Dart puro** para validar a
matemática rápido; migrar o núcleo quente para **Rust via FFI** para produção.
O contrato do motor (doc 3 §10) é agnóstico de linguagem justamente para permitir
essa troca sem tocar UI nem módulos. Rust também dá **um único núcleo** rodando
em celular e desktop — importante para um produto que quer ser sério.

> Nota: Python na nuvem é ótimo para **pesquisa/treino offline** dos arquétipos
> populacionais (§8), mas **não** para o motor em runtime — isso mandaria dados
> íntimos para fora.

## 4. Onde o LLM entra — sem quebrar a privacidade

Pilar 1 (doc 2/3): o LLM faz **linguagem e geração de hipóteses**, não
probabilidade. Mas há uma tensão real: mandar dados íntimos para uma API de LLM
na nuvem contradiz o local-first. Resolução em camadas:

1. **O LLM só vê a estrutura já computada**, não o log bruto. A explicação recebe
   o `OracleAnswer` (números, fatores, limitações) — que já é agregado e
   despersonalizado — e o transforma em prosa. Ele nunca recebe "seu diário".
2. **Geração de hipóteses** (ex.: no futuro módulo de decisões abertas) usa
   descrições abstratas, não identificáveis.
3. **Opção on-device:** um LLM pequeno local (ex.: modelos 1–3B quantizados) para
   quem exige zero dados na nuvem — qualidade de prosa menor, privacidade máxima.
   Configurável pelo usuário.
4. **Consentimento explícito e granular** para qualquer chamada de nuvem, com o
   que exatamente é enviado exibido.

> Resumo: o motor probabilístico é **sempre local**; o LLM é uma camada de
> linguagem que opera sobre **saídas já seguras** ou roda on-device. A separação
> do Pilar 1 é o que torna isso possível — se o LLM fosse o motor, não haveria
> como proteger os dados.

## 5. Camada de dados — event sourcing + features

### 5.1 Event Store (append-only) — a fonte da verdade

Toda observação é um **evento imutável** anexado a um log:

```
Event { id, ts, tipo, payload, origem }
  ex.: {t, "sono_registrado", {horas:5.5}, manual}
       {t, "tarefa_concluida", {id, atraso_min:20}, manual}
       {t, "previsao_emitida", {OracleAnswer...}, motor}   ← p/ calibração
```

Por que event sourcing:
- **Reconstrução e replay:** o estado e o twin são *derivados* dos eventos →
  podemos reprocessar quando o modelo evolui.
- **Right-to-forget real:** apagar eventos e re-derivar (doc 4 §7).
- **Calibração:** previsões e desfechos são só mais eventos — o loop do doc 3 §9
  lê deste log.

### 5.2 Time-series & Feature Store

Materializações derivadas do event log, para o motor consumir rápido:
- **Time-series:** séries por variável (sono, energia, conclusões) para
  tendências e sazonalidade.
- **Feature store local:** features pré-computadas (média móvel de sono, taxa de
  conclusão por dia-da-semana) que alimentam a atualização de `θ` e a simulação.

### 5.3 Stack de persistência (on-device)

| Necessidade | Escolha recomendada | Alternativa |
|---|---|---|
| Event log + queries | **SQLite via Drift** (tipado, migrações) | Isar/ObjectBox (mais rápido, menos SQL) |
| Cripto em repouso | **SQLCipher** (AES-256) | cifra a nível de app |
| Chaves | **Keychain (iOS) / Keystore (Android)** | — |
| Modelo do twin | serializado no mesmo DB (snapshot + eventos) | arquivo cifrado |

## 6. Pipeline de simulação (fluxo de um `predict`)

```
UI pede previsão
   │
   ▼
Orquestração (Dart): monta State a partir do Feature Store
   │
   ▼
Motor (Rust/isolate, FORA da thread de UI):
   carrega posterior(θ) → roda Monte Carlo (doc 3 §4)
   → sensibilidade (§7.2) → ajusta por calibração (§9)
   → devolve OracleAnswer (estrutura)
   │
   ▼
Orquestração: LLM.explicar(OracleAnswer) → prosa   (§4, opcional/local)
   │
   ▼
Event Store: grava "previsao_emitida"  (p/ calibração)
   │
   ▼
UI renderiza faixa + confiança + fatores + limitações
```

**Regra de performance:** o cálculo **nunca** roda na thread de UI — vai para
**Dart isolate** (fase 0) ou thread nativa Rust (produção). O `predict` alvo é de
milissegundos a poucos segundos (doc 3 §11.1), mantendo a UI fluida.

## 7. RAG, memória e agentes — o que serve e o que é overkill

Sendo crítico (o documento-fonte pede rigor, não hype):

- **RAG:** **útil, escopo estreito.** Serve para a camada de linguagem recuperar
  *o histórico do próprio usuário* como contexto para uma explicação melhor
  ("da última vez que você tentou isso…"). **Não** é para "buscar conhecimento
  do mundo". Implementação: embeddings locais dos eventos + busca por
  similaridade on-device. Fase 2.
- **Memória:** já resolvida pelo **event store + twin** — não precisamos de uma
  "memória de agente" separada. O twin *é* a memória estruturada; o event log *é*
  a memória episódica.
- **Agentes / multi-agente:** **overkill no MVP.** O motor é um pipeline
  determinístico, não um enxame de agentes autônomos. Agentes só se justificariam
  muito depois, para orquestrar *ações* (ex.: mexer na sua agenda por você) — o
  que colide com "o produto não decide" (doc 2). Manter fora até haver razão real.

> Princípio: **não adicionar componente de IA da moda sem um problema concreto que
> só ele resolva.** RAG entra estreito; agentes ficam de fora.

## 8. Nuvem opcional: priors populacionais sem exfiltrar dados

Os arquétipos do cold-start (doc 4 §4) precisam de dados populacionais — mas não
podemos coletar diários das pessoas. Abordagem preservando privacidade:

- **Agregação/anonimização:** só estatísticas agregadas de traços (não eventos)
  saem do device, com consentimento.
- **Aprendizado federado / privacidade diferencial:** atualizar os arquétipos a
  partir de updates locais com ruído, sem centralizar dados brutos. Fase 2+.
- **Alternativa fase 0:** arquétipos definidos por especialista + literatura
  (cronotipos, planning fallacy típico) — nenhum dado coletado. Suficiente para
  começar.

## 9. Segurança (resumo; detalhe no doc 7)

- Cripto em repouso (SQLCipher/AES-256) + chaves no enclave do OS.
- Sync (se ativado) **E2E**: a nuvem guarda blobs cifrados que não consegue ler.
- Sem PII para nuvem por padrão; toda saída de dados é opt-in e mostrada.
- Superfície de ataque mínima: motor e dados locais, nuvem burra.

## 10. Stack recomendada (resumo)

| Camada | Fase 0 (protótipo) | Produção |
|---|---|---|
| UI | Flutter | Flutter |
| Orquestração | Dart | Dart |
| Motor | Dart (isolates) | **Rust via `flutter_rust_bridge`** |
| Dados | Drift/SQLite | Drift/SQLite + **SQLCipher** |
| LLM | API cloud (só estrutura) | cloud consentido **ou** on-device |
| Priors pop. | especialista/literatura | federado + privacidade diferencial |
| Sync | nenhum | E2E cifrado, opcional |

---

## 11. Como este documento amarra o resto

- Realiza a **API do motor** e o requisito **on-device** do **doc 3 (§10, §11.1)**.
- Hospeda o **twin** e seu **event log** do **doc 4** (right-to-forget, painel).
- A camada de dados e a cripto são a base do **doc 7 (Ética/LGPD/Segurança)**.
- A stack por fase alimenta diretamente o **roadmap (doc 8)**: Dart puro primeiro,
  Rust depois; especialista antes de federado.
- O **módulo-farol (doc 6)** é construído sobre estas camadas.
