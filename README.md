# Project Oracle — Menthic

**Decision Intelligence Platform pessoal.** Uma plataforma que ajuda pessoas a
**explorar cenários e compreender as consequências prováveis** das próprias
decisões sob incerteza — nunca prometendo prever o futuro.

> O sistema nunca afirma *"isto vai acontecer"*. Ele diz: *"dadas as informações
> disponíveis, estes são os cenários mais prováveis, com esta confiança e estas
> limitações"* — e **compara estratégias** em vez de decidir pelo usuário.

**Status:** 🧠 Núcleo headless completo · **falta a UI em Flutter**.
O blueprint técnico está em `docs/blueprint/`. O motor de inteligência já está
construído e testado em **4 pacotes Dart puros** (88 testes, `dart analyze`
limpo). A próxima etapa é a **UI em Flutter**, que torna tudo utilizável e permite
rodar o experimento N=1.

## Estado atual (pacotes na `main`)

| Pacote | Fase | O que faz | Testes |
|---|---|---|---|
| [`engine/`](engine) (`oracle_engine`) | 0.1 | Motor de decisão: Monte Carlo aninhado, semi-Markov, energia/fadiga, sensibilidade, `OracleAnswer` | 28 |
| [`store/`](store) (`oracle_store`) | 0.2 | Event sourcing on-device (memória + SQLite), `DayStateDeriver` (eventos → estado do dia) | 29 |
| [`calibration/`](calibration) (`oracle_calibration`) | 0.3 | Brier/BSS, diagrama de confiabilidade, decomposição de Murphy, veredito do gate, recalibração Platt | 23 |
| [`learning/`](learning) (`oracle_learning`) | 0.4 | Aprendizado Bayesiano conjugado dos traços (`o`, `ρ`) → twin atualizado | 8 |

O ciclo do doc 3 fecha headless:
`estado → predict (engine) → log (store) → desfecho → calibração → aprendizado → twin melhor → predict`.

**Próximo:** UI em Flutter (entrada de 1 toque, revisão noturna, render do
`OracleAnswer`) — ver [doc 08](docs/blueprint/08-roadmap-de-construcao.md).
Especificações e planos de cada fase em [`docs/superpowers/`](docs/superpowers).

---

## Por onde começar

Comece pelo **[Sumário Executivo](docs/blueprint/00-sumario-executivo.md)** —
leitura de 5 minutos que abre o mapa.

## Os quatro pilares

1. **O LLM não é o motor probabilístico.** As probabilidades vêm de modelos
   estatísticos explícitos, inspecionáveis e calibráveis; o LLM só faz linguagem.
2. **Calibração é feature central.** Toda previsão é pontuada contra o desfecho
   real (Brier); o produto mostra o próprio histórico de acerto.
3. **Local-first / on-device.** Os dados mais íntimos vivem no dispositivo; LGPD
   como arquitetura, não promessa.
4. **Escopo ético como fronteira.** Sem modelar terceiros, sem diagnóstico, sem
   manipulação, sem promessa de prever o futuro.

## O dossiê

| # | Documento | Conteúdo |
|---|---|---|
| 00 | [Sumário executivo & tese](docs/blueprint/00-sumario-executivo.md) | mapa de 5 minutos |
| 01 | [Estado da arte & posicionamento](docs/blueprint/01-estado-da-arte-e-posicionamento.md) | mercado, concorrentes, a lacuna (19 fontes) |
| 02 | [Princípios de produto & filosofia](docs/blueprint/02-principios-de-produto-e-filosofia.md) | o contrato `OracleAnswer`, incerteza, ética |
| 03 | [Motor de decisão](docs/blueprint/03-motor-de-decisao.md) | a matemática implementável (coração) |
| 04 | [Digital twin cognitivo](docs/blueprint/04-digital-twin-cognitivo.md) | traços, cold-start, aprendizado |
| 05 | [Arquitetura de sistema](docs/blueprint/05-arquitetura-de-sistema.md) | local-first, Flutter+Rust, dados |
| 06 | [Módulo-farol: Vida Diária](docs/blueprint/06-modulo-farol-vida-diaria.md) | o spec concreto do MVP |
| 07 | [Ética, LGPD & riscos](docs/blueprint/07-etica-lgpd-e-riscos.md) | conformidade e salvaguardas |
| 08 | [Roadmap de construção](docs/blueprint/08-roadmap-de-construcao.md) | fases e gates falsificáveis |
| 09 | [Apêndice: visão completa](docs/blueprint/09-apendice-visao-completa.md) | os outros módulos |
| 10 | [Especificação da Fase 0](docs/blueprint/10-especificacao-fase-0.md) | parâmetros + protocolo + exemplo resolvido |

O documento de design que originou o dossiê está em
[`docs/superpowers/specs/`](docs/superpowers/specs/2026-07-16-project-oracle-blueprint-design.md).

## Stack planejada

- **App:** Flutter (Dart)
- **Motor:** Dart puro na Fase 0 → Rust via FFI em produção
- **Dados:** SQLite/Drift + SQLCipher, on-device (event sourcing)
- **IA:** LLM apenas na camada de linguagem (sobre saídas já computadas)

## Próximo passo

Construir a **UI em Flutter** sobre os 4 pacotes headless: entrada de 1 toque,
revisão noturna e render do `OracleAnswer` (faixa, confiança, fatores). É o que
torna o app utilizável e permite rodar o **experimento N=1** — o gate falsificável
(Brier bate o baseline trivial em 4–6 semanas) já está implementado em
`oracle_calibration`. Detalhe em [doc 10](docs/blueprint/10-especificacao-fase-0.md)
e [doc 08](docs/blueprint/08-roadmap-de-construcao.md).

---

© 2026 Project Oracle / Menthic. Todos os direitos reservados. Consulte
[LICENSE](LICENSE).
