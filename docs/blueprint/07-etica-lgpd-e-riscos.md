# 07 — Ética, LGPD & Riscos

**Project Oracle — Decision Intelligence Platform pessoal**
Documento 7 do dossiê técnico · 2026-07-16

> Operacionaliza o escopo ético (doc 2 §6) e trata a **LGPD como requisito de
> arquitetura** (não capítulo final). Cobre: conformidade LGPD concreta, dados
> sensíveis e minimização, **vieses e loops de retroalimentação**, **riscos
> psicológicos** (o mais subestimado), guardrails anti-manipulação, limitações
> declaradas, e governança (RIPD, red-team, resposta a incidente). Fundamentado
> na LGPD (Lei 13.709/2018) e na literatura de ética de digital twins cognitivos
> (doc 1 §3.1).

---

## 1. Por que a ética aqui é mais séria que na média

O Oracle modela a **mente e a rotina** de uma pessoa, com dados **sensíveis** por
definição (saúde, humor, finanças). O paper de governança de digital twins
cognitivos (doc 1 §3.1) lista quatro riscos que tratamos como requisitos:
privacidade/autonomia, consentimento/controle, **dano psicológico**, e duplo uso.
Um produto que erra aqui não é só ilegal — é nocivo. A privacidade é a
**arquitetura** (doc 5), não uma promessa.

## 2. LGPD — conformidade por design

### 2.1 Os dados e sua classificação

| Dado | Classificação LGPD | Tratamento |
|---|---|---|
| Sono, energia, humor, saúde | **Sensível** (art. 5º, II; art. 11) | on-device, cifrado, nunca em nuvem por padrão |
| Finanças (módulos futuros) | Pessoal, alto risco | idem |
| Agenda, tarefas | Pessoal | idem |
| Agregados anônimos (arquétipos) | Anonimizado (art. 5º, XI) | fora do escopo da LGPD se irreversível |

### 2.2 Base legal

- **Consentimento** (art. 7º, I; art. 11, I para sensíveis) — específico,
  destacado, informado, revogável. É a base primária.
- Como os dados **não saem do dispositivo** por padrão, grande parte do
  tratamento sequer transfere dados a terceiros — reduz drasticamente a
  superfície regulatória.

### 2.3 Princípios (art. 6º) → como cada um vira design

| Princípio LGPD | Implementação |
|---|---|
| **Finalidade** | cada dado tem uso declarado (ex.: sono → energia); nada coletado "por acaso" |
| **Necessidade / minimização** | coleta o mínimo; value-of-information justifica cada pedido (doc 6 §3) |
| **Livre acesso** | painel do Twin + export mostram tudo (doc 4 §7) |
| **Qualidade / transparência** | origem e força de cada padrão exibidas (doc 2 §5) |
| **Segurança / prevenção** | cripto em repouso + E2E no sync (doc 5 §9) |
| **Não discriminação** | ver §4 (vieses) |
| **Responsabilização** | RIPD + logs de consentimento (§8) |

### 2.4 Direitos do titular (art. 18) → como são atendidos

- **Acesso e portabilidade:** export completo (event log é a fonte, doc 5 §5.1).
- **Correção:** contestar/ajustar traços do twin (doc 4 §7).
- **Eliminação:** apagar local = apagar de verdade; re-derivação do twin (doc 5
  §1). O right-to-forget é **trivial** aqui, ao contrário de arquiteturas cloud.
- **Revogação de consentimento:** granular, a qualquer momento, com efeito
  imediato.

### 2.5 Privacy by design & by default (art. 46)

O padrão de fábrica é o mais privado: local-first, sem nuvem, sem
compartilhamento. Qualquer abertura (LLM cloud, sync, doação de agregados) é
**opt-in explícito** com o que exatamente é enviado exibido.

## 3. Dados sensíveis — regras duras

- **Nenhum dado bruto sensível vai para a nuvem** sem consentimento específico e
  granular por finalidade.
- O **LLM na nuvem só recebe estrutura já computada** (`OracleAnswer`), nunca o
  diário (doc 5 §4).
- **Saúde:** o app **não diagnostica** e exibe aviso claro; simula hábitos e
  tendências, não condições clínicas. Evita enquadramento como dispositivo médico.

## 4. Vieses e loops de retroalimentação (risco técnico-ético)

### 4.1 Fontes de viés

- **Priors populacionais enviesados:** se os arquétipos (doc 4 §4) vierem de
  população não representativa, o cold-start empurra todos para um "normal"
  enviesado. Mitigação: arquétipos auditados por representatividade;
  transparência de que o dia-1 é populacional; shrinkage rápido para o indivíduo.
- **Viés de disponibilidade de dados:** quem loga mais domina o aprendizado.
  Mitigação: incerteza honesta quando `n` é baixo.

### 4.2 O loop mais perigoso: profecia autorrealizável

Se o sistema diz "63% de chance de cumprir a agenda" e isso **desmotiva** o
usuário, que então não cumpre — a previsão se autoconfirma e o twin "aprende" a
pessimista. Salvaguardas:
- **Framing de agência** (doc 2 §4): incerteza como convite à ação, com
  estratégias que **melhoram** o número — nunca um veredito fatalista.
- **Nunca linguagem determinista** ("você não vai conseguir").
- Monitorar se previsões baixas correlacionam com queda de engajamento (sinal de
  efeito nocebo) — e ajustar a comunicação.

