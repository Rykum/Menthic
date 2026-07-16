# 08 — Roadmap de Construção

**Project Oracle — Decision Intelligence Platform pessoal**
Documento 8 do dossiê técnico · 2026-07-16

> A ordem de construção, os marcos e — o mais importante — **o que cada fase
> precisa provar antes de continuar**. Cada fase tem um *gate falsificável*: se o
> critério não for atingido, para-se e reavalia-se, em vez de empilhar features
> sobre uma fundação que não funciona. O princípio é **provar a parte mais
> arriscada primeiro** (o loop motor + calibração), com N=1, antes de investir em
> polimento ou escala.

---

## 1. Filosofia do roadmap

Três regras que ordenam tudo:

1. **De-risk antes de escalar.** A maior incerteza não é a UI — é *o motor
   probabilístico produz previsões calibradas sobre a vida real de alguém?*
   Provar isso primeiro, com o próprio construtor como cobaia (N=1).
2. **Um motor, muitos módulos** (doc 3 §10.1): construir o motor genérico + um
   módulo; os outros herdam sem tocar o núcleo.
3. **Gates falsificáveis.** Cada fase tem um número que a valida ou a mata.
   Sem "quase funcionou".

## 2. Dependências (o que precisa vir antes de quê)

```
Event Store ──► Motor mínimo ──► Digital Twin ──► Módulo Vida Diária
    (doc 5)        (doc 3)          (doc 4)            (doc 6)
                      │                                   │
                      └──────────► Loop de Calibração ◄───┘
                                       (doc 3 §9)
                                          │
                                          ▼
                                     UI de XAI (doc 6 §6)
                                          │
                                          ▼
                              [gate] calibração N=1 valida?
                                          │
                          ┌───────────────┴───────────────┐
                       sim: escalar                    não: reavaliar modelo
```

## 3. As fases

### Fase 0 — Prova do loop (N=1, "as férias")

**Objetivo:** provar que o loop `estado → simulação → previsão → desfecho →
aprendizado → calibração` funciona ponta a ponta, com **uma pessoa** (o próprio
construtor).

**Escopo mínimo:**
- Event store local (Drift/SQLite), coleta manual + sono/agenda passivos.
- Motor em **Dart puro** (doc 5 §3): Monte Carlo + semi-Markov + energia/fadiga +
  atualização Beta/Normal-Normal. Nada de Rust ainda.
- Twin com poucos traços (cronotipo, produtividade, sono, otimismo de agenda).
- Um desfecho principal: `cumpriu_agenda`.
- Revisão noturna + Brier score + diagrama de confiabilidade.
- UI crua do `OracleAnswer` (nem precisa ser bonita).

**Fora de escopo:** Rust, nuvem, LLM, outros módulos, onboarding polido, RAG.

**Gate falsificável (o mais importante do projeto):**
> Após ~4–6 semanas de uso diário por 1 pessoa, o **Brier score do desfecho
> principal é melhor que o baseline trivial** (prever sempre a taxa-base) e o
> diagrama de confiabilidade não está grosseiramente torto.

Se **não** passar: o modelo do dia está errado — reavaliar variáveis/estrutura
antes de qualquer coisa. Este gate protege contra construir um produto lindo sobre
matemática que não prevê nada.

### Fase 1 — MVP real (poucos usuários, ainda pré-escala)

**Objetivo:** transformar o protótipo em produto usável por pessoas que não são o
construtor, com onboarding e retenção.

**Escopo:**
- Onboarding por arquétipos + cold-start com shrinkage (doc 4 §4).
- Coleta passiva madura (HealthKit/Google Fit/Calendar) — fricção baixa (doc 6 §3).
- Estratégias comparáveis + "Simular" ao vivo (doc 6 §5).
- LLM para prosa da explicação (só estrutura → nuvem consentida ou on-device,
  doc 5 §4).
- Painel do Twin (inspeção, correção, reversibilidade) — requisito LGPD.
- Cripto em repouso (SQLCipher); RIPD produzido (doc 7 §8).
- UI de XAI cuidada (regras de incerteza, doc 2 §4).

**Gates falsificáveis:**
> **Calibração:** Brier do módulo < ~0,20 após 60 dias por usuário.
> **Retenção do núcleo:** fração relevante mantém a revisão noturna após 4
> semanas (o preditor de retenção, doc 1 §4.2).
> **Valor:** usuários que agem sobre estratégias sugeridas melhoram o desfecho
> (medível pré/pós via calibração).

