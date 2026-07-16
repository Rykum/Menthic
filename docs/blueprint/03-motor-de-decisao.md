# 03 — O Motor de Decisão (coração técnico)

**Project Oracle — Decision Intelligence Platform pessoal**
Documento 3 do dossiê técnico · 2026-07-16 · Profundidade: implementável

> Este é o documento mais denso. Especifica a **matemática e a arquitetura do
> motor** que todos os módulos compartilham: representação de estado e incerteza,
> o modelo generativo Monte Carlo, a dinâmica intra-dia (Markov/semi-Markov), a
> atualização Bayesiana do digital twin, a avaliação de estratégias, a
> explicabilidade computável e o loop de calibração. Fecha com a **API do motor**
> e as **escolhas de algoritmo** com justificativa. Notação: `~` = "amostrado
> de"; `P(·)` = probabilidade; `E[·]` = valor esperado; `θ` = parâmetros do twin.

---

## 1. O que o motor é (e o que não é)

O motor é **agnóstico de domínio**. Ele não sabe o que é "academia" ou "estudo";
sabe manipular **estados, eventos, probabilidades e consequências**. Um *módulo*
(Vida Diária, Finanças, …) fornece ao motor quatro coisas — schema de estado,
modelo generativo, definição de desfecho e priors — e recebe de volta previsões
calibradas no formato `OracleAnswer` (doc 2, §2).

```
        MÓDULO fornece                         MOTOR devolve
  ┌───────────────────────┐            ┌──────────────────────────┐
  │ schema de estado      │            │ distribuição de desfecho │
  │ modelo generativo     │  ───────▶  │ estimativa + confiança   │
  │ definição de desfecho │            │ fatores (sensibilidade)  │
  │ priors                │            │ estratégias comparadas   │
  └───────────────────────┘            │ relatório de calibração  │
                                       └──────────────────────────┘
```

Isso é o que permite **um motor, muitos módulos** sem reescrever a matemática.

## 2. O loop, formalizado

O ciclo `estado → evento → probabilidade → consequência → novo estado` é um
**processo estocástico controlado** (um POMDP simplificado):

- **Estado** `S_t`: a situação do usuário no instante `t` (variáveis observadas +
  contexto). Nunca conhecido com certeza → trabalhamos com a **crença**
  `b_t = P(S_t | histórico, θ)`.
- **Parâmetros latentes** `θ`: os *traços* do usuário (o digital twin, doc 4).
  Também incertos → temos a posterior `P(θ | dados)`.
- **Evento/ação** `a_t`: algo que acontece ou que o usuário escolhe (uma
  "estratégia" é uma sequência de ações).
- **Transição**: `S_{t+1} ~ P(S_{t+1} | S_t, a_t, θ)`.
- **Consequência/desfecho** `Y`: uma função do caminho, ex.: "cumpriu a agenda?"
  `Y = g(S_0, …, S_T)`.

O objetivo do motor é estimar `P(Y | estado atual, estratégia)` **propagando toda
a incerteza** — tanto a do acaso do dia quanto a do nosso desconhecimento sobre o
usuário. Como raramente há solução fechada, resolvemos por **simulação Monte
Carlo** (§4).

### 2.1 Dois tipos de incerteza (distinção crítica para a confiança)

- **Aleatória (aleatoric):** o dia é intrinsecamente ruidoso; mesmo conhecendo
  `θ` perfeitamente, o desfecho varia. → é a *largura da distribuição*.
- **Epistêmica (epistemic):** não conhecemos `θ` nem `S_t` bem (poucos dados). →
  é a *incerteza sobre a distribuição*, e **encolhe com aprendizado**.

O campo `confianca` do `OracleAnswer` reflete sobretudo a **epistêmica**; a
`distribuicao` reflete a **aleatória**. Separá-las é o que torna a confiança
honesta (doc 2, §4, "confiança separada da estimativa").

## 3. Representação de estado e incerteza

### 3.1 Estado

O estado é um vetor tipado de variáveis, cada uma com **distribuição**, nunca
valor pontual:

```
State = {
  continuas:  { energia: Beta(a,b),        // 0..1
                sleep_debt_h: Normal(μ,σ),
                horas_livres: Gamma(k,θ) },
  discretas:  { local: Categorical{casa,trabalho,rua},
                humor: Ordinal{ruim..otimo} },
  contexto:   { dow: seg..dom, clima, feriado },
  agenda:     [ {inicio, dur_prevista, tipo, prioridade}, ... ]
}
```

### 3.2 Crença como distribuição fatorada

Manter a distribuição conjunta completa é inviável. **Fatoramos** assumindo
independência condicional onde razoável (a estrutura de dependências vem de uma
**rede Bayesiana** — doc 1 §2.1 mostra que isso já é prática validada):

```
b(S) ≈ Π_i P(Sᵢ | pais(Sᵢ), θ)
```

Ex.: `produtividade ⟂ clima | energia`. A rede Bayesiana é o *grafo* de quem
influencia quem; os parâmetros dessas condicionais são parte de `θ`.

## 4. O modelo generativo do dia — Monte Carlo

**Ideia central:** para estimar `P(Y)`, não resolvemos integral — **simulamos
milhares de dias possíveis** e contamos. Cada dia amostra (a) um valor plausível
dos traços do usuário e (b) uma trajetória estocástica.

```
função ESTIMAR_DESFECHO(state0, estrategia, N=2000):
    resultados = []
    para i em 1..N:
        θ_i      ~ posterior(θ | dados_do_usuario)     # incerteza EPISTÊMICA
        traj_i   = SIMULAR_DIA(state0, estrategia, θ_i) # incerteza ALEATÓRIA
        y_i      = g(traj_i)                            # desfecho (ex.: cumpriu?)
        resultados.append(y_i)
    retornar DISTRIBUIÇÃO(resultados)   # média, faixa, quantis
```

Amostrar `θ_i` da posterior **a cada trajetória** é o truque que faz a incerteza
epistêmica aparecer na saída: com poucos dados, a posterior de `θ` é larga → as
trajetórias divergem → a `confianca` cai automaticamente. Não precisamos de regra
ad-hoc para "confiança baixa quando há poucos dados": **cai sozinho da matemática.**

Estimativas derivadas da amostra `{y_i}`:
- `estimativa_central` = média (ou mediana) de `{y_i}`.
- `distribuicao` / faixa = quantis 10–90 (ou intervalo de credibilidade).
- Erro de Monte Carlo ≈ `σ/√N` → escolhemos `N` para que seja < ~1pp.

## 5. Dinâmica intra-dia — Markov e semi-Markov

`SIMULAR_DIA` percorre o dia em passos, alternando entre **estados de atividade**:

```
A = { foco, trabalho_raso, distração, descanso, deslocamento, refeição, sono }
```

### 5.1 Por que semi-Markov (e não Markov puro)

Numa cadeia de Markov comum, o tempo em cada estado é geométrico/exponencial
(sem memória) — irreal: uma sessão de foco não tem probabilidade constante de
acabar a cada minuto. Usamos **semi-Markov**: a transição tem duas partes —

1. **Duração** no estado atual: `d ~ SojournDist(s, θ, contexto)` (ex.:
   `LogNormal` para foco, dependente de energia e hora).
2. **Para onde vai**: `s' ~ P(s' | s, θ, contexto)` (matriz de transição).

```
função SIMULAR_DIA(state, estrategia, θ):
    t = inicio_do_dia; s = estado_inicial(state)
    fadiga = state.sleep_debt → f0(θ)
    enquanto t < fim_do_dia:
        d   = amostrar_duração(s, energia(state,fadiga,t), θ)
        s'  = amostrar_transição(s, contexto(t, estrategia), θ)
        # progresso de tarefas durante estados produtivos
        se s in {foco, trabalho_raso}:
            progresso += taxa(s, fadiga, θ) * d
        # acúmulo de fadiga (atualização discreta tipo-ODE)
        fadiga = clamp(fadiga + α(s,θ)*d − recuperação(s,θ)*d, 0, 1)
        t += d; s = s'
    retornar trajetória(progresso, fadiga_final, atrasos, ...)
```

