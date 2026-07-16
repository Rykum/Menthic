# Design Spec — Project Oracle: Blueprint Técnico (Vertical Slice)

**Data:** 2026-07-16
**Autor:** Equipe (via Claude) + Ppica
**Status:** Aprovado para produção do dossiê
**Tipo de entrega:** Dossiê técnico (blueprint), NÃO código

---

## 1. Contexto & natureza da entrega

Este documento NÃO especifica um app a ser codado agora. Ele especifica a
**produção de um blueprint técnico** ("dossiê de startup") para o produto
provisoriamente chamado **Project Oracle** — uma *Decision Intelligence Platform*
pessoal.

Decisões de enquadramento já tomadas com o usuário:

| Decisão | Escolha | Implicação |
|---|---|---|
| Meta das férias | **Blueprint de startup** | Produzir documentos rigorosos, não código |
| Leitor primário | **Você, o futuro builder** | Profundidade técnica máxima; negócio de leve |
| Abordagem | **A — Vertical Slice** | Ir fundo no Motor + 1 módulo-farol; resto por herança |
| Pesquisa | **Web real (WebSearch/WebFetch)** | Estado da arte e concorrentes com fontes reais |

## 2. Tese do produto (resumo)

Uma plataforma que ajuda pessoas a **explorar cenários e compreender consequências
prováveis** de suas decisões sob incerteza. Nunca afirma "isto vai acontecer";
sempre entrega **distribuição + grau de confiança + fatores + hipóteses +
limitações**. O produto não decide pelo usuário — ele ilumina trade-offs.

## 3. Pilares arquiteturais aprovados

Estes são os compromissos inegociáveis que atravessam todo o dossiê:

### Pilar 1 — O LLM NÃO é o motor probabilístico
- **LLM:** linguagem — interpretar input, **gerar hipóteses candidatas**, explicar
  resultados em prosa.
- **Modelos estatísticos explícitos** (Bayesiano / Monte Carlo / Markov):
  produzem as probabilidades, e são **inspecionáveis e calibráveis**.
- Justificativa: probabilidades saídas do LLM seriam impossíveis de calibrar e
  explicar de verdade — seria a adivinhação que o produto rejeita.

### Pilar 2 — Calibração é feature central, não enfeite
- Toda previsão é registrada com seu desfecho real e pontuada (**Brier score**,
  curvas de confiabilidade). Sem isso, as probabilidades são decoração.

### Pilar 3 — Local-first / on-device por padrão
- Os dados (humor, saúde, finanças, rotina) são os mais íntimos possíveis. LGPD e
  privacidade são **restrição de arquitetura**, não capítulo final.

### Pilar 4 — Escopo ético: Relacionamentos FORA do MVP
- Modelar o comportamento provável de outra pessoa (mesmo como "hipótese") é o
  "ler a mente" que o produto rejeita: validade quase nula (N=1, sem ground
  truth) e alto passivo ético/estratégico. Fica fora da fatia inicial.

## 4. Módulo-farol escolhido: Vida Diária

Único domínio com (a) dados logáveis de alta frequência, (b) matemática tratável,
(c) feedback de acerto verificável (calibração), (d) risco ético baixo. É a fatia
que prova o loop inteiro com N=1 (o próprio usuário).

## 5. Estrutura do dossiê a produzir

Cada item abaixo é um documento (ou seção maior) do blueprint:

0. **Sumário executivo & tese** — curto.
1. **Estado da arte & posicionamento** *(pesquisa web real)* — Decision
   Intelligence; métodos (redes Bayesianas, Monte Carlo, Markov, inferência
   causal, RL, XAI, digital twins cognitivos); concorrentes reais e onde falham;
   papers recentes; a lacuna onde inovamos. Com citações.
2. **Princípios de produto & filosofia** — contrato anti-certeza formalizado;
   calibração como feature; escopo ético; apresentação de incerteza sem paralisar
   (economia comportamental).
3. **O Motor de Decisão (coração técnico)** — formalização do loop
   `estado → evento → probabilidade → consequência → novo estado`; ontologia de
   estado; matemática (incerteza, Monte Carlo de dia, Markov/semi-Markov,
   atualização Bayesiana, análise de sensibilidade, árvores de decisão); loop de
   calibração; API conceitual do motor.
4. **Digital Twin Cognitivo** — modelo probabilístico do usuário (distribuições de
   parâmetros); aprendizado online Bayesiano e hierárquico; estratégia de
   cold-start (priors populacionais → shrinkage); transparência do aprendizado.
5. **Arquitetura de sistema** — local-first/on-device; Flutter + camada de motor
   (Dart vs. Rust-FFI vs. backend — trade-offs); onde LLM/IA entra; event store +
   time-series + feature store local; RAG/memória/agentes (onde fazem sentido);
   pipeline de simulação; sync opcional.
6. **Módulo-farol: Vida Diária (spec completo)** — modelo de dados do dia; inputs
   e coleta; simulação concreta (cumprir agenda, fadiga, produtividade, atrasos,
   bem-estar); saídas XAI concretas; fechamento do loop de calibração.
7. **Ética, LGPD & riscos** — dados sensíveis e minimização; vieses e limitações;
   guardrails anti-manipulação; o que NÃO fazemos e por quê.
8. **Roadmap de construção** — ordem de build (motor mínimo → digital twin →
   Vida Diária → calibração → UI de XAI); marcos e o que provar em cada fase.

**Apêndice — Visão completa** — os 6 módulos e como cada um mapeia no motor.

## 6. Fora de escopo (YAGNI para este dossiê)

- Spec profundo dos módulos Relacionamentos, Carreira, Estudos, Saúde, Finanças
  (entram só no apêndice, como herança do motor).
- Plano de negócio, GTM, captação (audiência é o builder, não investidor).
- Código de produção (é blueprint, não implementação).

## 7. Critério de sucesso

O dossiê está pronto quando um builder consegue, a partir dele, **começar a
construir o Motor + Vida Diária no dia 1**, com a matemática, a arquitetura e o
loop de calibração suficientemente especificados para não precisar re-decidir o
fundamental.

## 8. Método de produção

- Pesquisa web real para as seções 1 (estado da arte/concorrentes) e insumos das
  seções 3–5 (métodos e tecnologias).
- Cada documento numerado acima vira uma tarefa no plano de implementação
  (writing-plans), produzido em sequência com checkpoints de revisão.
