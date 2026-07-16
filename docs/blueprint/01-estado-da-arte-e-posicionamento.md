# 01 — Estado da Arte & Posicionamento

**Project Oracle — Decision Intelligence Platform pessoal**
Documento 1 do dossiê técnico · 2026-07-16

> Objetivo deste documento: mapear o que já existe (campo, métodos, produtos),
> onde os análogos falham, e **onde há espaço real para inovar**. Serve de
> fundação para as decisões de arquitetura e matemática dos documentos 3–5.
> Fontes reais listadas ao final; afirmações sem link são síntese/conhecimento
> de domínio e estão marcadas como tal.

---

## 1. O campo: Decision Intelligence (DI)

**Decision Intelligence** é a disciplina que combina ciência de dados, ciências
sociais e teoria da decisão para melhorar como decisões são tomadas —
tratando a decisão em si como o objeto de engenharia, não apenas o dado ou o
modelo.

### 1.1 Mercado — grande, mas quase todo B2B

O mercado de plataformas de DI é estimado entre **US$ 16–17 bilhões em 2025**,
com projeção de ~US$ 20,7 bi em 2026 (CAGR ~19%) e cenários de US$ 68 bi até
2035 [1][6]. Segundo o Gartner CDAO Agenda Survey 2024, ~33% das organizações já
usavam DI e mais 17% planejavam adotar em 6 meses [1].

Os líderes são **corporativos**: FICO, SAS, IBM, Aera Technology, Pyramid,
Tellius, ThoughtSpot, Decisions, InRule [1]. Movimentos recentes: InRule AI Core
(regras via linguagem natural, 2025), IBM Decision Manager AI Suite + watsonx
(2025), Decisions com "Agentic Orchestration" (2025) [1].

> **Observação de posicionamento (a lacuna nº 1):** praticamente todo o mercado
> de DI é **B2B / operação empresarial** — otimizar supply chain, crédito,
> pricing, fraude. **Não existe um líder consolidado de "Decision Intelligence
> para a vida pessoal".** É exatamente o espaço do Project Oracle. O ferramental
> matemático é maduro e provado em empresa; a inovação é **transferi-lo para o
> indivíduo, com privacidade e explicabilidade no centro.**

## 2. Métodos e tecnologias do estado da arte

O motor de decisão pessoal precisa combinar várias famílias de técnicas. Estado
de maturidade de cada uma:

| Técnica | Para que serve no Oracle | Maturidade | Ferramentas de referência |
|---|---|---|---|
| **Redes Bayesianas / Causais** | Modelar dependências entre fatores (sono → energia → produtividade) e inferir sob incerteza | Alta, madura | BayesiaLab, Bayes Server, GeNIe/SMILE, Bayes Server, DoWhy [7] |
| **Simulação Monte Carlo** | Rodar milhares de "dias possíveis" e obter distribuições de resultado | Alta, madura | Padrão em planejamento financeiro de aposentadoria [16][17] |
| **Cadeias de Markov / semi-Markov** | Transições de estado ao longo do dia (foco → distração → descanso) | Alta | — |
| **Inferência Bayesiana online** | Aprender parâmetros do usuário e atualizar crenças a cada novo dado | Alta | PyMC, Stan, filtros conjugados |
| **Causal AI** | Distinguir correlação de causa ("dormir mal *causa* baixa produtividade?") | Média, em ascensão | DoWhy, EconML, Causica, causaLens DecisionOS [18][19] |
| **Reinforcement Learning** | Sugerir estratégias que maximizam objetivo do usuário ao longo do tempo | Média; cuidado com dados escassos | — |
| **XAI (Explainable AI)** | Traduzir a matemática em explicação legível + incerteza | Média, muito ativa | SHAP, LIME + pesquisa de UX de incerteza [8][11][12] |
| **LLMs** | Interface de linguagem + geração de hipóteses + explicação em prosa | Alta | Claude, etc. |

> **Decisão herdada do design (Pilar 1):** LLMs entram como **camada de
> linguagem e geração de hipóteses**, nunca como fonte das probabilidades. As
> probabilidades vêm das técnicas estatísticas explícitas acima, que são
> auditáveis e calibráveis.

### 2.1 Redes Bayesianas para comportamento pessoal — já é pesquisa real

Não é especulação: há literatura aplicando redes Bayesianas (inclusive
**dinâmicas**, DBNs) a comportamento humano e engajamento. Exemplos recentes:

- **HeartSteps II** — DBN modelando engajamento e caminhada num ensaio
  micro-randomizado de um ano [9]. Prova que dá para modelar hábito/atividade
  probabilisticamente com dados reais de app.
- Modelos Bayesianos ligando estados de saúde, fatores ambientais e
  comportamentos para inferência causal e suporte à decisão personalizado [7].
- Modelagem personalizada de fraqueza física a partir de features
  comportamentais detalhadas [via busca].

Isso valida tecnicamente o coração do módulo Vida Diária.

## 3. Digital Twin Cognitivo — definição, gerações e riscos

O conceito que o documento-fonte pede para pesquisar tem base acadêmica sólida e
crescente.

**Definição (2025):** um digital twin cognitivo é uma *representação
computacional dinâmica dos estados, disposições ou processos cognitivos de uma
pessoa específica, atualizada com dados comportamentais, contextuais,
fisiológicos, interacionais ou inferidos, para modelar, prever ou simular a
cognição dessa pessoa* [2][4].

- A literatura já fala em **gerações** de digital twins cognitivos, de
  instrumentos fundacionais a "ecossistemas meta-cognitivos", com camadas
  estrutural, funcional, comportamental e reflexiva [2].
- Aplicações consumer usam **RAG** para trazer contexto externo e mecanismos que
  internalizam preferências duradouras e tendências cognitivas [2].

> **Alinhamento com nossa filosofia:** a academia converge exatamente para o que
> definimos — um **modelo probabilístico de tendências**, não uma cópia. Nunca
> "o cérebro do usuário"; sempre distribuições de parâmetros comportamentais.

### 3.1 Riscos éticos já mapeados (input direto para o doc 7)

O paper *"Cognitive Digital Twins: Ethical Risks and Governance for AI Systems
That Model the Mind"* [3] lista riscos que devemos tratar como requisitos:

- **Privacidade e autonomia** — modelos detalhados da mente permitem vigilância
  e manipulação sem precedentes.
- **Consentimento e controle** — a pessoa consegue consentir de forma
  significativa e manter controle sobre o uso do modelo?
- **Dano psicológico** — saber que existe um modelo cognitivo detalhado de si
  pode gerar ansiedade e "perda de liberdade cognitiva".
- **Duplo uso** — persuasão, engano e controle comportamental em escala.

Governança recomendada: transparência de quando o modelo está sendo criado,
mecanismos de consentimento, controles de acesso, e revisão ética [3]. → No
Oracle isso vira **local-first + transparência do aprendizado + escopo ético**
(relacionamentos fora do MVP).

## 4. Concorrentes e análogos — e onde falham

Ninguém entrega a combinação completa. Mapa dos quatro campos vizinhos:

### 4.1 AI Life Coaches conversacionais (Rocky.AI, Pi, e os LLMs genéricos)

Rocky.AI oferece desenvolvimento pessoal e role-play; Pi é companheiro
conversacional para "pensar decisões e emoções"; Claude/ChatGPT são usados como
coach reflexivo [5].

**Onde falham:** são **puramente conversacionais**. Não têm modelo persistente e
quantitativo da vida do usuário, não simulam cenários com distribuições, não
produzem grau de confiança calibrado, e não aprendem padrões longitudinais de
forma auditável. Respondem no momento; esquecem a estrutura. → É precisamente o
"eles respondem perguntas, mas não têm modelo profundo da vida do usuário" do
documento-fonte.

### 4.2 Quantified-Self / hábitos / humor (trackers)

Coletam dados, mas **param aí**: mostram gráficos do passado, não simulam futuro
nem avaliam estratégias.

**Onde falham (e a lição mais importante):** **retenção catastrófica.** ~96% dos
apps perdem usuários até o dia 30; saúde/fitness fica em 8–12% de retenção D30
[10]. Motivos documentados de abandono: fricção de coleta, "saturação de dados"
(o usuário sente que não aprende mais nada), descompasso entre expectativa e
capacidade [via busca / QS]. **Contraponto útil:** quem usa o núcleo de
self-monitoring com frequência tem ~80% de chance de permanecer após 40 semanas,
vs. ~60% de não-usuários [10] — ou seja, **o valor precisa aparecer cedo e o
núcleo precisa ser usado com frequência.** Isso é munição direta contra o
problema de cold-start (doc 4).

### 4.3 Ferramentas de forecasting / calibração (Metaculus, apps de calibração)