### 5.2 Fadiga e energia como variável de estado dinâmica

Fadiga não é constante — evolui. Modelo discreto (Euler de uma EDO simples):

```
fadiga_{t+Δ} = fadiga_t + α·(carga_da_atividade)·Δ − β·(recuperação)·Δ
energia_t    = σ( baseline(θ) − γ·fadiga_t − δ·sleep_debt + ritmo_circadiano(t) )
```

`σ` = logística (mantém em 0..1). O ritmo circadiano é uma senoide com pico
individualizado por `θ` (matutino vs vespertino — um dos primeiros padrões que o
twin aprende, doc 4). A energia realimenta as durações e taxas → é o que liga
"dormi mal" a "menos chance de cumprir a agenda", de forma **causal e explicável**.

## 6. O digital twin como parâmetros: atualização Bayesiana

`θ` são os traços comportamentais: `baseline_produtividade`,
`propensão_procrastinar`, `sensibilidade_ao_sono`, `pico_circadiano`,
`taxa_recuperação`, matrizes de transição, etc. (detalhe no doc 4). Aqui: **como
aprendemos `θ` dos dados**.

### 6.1 Conjugação onde possível (barato e exato)

Muitos desfechos são Bernoulli ("cumpriu a tarefa?"). Para uma taxa `p` com prior
**Beta**:

```
p ~ Beta(a, b)
observa k sucessos em n tentativas
posterior:  p | dados ~ Beta(a + k, b + n − k)
```

Atualização **online** trivial: a cada dia soma-se aos contadores. Para variáveis
contínuas (ex.: horas de foco), **Normal-Normal** conjugado dá update fechado da
média e variância. Esses casos rodam **on-device sem esforço**.

### 6.2 Modelo hierárquico → resolve o cold-start

No dia 1 não há dados do usuário. Solução: **priors populacionais** com
**shrinkage** (doc 4 detalha):

```
θ_usuario ~ Normal(μ_pop, τ²)         # prior vem da população
estimativa = w·dados_do_usuario + (1−w)·μ_pop,   w = n/(n + τ⁻²·σ²)
```

Com `n` pequeno, `w→0`: o twin "empresta" da população (chute razoável, não
aleatório). Conforme `n` cresce, `w→1`: vira cada vez mais *você*. E o `OracleAnswer`
pode dizer honestamente: *"baseado mais em padrões gerais do que nos seus, ainda"*.

### 6.3 Casos não-conjugados: filtragem online

Para partes não-conjugadas (ex.: parâmetros da semi-Markov acoplados), usamos
**filtro de partículas** ou **assumed density filtering** para manter a posterior
aproximada e atualizável em streaming, sem re-treinar do zero a cada dia. Custo
controlado (algumas centenas de partículas cabem on-device).

## 7. Estratégias e decisão — sensibilidade + utilidade esperada

O produto **não decide**, mas **compara estratégias** (doc 2, §1). Uma estratégia
`π` é uma intervenção no plano/estado (mover tarefa de foco para de manhã, dormir
+1h, cortar um compromisso).

### 7.1 Avaliação de estratégia

Para cada `π` candidata, roda-se o Monte Carlo (§4) **sob** `π`:

```
para cada π em estrategias:
    D_π = ESTIMAR_DESFECHO(state0, π, N)
    U_π = E_{y~D_π}[ Utilidade(y | objetivo_do_usuario) ]
```

`Utilidade` codifica o **objetivo declarado** do usuário (terminar tudo? preservar
bem-estar? minimizar atraso?) — é uma função de preferências, não um valor moral
do sistema. O motor ordena as estratégias por `U_π` **e mostra os trade-offs**
(cada `D_π` tem sua faixa), nunca só a "vencedora". Isso é uma **árvore/diagrama de
influência** avaliado por simulação.

### 7.2 Análise de sensibilidade → alimenta os `fatores[]`

Quais entradas mais movem o desfecho? Dois níveis:

