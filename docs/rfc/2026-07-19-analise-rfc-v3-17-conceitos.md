# Análise crítica — RFC v3: 17 conceitos da pesquisa

**Data:** 2026-07-19 · **Método:** cada conceito foi verificado contra o código real da main (pacotes `engine`/`store`/`calibration`/`learning` + app Flutter), com veredito de custo×benefício. Rigor antes de entusiasmo: 6 aceitos (4 deles em versão mínima), 5 adiados com pré-requisito explícito, 4 rejeitados por ora, 2 já resolvidos.

## Sumário dos vereditos

| # | Conceito | Já existe? | Veredito |
|---|---|---|---|
| 1 | Bidirectional Learning Loop | **Sim, estruturalmente** | Fechar o último elo: ligar Platt pós-gate |
| 2 | Confidence Calibration | **Sim — o RFC está desatualizado** | Já feito; falta só a recalibração automática (=#1) |
| 3 | Counterfactual Engine | Parcial (Simular é prospectivo) | ACEITAR versão barata: simular dia passado |
| 4 | Multi-Agent Deliberation | Não | **REJEITAR** por ora |
| 5 | Strategy Evaluation Engine | Não (mas o mockup §6 promete) | **ACEITAR** — maior lacuna real do produto |
| 6 | Digital Twin Evolution (fases) | Parcial (agePriors) | REJEITAR por ora; #12 cobre o essencial |
| 7 | Goal Conflict Resolution | Não | ADIAR — pré-requisito: Motor de Objetivos |
| 8 | Opportunity Discovery | Não | **REJEITAR** por ora — sem dados que sustentem |
| 9 | Future Identity Modeling | Não | **REJEITAR** — violaria "LLM não inventa números" |
| 10 | Decision Replay | Derivável dos eventos | ACEITAR adaptado (Retrospectiva) — fase 1 |
| 11 | Evidence Graph | O event store já é a origem | ACEITAR mínimo: contagens de evidência no Meu Twin |
| 12 | Reality Drift Detection | Não | ACEITAR — pesquisa aplicada da fase 1 |
| 13 | Simulation Quality Metrics | **Sim (Brier/BSS/Murphy)** | Falta 1 métrica: cobertura da faixa |
| 14 | Adaptive Memory Pruning | Parcial (agePriors é esquecimento) | ADIAR; nunca apagar eventos |
| 15 | Decision Infrastructure | **Sim** — é a arquitetura atual | Nada a fazer |
| 16 | JITAI | Não | ADIAR para pós-Android; começar com 1 intervenção |
| 17 | Meta-Learning do Usuário | Não | ADIAR — pré-requisito: #5 + log de aceitação |

---

## 1. Bidirectional Learning Loop — já existe; falta um elo

O ciclo do RFC (modelo → simulação → realidade → diferença → recalibração) **é
literalmente o pipeline da main**: eventos → `DayStateDeriver` →
`answerAgenda` (Monte Carlo) → `previsao_emitida` → Revisão noturna →
`TwinLearner` (Bayes conjugado) → priors novos. O que o RFC chama de
"aprender com os próprios erros" tem um elo ainda solto: o pacote
`oracle_calibration` já tem **Platt scaling e gate** (`evaluateGate`,
minN=120), mas a recalibração **não é aplicada** às probabilidades emitidas.
**Ação concreta:** quando o gate aprovar (histórico suficiente), passar a
emitir `platt(p)` em vez de `p`, com transparência na tela de Calibração
("recalibrado desde <data>"). Custo baixo; valor alto; zero arquitetura nova.

## 2. Model Confidence Calibration — o RFC está factualmente errado aqui

"Esse mecanismo praticamente não aparece no projeto atual" — **aparece, e além
do que o RFC pede**: `brierScore`, `brierSkillScore`, `calibrationInTheLarge`,
`reliabilityDiagram`, decomposição de Murphy, gate e Platt estão implementados
e testados em `oracle_calibration`, e a **tela de Calibração** (leva 3) já
mostra Brier e pares previsão×realidade ao usuário. O exemplo do RFC ("previu
90%, acertou 50%") é exatamente o que `calibrationInTheLarge` e o diagrama de
confiabilidade medem. Pendência real = só o wiring do item 1.

## 3. Counterfactual Engine — versão barata é viável; a completa é pesquisa

Simular já responde "e se…" **prospectivo** (intervenção sobre o dia de hoje).
O retrospectivo ("o que teria acontecido se…") é mais tratável aqui do que na
literatura geral porque nosso simulador é um **modelo estrutural**
(`simulateDay` com traços amostrados): reconstruir um dia passado é
`DayStateDeriver.derive(store, dataPassada)` + editar a agenda hipotética —
infra que já existe. **Versão adaptada:** a tela Simular ganha um seletor de
data passada ("replay contrafactual"), com o caveat honesto de que é o modelo
de hoje olhando para trás (não há abdução de ruído à la Pearl camada 3 — os
choques aleatórios daquele dia não são recuperáveis). Custo baixo. Prioridade
média. Contrafactual causal rigoroso (inferência causal, backdoor etc.) fica
como pesquisa — hoje não temos nem variáveis suficientes para confusores.

## 4. Multi-Agent Deliberation — rejeitar por ora

A literatura de multiagentes resolve **orquestração de LLMs**; o Menthic não
tem LLM no produto e o motor é um modelo probabilístico único e coerente.
"Agente financeiro/social/saúde" pressupõe camadas que não coletamos.
Deliberação multiagente adicionaria variância, custo e opacidade — o oposto do
contrato XAI. Se um dia houver camadas de vida, a fronteira certa são
**módulos de modelo** (submodelos acoplados no estado), não agentes
conversando. Reavaliar apenas se/quando entrar a camada LLM de redação.

## 5. Strategy Evaluation Engine — a maior lacuna real; aceitar

O mockup do doc 06 §6 promete a seção *"Se seu objetivo é terminar tudo →
mover estudo p/ 8h → ~74%"* — e **isso não está implementado** em lugar
nenhum. É a peça de maior valor que falta: transforma diagnóstico em decisão.
**Versão adaptada (fase 0.6, no engine):** um gerador de estratégias locais —
perturbações candidatas do `DayState` (mover compromisso para o pico
circadiano, cortar o de menor prioridade, +1h de sono → afeta amanhã, quebrar
bloco longo) — cada uma avaliada pelo **mesmo** `answerAgenda` e ranqueada
pelo delta na estimativa (e depois pela utilidade U(y) do doc 06 §5 quando
houver pesos do usuário). Sai `List<Strategy>` com `label`, `delta`, faixa —
renderizada no card da Hoje. Sem matemática nova: é busca local sobre o
simulador existente. Custos/riscos/reversibilidade formais (MCDA) ficam para
depois — começar com o que o motor já sabe estimar. **Primeiro candidato a
próxima leva de engine.**

## 6. Digital Twin Evolution (fases de vida) — rejeitar por ora

Com N=1 e dias de histórico, modelar "fases da vida" é especulação sem dado.
O que envelhece já envelhece (`agePriors`); o que muda de regime é o item 12
(drift). Marcos explícitos ("mudei de emprego") poderiam um dia ser um evento
manual que **acelera o decay** — nota para o futuro, não módulo.

## 7. Goal Conflict Resolution — adiar com pré-requisito

Não existe Motor de Objetivos (a UI não coleta objetivos). Multi-objective
optimization é literatura madura (Pareto, scalarização), mas otimizar
objetivos que não são coletados é ordem errada. **Caminho:** o blueprint já
prevê o conflito mínimo — cumprir agenda × preservar energia — via pesos `w`
da utilidade (doc 06 §5). Quando os pesos entrarem na UI (junto com #5), o
"conflito de 2 objetivos" aparece de graça como trade-off exibido. Modelagem
geral de N objetivos: só depois de existirem objetivos persistidos.

## 8. Opportunity Discovery — rejeitar por ora

Pressupõe texto livre (conversas, notas), grafo de pessoas e NLP — nada disso
é coletado. Sem dados, vira heurística inventada, e proatividade não
solicitada carrega os riscos do item 16 ao quadrado (sugerir "abrir empresa" é
consequente). Reavaliar somente depois de: Life Graph derivado + camada LLM +
política ética de proatividade.

## 9. Future Identity Modeling — rejeitar

"Você empreendedor / você pesquisador" não é derivável de sono+agenda; seria
narrativa gerada, e a regra de ouro do projeto é *"o LLM só escreve as frases;
não inventa nenhum número"* (doc 06 §6). Futuros múltiplos **quantitativos**
já existem em forma embrionária: a faixa low–high É um leque de futuros.
Reflexão qualitativa de identidade é um produto diferente (coaching), com
riscos psicológicos próprios. Fora do Menthic fase 0–1.

## 10. Decision Replay — aceitar adaptado (fase 1)

Barato e coerente: tudo que uma retrospectiva precisa já está no event store
(previsões, desfechos, humor) — falta só registrar **snapshots dos priors** a
cada revisão (novo evento `priors_atualizados` com o JSON do codec, ~5 linhas)
para poder mostrar "o que o twin aprendeu esta semana". Uma tela/segmento
"Retrospectiva" (semanal): previ × aconteceu, Brier da semana, deltas dos
traços. Journaling de decisões livres (hipóteses consideradas etc.) exige
coleta de texto — fase posterior.

## 11. Evidence Graph — a versão certa já existe; expor, não duplicar

Criar um grafo de evidências separado **duplicaria o event store**, que já é a
origem única e auditável de toda conclusão (os traços saem do
`ObservableExtractor`, que é determinístico — a "prova" é recomputável).
**Versão mínima aceita:** o Meu Twin mostrar, por traço, a contagem de
evidência que o extractor já computa (ρ: "N tarefas aversivas observadas"; o:
"N durações comparadas") + data da última evidência. É o exemplo do RFC
("observado em 43 sessões") com dados verdadeiros. Custo: expor números que já
existem.

## 12. Reality Drift Detection — aceitar como pesquisa aplicada da fase 1

Relevante e tratável com o que logamos: (a) **Brier em janela móvel** subindo
= modelo desatualizado; (b) CUSUM sobre resíduos (previsto−realizado); (c)
comparar posteriors estimados em janelas disjuntas. A **reação** já tem
mecanismo pronto: acelerar o `agePriors` (meia-vida menor) quando drift é
detectado, reinflando a incerteza honestamente. Começo barato: um aviso na
tela de Calibração quando o Brier recente ≫ Brier histórico. Literatura:
concept drift (Gama et al.), Page-Hinkley/ADWIN — adaptáveis a série pequena.

## 13. Simulation Quality Metrics — já respondido; falta uma métrica

A previsão É a saída da simulação, então Brier/BSS/reliability/Murphy **são**
as métricas de qualidade — implementadas. Lacuna real e barata: **cobertura da
faixa** (em quantos dias o desfecho "caiu dentro" do intervalo low–high vs a
cobertura nominal). Adicionar à tela de Calibração quando houver N razoável.
Robustez (sensibilidade a perturbação) já existe como feature (análise de
sensibilidade); utilidade prática se mede com #17, adiado.

## 14. Adaptive Memory Pruning — adiar; nunca apagar eventos

O esquecimento **do modelo** já existe (`agePriors`). Apagar eventos
conflitaria com o event sourcing (auditabilidade, recalibração retroativa,
LGPD à parte — exclusão a pedido do usuário é outro assunto e essa o store já
suporta via `deleteWhere`). Se o volume um dia pesar, a resposta é **janela ou
peso exponencial no extractor** (ler menos, não guardar menos). Com N=1, não
há pressão.

## 15. Decision Infrastructure — é o que já foi construído

Observação (eventos) + modelagem (twin bayesiano) + simulação (Monte Carlo) +
feedback (revisão→learning→calibração) num ciclo contínuo: a definição do
artigo descreve a arquitetura da main. Confirmação de rota, não trabalho novo.

## 16. JITAI — adiar para pós-Android; começar com UMA intervenção

O conceito certo no momento errado. Pré-requisitos ausentes: app no bolso
(Android instalável — leva 5 em andamento), notificações, e um modelo de
**interruptibilidade** (JITAI, Nahum-Shani et al.: intervenção na hora errada
corrói confiança e adesão — o custo do falso positivo é alto). Quando os
pré-requisitos existirem, começar com a intervenção que o blueprint §8 já
define e que não é "esperta": **push da manhã com a previsão do dia** (gatilho
por relógio, não por inferência). Só depois de medir adesão, evoluir para
gatilhos contextuais.

## 17. Meta-Learning do Usuário — adiar com ordem de dependência clara

Para aprender "quais recomendações o usuário segue", é preciso primeiro
**haver recomendações** (#5) e logar aceitação (`estrategia_aceita` /
`estrategia_ignorada` — eventos triviais). Com esse log, o meta-aprendizado
mínimo é um Beta-Bernoulli por tipo de estratégia (taxa de adesão) — mesma
maquinaria conjugada do learning atual. Ordem: #5 → log de aceitação → adesão
por tipo → só então personalização de comunicação.

---

## Priorização recomendada (custo×valor, com o que existe)

**Próxima leva de engine (fase 0.6):** #5 Estratégias na Hoje (a promessa não
cumprida do mockup) — inclui os eventos de aceitação que destravam #17.

**Peças pequenas junto:** #11-mínimo (contagens de evidência no Meu Twin),
#13-cobertura da faixa e #1-Platt pós-gate (na Calibração), #3-barato
(Simular com data passada), #10-snapshot `priors_atualizados` na Revisão
(5 linhas que destravam a Retrospectiva).

**Fase 1:** #10 Retrospectiva, #12 drift com aviso na Calibração, #16 push
matinal pós-Android.

**Rejeitados por ora (reavaliar com novos pré-requisitos):** #4, #6, #8, #9.
**Já resolvidos:** #2, #15 (e #14 no que importa).
