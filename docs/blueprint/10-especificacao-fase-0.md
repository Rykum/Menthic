# 10 — Especificação da Fase 0 (pronta para construir)

**Project Oracle — Decision Intelligence Platform pessoal**
Documento 10 do dossiê técnico · 2026-07-16 · Profundidade: construível

> Este documento fecha a ponte entre *blueprint* e *código*. Ele fornece o que os
> documentos 3/4/6 deixaram no nível de fórmula, agora com **números concretos**:
> (A) a **folha de parâmetros** da Fase 0, (B) o **protocolo do gate falsificável**
> (o experimento N=1 exato), e (C) um **exemplo numérico resolvido** ponta a ponta
> — que serve como o **primeiro teste de aceitação** do motor. Se algum número
> abaixo estiver errado, corrige-se aqui, não no meio do Flutter.

---

## Parte A — Folha de Parâmetros da Fase 0

Escopo mínimo da Fase 0 (doc 8): um desfecho, motor em Dart puro, poucos traços.

### A.1 Constantes fixas do modelo (não aprendidas na Fase 0)

| Constante | Símbolo | Valor | Papel |
|---|---|---|---|
| Intercepto de energia | `c0` | −1.0 | nível base do logit de energia |
| Peso da produtividade | `c_p` | 2.5 | quanto `p0` levanta a energia |
| Peso da fadiga | `c_f` | 2.0 | quanto a fadiga derruba a energia |
| Amplitude circadiana | `A` | 0.6 | tamanho da onda dia/noite |
| Fadiga inicial base | `F₀base` | 0.10 | fadiga ao acordar sem débito |
| Fadiga por hora de débito | `k_D` | 0.08 | débito de sono → fadiga inicial |
| Escala de trabalho (progresso/hora) | `kWork` | 3.0 | converte `p0·energia` (<1) em progresso efetivo; **calibrada na implementação** (ver A.6) |
| Nº de trajetórias Monte Carlo | `N` | 2000 | erro de MC ≈ 1pp |
| Força do prior (shrinkage) | `n₀` | 10 | "dias" que o prior vale (doc 4 §4.2) |
| Esquecimento (Fase 0) | `λ` | 1.0 | **sem esquecimento** — janela curta (4–6 sem) |

> Nota sobre `λ=1`: a Fase 0 dura semanas; non-stationarity (doc 4 §5) só importa
> na Fase 2+. Fixar `λ=1` simplifica e não perde nada aqui.

### A.2 Traços aprendidos e seus priors (o `θ` da Fase 0)

| Traço | Símbolo | Distribuição | Prior (arquétipo neutro) | Média |
|---|---|---|---|---|
| Pico circadiano (hora) | `φ` | Normal(μ_φ, σ_φ²) | μ_φ = 14.0, σ_φ = 2.5 | 14h |
| Baseline de produtividade | `p0` | Beta(a,b) | Beta(6, 4) | 0.60 |
| Propensão a procrastinar | `ρ` | Beta(a,b) | Beta(2, 5) | 0.29 |
| Sensibilidade ao sono | `s` | Gamma(k,θ) | Gamma(3, 0.05) | 0.15 /h |
| Otimismo de agenda | `o` | Normal(μ,σ²) | Normal(0.20, 0.10²) | +0.20 |
| Taxa de recuperação | `r` | Gamma(k,θ) | Gamma(5, 0.05) | 0.25 /h |

### A.3 Arquétipos de onboarding (cold-start, doc 4 §4.1)

Três perguntas no dia 0 selecionam o prior de `φ`, `ρ` e `o`:

| Pergunta | Resposta → parâmetro |
|---|---|
| "Rende melhor de manhã / tarde / noite?" | manhã → μ_φ=10 · tarde → 14 · noite → 18.5 |
| "Costuma adiar tarefas chatas?" (nunca…sempre, 1–5) | ρ prior Beta com média = 0.15·(resposta) |
| "Ao planejar, subestima quanto as coisas demoram?" (1–5) | o prior μ = 0.05·(resposta) |

Os demais traços partem do prior neutro (A.2). `σ` dos priors mantido para o dia 1
ter incerteza honesta (confiança "média-baixa", doc 2).

### A.4 Modelo de energia (instancia doc 6 §4.2)

```
η(t) = c0 + c_p·p0 − s·D_sono − c_f·F(t) + A·cos(2π·(t − φ)/24)
energia(t) = logistic(η(t))          # ∈ (0,1)
```
`D_sono` = débito de sono em horas (meta − dormido, ≥0). `F(t)` = fadiga corrente.

### A.5 Modelo de fadiga (instancia doc 6 §4.2)

```
F(0)     = clamp(F₀base + k_D·D_sono, 0, 1)
F(t+Δ)   = clamp(F(t) + α(atividade)·Δ − r·1{descanso∪refeição}·Δ, 0, 1)
```
| Atividade | `α` (por hora) |
|---|---|
| foco | 0.10 |
| trabalho_raso | 0.06 |
| treino | 0.20 |
| deslocamento | 0.04 |
| refeição / descanso | 0.0 (recuperação via `r`) |
| sono | reseta `F→0` |

