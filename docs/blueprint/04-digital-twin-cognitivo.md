# 04 — Digital Twin Cognitivo

**Project Oracle — Decision Intelligence Platform pessoal**
Documento 4 do dossiê técnico · 2026-07-16 · Profundidade: implementável

> O documento 3 tratou `θ` como uma caixa de "traços do usuário". Aqui abrimos a
> caixa: **quais são os traços**, como o twin **começa sem dados** (cold-start),
> como **aprende e se adapta** (inclusive quando a pessoa muda), como **descobre
> padrões** de forma honesta, e como tudo isso é **inspecionável e reversível**.
> O twin é um **modelo probabilístico de tendências — nunca uma cópia**.

---

## 1. Definição operacional

Alinhado à literatura (doc 1 §3), o twin é *uma representação computacional
dinâmica das disposições e tendências de uma pessoa, atualizada com dados
comportamentais e contextuais, para simular — não para copiar — sua cognição*.

Concretamente, o twin **é** a distribuição posterior `P(θ | dados)` — um conjunto
de parâmetros comportamentais, cada um com incerteza. Ele não "sabe" o que você
vai fazer; ele carrega a **incerteza sobre suas tendências** e a alimenta no motor
(doc 3, §6).

**Três negações que definem o que ele NÃO é:**
- Não é uma cópia determinística ("o que você faria").
- Não é um perfil psicométrico fixo (ele muda; §5).
- Não é um modelo de outras pessoas (só do próprio usuário; relacionamentos fora
  do MVP, doc 2 §6).

## 2. Estrutura em camadas por escala de tempo

Traços mudam em ritmos diferentes. Separá-los por **escala temporal** é o que
permite aprender rápido o que é rápido e devagar o que é estável:

```
Camada                     Escala        Exemplos
──────────────────────────────────────────────────────────────────
TRAÇOS (estáveis)          meses/anos    cronotipo, baseline de produtividade,
                                         propensão a procrastinar, aversão a risco
DISPOSIÇÕES (lentas)       semanas       rotina de sono atual, carga de trabalho,
                                         nível de estresse do período
ESTADOS (rápidos)          horas/dia     energia, fadiga, humor de hoje
CONTEXTO (externo)         instantâneo   dia da semana, clima, agenda, local
```

O motor (doc 3) amostra `θ` = traços + disposições; estados são simulados
dentro do dia; contexto é entrada. Cada camada tem sua **taxa de esquecimento**
(§5.2): traços quase não esquecem; disposições esquecem rápido.

## 3. Catálogo de traços (o conteúdo de `θ` no MVP)

Parâmetros do módulo Vida Diária. Cada um tem uma **distribuição** (não valor) e
um **prior populacional** (para cold-start, §4):

| Traço | Símbolo | Domínio | Distribuição | Significado |
|---|---|---|---|---|
| Cronotipo (pico circadiano) | `φ` | hora do dia | Normal(μ,σ) | matutino↔vespertino |
| Baseline de produtividade | `p₀` | 0..1 | Beta | taxa de foco em dia neutro |
| Propensão a procrastinar | `ρ` | 0..1 | Beta | chance de adiar tarefa aversiva |
| Sensibilidade ao sono | `s` | ≥0 | Gamma | quanto o débito de sono derruba energia |
| Taxa de recuperação | `r` | ≥0 | Gamma | quão rápido a fadiga cai em descanso |
| Custo de troca de contexto | `κ` | ≥0 | Gamma | penalidade ao alternar tarefas |
| Otimismo de agenda | `o` | −..+ | Normal | quanto subestima durações (planning fallacy) |
| Matriz de transição de atividade | `T` | estocástica | Dirichlet (por linha) | dinâmica foco↔distração↔descanso |
| Durações de permanência | `SojournDist` | tempo | LogNormal(μ_s,σ_s) por estado | quanto dura cada estado (semi-Markov) |

> Todos são **interpretáveis por construção** — cada um vira uma frase de
> explicação ("você tende a ser vespertino", "você subestima durações em ~20%").
> Isso é o que faz o `como_aprendi` do `OracleAnswer` ser legível.