### 4.3 Gaming e otimização perversa

O usuário pode "jogar" para o número subir (marcar tarefas triviais como
concluídas). Mitigação: o objetivo é *insight*, não pontuação; evitar
gamificação que crie incentivo a enganar o próprio twin (doc 2 §7).

## 5. Riscos psicológicos (o mais subestimado)

O paper de governança alerta para **dano psicológico** de saber que existe um
modelo detalhado de si. Riscos concretos e mitigação:

| Risco | Descrição | Mitigação |
|---|---|---|
| **Ansiedade de vigilância** | sentir-se medido o tempo todo | coleta passiva discreta; sem "streaks" agressivos; controle total |
| **Fatalismo / determinismo** | tratar probabilidade como destino | contrato anti-certeza; sempre mostrar que dá para mudar (estratégias) |
| **Dependência excessiva** | terceirizar decisões ao app | "o produto não decide" (doc 2 §1); incentivar autonomia |
| **Ruminação** | obcecar sobre números | design calmo; não empurrar métricas ansiogênicas |
| **Autoimagem negativa** | "aprendi que você procrastina" vira rótulo | linguagem "nos seus dados observei…", nunca "você é…" (doc 4 §6.2) |

> Recomendação: **consultar psicologia/UX research** antes do lançamento e
> **red-team psicológico** dos textos (a forma como o número é dito importa mais
> que o número).

## 6. Guardrails anti-manipulação (operacionaliza doc 2 §6-§7)

Regras de produto verificáveis:
- Sem dark patterns, gatilhos de vício, ou notificações que exploram ansiedade.
- Sem empurrar decisão que sirva ao produto (ex.: mais engajamento) contra o
  interesse do usuário.
- Sem inferência sobre terceiros (relacionamentos fora, §7 abaixo).
- Toda persuasão do sistema é **para a agência do usuário**, não contra ela.
- O **checklist de anti-padrões** (doc 2 §7) roda como gate de review de feature.

## 7. Relacionamentos fora do MVP — a decisão ética central

Reafirmando com a fundamentação legal/ética (doc 1 §3.1, doc 2 §6):
modelar o comportamento provável de **outra pessoa** — mesmo como "hipótese" —
significa (a) tratar dados/inferências sobre um terceiro que **não consentiu**,
(b) com validade estatística quase nula (N=1, sem ground truth), e (c) risco
direto de manipulação interpessoal. É juridicamente frágil (dados de terceiros
sem base legal) e eticamente indefensável. **Fica fora**, e essa fronteira é um
diferencial de confiança, não uma limitação.

## 8. Governança

- **RIPD (DPIA / Relatório de Impacto à Proteção de Dados):** obrigatório dado o
  tratamento de sensíveis em escala — produzir antes do lançamento.
- **Registro de consentimento:** cada opt-in logado, auditável, revogável.
- **Red-team ético e psicológico:** revisar textos e fluxos quanto a manipulação,
  fatalismo, ansiedade.
- **Revisão de vieses:** auditar arquétipos e calibração por subgrupos.
- **Resposta a incidente:** plano para vazamento (mitigado por local-first, mas
  sync/backup exigem plano).
- **Encarregado (DPO):** designar quando houver operação de dados que justifique.

## 9. Limitações declaradas (honestidade como produto)

O que o Oracle **não pode** — dito ao usuário, não escondido:
- Não prevê o futuro; estima probabilidades sob hipóteses.
- Não sabe o que outras pessoas pensam ou farão.
- Não substitui profissional de saúde, finanças ou direito.
- É pior quanto menos dados tem (e diz isso).
- Pode estar mal calibrado — e mostra seu próprio histórico de acerto (doc 6 §8).

## 10. Riscos de produto/negócio (mapa)

| Risco | Gravidade | Mitigação |
|---|---|---|
| **Cold-start / retenção** | alta | arquétipos + valor cedo + coleta passiva (docs 4, 6) |
| **Acusação de "astrologia"** | média | contrato anti-certeza + calibração visível (docs 2, 6) |
| **Enquadramento regulatório (saúde)** | média | sem diagnóstico; simulação de hábito; aviso |
| **Dano psicológico / reputação** | alta | §5 + red-team + psicologia |
| **Privacidade / vazamento** | alta | local-first + cripto + E2E (doc 5) |

## 11. Checklist de conformidade (gate de lançamento)

- [ ] RIPD produzido e revisado.
- [ ] Consentimento granular, específico, revogável, logado.
- [ ] Nenhum dado sensível bruto sai do device por padrão.
- [ ] Export, correção e eliminação funcionando (art. 18).
- [ ] Cripto em repouso + E2E no sync verificados.
- [ ] Textos passaram por red-team psicológico (fatalismo, ansiedade, rótulo).
- [ ] Checklist de anti-padrões (doc 2 §7) aplicado a cada feature.
- [ ] Arquétipos auditados por representatividade.
- [ ] Avisos de "não diagnostica / não prevê o futuro" presentes.

---

## 12. Como este documento amarra o resto

- Converte os riscos do **doc 1 §3.1** em requisitos concretos.
- Depende da arquitetura **local-first do doc 5** para satisfazer a LGPD por
  design.
- Operacionaliza o **escopo ético do doc 2** e a **transparência/controle do
  doc 4**.
- Suas mitigações de retenção e regulatórias entram no **roadmap (doc 8)** como
  gates.
