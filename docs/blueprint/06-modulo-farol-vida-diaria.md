# 06 — Módulo-Farol: Vida Diária (spec completo)

**Project Oracle — Decision Intelligence Platform pessoal**
Documento 6 do dossiê técnico · 2026-07-16 · Profundidade: implementável

> O primeiro módulo, e o que prova o produto inteiro. Instancia concretamente o
> **contrato de módulo** (doc 3 §10.1): schema de estado, modelo generativo,
> desfecho, priors e utilidade. Define os **inputs e a coleta de baixa fricção**
> (a chave da retenção), a **simulação concreta**, as **saídas XAI reais** (com
> mockup), o **loop de calibração** e as **telas**. Escolhido por ter dados
> logáveis de alta frequência, matemática tratável, feedback verificável e risco
> ético baixo (doc 1 §4).

---

## 1. O que o módulo responde

Perguntas concretas do dia a dia, sempre em forma de `OracleAnswer` (doc 2 §2):

- *"Qual a chance de eu cumprir minha agenda de hoje?"*
- *"Como vai estar minha energia às 18h se eu treinar antes?"*
- *"Se eu mover o estudo para de manhã, melhora minhas chances?"*
- *"Vou conseguir terminar tudo sem virar a noite?"*

Não responde: diagnósticos, o que outras pessoas farão, certezas.

## 2. Modelo de dados do dia (instancia `state_schema`)

```
DayState {
  data, dow, feriado?, clima?
  sono:      { horas: float, qualidade?: 1..5, debito_acum: float }
  energia0:  Beta(a,b)            # energia estimada ao acordar
  agenda:    [ Compromisso ]      # ver abaixo
  contexto:  { local_inicial, deslocamentos: [ {de,para,dur} ] }
  humor?:    Ordinal{ruim..otimo} # opcional, 1 toque
}

Compromisso {
  id, inicio, dur_prevista, tipo: {trabalho,estudo,treino,lazer,refeicao,sono,social},
  prioridade: 1..3, flexivel?: bool, aversivo?: bool
}
```

Tudo com incerteza onde faz sentido (energia0 é distribuição, não número).

## 3. Inputs e coleta — baixa fricção é requisito de sobrevivência

A pesquisa de retenção (doc 1 §4.2) é clara: **fricção de coleta mata o app**.
Estratégia em três níveis, do mais passivo ao mais ativo:

| Nível | Dado | Como | Fricção |
|---|---|---|---|
| **Passivo** | sono, passos, freq. cardíaca | HealthKit / Google Fit / wearable | zero |
| **Passivo** | agenda | Calendar (com permissão) | zero |
| **Passivo** | clima, dia da semana | API/sistema | zero |
| **1 toque** | humor, energia atual | widget/emoji rápido | mínima |
| **1 toque** | "concluí" / "atrasei" | check na tarefa | mínima |
| **Ativo** | prioridade, aversividade | ao criar tarefa | pontual |

Princípios de coleta:
- **Padrão é passivo.** O usuário pode usar o app sem digitar quase nada.
- **Registro é 1 toque**, contextualizado (a revisão noturna, §8, pergunta só o
  essencial daquele dia).
- **Cada pedido de dado é justificado** com value-of-information (doc 3 §7.3):
  *"registrar seu humor hoje aperta a estimativa em ~8 pontos"*.

## 4. A simulação concreta (instancia o modelo generativo, doc 3 §5)

### 4.1 Estados de atividade e progresso

```
A = { foco, trabalho_raso, distração, descanso, deslocamento, refeição, treino }
```

Progresso na agenda = soma do trabalho efetivo feito nas janelas dos
compromissos, descontando atrasos e trocas de contexto.

### 4.2 Energia, fadiga e a hora do dia (doc 3 §5.2, com traços do doc 4)

```
energia(t) = σ( baseline_p0(θ)
                − s(θ)·debito_sono
                − fadiga(t)
                + circadiano(t; φ(θ)) )          # φ = cronotipo do usuário

fadiga(t+Δ) = clamp( fadiga(t) + α(atividade)·Δ − r(θ)·recuperação·Δ , 0, 1 )
```

