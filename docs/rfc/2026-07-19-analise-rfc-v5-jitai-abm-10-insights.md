# Análise crítica — RFC v5: JITAI, ABM e os 10 insights

**Data:** 2026-07-19 · **Referências cruzadas:** análise v3 (17 conceitos) e v4 (cloud-native) — vários itens deste RFC já foram julgados lá; este doc não repete, aponta.

## O princípio que julga tudo

O Menthic tem um ativo que quase nenhum produto tem: **um loop fechado e
mensurável** (previsão → desfecho → Brier). Então o critério para qualquer
módulo novo é objetivo: **ele melhora a calibração ou a adesão, de forma
mensurável?** Se não move o Brier nem a retenção, é decoração conceitual.
Esse critério aceita 2 ideias novas deste RFC, adapta 2 e rejeita o resto.

## As 2 ideias genuinamente boas (e baratas) deste RFC

### #5 Reality Gap Engine — ACEITAR (a melhor ideia do documento)
"O que você acredita vs o que os dados mostram" — e nós **já coletamos a
crença**: as respostas do onboarding são autodeclarações (ρ "costuma adiar?",
o "subestima duração?"). O posterior aprendido é o que os dados mostram. O
gap é computável hoje, sem coleta nova:
> *"Você se declarou procrastinador nível 4 (~60%); nos seus dados, tarefas
> chatas atrasaram em 30% das vezes. Você é melhor do que pensa."*
Versão mínima: seção "auto-imagem vs dados" no **Meu Twin**, só para ρ e o
(os dois traços com prior autodeclarado e aprendizado ativo), com gating
honesto de N mínimo. Sem julgamento, com contagens. Custo baixo, valor alto,
zero ética nova (é o próprio usuário sobre ele mesmo).

### #9 Life Strategy Backtesting — ACEITAR adaptado (fase 1)
"Backtest da própria vida" = consulta de frequência condicional sobre o
histórico: *"nos dias com sono < 6h, você cumpriu a agenda em X% (N=12); com
sono ≥ 7h, Y% (N=23)"*. Não é ML — é contagem sobre eventos que já logamos, e
complementa a sensibilidade **simulada** com a versão **observada** (quando
as duas concordam, a confiança sobe; quando divergem, é sinal de drift ou de
modelo ruim — informação valiosíssima). Precisa de semanas de dados para ter
N; construir com o mesmo gating da Calibração. Candidata natural à
Retrospectiva (v3 #10).

## Os adaptáveis

- **#2 Vulnerability Detection** — a versão honesta é derivável hoje: débito
  de sono alto + agenda pesada + humor baixo recente já estão nos eventos. Um
  "modo leve" (banner na Hoje + Revisão encurtada) é barato. Mas atenção: o
  engine já modela energia/fadiga — o valor aqui é de **tom/UX**, não de
  modelo. Aceitável como peça pequena, prioridade baixa.
- **#3 Behavioral Reinforcement** — é o v3 #17, e a leva 6 já instalou a
  matéria-prima (`estrategia_aceita`). Próximo passo real: taxa de adesão por
  tipo de estratégia (Beta-Bernoulli, mesma maquinaria conjugada) **quando
  houver volume de dados**. Não é "RL" — e não precisa ser.

## Os rejeitados (com o porquê)

- **#1 Opportunity Window** — v3 #8: sem coleta de texto/pessoas/mercado, não
  há sinal de onde inferir "janelas". JITAI não muda a disponibilidade de
  dados; muda o timing de intervir sobre dados que existem.
- **#4 Life Policy Learning (RL)** — RL formal com N=1 e dezenas de episódios
  é fantasia estatística (sample complexity). O que é tratável já está no
  produto: estratégias contextuais geradas pelo simulador + adesão (#3). O
  *framing* "aprenda políticas, não ações" é bom — e é o que `agePriors` +
  posteriors por contexto podem evoluir a ser, com estatística honesta.
- **#6 Narrative Engine** — depende da camada LLM (v4 §5 passo 2); a mineração
  por baixo É o backtesting (#9). Sequência: backtesting primeiro (números),
  narrativa depois (LLM lê os números — nunca o contrário).
- **#7 Twin de Relacionamentos / #8 Social Graph** — modelar **terceiros** sem
  consentimento é a linha ética mais grossa do doc 07 (LGPD: dado pessoal de
  quem nunca aceitou termo nenhum). Rejeitado enquanto o produto não tiver
  resposta ética séria — e não tem dados de qualquer forma.
- **JITAI em geral** — veredito do v3 #16 mantido: pós-Android, começando com
  a intervenção "burra" (push matinal com a previsão do dia), medindo adesão
  antes de qualquer gatilho "esperto". O paper do JMIR citado (Digital Twins
  for JITAIs) reforça justamente o que já temos: o twin serve para **otimizar
  o timing** — mas só com o app no bolso.

## #10 Reality Simulator / ABM / BDI — a armadilha do documento

A recomendação nº 1 do RFC ("pesquisar Agent-Based Life Simulation") é a que
eu **não** seguiria, e o critério do topo explica: ABM/BDI (LifeSim, ACT-R,
SOAR) geram trajetórias **plausíveis**, não previsões **calibradas** — não há
como validar um ABM da vida inteira contra desfechos reais com N=1, e um
sistema que não pode ser reprovado pelo próprio Brier viola o princípio
fundador do Menthic (honestidade mensurável). A rota certa para "simular o
ambiente completo" é a que o projeto já pratica: **crescer o simulador
estrutural por camadas validáveis** — cada camada nova (ex.: finanças, carga
social) entra como variável do `DayState`/traço do twin, e o loop de
calibração diz se ela melhora a previsão ou não. ABM vira interessante se um
dia houver múltiplos agentes reais interagindo (multiusuário) — não antes.

## Priorização respondida

A lista de 10 pesquisas do RFC, filtrada pelo critério do Brier, vira:
1. **Reality Gap no Meu Twin** (#5) — implementável já, dado real.
2. **Backtesting condicional** (#9) + Retrospectiva (v3 #10) — fase 1.
3. **Adesão por estratégia** (#3/v3 #17) — quando houver volume.
4. **JITAI push matinal** — pós-Android no bolso.
5. Camada LLM (redator + validador numérico, v4) — destrava Narrative (#6).
O resto: manter rejeitado até os pré-requisitos (dados, ética, multiusuário)
existirem. O diagnóstico final do RFC está certo e é a tese do projeto desde
o dia 1: o fosso não é a IA, é **o modelo da realidade + o loop que o
corrige**. A IA é trocável; o histórico calibrado de um usuário, não.