- **Barato (one-at-a-time):** perturbar cada fator ±1 desvio e medir Δ na
  estimativa. Rápido, bom para a UI.
- **Rigoroso (variância / índices de Sobol):** decompor a variância de `Y` na
  contribuição de cada entrada. Usar quando quisermos ranquear fatores com
  interação.

O ranking resultante **é** o campo `fatores[]` (com direção = sinal do Δ,
magnitude = tamanho). A explicação não é *post-hoc*: **sai da própria simulação.**

### 7.3 (Opcional) Valor da informação

Quanto a incerteza cairia se o usuário registrasse `X` (ex.: humor de hoje)?
Calcula-se o *Expected Value of Perfect/Partial Information*. Vira o convite
acionável do doc 2 §4: *"posso apertar essa faixa se você me disser Y"*.

## 8. Explicabilidade computável (mapeando para `OracleAnswer`)

O motor produz cada campo do contrato **a partir da matemática**, não de texto
gerado:

| Campo `OracleAnswer` | De onde vem |
|---|---|
| `estimativa_central` | média de `{y_i}` (§4) |
| `distribuicao` / faixa | quantis de `{y_i}` (incerteza aleatória) |
| `confianca` | dispersão induzida pela posterior de `θ`; `n` efetivo; largura do intervalo (incerteza epistêmica, §2.1/§4) |
| `fatores[]` | análise de sensibilidade (§7.2) |
| `hipoteses[]` | condições fixadas na simulação (agenda mantida, etc.) |
| `limitacoes[]` | heurísticas: `n` baixo, cauda larga, contexto faltante, `w` de shrinkage alto |
| `alternativas[]` | ranking de estratégias por `U_π` (§7.1) |
| `como_aprendi` | quais dados moveram a posterior (rastro do §6) |

O LLM (Pilar 1) **só traduz esta estrutura em prosa** — não inventa os números.

## 9. Loop de calibração (implementa o compromisso do doc 2 §3)

### 9.1 Registrar e pontuar

Toda previsão significativa `p_i` é logada com seu desfecho real `o_i ∈ {0,1}`
quando ele acontece.

```
Brier = (1/M) Σ (p_i − o_i)²        # menor é melhor (0..1)
```

Decomposição de Murphy (dá diagnóstico, não só nota):
```
Brier = Confiabilidade − Resolução + Incerteza
        (calibração)    (poder)     (dificuldade base)
```
- **Confiabilidade (reliability):** quão perto "70% dito" fica de "70% observado"
  (queremos ~0).
- **Resolução:** quão bem o modelo separa casos (queremos alto).

### 9.2 Diagrama de confiabilidade e recalibração

Agrupa previsões em faixas (0–10%, …, 90–100%), plota frequência observada vs
prevista. Se sistematicamente torto (ex.: excesso de confiança), **recalibra**:

- **Platt scaling** (logística sobre o log-odds) ou **regressão isotônica**
  (monótona, não-paramétrica) ajustadas sobre o log `{(p_i, o_i)}`.
- A função de recalibração é aplicada às previsões futuras antes de exibir.

### 9.3 Realimentação honesta

O `confianca` reportado é ajustado pelo histórico de calibração do próprio
usuário/módulo. E o produto **expõe** isso (doc 2 §3): *"quando digo 70%, tenho
acertado ~68%"*. Nenhum concorrente conversacional faz isto.

## 10. API conceitual do motor

Interface estável que os módulos consomem (pseudo-assinaturas, agnósticas de
linguagem — mapeamento p/ Dart/Rust no doc 5):

```
Engine.predict(state, query)        -> OracleAnswer        # §4 + §8
Engine.simulate(state, strategy)    -> Distribution        # §4
Engine.compare(state, [strategies]) -> [ (strategy, OracleAnswer) ]   # §7.1
Engine.update(observation)          -> void  (atualiza posterior de θ) # §6
Engine.explain(prediction)          -> Factors + Limits    # §7.2 + §8
Engine.calibration_report(module)   -> Brier + ReliabilityCurve       # §9
Engine.value_of_info(state, signal) -> ExpectedReduction   # §7.3 (opcional)
```