Este é o campo que **leva incerteza e calibração a sério**. Treinos de calibração
melhoram o Brier score de forma mensurável em <30 min [14]; superforecasters
atingem Brier ~0,166 vs ~0,259 de forecasters comuns [15]. Existem ferramentas
open-source de registro de previsões e cálculo de Brier [via busca].

**Onde falham (para o nosso caso):** são voltadas a **eventos externos** (eleições,
geopolítica, esportes), exigem esforço manual alto e disciplina de nerd, e **não
modelam a vida pessoal do usuário nem fecham o loop automaticamente**. Temos algo
a *aprender* deles (a metodologia de calibração/Brier é exatamente nosso Pilar 2)
e algo a *superar* (aplicar isso à vida pessoal, com fricção baixa).

### 4.4 Simuladores Monte Carlo financeiros

Planejadores de aposentadoria rodam **milhares de cenários randomizados** de
retorno, inflação e gastos para estimar a **probabilidade de sucesso** do plano —
ex.: se 600 de 1.000 simulações terminam com o dinheiro durando, a "chance de
sucesso" é 60% [16][17]. São **probabilísticos, dão faixas de resultado e expõem
a incerteza** exatamente como queremos — e é a modelagem mais madura e aceita do
mercado consumidor (T. Rowe Price, Boldin, MaxiFi e afins) [16].

**Onde falham:** silo único (só finanças), sem digital twin comportamental, sem
XAI de linguagem natural, sem aprendizado de padrões pessoais. **A lição:** a
mecânica Monte Carlo → "probabilidade de sucesso" já é familiar e confiável para
o público — o Oracle a generaliza para além das finanças.

### 4.5 Resumo comparativo

| Capacidade | Life coaches (LLM) | Trackers QS | Forecasting/calibração | MC financeiro | **Oracle (alvo)** |
|---|:--:|:--:|:--:|:--:|:--:|
| Modelo persistente da vida | ❌ | Parcial (só log) | ❌ | Parcial (só $) | ✅ |
| Simulação probabilística de cenários | ❌ | ❌ | Parcial (manual) | ✅ (só $) | ✅ |
| Grau de confiança + **calibração** | ❌ | ❌ | ✅ | Parcial | ✅ |
| Explicação (XAI) legível | Parcial | ❌ | ❌ | ❌ | ✅ |
| Aprendizado de padrões pessoais | ❌ | ❌ | ❌ | ❌ | ✅ |
| Multi-domínio sobre 1 motor | ❌ | ❌ | ❌ | ❌ | ✅ |
| Local-first / privacidade forte | ❌ | Varia | ❌ | ❌ | ✅ |

## 5. XAI e comunicação de incerteza — o que a pesquisa manda fazer

Como mostramos incerteza é decisão de produto **fundamentada em evidência**:

- **Automation bias:** usuários seguem a recomendação da IA mesmo quando ela
  erra, sobretudo quando a interface **não mostra sinal de dúvida** [8][11].
- Interfaces que **tornam a incerteza legível e acionável** reduzem esse viés e
  aumentam a taxa de correção do usuário; confiança não se constrói escondendo
  incerteza, mas exibindo-a [11].
- **Granularidade importa:** o nível de detalhe da incerteza muda como humanos
  verificam decisões assistidas por LLM [8].

> → Confirma o contrato anti-certeza do Oracle (doc 2): sempre mostrar
> distribuição + confiança + fatores + limitações não é só ética, é o que
> **melhora a decisão** e a confiança calibrada.

## 6. Síntese — a lacuna e nossa aposta

Cruzando tudo:

1. **O ferramental existe e é maduro** (redes Bayesianas, Monte Carlo, Markov,
   calibração/Brier, XAI) — mas está **fragmentado** e **preso ao B2B ou a
   silos** (só finanças, só forecasting externo).
2. **Os produtos B2C vizinhos** ou são conversacionais sem modelo (life coaches),
   ou coletam sem simular (trackers), ou simulam sem personalizar (MC financeiro).
3. **Ninguém combina**: motor probabilístico multi-domínio + digital twin
   cognitivo + calibração automática + XAI de incerteza + local-first.

**A aposta do Oracle é a integração disciplinada disso num motor único, provada
primeiro num vertical slice (Vida Diária) com calibração real.** O diferencial
defensável não é um algoritmo inédito — é a **arquitetura + o loop de calibração
+ a explicabilidade** operando sobre a vida pessoal, com privacidade no centro.

## 7. Riscos que a pesquisa já sinaliza (entram nos docs 4, 7, 8)

