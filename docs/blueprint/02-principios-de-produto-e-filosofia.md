# 02 — Princípios de Produto & Filosofia

**Project Oracle — Decision Intelligence Platform pessoal**
Documento 2 do dossiê técnico · 2026-07-16

> Este documento formaliza *como o produto pensa e fala*. Ele define o **contrato
> anti-certeza**, a **calibração como feature**, as regras de **apresentação de
> incerteza** (fundamentadas em psicologia cognitiva e economia comportamental) e
> o **escopo ético**. Tudo o que os documentos técnicos produzem tem de respeitar
> estes princípios. É a "constituição" do produto.

---

## 1. O princípio-raiz

O sistema **nunca** afirma *"isto vai acontecer"*. Ele sempre diz:
*"Dadas as informações disponíveis, estes são os cenários mais prováveis, com
esta confiança e estas limitações."*

O produto **não decide pelo usuário**. Ele ilumina consequências e trade-offs.
A frase canônica não é *"Faça isso"*, e sim:

> *"Se o seu objetivo é X, estas estratégias tendem a produzir melhores
> resultados, considerando seu histórico e o contexto informado — com esta
> incerteza."*

Isto não é só ética: a pesquisa de XAI mostra que **esconder incerteza aumenta o
automation bias** (o usuário segue a IA mesmo quando ela erra) e que tornar a
incerteza legível melhora a decisão e a correção (ver doc 1, §5). Honestidade
probabilística é também **melhor produto**.

## 2. O Contrato Anti-Certeza (resposta canônica)

Toda saída do motor obedece a um **schema fixo**. Nenhuma resposta pode omitir
um campo. Este é o artefato mais importante do produto — a "forma" de toda
resposta.

```
OracleAnswer {
  pergunta            // o que o usuário quis saber
  distribuicao        // NÃO um número único: faixa/distribuição de resultados
  estimativa_central  // ex.: 63% — sempre acompanhada da faixa
  confianca           // quão confiável é esta estimativa (meta-incerteza)
  fatores[]           // o que mais pesou, com direção e magnitude
  hipoteses[]         // suposições assumidas para poder calcular
  limitacoes[]        // o que enfraquece esta resposta (dados, contexto)
  alternativas[]      // estratégias e seus trade-offs (quando aplicável)
  como_aprendi        // por que o sistema acredita nisto (rastreabilidade)
}
```

Exemplo concreto (módulo Vida Diária):

> **Chance de cumprir sua agenda hoje: ~63%** (faixa provável 52–71%).
> **Confiança: média** — tenho 3 semanas dos seus dados.
> **O que mais pesou:** pouco sono ontem (−), agenda cheia à tarde (−), histórico
> bom em terças (+), sem deslocamento longo (+).
> **Hipóteses:** você mantém o horário de almoço; nenhuma reunião nova entra.
> **Limitações:** poucos dados sobre dias com >5 compromissos; não sei seu humor
> hoje.
> **Se seu objetivo é terminar tudo:** mover a tarefa de foco para de manhã
> aumenta a estimativa para ~74% (faixa 65–80%), ao custo de adiar e-mails.

### 2.1 Regras de forma (invioláveis)

1. **Nunca um número nu.** Todo ponto vem com faixa e confiança.
2. **Sem falsa precisão.** "≈63%" ou "60–65%", nunca "63,48%". A precisão exibida
   nunca pode exceder a precisão real do modelo.
3. **Fatores sempre com direção e peso** (+/− e magnitude), não só listados.
4. **Limitações são obrigatórias**, mesmo quando a confiança é alta.
5. **Rastreabilidade:** o usuário sempre pode perguntar "por quê?" e descer um
   nível (ver §5, aprendizado transparente).

## 3. Calibração como feature central (não enfeite)

Uma probabilidade só significa algo se for **calibrada**: quando o sistema diz
70%, deve acontecer ~70% das vezes. Sem isso, "63%" é decoração.

**Compromissos do produto:**

- Toda previsão significativa é **registrada com o desfecho real** e pontuada
  (**Brier score**; curvas de confiabilidade / reliability diagrams).
- O usuário pode ver o **histórico de calibração do próprio sistema**:
  *"Quando eu digo 70%, acerto em 68% das vezes."* Isso é honestidade radical e
  um diferencial que nenhum concorrente conversacional tem.
- Referência de qualidade: superforecasters atingem Brier ~0,166 vs ~0,259 de
  forecasters comuns (doc 1). O motor tem uma **meta de calibração mensurável.**
- Quando mal calibrado, o sistema **recalibra** (ex.: Platt/isotonic scaling) e
  **admite** menor confiança em vez de esconder.

