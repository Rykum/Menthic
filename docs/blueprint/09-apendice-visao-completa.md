# 09 — Apêndice: Visão Completa (os módulos e como herdam o motor)

**Project Oracle — Decision Intelligence Platform pessoal**
Apêndice do dossiê técnico · 2026-07-16

> O blueprint principal aprofundou o **motor + Vida Diária** (vertical slice). Este
> apêndice registra a **visão completa** — os demais domínios — mostrando que cada
> um é o **mesmo contrato de módulo** (doc 3 §10.1) com outro conteúdo. Serve para
> não perder a ambição de longo prazo e para orientar a expansão (doc 8, Fases
> 3+). Profundidade: esboço, não spec — cada módulo terá seu próprio ciclo
> spec→plano quando chegar a hora.

---

## 1. O princípio que unifica tudo

Todo módulo entrega ao motor as mesmas cinco peças:
`state_schema · generative_model · outcome · priors · utility`. O motor
(Monte Carlo, semi-Markov, Bayes, sensibilidade, calibração) **não muda**. É isto
que torna o Oracle uma *plataforma*, não uma coleção de apps.

## 2. Os módulos

### 2.1 Vida Diária ✅ (MVP — doc 6)

Já especificado. Referência de como todos os outros se parecem.

### 2.2 Estudos (recomendado como 2º módulo — doc 8 Fase 3)

- **state_schema:** meta de estudo, horas/dia disponíveis, histórico de sessões,
  dificuldade percebida, prazo.
- **generative_model:** sessões de estudo com foco/energia (reusa muito de Vida
  Diária) + curva de aprendizado/retenção.
- **outcome:** `atingiu_meta` (Bernoulli, calibrável) — ex.: "chance de atingir a
  meta em 4 meses estudando 2h/dia, dado seu histórico".
- **priors:** consistência típica, decaimento de motivação.
- **utility:** progresso vs bem-estar/burnout.
- **Por que é bom 2º:** dados logáveis, desfecho verificável, matemática parecida,
  risco ético baixo. Valida a tese "um motor, muitos módulos".

### 2.3 Carreira

- **state_schema:** situação atual (salário, satisfação, risco), opções (trocar,
  empreender, freelancer, aceitar proposta).
- **generative_model:** projeção multi-cenário de renda, aprendizado, estabilidade
  e qualidade de vida ao longo do tempo (Monte Carlo de trajetórias de carreira).
- **outcome:** distribuições de renda/satisfação/risco por estratégia.
- **utility:** trade-off risco × retorno × qualidade de vida × aprendizado.
- **Cuidado:** horizonte longo e dados esparsos → incerteza alta, a ser declarada
  com força. Bom para *comparar estratégias*, fraco para *números precisos*.

### 2.4 Saúde (como tendências, NUNCA diagnóstico — doc 7 §3)

- **state_schema:** sono, alimentação, atividade, hidratação (hábitos, não
  condições clínicas).
- **generative_model:** projeção de tendências de hábito (ex.: trajetória de sono
  se manter rotina X).
- **outcome:** tendências projetadas, não desfechos clínicos.
- **Restrição dura:** sem diagnóstico, sem aconselhamento clínico; aviso claro;
  evitar enquadramento como dispositivo médico. Risco regulatório exige cautela.

### 2.5 Finanças

- **state_schema:** renda, gastos, reserva, dívidas, objetivos.
- **generative_model:** **Monte Carlo financeiro** (o mais maduro do mercado, doc
  1 §4.4) — simular compras, investimentos, reserva de emergência, financiamento.
- **outcome:** distribuições de patrimônio/liquidez por estratégia; chance de
  atingir meta.
- **utility:** retorno × risco × liquidez × objetivos.
- **Cuidado:** fronteira com aconselhamento financeiro regulado — simular, não
  recomendar produto. Sinergia forte com o motor (probabilístico por natureza).

### 2.6 Relacionamentos ❌ (FORA — doc 7 §7)

**Permanece fora** e a decisão é de princípio, não de cronograma:
- Modelar o comportamento de um **terceiro que não consentiu** é juridicamente
  frágil (dados de terceiros sem base legal) e eticamente indefensável.
- Validade estatística quase nula (N=1, sem ground truth).
- Risco direto de manipulação interpessoal e de virar a "leitura de mente" que o
  produto rejeita (doc 2 §6).

*Se um dia entrar*, teria de ser radicalmente reformulado: focado **apenas no
próprio usuário** (suas próprias reações, seus padrões de comunicação, seus
valores em conflito), jamais em inferir a mente do outro. Ex.: "como *eu* costumo
reagir quando ansioso?" — nunca "o que *ela* está pensando?".

## 3. Mapa de expansão (resumo)

| Módulo | Maturidade da matemática | Risco ético/regulatório | Prioridade |
|---|---|---|---|
| Vida Diária | alta | baixo | **MVP** ✅ |
| Estudos | alta | baixo | **2º** (valida arquitetura) |
| Finanças | alta (MC maduro) | médio (regulação) | 3º, com cautela |
| Carreira | média (dados esparsos) | baixo | depois |
| Saúde | média | **alto** (dispositivo médico) | depois, muito cuidado |
| Relacionamentos | ~nula | **inaceitável** | **fora** |

## 4. A visão de longo prazo

Um **Personal Decision Operating System**: um motor de decisão que atravessa os
domínios da vida, sempre probabilístico, sempre explicável, sempre local-first, e
**calibrado** — algo que hoje não existe para pessoas (doc 1 §6). Chega-se lá
**um módulo de cada vez**, cada um passando pelos mesmos gates de calibração e
ética. A disciplina de escopo (doc 8) é o que separa esta visão de um cemitério de
features.
