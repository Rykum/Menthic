# 00 — Sumário Executivo & Tese

**Project Oracle — Decision Intelligence Platform pessoal**
Documento de abertura do dossiê técnico · 2026-07-16

> Leitura de 5 minutos que abre o mapa. Para o detalhe, seguir os documentos
> numerados. Audiência: você, o futuro builder.

---

## A tese em um parágrafo

O **Project Oracle** é um motor de decisão pessoal que ajuda a **explorar
cenários e entender as consequências prováveis** das próprias decisões, sob
incerteza. Ele **nunca afirma o futuro**; sempre entrega uma **distribuição + grau
de confiança + fatores + hipóteses + limitações**, e **compara estratégias** em
vez de decidir pelo usuário. É um *Personal Decision Operating System*: um único
motor probabilístico, explicável e calibrado, atravessando os domínios da vida —
começando por um.

## A oportunidade (doc 1)

O mercado de Decision Intelligence vale ~US$ 16–17 bi (2025, +19%/ano), mas é
**quase todo B2B**. O ferramental matemático (redes Bayesianas, Monte Carlo,
Markov, calibração, XAI) é maduro e provado em empresa — mas **ninguém o levou,
de forma integrada, para a vida pessoal**. Os vizinhos falham cada um por um lado:
life coaches de IA são conversacionais **sem modelo**; trackers coletam mas **não
simulam**; forecasting calibra só **eventos externos**; Monte Carlo financeiro é
**silo único**. A lacuna é a integração disciplinada — e é onde está o produto.

## Os quatro pilares (docs 2, 3, 5, 7)

1. **O LLM não é o motor probabilístico.** LLM faz linguagem e hipóteses; as
   probabilidades vêm de modelos estatísticos explícitos, **inspecionáveis e
   calibráveis**. É o que separa o Oracle de "uma IA chutando".
2. **Calibração é feature central.** Toda previsão é registrada contra o desfecho
   real e pontuada (Brier). O produto **mostra o próprio histórico de acerto** —
   honestidade radical que nenhum concorrente conversacional tem.
3. **Local-first / on-device.** Os dados mais íntimos vivem no dispositivo; a
   nuvem é opcional e nunca vê dados brutos. LGPD vira **arquitetura**.
4. **Escopo ético como fronteira, não limitação.** Relacionamentos (modelar
   terceiros) fica **fora**; sem diagnóstico; sem manipulação; sem promessa de
   prever o futuro.

## A aposta técnica (docs 3, 4)

Um **motor genérico** roda o loop `estado → evento → probabilidade → consequência
→ novo estado` por **simulação Monte Carlo**, amostrando os traços do usuário
(o **digital twin** = a posterior `P(θ|dados)`) a cada trajetória. Isso faz a
**confiança cair sozinha** quando há poucos dados (incerteza epistêmica), separa-a
da variabilidade natural do dia (aleatória), e produz **explicações a partir da
própria matemática** (os fatores saem da análise de sensibilidade). O **cold-start**
— a ameaça nº 1 de retenção — é resolvido com **arquétipos populacionais +
shrinkage**: útil no dia 1, cada vez mais "você" com o tempo.

## O módulo-farol e o diferencial (doc 6)

**Vida Diária** — único domínio com dados de alta frequência, matemática
tratável, feedback verificável e risco ético baixo. Coleta **passiva por padrão**
(sono/agenda), registro de **1 toque**, e uma **revisão noturna de 20s** que fecha
o loop de calibração. O diferencial defensável não é um algoritmo inédito — é a
**arquitetura + calibração + explicabilidade + privacidade** operando sobre a vida
pessoal.

## O plano (doc 8)

**De-risk antes de escalar**, com gates falsificáveis:
- **Fase 0 (as férias):** protótipo N=1 em Dart puro. *Gate:* o Brier bate o
  baseline trivial em 4–6 semanas. **Este é o alvo realista das férias.**
- **Fase 1:** MVP com onboarding, coleta passiva, XAI, LGPD. *Gate:* calibração
  < 0,20 + retenção do núcleo.
- **Fase 2:** motor em Rust, adaptação, RAG estreito, priors federados.
- **Fase 3:** 2º módulo (Estudos) **sem tocar o motor** — valida a plataforma.

## O que ler a seguir

| # | Documento | Para quê |
|---|---|---|
| 1 | Estado da arte & posicionamento | mercado, concorrentes, a lacuna |
| 2 | Princípios & filosofia | o contrato `OracleAnswer`, incerteza, ética |
| 3 | **Motor de decisão** | a matemática implementável (coração) |
| 4 | Digital Twin Cognitivo | traços, cold-start, aprendizado |
| 5 | Arquitetura de sistema | local-first, Flutter+Rust, dados |
| 6 | **Módulo Vida Diária** | o spec concreto do MVP |
| 7 | Ética, LGPD & riscos | conformidade e salvaguardas |
| 8 | Roadmap | ordem de build e gates |
| 9 | Apêndice: visão completa | os outros módulos |

## A frase que resume tudo

> Não mais um app de IA que responde perguntas — um motor que ajuda pessoas a
> **pensar melhor sob incerteza**, mostrando os cenários prováveis, o quanto
> confiar neles, e o que fazer a respeito. Com honestidade probabilística no
> centro.
