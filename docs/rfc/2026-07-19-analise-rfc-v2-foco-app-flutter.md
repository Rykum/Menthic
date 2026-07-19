# Análise do RFC v2 (Evolução da Visão) — foco no app Flutter

**Data:** 2026-07-19 · **Base:** main com leva 2 (Onboarding → Hoje/OracleAnswer → Revisão)

## Veredito em uma frase

O RFC v2 não muda a arquitetura construída — ele a **confirma**: o núcleo
probabilístico, o contrato XAI e o ciclo fechado de aprendizagem que o RFC
apresenta como visão já existem nos 4 pacotes headless; o que falta é
**torná-los visíveis na UI**, e isso define exatamente a próxima leva.

## 1. O que o RFC pede que JÁ existe (e onde)

| Conceito do RFC | Onde já está |
|---|---|
| "Não prevê o futuro": cenários + confiança + hipóteses + limitações | Contrato `OracleAnswer` (estimate/low/high/confidence/factors/limitations) — renderizado fiel no `AnswerCard` da Hoje |
| Ciclo fechado (observação → modelo → simulação → escolha → resultado → recalibração) | Ponta a ponta: eventos → `DayStateDeriver` → `answerAgenda` (Monte Carlo) → `previsao_emitida` → Revisão noturna → `TwinLearner` (Bayes conjugado) → priors atualizados |
| Digital Twin Cognitivo probabilístico ("tendências, não certezas") | `TraitPriors`/`Traits` com distribuições (Normal/Beta/Gamma) + `simulateDay` |
| Sistema baseado em evidências, confiança revisável | Posteriors bayesianos com incerteza; rótulo de shrinkage ("ainda baseado mais em padrões gerais que nos seus") |
| Timeline Universal / Estado Global | O event store É a timeline universal — fonte única, tudo é evento com `ts`/`type`/`payload`; o estado do dia é derivado, nunca armazenado |
| Autoavaliação e recalibração ("diferencial mais forte") | `oracle_calibration` completo (Brier, skill score, reliability diagram, decomposição de Murphy, gate, Platt) — **construído e testado, mas sem UI** |

## 2. O que o RFC pede que NÃO existe e é implementável agora (leva 3)

1. **Modo Exploração "E se..."** → tela **Simular**: editar um dia hipotético
   (sono, agenda) e ver o `OracleAnswer` recalcular ao vivo, sem gravar nada.
   O engine já suporta; é só UI.
2. **Reality Model visível** (hipóteses + confiança + revisão) → tela **Meu
   Twin**: os 6 traços com valor central, incerteza e base de evidência.
3. **Recalibração visível** ("quando digo 70%, acerto ~68%") → tela
   **Calibração**: parear `previsao_emitida` × desfecho real do dia e mostrar
   Brier/acerto — o fechamento do loop que o RFC chama de maior diferencial.

Essas são exatamente as 3 telas restantes do blueprint doc 06 §9. O RFC v2 e
o blueprint convergem.

## 3. O que é visão de longo prazo — registrar, não construir agora

- **Life Graph / Context Graph, memórias multi-nível, World Model,
  camadas social/financeira/profissional**: exigem dados que o produto ainda
  não coleta e um motor além da fase 0. O substrato certo já existe — o event
  store é o log canônico de onde um grafo pode ser **derivado** depois (mesmo
  padrão do `DayStateDeriver`). Não criar um segundo banco agora.
- **Estados latentes e hipóteses sociais** ("ela demorou para responder"):
  inferir estado emocional de terceiros tem implicações sérias de LGPD/ética
  (blueprint doc 07). Fora do app até existir spec ética própria.
- **Causalidade** (vs correlação): direção correta, mas exige desenho de
  identificação causal no engine — pesquisa, não UI.
- **Confiança adaptativa (aging de evidência)**: implementável depois como
  decay nos posteriors do `oracle_learning`; não bloqueia nada da UI.
- **Integrações externas** (agenda, sono, banco...): o campo `origin` do
  evento já reserva o lugar; cada integração é uma leva própria.

## 4. Riscos que o RFC introduz (e como o app se protege)

- **Inflação de escopo**: "plataforma de tudo" mata a fase 0. Proteção: a
  unidade continua sendo o evento + o `OracleAnswer`; cada conceito novo do
  RFC só entra quando puder ser derivado dos eventos existentes.
- **Promessa acima da evidência**: com poucos dias de dados, qualquer tela de
  "Reality Model" precisa mostrar incerteza com a mesma proeminência que o
  valor central — regra que o design system já segue.

## 5. Decisão

Leva 3 do app Flutter = **Simular + Meu Twin + Calibração**, reusando o
design system e os pacotes prontos. Specs/planos em `docs/superpowers/`.