Se retenção falhar: o problema é fricção/valor-cedo — iterar coleta e onboarding
antes de adicionar módulos.

### Fase 2 — Robustez e escala do núcleo

**Objetivo:** tornar o motor rápido, portátil e o aprendizado mais rico —
**sem** ainda multiplicar módulos.

**Escopo:**
- **Migração do motor para Rust via FFI** (doc 5 §3) — mesmo core em
  iOS/Android/desktop.
- Esquecimento/adaptação (non-stationarity, doc 4 §5) e detecção de mudança.
- **RAG estreito** do histórico do próprio usuário para explicações melhores
  (doc 5 §7).
- Descoberta de padrões com gate de evidência (doc 4 §6).
- Sync E2E opcional (doc 5 §9).
- Priors populacionais reais (agregados/federado + privacidade diferencial,
  doc 5 §8) substituindo os de especialista.

**Gate:**
> Calibração se mantém ou melhora com o motor Rust; a adaptação melhora previsões
> após mudanças de rotina (medível); performance on-device dentro do alvo (doc 3
> §11.1).

### Fase 3 — Segundo módulo (validar "um motor, muitos módulos")

**Objetivo:** provar a tese arquitetural adicionando um módulo **sem tocar o
motor**. Candidato recomendado: **Estudos** (dados logáveis, desfecho verificável,
matemática parecida com Vida Diária) — não Finanças (regulatório) nem
Relacionamentos (fora, doc 7 §7).

**Escopo:** preencher o contrato de módulo (doc 3 §10.1) para Estudos:
`state_schema`, `generative_model`, `outcome` (ex.: atingir meta de estudo),
`priors`, `utility`.

**Gate falsificável (valida a arquitetura):**
> O módulo Estudos é adicionado **sem modificar o núcleo do motor**, e atinge
> calibração comparável. Se exigir reescrever o motor, a abstração do doc 3
> estava errada — corrigir a fronteira antes de seguir.

### Fase 4+ — Expansão disciplinada

Módulos adicionais (Finanças com cuidado regulatório, Saúde como
tendências-não-diagnóstico), na ordem que a demanda e o risco permitirem. Cada um:
mesmo contrato, mesmos gates de calibração e ética. **Relacionamentos permanece
fora** até (e se) surgir uma abordagem eticamente defensável (doc 7 §7).

## 4. O que cabe realisticamente nas férias

Seja honesto sobre escopo (doc 1 alertou: a visão é plurianual). Nas férias, o
alvo **realista e valioso** é a **Fase 0**: o protótipo N=1 que prova o loop. Isso
é, ao mesmo tempo:
- um experimento de ciência de dados sobre a própria vida (valor imediato), e
- a fundação e a validação de risco de todo o resto (valor estratégico).

Tentar Fase 1+ nas férias é a armadilha de escopo. **Fase 0 bem feita > meia
Fase 1.**

## 5. Marcos resumidos

| Fase | Entrega | Gate falsificável |
|---|---|---|
| **0** | protótipo N=1, motor em Dart, calibração | Brier > baseline trivial em 4–6 sem |
| **1** | MVP com onboarding, coleta passiva, XAI, LGPD | Brier < 0,20; retenção do núcleo; valor pré/pós |
| **2** | motor Rust, adaptação, RAG, priors federados | calibração mantém; adaptação mensurável; perf on-device |
| **3** | 2º módulo (Estudos) | adicionado sem tocar o motor; calibração comparável |
| **4+** | módulos extras, disciplinados | mesmos gates de calibração + ética |

## 6. Riscos de execução e mitigação (liga ao doc 7 §10)

- **Escopo:** o inimigo nº 1. Gates falsificáveis + "Fase 0 primeiro" são o
  antídoto.
- **Retenção:** provada na Fase 1, não assumida. Coleta passiva e valor-cedo são
  pré-requisitos, não polimento.
- **Overengineering:** Rust, RAG e federado só nas Fases 2+, quando há sinal.
- **Ética/regulatório:** RIPD e red-team são gates da Fase 1, não afterthought.

---

## 7. Como este documento amarra o resto

- Sequencia a construção de tudo: event store/arquitetura (doc 5) → motor
  (doc 3) → twin (doc 4) → módulo (doc 6) → calibração/XAI (docs 2, 3, 6).
- Seus gates usam as **métricas do doc 6 §10** e os **gates éticos do doc 7**.
- A Fase 3 valida a **abstração de módulo do doc 3** e abre o caminho para os
  módulos do **apêndice (visão completa)**.