> O detalhamento matemático do loop de calibração está no doc 3, §(loop de
> calibração). Aqui fica o **compromisso de produto**: calibração é visível,
> medida e assumida.

## 4. Apresentação de incerteza sem paralisar (psicologia + economia comportamental)

Mostrar incerteza mal feito paralisa ou confunde. A pesquisa cognitiva dá as
armadilhas e as saídas:

**Armadilhas a evitar:**

- **Aversão à ambiguidade** (Ellsberg): pessoas fogem de faixas largas mesmo
  quando são a verdade. Não podemos escondê-las — mas podemos torná-las
  **acionáveis**.
- **Viés de certeza / efeito zero-risco:** usuário superestima a diferença entre
  "quase certo" e "certo". Nunca prometer certeza para satisfazer esse viés.
- **Sobrecarga cognitiva:** incerteza demais, detalhada demais, trava a decisão.
- **Falsa precisão / ilusão de validade:** decimais falsos geram confiança
  indevida.
- **Framing:** "70% de sucesso" e "30% de falha" mudam a decisão — precisamos ser
  conscientes e, quando relevante, mostrar **os dois lados**.

**Princípios de apresentação (derivados da pesquisa de XAI, doc 1 §5):**

1. **Legível e acionável antes de completa.** A camada 1 é uma frase que orienta;
   o detalhe fica sob demanda (progressive disclosure).
2. **Tripla codificação:** número + linguagem verbal ("provável", "incerto") +
   visual (faixa/barra). Reduz erro de interpretação.
3. **Faixa, não ponto.** Mostrar a distribuição comunica incerteza melhor que
   qualquer aviso textual.
4. **Incerteza como convite à ação**, não como desculpa: *"posso reduzir essa
   incerteza se você registrar X"*.
5. **Confiança separada da estimativa.** "63%" (o quê) e "confiança média" (quão
   sólido) são coisas diferentes — meta-incerteza explícita.

## 5. Aprendizado transparente

O sistema aprende, mas **nunca como caixa-preta**. Sempre que usa um padrão
aprendido, pode explicá-lo:

> *"Estimei isso mais baixo porque observei que, nas últimas 4 terças com menos
> de 6h de sono, você cumpriu a agenda em 2 de 5 vezes."*

Regras:
- Todo aprendizado é **inspecionável e reversível** — o usuário pode corrigir ou
  descartar um padrão ("isso não é verdade sobre mim").
- O sistema mostra **de quais dados** um padrão veio e **quão forte** é a
  evidência (n amostral, incerteza).
- Correção do usuário é sinal de treino — o twin se ajusta (doc 4).

## 6. Escopo ético (o que NÃO fazemos, e por quê)

Restrições de princípio, não negociáveis:

- **Não assumir intenções de terceiros.** O sistema nunca afirma o que outra
  pessoa pensa ou sente. → **Módulo Relacionamentos fica fora do MVP** (doc 1 §3
  mostra o risco ético já teorizado; validade quase nula com N=1).
- **Não manipular.** Nada de dark patterns, gatilhos de vício, ou empurrar o
  usuário a uma decisão que sirva ao produto e não a ele.
- **Não diagnosticar** saúde nem dar aconselhamento clínico/financeiro
  regulado. Simula hábitos e tendências; não substitui profissional.
- **Não prometer prever o futuro.** Sem astrologia, adivinhação, "ler a mente".
  Tudo é probabilidade, hipótese e modelo — declarado como tal.
- **Local-first por padrão** (detalhes no doc 5/7): os dados mais íntimos ficam
  com o usuário.

## 7. Anti-padrões proibidos (checklist de rejeição)

Qualquer feature que caia em um destes é rejeitada na origem:

- [ ] Afirma certeza ("vai acontecer", "com certeza").
- [ ] Mostra número sem faixa/confiança.
- [ ] Exibe precisão falsa (decimais que o modelo não sustenta).
- [ ] Infere pensamento/intenção de outra pessoa.
- [ ] Esconde limitações ou a origem de um aprendizado.
- [ ] Usa incerteza para se eximir sem oferecer ação.
- [ ] Empurra decisão via gatilho emocional/vício.

## 8. Como este documento amarra o resto

- O **schema OracleAnswer** (§2) é o contrato de saída que o **motor (doc 3)**
  deve produzir e a **UI de XAI (docs 6, 8)** deve renderizar.
- O **compromisso de calibração** (§3) é implementado pelo **loop de calibração
  (doc 3)** e pelo **digital twin (doc 4)**.
- O **escopo ético** (§6) é detalhado e operacionalizado no **doc 7 (Ética/LGPD)**.
- As **regras de apresentação** (§4) guiam o **spec de UX do módulo-farol (doc 6)**.
