# Análise crítica — RFC v4: "Sistema Cognitivo" cloud-native

**Data:** 2026-07-19 · **Tese do RFC:** se o objetivo nº 1 é confiabilidade máxima, abandonar o offline e virar plataforma cloud-native com um pipeline de ~15 engines, LLM só no fim.

## Veredito em três frases

1. A **filosofia** do RFC (LLM é interface, o cérebro é o Reality Model
   probabilístico, nada sai sem evidência) **já é a arquitetura construída** —
   não é um pivô, é a regra fundadora do projeto (doc 06 §6: *"o LLM só
   escreveu as frases; não inventou nenhum número"*).
2. O que seria realmente novo — **mover o motor para a nuvem e depender
   totalmente de internet — não compra a confiabilidade que promete**:
   o Monte Carlo produz números idênticos no dispositivo ou num servidor;
   confiabilidade vem do modelo + dados + calibração, não do CEP do CPU.
3. O caminho certo é **local-first com sync (Firebase)**: 90% dos benefícios
   do cloud (multi-dispositivo, backup, integrações, LLM) sem pagar os custos
   que matam o produto (latência no hábito diário, privacidade/LGPD,
   complexidade operacional, custo por usuário).

## 1. O que o RFC propõe que já existe (de novo)

| Caixa do diagrama do RFC | Onde já está na main |
|---|---|
| Memory Engine | Event store (fonte única, `ts/type/payload/origin`) |
| Reality Engine / Reality Model | `TraitPriors` bayesianos + derivação de estado (`DayStateDeriver`) |
| Probability Engine | `predict`/Monte Carlo (`oracle_engine`) |
| Simulation Engine | `simulateDay` + telas Hoje/Simular |
| Strategy Engine | `suggestStrategies` (leva 6) |
| Counterfactual Engine | Simular ("E se…"); replay retrospectivo aceito na análise v3 §3 |
| Evidence Engine | Extractor determinístico + contrato XAI (fatores/limitações) |
| Confidence Engine | `oracle_calibration` completo (Brier, reliability, gate, Platt) + tela |
| Reasoning "encadeado" antes do LLM | O pipeline inteiro roda **sem** LLM hoje |
| "LLM entra quase no final" | Regra fundadora do blueprint; ainda nem entrou |

O diagrama de 15 engines descreve, com nomes de slide, um pipeline que na
prática são funções puras encadeadas em 4 pacotes Dart. **Renomear estágios
como microsserviços separados adiciona fronteiras, contratos e deploys — não
adiciona inteligência.** Se um dia precisar escalar, os mesmos pacotes Dart
rodam num backend (Cloud Run) sem reescrita: a arquitetura headless foi
desenhada exatamente para isso.

## 2. Cloud-native e "depender totalmente da internet": o trade-off real

**O que a nuvem compra de verdade:** sync multi-dispositivo; backup; dados
disponíveis para integrações server-side; chamadas de LLM (que são online por
natureza); compute pesado *se* o modelo crescer (hoje as simulações rodam em
milissegundos no dispositivo).

**O que ela cobra:** (a) o hábito central do produto — revisão noturna de 20s
na cama — passa a falhar sem sinal, e a revisão é *o* preditor de retenção
(doc 01 §4.2); (b) os dados mais íntimos possíveis (sono, humor, agenda,
relações) saem do dispositivo — o capítulo LGPD/ética (doc 07) fica uma ordem
de magnitude mais pesado; (c) custo por usuário e superfície operacional
(gateway, auth, filas, observabilidade) para um produto em fase N=1; (d)
latência num loop que hoje é instantâneo.

**Conclusão:** "confiabilidade máxima" não é argumento para cloud-first — os
números não melhoram por rodar longe. O argumento honesto para nuvem é
sync + LLM + integrações, e isso o modelo **local-first + Firebase** (decisão
já tomada: Firebase como banco) entrega: motor no dispositivo, event store
sincronizado no Firestore, auth Firebase, LLM via function na borda.

## 3. Os engines novos que têm substância (e como fazê-los barato)

- **Validator Engine** — a versão que vale: quando o LLM entrar como redator,
  um validador **determinístico** confere cada número citado no texto contra o
  payload do `OracleAnswer` (regex/estruturado). Se citar número que não veio
  do motor → rejeita e regenera. ~100 linhas, elimina a alucinação numérica.
  ACEITAR junto com a camada LLM.
- **Missing Information Engine** — metade existe: `limitations` já diz o que
  falta ("não sei seu humor de hoje"). Elevar a **pergunta ativa** ("registrar
  humor aperta a faixa em ~X pts") é próximo e barato. ACEITAR adaptado.
- **Contradiction Engine** — cheques de consistência pré-resposta
  (recomendação vs agenda/sono registrados) são regras determinísticas sobre o
  mesmo estado; só fazem sentido quando houver texto livre de LLM para
  policiar. ADIAR para a camada LLM.
- **Human Factors Engine** — **o twin já é isso**: ρ (procrastinação) e o
  (otimismo de planejamento) são exatamente vieses comportamentais, medidos
  por evidência em vez de questionário. Aversão a risco pode entrar um dia
  como peso da utilidade U(y). Nada a construir agora.
- **Ethical Engine** — sem LLM gerando recomendações abertas, não há o que
  filtrar; quando houver, vira política/guardrails do redator. ADIAR.
- Multi-agentes e motor causal: já rejeitados/adiados na análise v3 (#4, #3).

## 4. "Decision-Centric AI" — sim, e o caminho já está mapeado

"A melhor decisão dado objetivos, restrições, riscos e preferências" é o
contrato `OracleAnswer` + a utilidade U(y) do doc 06 §5. O passo concreto
nessa direção não é renomear a plataforma — é o **Motor de Objetivos** (pesos
de utilidade do usuário), já identificado como pré-requisito do conflito de
objetivos (análise v3 #7).

## 5. Recomendação de sequência (sem reescrever nada)

1. **Firebase: auth real + sync do event store** (Firestore) — o
   `PersistentEventStore` vira uma implementação entre outras do mesmo
   `EventStore`; motor continua local; offline-first com sync quando online.
   Pré-requisito do usuário: criar o projeto Firebase e fornecer a config.
2. **Camada LLM como redator** do `OracleAnswer` (function na borda) + o
   Validator numérico determinístico do §3.
3. **Motor de Objetivos** (pesos U(y)) — destrava decisão-cêntrica de verdade
   e o conflito de 2 objetivos.
4. Escala de compute só quando um modelo realmente exigir: os mesmos pacotes
   Dart sobem num Cloud Run — contratos intactos.

**Não fazer:** fragmentar o pipeline em microsserviços nomeados; tornar o app
inutilizável offline; deixar o LLM "decidir e depois validar" (a ordem certa
continua motor decide → LLM escreve → validador confere).