### 10.1 Contrato do módulo (o que um domínio precisa entregar)

```
Module {
  state_schema     : tipos + distribuições das variáveis (§3)
  generative_model : simulate_step(s, a, θ) -> s'   (§5)
  outcome          : g(trajetória) -> Y             (§2)
  priors           : P(θ) populacional              (§6.2)
  utility          : U(y | objetivo)                (§7.1)
}
```

Adicionar um novo domínio (Finanças, Estudos) = implementar este contrato. **Zero
mudança no motor.** É isto que realiza "um motor, muitos módulos".

## 11. Escolhas de algoritmo — justificativa e trade-offs

| Escolha | Por quê | Alternativa rejeitada | Custo |
|---|---|---|---|
| **Monte Carlo** para `P(Y)` | Flexível, aceita modelos não-lineares/não-conjugados, propaga incerteza epistêmica trivialmente | Inferência exata (só serve p/ modelos simples) | O(N); `N~2000` é barato on-device |
| **Semi-Markov** intra-dia | Durações realistas (sojourn não-geométrico) | Markov puro (sem memória, irreal) | leve |
| **Bayesiano hierárquico** | Resolve cold-start via shrinkage; incerteza nativa | ML frequentista (sem incerteza, ruim com n pequeno) | conjugado é O(1)/update |
| **Separar aleatoric/epistemic** | Confiança honesta (doc 2 §4) | Um número só de "incerteza" | grátis (cai do §4) |
| **Sensibilidade p/ XAI** | Explicação sai da simulação, não post-hoc | SHAP/LIME sobre caixa-preta | O(#fatores·N) barato no modo OAT |
| **Platt/Isotônica** p/ calibrar | Padrão, robusto, pouca data | Deixar sem recalibrar | trivial |
| **Filtro de partículas** (não-conjugado) | Online, sem re-treino | MCMC batch (caro, não-streaming) | centenas de partículas |

### 11.1 Cabe on-device?

Sim, por design (Pilar 3, local-first): modelos são **leves** (dezenas de
parâmetros por módulo), `N` moderado, updates conjugados são O(1), e a simulação
de um dia são centenas de passos. Um `predict` completo com comparação de 3
estratégias ≈ `4 × N` simulações de dia — na casa de milissegundos a poucos
segundos em hardware móvel. Detalhe de engenharia (Dart isolate vs Rust FFI) no
doc 5.

## 12. O "tick" integrado do motor (visão de topo)

```
função TICK(usuario, pergunta_ou_estrategias):
    state0 = montar_estado(usuario)                     # §3
    θ_post = posterior_atual(usuario)                   # §6
    se pergunta:
        ans = predict(state0, pergunta)                 # §4,§8
    se estrategias:
        ans = compare(state0, estrategias)              # §7
    ans.confianca = ajustar_por_calibração(ans, usuario)# §9
    ans.prosa = LLM.explicar(ans)                       # Pilar 1 (só linguagem)
    log_previsao(ans)                                   # p/ calibração futura §9
    retornar ans   # formato OracleAnswer (doc 2 §2)

# quando o desfecho real chega:
função OBSERVAR(usuario, desfecho):
    update(usuario, desfecho)          # §6 posterior de θ
    registrar_para_calibração(desfecho)# §9
```

---

## 13. Como este documento amarra o resto

- O **digital twin `θ`** (§6) é aprofundado no **doc 4** (traços concretos,
  cold-start, transparência).
- A **API** (§10) e o **custo/on-device** (§11.1) são realizados na **arquitetura
  (doc 5)** — linguagem, event store, isolates/FFI.
- O **modelo generativo do dia** (§5) é instanciado concretamente no **módulo Vida
  Diária (doc 6)** com variáveis e inputs reais.
- O **loop de calibração** (§9) e a **explicabilidade** (§8) produzem os campos do
  `OracleAnswer` (doc 2) que a **UI (docs 6, 8)** renderiza.