## 4. Cold-start — o problema nº 1 de retenção, resolvido

A pesquisa (doc 1 §4.2) é dura: o valor precisa aparecer **cedo** ou o usuário
abandona. Um twin que só é útil após meses está morto. Três mecanismos, em
ordem de entrada:

### 4.1 Prior por arquétipos (dia 0, via onboarding curto)

Em vez de um prior populacional único e vago, usamos uma **mistura de
arquétipos** aprendida de dados populacionais (ou, no início, definida por
especialista):

```
P(θ) = Σ_k π_k · Normal(μ_k, Σ_k)        # k = arquétipos comportamentais
```

Um onboarding de poucas perguntas ("você rende melhor de manhã ou à noite?",
"costuma adiar tarefas chatas?") faz uma **atribuição suave** do usuário aos
arquétipos (`π_k`), produzindo um prior **já personalizado** no minuto 1. Não é
adivinhação: é um chute informado e honestamente rotulado como tal.

### 4.2 Shrinkage (dias 1..N)

Enquanto os dados são poucos, a estimativa combina usuário + população (doc 3
§6.2):

```
θ̂ = w·(dados do usuário) + (1−w)·μ_arquétipo,    w = n / (n + n₀)
```

`n₀` = "força" do prior (quantos dias de dados populacionais ele vale). Com
`n=2`, `n₀=10` → `w≈0,17`: ainda 83% população. Com `n=30` → `w=0,75`: já é
majoritariamente você. E o produto **diz isso**: *"baseado mais em padrões gerais
do que nos seus, por enquanto — confiança média-baixa"*.

### 4.3 Valor imediato sem esperar convergência

O twin não precisa estar convergido para ser útil no dia 1: com o prior de
arquétipo, o motor já roda cenários plausíveis. E o **loop de valor cedo** que a
retenção exige vem de mostrar, desde o começo, previsões acionáveis + a promessa
explícita *"quanto mais você registrar, mais isto vira sobre você"* (value of
information, doc 3 §7.3, como gancho de engajamento honesto).

## 5. Aprendizado online e adaptação (as pessoas mudam)

### 5.1 Atualização por observação

Cada dia observado atualiza os parâmetros relevantes (doc 3 §6): contadores
Beta/Dirichlet para taxas e transições, Normal-Normal para contínuos, filtro de
partículas para o acoplado. Tudo **incremental** — nunca re-treina do zero.

### 5.2 Esquecimento (non-stationarity)

Uma pessoa que mudou de emprego não deve ser modelada por dados de 8 meses atrás.
Aplicamos **esquecimento exponencial** — os "pseudo-contadores" decaem:

```
a ← λ·a + k_hoje          (0 < λ < 1)
b ← λ·b + (n_hoje − k_hoje)
```

`λ` por camada (§2): traços `λ≈0,999` (memória longa); disposições `λ≈0,95`
(memória de semanas). Efeito: o twin dá **mais peso ao presente** sem jogar fora
o passado bruscamente. `n` efetivo satura em `1/(1−λ)`, o que também impede
excesso de confiança com o tempo (a incerteza nunca colapsa a zero — honesto).

### 5.3 Detecção de mudança brusca (opcional, fase 2)

Para viradas abruptas (mudança, término, doença), um **change-point detector**
bayesiano leve pode disparar reset parcial de disposições, com o usuário no
controle: *"notei uma mudança grande na sua rotina há ~2 semanas — quer que eu
reaprenda a partir daí?"*. Transparência antes de agir.

## 6. Descoberta de padrões — o "aprendi X porque observei Y"

Este é o recurso que encanta e o que mais pode enganar. Regra de ouro: **só
afirmar um padrão quando a evidência sustenta**, com incerteza declarada.

### 6.1 Mecânica

Para um padrão candidato (ex.: "sono < 6h → menos foco"), estimamos o **efeito
condicional** com intervalo de credibilidade:

```
Δ = E[foco | sono<6h] − E[foco | sono≥6h]
```

Só vira uma afirmação ao usuário se:
- o **intervalo de credibilidade de Δ exclui ~0** (efeito real, não ruído), e
- o **n** em cada braço é suficiente (evita padrão de 2 amostras), e
- o efeito é **acionável/relevante** (magnitude importa, não só significância).

Caso contrário, fica como **hipótese interna** de baixa confiança, não exibida
como fato. Isso mata a "leitura de borra de café estatística".

### 6.2 Como é comunicado

Sempre com origem e força (doc 2 §5):

> *"Nas últimas 4 terças com menos de 6h de sono, você cumpriu a agenda em 2 de 5
> vezes, contra 8 de 10 nas demais. Evidência ainda fraca (poucos casos), mas é o
> que estou observando."*

Nunca *"você é uma pessoa que…"* — sempre *"nos seus dados, observei…"*.

### 6.3 Descoberta de estrutura (fase 2)

Aprender **quais** fatores dependem de quais (a topologia da rede Bayesiana, doc 3
§3.2) é *structure learning*. No MVP a estrutura é fixada por especialista (poucos
nós, bem entendidos); descoberta automática de novas arestas fica para quando
houver dados suficientes, sempre com validação e sob controle do usuário.

## 7. Transparência, inspeção e controle

O twin é um **objeto que o usuário pode abrir**:

- **Painel do twin:** mostra cada traço, seu valor estimado, sua incerteza, e de
  quantos dias de dados veio.
- **Reversibilidade:** o usuário pode contestar/apagar um padrão ("isso não é
  verdade sobre mim") — e a correção **é sinal de treino** (vira uma observação
  forte que ajusta a posterior).
- **Direito ao esquecimento:** apagar dados reverte o twin proporcionalmente
  (viável porque local-first, doc 5/7).
- **Nada oculto:** não há traço que o produto use e não mostre. Auditabilidade
  total do lado do usuário.

## 8. Anti-overfitting: a humildade do N=1

Modelar uma pessoa a partir dos dados dela mesma é estatística de **amostra
pequena** — o risco é overfit e falsa confiança. Salvaguardas embutidas:

- **Regularização via hierarquia:** o shrinkage populacional (§4) *é* a
  regularização — puxa estimativas extremas de volta ao plausível.
- **Incerteza nunca colapsa:** o esquecimento (§5.2) mantém `n` efetivo limitado;
  o twin **nunca** fica "100% certo sobre você".
- **Poucos parâmetros:** dezenas, não milhares — capacidade de overfit limitada
  por design.
- **Padrões precisam passar no teste de evidência** (§6.1) antes de virar
  afirmação.
- **Ceticismo exibido:** quando a base é fraca, o `OracleAnswer` diz — em vez de
  fingir robustez.

## 9. Ética do twin (entra no doc 7)

Os riscos do doc 1 §3.1 (privacidade, consentimento, dano psicológico, duplo uso)
são tratados aqui como requisitos de design:
- **Local-first** (doc 5): o modelo mais íntimo mora no dispositivo do usuário.
- **Transparência do aprendizado** (§6, §7): sem modelo oculto da mente.
- **Controle e reversibilidade** (§7): consentimento contínuo, não de uma vez.
- **Sem inferência sobre terceiros** (doc 2 §6): o twin é só do usuário.

---

## 10. Como este documento amarra o resto

- Os **traços** (§3) são o `θ` que o **motor (doc 3)** amostra e atualiza.
- O **cold-start** (§4) e o **esquecimento** (§5) realizam os compromissos de
  retenção e honestidade dos docs 1 e 2.
- A **descoberta de padrões** (§6) produz o campo `como_aprendi` do `OracleAnswer`
  (doc 2 §2) e o "aprendizado transparente" (doc 2 §5).
- O **painel do twin** e a **reversibilidade** (§7) são telas do **módulo-farol
  (doc 6)** e requisitos de **privacidade (doc 7)**.