`circadiano` é a senoide com pico em `φ(θ)` (matutino vs vespertino, aprendido
pelo twin). É isto que faz "estudar às 7h" render diferente de "estudar às 22h"
**para aquele usuário específico**.

### 4.3 Conclusão de tarefa e atraso

Para cada compromisso, a duração real é amostrada com o **otimismo de agenda**
`o(θ)` (planning fallacy — pessoas subestimam durações):

```
dur_real ~ LogNormal( log(dur_prevista) + o(θ), σ_dur )
atraso   = max(0, acumulado − inicio_previsto)
concluiu = (trabalho_efetivo ≥ trabalho_necessário) dentro da janela
```

Procrastinação: tarefas `aversivo=true` têm probabilidade `ρ(θ)` de serem adiadas
no início de sua janela, empurrando tudo para frente.

### 4.4 Desfechos (a função `g`, doc 3 §2)

De cada trajetória Monte Carlo extraímos:
- `cumpriu_agenda` ∈ {0,1} — desfecho principal (Bernoulli → calibrável).
- `n_atrasos`, `atraso_total_min`.
- `fadiga_final`, `energia_18h`.
- `bem_estar` = função de (folga, sono, lazer, fadiga) — proxy, declarado como
  proxy.
- `virou_a_noite` ∈ {0,1}.

Rodando `N≈2000` trajetórias (doc 3 §4) → distribuições de cada desfecho.

## 5. Estratégias comparáveis (a `utility` do módulo, doc 3 §7)

Intervenções que o usuário pode explorar (o motor compara, não impõe):

- **Mover** um bloco (ex.: estudo 22h → 8h).
- **Dormir +1h** (aumenta energia0, reduz débito).
- **Cortar** um compromisso de baixa prioridade.
- **Encaixar** um descanso/pausa.
- **Reordenar** para agrupar tarefas do mesmo tipo (reduz custo de troca `κ`).

Utilidade configurável pelo **objetivo do usuário**:
```
U(y) = w1·cumpriu_agenda + w2·bem_estar − w3·atraso_total − w4·virou_a_noite
```
Os pesos `w` vêm do que o usuário declara priorizar (terminar tudo vs preservar
energia). O motor mostra o **trade-off**, com faixa de cada estratégia — nunca só
a "vencedora" (doc 2 §1).

## 6. Saída XAI real (mockup do `OracleAnswer` renderizado)

```
┌───────────────────────────────────────────────────────────┐
│  Cumprir a agenda de hoje                                  │
│                                                            │
│   ~63%   ▓▓▓▓▓▓▓▓▓▓░░░░░   faixa provável 52–71%           │
│   confiança: média · baseado em 3 semanas suas             │
│                                                            │
│  O que mais pesou                                          │
│   ↓ pouco sono ontem (5h)              forte               │
│   ↓ tarde com 5 compromissos           média               │
│   ↑ terças costumam ser boas p/ você   média               │
│   ↑ sem deslocamento longo             fraca               │
│                                                            │
│  Assumi que                                                │
│   • você mantém o horário de almoço                        │
│   • nenhuma reunião nova entra                             │
│                                                            │
│  Limitações                                                │
│   • poucos dados em dias com +5 compromissos               │
│   • não sei seu humor de hoje  → registrar aperta ~8 pts   │
│                                                            │
│  Se seu objetivo é terminar tudo                           │
│   ▸ mover “estudo” p/ 8h    →  ~74%  (65–80%)  ↑ melhor    │
│   ▸ dormir +1h hoje à noite →  afeta amanhã, não hoje      │
│   ▸ cortar a reunião opcional → ~70% (60–78%)              │
│                                                            │
│  Por que eu acho isto?  ▸ (abre o rastro do aprendizado)   │
└───────────────────────────────────────────────────────────┘
```