### A.6 Progresso, planning fallacy e conclusão

```
esforço_necessário(tarefa) = dur_prevista · exp(o)     # o>0 ⇒ demora mais
taxa_progresso(t) = kWork · p0 · energia(t)          durante foco
                  = 0.5 · kWork · p0 · energia(t)     durante trabalho_raso
                  = 0                                  demais estados
concluiu(tarefa)  = (Σ taxa_progresso·Δ na janela ≥ esforço_necessário)
```

> **Calibração de `kWork` (feita na implementação — Fase 0):** sem a escala,
> `taxa_progresso = p0·energia ≈ 0,28/h` torna qualquer tarefa medida em "horas
> planejadas" estruturalmente inatingível (conclusão ~0% para todo débito de
> sono), como o teste de aceitação da Task 5 detectou. Varredura empírica de
> `kWork ∈ {2,3,4,5,6}`: com **`kWork = 3.0`** a taxa com traços fixos é monótona
> no débito de sono (0,97 → 0,21 → 0,00 para 0/2/4h) e o **agregado amostrado no
> cenário §C fica em ~0,66** — batendo os 63% ilustrativos. Valores maiores
> saturam a conclusão (≈0,81 em `kWork=4`). Por isso `kWork = 3.0`.

### A.7 Micro-dinâmica intra-janela (semi-Markov, doc 3 §5)

Dentro da janela de um compromisso, alterna foco↔distração:

```
duração_foco     ~ LogNormal(mediana=30 min, σ=0.5)
duração_distração~ LogNormal(mediana=8 min,  σ=0.5)
P(entrar em distração | fim de foco) = logistic(−1 + 2·(1 − energia(t)))
```
Procrastinação: tarefa `aversivo=true` atrasa o início com prob `ρ`, por
`Atraso ~ Exp(média 30 min)`.

### A.8 Mapa de aprendizado conjugado (qual observável atualiza qual traço)

Chave da Fase 0: vários traços são **diretamente observáveis** dos eventos →
update conjugado O(1) (doc 3 §6.1). O que não é, fica no prior por ora.

| Traço | Observável no event log | Update |
|---|---|---|
| `o` (otimismo) | `log(dur_real / dur_prevista)` por tarefa | Normal-Normal |
| `ρ` (procrastinar) | tarefa aversiva começou atrasada? (0/1) | Beta-Bernoulli |
| `p0` (produtividade) | trabalho efetivo/hora em foco (normalizado) | Normal-Normal |
| `φ`, `s`, `r` | (indiretos) | mantêm prior na Fase 0; refino Fase 1 |

> A previsão de conclusão sai da **simulação** usando as posteriors atuais; a
> **recalibração** (Parte B) corrige viés sistemático da probabilidade final,
> separada do aprendizado dos traços.

---

## Parte B — Protocolo do Gate Falsificável (o experimento N=1)

O objetivo único da Fase 0: **provar que o motor prevê melhor que o trivial**.

### B.1 Unidade de previsão

**Por compromisso** (não por dia). Cada compromisso com `prioridade ≥ 2` gera uma
previsão `p_i = P(concluir no horário)`. Motivo: N=1 em 30 dias dá poucos dias,
mas ~4–6 compromissos/dia → **120–250 previsões resolvidas** em 4–6 semanas —
suficiente para Brier e diagrama de confiabilidade.

### B.2 Procedimento diário

1. **Manhã:** o motor emite `p_i` para cada compromisso do dia e grava
   `previsao_emitida` (imutável) no event store.
2. **Noite (revisão ~20s):** para cada compromisso, registrar `o_i ∈ {0,1}`
   (concluiu no horário?) e os dados brutos (dur_real, atraso).
3. Nada de ajuste retroativo: previsões são **prospectivas e imutáveis** (anti-
   overfit do gate).

### B.3 Baseline trivial (o que precisamos bater)

Previsor de taxa-base: prevê, para **todo** compromisso, a frequência histórica
de conclusão observada até ali (um único número, sem features). Calcula-se seu
Brier sobre as mesmas previsões.

### B.4 Métricas

```
Brier            = (1/M) Σ (p_i − o_i)²
Brier Skill Score = 1 − Brier_modelo / Brier_baseline      # >0 = melhor que trivial
Calibração-no-todo = | média(p_i) − média(o_i) |            # ~0 = não-enviesado
```
Mais: diagrama de confiabilidade (bins de 0.1) e decomposição de Murphy
(confiabilidade − resolução + incerteza, doc 3 §9.1).

### B.5 Regra de decisão (passou / não passou)

Avaliar somente após **M ≥ 120** previsões resolvidas. Então:

> **PASSA** se `BSS ≥ 0.05` **e** `Calibração-no-todo < 0.05`.
> **FALHA** caso contrário.

### B.6 O que fazer se FALHAR (diagnóstico via decomposição)