- **Cold-start / retenção** é a ameaça de produto nº 1 [10]. Mitigar com priors
  populacionais, valor cedo, e núcleo de uso frequente (doc 4).
- **Ética do digital twin cognitivo** é risco real e já teorizado [3]. Mitigar
  com local-first, transparência do aprendizado, escopo ético (doc 7).
- **Automation bias / falsa precisão** — mitigar com XAI de incerteza legível,
  nunca esconder dúvida (doc 2).

---

## Fontes

1. [Top Decision Intelligence Platforms of 2026, According to Gartner — FintechNews CH](https://fintechnews.ch/aifintech/top-decision-intelligence-platforms-of-2026-according-to-gartner/82427/)
2. [Cognitive Digital Twin Generations: From Foundational Instruments to Meta-Cognitive Ecosystems — *Information* (MDPI)](https://doi.org/10.3390/info17030285)
3. [Cognitive Digital Twins: Ethical Risks and Governance for AI Systems That Model the Mind — arXiv](https://arxiv.org/pdf/2606.23094)
4. [Human-Centered Cognition Model for Human Digital Twins — Springer](https://link.springer.com/chapter/10.1007/978-3-032-12660-3_20)
5. [AI Life Coach Apps: Rocky.AI, Pi, and others — Neoprompt](https://neoprompt.ai/en-US/blog/ai-life-coach-apps)
6. [Decision Intelligence Platform: 10 Picks to Compare — Domo](https://www.domo.com/learn/article/decision-intelligence-platforms)
7. [A guide to Bayesian networks software for structure/parameter learning and causal discovery — PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC12415694/)
8. [Not All Uncertainty Is Equal: How Uncertainty Granularity Shapes Human Verification in LLM-Assisted Decision Making — arXiv](https://arxiv.org/pdf/2605.28571)
9. [A dynamic Bayesian network approach to modeling engagement and walking behavior (HeartSteps II) — Taylor & Francis](https://www.tandfonline.com/doi/full/10.1080/21642850.2025.2552479)
10. [Mobile App Retention in 2026: Why 96% of Users Leave by Day-30 — Userpilot](https://userpilot.com/blog/mobile-app-retention/) · [Effect of self-monitoring on long-term engagement with mHealth apps — PMC](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6062090/)
11. [AI Uncertainty & Trust: Design Framework — reloadux](https://reloadux.com/blog/ai-uncertainty-trust-design-framework/)
12. [Developing user-centered system design guidelines for explainable AI: a systematic literature review — Springer](https://link.springer.com/article/10.1007/s10462-025-11363-y)
13. [Knowing oneself with and through AI: From self-tracking to chatbots — arXiv](https://arxiv.org/pdf/2512.03682)
14. [Calibration training for improving probabilistic judgments using an interactive app — Gruetzemacher, 2024, *Futures & Foresight Science*](https://onlinelibrary.wiley.com/doi/abs/10.1002/ffo2.177)
15. [Mean standardized Brier scores for superforecasters — ResearchGate](https://www.researchgate.net/figure/Mean-standardized-Brier-scores-for-superforecasters-Supers-and-the-two-comparison_fig1_277087515)
16. [How a Monte Carlo analysis could help improve your retirement plan — T. Rowe Price](https://www.troweprice.com/personal-investing/resources/insights/how-monte-carlo-analysis-could-improve-your-retirement-plan.html) · [Boldin's Monte Carlo Simulation — Boldin Help Center](https://help.boldin.com/en/articles/5805671-boldin-s-monte-carlo-simulation)
17. [Using Monte Carlo Methods for Retirement Simulations — arXiv](https://arxiv.org/pdf/2306.16563) · [A Monte Carlo 50% Retirement Success Probability Can Work — Kitces](https://www.kitces.com/blog/monte-carlo-retirement-projection-probability-success-adjustment-minimum-odds/)
18. [A Causal AI Suite for Decision-Making (DoWhy, EconML, Causica, ShowWhy) — Microsoft Research](https://www.microsoft.com/en-us/research/wp-content/uploads/2022/11/CausalAISuiteForDecisionMaking.pdf) · [PyWhy — open-source causal ML ecosystem](https://www.pywhy.org/)
19. [Why Causal AI? — causaLens (DecisionOS)](https://causalai.causalens.com/why-causal-ai/) · [Causal AI Market forecast — MarketsandMarkets](https://www.prnewswire.com/news-releases/causal-ai-market-worth-119-500-thousand-by-2030---exclusive-report-by-marketsandmarkets-301827010.html)