Note como cada elemento mapeia 1:1 no schema (doc 2 §2) e cada número sai da
matemática (doc 3 §8): a faixa dos quantis Monte Carlo, os fatores da análise de
sensibilidade, a confiança da largura epistêmica, as estratégias do ranking de
utilidade. **O LLM só escreveu as frases; não inventou nenhum número.**

## 7. Onboarding e cold-start do módulo (doc 4 §4)

Fluxo do dia 0 (poucas perguntas → prior por arquétipo):
1. "Você rende melhor de manhã, à tarde ou à noite?" → `φ` inicial.
2. "Costuma adiar tarefas chatas?" (nunca…sempre) → `ρ` inicial.
3. "Quando planeja, tende a subestimar quanto as coisas demoram?" → `o` inicial.
4. Conectar sono/agenda (opcional, mas incentivado) → dados passivos.

Resultado: previsões **plausíveis já no dia 1**, rotuladas como *"ainda baseado
mais em padrões gerais que nos seus"* (shrinkage, doc 4 §4.2). Conforme os dias
passam, vira sobre o usuário.

## 8. Loop de calibração concreto (doc 3 §9)

- **Manhã:** o app emite e loga a previsão do dia (`previsao_emitida`).
- **Noite (revisão de 20s):** pergunta o essencial — "cumpriu?", "atrasos?",
  humor. Gera os eventos de desfecho.
- **Pontuação:** `cumpriu_agenda` prevista vs real → entra no Brier do módulo.
- **Exibição honesta:** tela de calibração — *"quando digo 70%, tenho acertado
  ~68% (últimos 60 dias)"* + diagrama de confiabilidade.
- **Recalibração** automática (Platt/isotônica) quando o diagrama entorta.

Este loop é o que transforma o módulo de "chute bonito" em **instrumento
calibrado** — e é o diferencial que nenhum concorrente conversacional tem.

## 9. Telas principais

| Tela | Função |
|---|---|
| **Hoje** | o `OracleAnswer` do dia (§6) + estratégias |
| **Simular** | mexer na agenda e ver a estimativa mudar ao vivo |
| **Revisão noturna** | coleta de desfecho em ~20s (§8) |
| **Meu Twin** | traços aprendidos, incerteza, origem, correção (doc 4 §7) |
| **Calibração** | histórico de acerto do sistema (§8) — honestidade radical |

## 10. Métricas de sucesso do módulo (para o roadmap, doc 8)

- **Calibração:** Brier do módulo abaixo de um alvo (ex.: < 0,20) após 60 dias.
- **Retenção do núcleo:** frequência de uso da revisão noturna (o preditor de
  retenção, doc 1 §4.2).
- **Valor percebido:** o usuário age sobre uma estratégia sugerida e o desfecho
  melhora (medível via calibração pré/pós).
- **Redução de incerteza:** faixa média das previsões encolhe com o tempo (twin
  aprendendo).

## 11. Contrato de módulo preenchido (fecha o doc 3 §10.1)

```
VidaDiaria implements Module {
  state_schema     = DayState                       // §2
  generative_model = simular_dia (energia/fadiga/   // §4
                     semi-Markov/planning-fallacy)
  outcome          = g → {cumpriu_agenda, atrasos,  // §4.4
                     fadiga_final, bem_estar}
  priors           = arquétipos de cronotipo/       // §7, doc 4 §4
                     procrastinação/otimismo
  utility          = U(y | pesos do objetivo)       // §5
}
```

Nenhuma linha do motor muda. Adicionar Estudos/Finanças depois = repetir este
preenchimento com outro `state_schema`/`outcome`.

---

## 12. Como este documento amarra o resto

- É a **instância concreta** do motor (doc 3) e do twin (doc 4).
- Roda sobre as **camadas** do doc 5 (coleta passiva, event store, motor
  isolado, LLM só na prosa).
- Suas **saídas** obedecem ao contrato do doc 2 e às regras de incerteza.
- Suas **métricas** (§10) e **fases de coleta** (§3) alimentam o **roadmap
  (doc 8)**; suas telas de dados alimentam **privacidade (doc 7)**.