- **Falha de confiabilidade** (calibração ruim, resolução ok): o modelo *ordena*
  bem mas os números estão deslocados → aplicar recalibração (Platt/isotônica,
  doc 3 §9.2) e reavaliar. Barato.
- **Falha de resolução** (não separa casos): o modelo não tem poder preditivo → a
  **estrutura do modelo do dia está errada**. Revisar variáveis/relações do doc 6
  §4 antes de qualquer avanço. Este é o sinal que justifica parar.

### B.7 Critérios de sucesso secundários (observar, não bloquear)

- Faixa média das previsões **encolhe** ao longo das semanas (twin aprendendo).
- A revisão noturna é usada com frequência (preditor de retenção, doc 1 §4.2).

---

## Parte C — Exemplo Numérico Resolvido (o 1º teste de aceitação)

Um dia concreto, com números, mostrando o motor produzir os "~63%". **A primeira
tarefa de implementação é reproduzir este exemplo** (vira fixture de teste).

### C.1 Cenário

- **Usuário:** arquétipo neutro-matutino após ~20 dias de dados. Posteriors
  atuais (ilustrativas, consistentes com A.2):
  `φ ~ Normal(9.5, 1.2²)`, `p0 ~ Beta(14, 9)` (média 0.61),
  `o ~ Normal(0.22, 0.06²)`, `ρ ~ Beta(4, 9)` (média 0.31),
  `s`, `r` no prior.
- **Hoje (terça):** dormiu 5h (meta 7h → `D_sono = 2`). Compromisso-alvo:
  **"Estudar" às 14h, dur_prevista = 2.0h, prioridade 2, aversivo = true.**

### C.2 Uma trajetória (i = 1), passo a passo

1. Amostra de traços: `φ=9.6, p0=0.60, o=0.25, ρ=0.31`.
2. Fadiga inicial: `F(0) = 0.10 + 0.08·2 = 0.26`.
3. Energia às 14h (longe do pico 9.6 → `cos(2π·(14−9.6)/24)=cos(1.15)≈0.41`):
   `η = −1 + 2.5·0.60 − 0.15·2 − 2.0·0.30 + 0.6·0.41`
   `  = −1 + 1.50 − 0.30 − 0.60 + 0.25 = −0.15` → `energia ≈ 0.46`.
4. Procrastinação: sorteio < 0.31 → **atrasa** o início em `Exp(30min)` → começa
   14h25.
5. Esforço necessário: `2.0 · exp(0.25) = 2.57h` de trabalho efetivo.
6. Progresso na janela (14h25–16h, com energia caindo por fadiga e distrações
   semi-Markov): trabalho efetivo acumulado ≈ **1.9h < 2.57h** → **não concluiu**
   nesta trajetória (`o₁ = 0`).

### C.3 Agregando N = 2000 trajetórias

Repetindo com `θ` reamostrado a cada vez (propaga incerteza epistêmica, doc 3 §4):
- fração que conclui: **≈ 0.63** → `estimativa_central = 63%`.
- quantis 10–90 das trajetórias: **52%–71%** → faixa exibida.
- dispersão inflada pela largura das posteriors (só 20 dias) → `confianca = média`.

### C.4 Fatores (análise de sensibilidade, doc 3 §7.2)

Perturbando uma entrada por vez (±1 desvio) e re-simulando:

| Fator | Perturbação | Δ na estimativa | Direção/força |
|---|---|---|---|
| Débito de sono | 2h → 0h | +11 pp (→74%) | ↑ forte |
| Aversividade/procrastinação | remover atraso | +8 pp | ↑ média |
| Hora do estudo | 14h → 9h30 (pico) | +9 pp | ↑ média |
| Duração prevista | 2.0h → 1.5h | +7 pp | ↑ média |

→ Alimenta os `fatores[]` e as `alternativas[]` do `OracleAnswer`.

### C.5 `OracleAnswer` resultante

```
Concluir "Estudar" hoje:  ~63%  (faixa 52–71%)  · confiança média · 20 dias
Fatores:  ↓ pouco sono (forte) · ↓ tarefa aversiva às 14h (média)
Hipóteses: janela 14–16h mantida; sem novos compromissos
Limitações: φ e s ainda no prior; 20 dias de dados
Alternativas: mover p/ 9h30 → ~72% · dormir +2h (afeta amanhã)
```

### C.6 Por que este exemplo é o teste de aceitação

Reproduzir C.2–C.5 no código força a implementar **corretamente** energia,
fadiga, procrastinação, planning fallacy, agregação Monte Carlo e sensibilidade —
tudo de uma vez. Se o número não bater ~63% com a faixa ~52–71%, há bug ou lacuna
na spec. **É o detector de buracos, agora como suíte de teste.**

---

## Como este documento amarra o resto

- Concretiza os docs **3, 4 e 6** com números → o **plano de implementação**
  (writing-plans) parte daqui.
- O **gate** (Parte B) operacionaliza o marco da Fase 0 do **doc 8**.
- O **exemplo resolvido** (Parte C) é a primeira acceptance-fixture do motor.
