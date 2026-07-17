# Design Spec — Event Store & Data Layer (Fase 0.2)

**Data:** 2026-07-17
**Status:** Aprovado para implementação
**Depende de:** `engine/` (pacote `oracle_engine`, Fase 0.1 — já na `main`)

---

## 1. Contexto e objetivo

O motor (`oracle_engine`) é headless e recebe um `DayState` pronto. Este
sub-projeto constrói a **fundação de dados** que produz esse `DayState` a partir
de eventos registrados — realizando o event sourcing do doc 5 §5 e desbloqueando
aprendizado, calibração e UI nas fases seguintes.

Decisões de enquadramento já tomadas com o usuário:

| Decisão | Escolha |
|---|---|
| Escopo | Event store **+ derivação que alimenta o motor** (prova a pipeline eventos→motor) |
| Persistência | **Interface + SQLite (`sqlite3`, sem codegen) + impl em memória** |
| Cripto (SQLCipher) | **Fora** — adiada para a fase do app Flutter |
| Aprendizado / UI | **Fora** — sub-projetos futuros |

## 2. Pacote

Novo pacote Dart puro **`store/`** (nome `oracle_store`), headless, testável com
`dart test`. Dependências: `oracle_engine` (tipos `DayState`/`Commitment`) e
`sqlite3`. Mesmo padrão de qualidade do motor (`dart analyze` limpo, `dart
format`, TDD).

## 3. Componentes

### 3.1 Modelo de evento (imutável)

```
Event {
  id: int          // atribuído pelo store ao persistir
  ts: DateTime     // quando o evento ocorreu
  type: String     // tipo do evento (ver 3.2)
  payload: Map<String, dynamic>   // dados do evento (serializado como JSON)
  origin: String   // 'manual' | 'passivo' | 'motor'
}

EventDraft { ts, type, payload, origin }   // evento sem id, pré-persistência
```

### 3.2 Tipos de evento da Fase 0

| Tipo | Payload | Origem típica |
|---|---|---|
| `sono_registrado` | `{horas, qualidade?}` | manual/passivo |
| `compromisso_criado` | `{cid, inicio, dur_prevista, tipo, prioridade, aversivo}` | manual |
| `tarefa_concluida` | `{cid, atraso_min}` | manual |
| `tarefa_nao_concluida` | `{cid}` | manual |
| `humor_registrado` | `{valor}` | manual |
| `previsao_emitida` | `{oracle_answer}` | motor |

`previsao_emitida` é mantida já agora para o **loop de calibração** futuro
(previsões e desfechos são só mais eventos, doc 3 §9), mesmo sem consumo nesta
fase. Helpers tipados criam/leem cada tipo; a tabela é única.

### 3.3 Interface `EventStore` (assíncrona)

```
abstract class EventStore {
  Future<Event> append(EventDraft draft);
  Future<List<Event>> query({DateTime? from, DateTime? to, List<String>? types});
  Future<List<Event>> all();
  Future<void> deleteById(int id);
  Future<void> deleteWhere({DateTime? from, DateTime? to, List<String>? types});
  Future<void> clear();
}
```

`deleteById`/`deleteWhere`/`clear` realizam o **right-to-forget** granular
(doc 7 §2.4). `query` ordena por `ts` ascendente.

### 3.4 Implementações

- **`InMemoryEventStore`** — `List<Event>` interna; para testes rápidos e uso
  efêmero.
- **`SqliteEventStore`** — pacote `sqlite3`; tabela
  `events(id INTEGER PRIMARY KEY AUTOINCREMENT, ts INTEGER, type TEXT, payload TEXT, origin TEXT)`;
  `payload` como JSON string; `ts` como epoch millis. Abre arquivo `.db` (path
  injetável) ou SQLite in-memory (`:memory:`) para testes de integração.

Um **conjunto de testes de contrato compartilhado** roda contra AMBAS as impls,
garantindo comportamento idêntico (append retorna id/ts; query filtra e ordena;
deletes removem; clear esvazia).

### 3.5 Camada de derivação

```
DerivationConfig { double metaSonoHoras = 7.0; double dayEnd = 24.0; }

class DayStateDeriver {
  Future<DayState> derive(EventStore store, DateTime date, DerivationConfig cfg);
}
```

`derive` lê os eventos do dia `date` e monta o `DayState` que o motor consome:
- `sleepDebt = max(0, metaSonoHoras − horas_do_ultimo_sono_registrado)`;
- `agenda` a partir dos `compromisso_criado` do dia (mapeados para `Commitment`);
- `dayEnd` de `cfg`.

## 4. Fluxo de dados (a pipeline provada)

```
append(eventos) → EventStore → DayStateDeriver.derive → DayState
                → oracle_engine.answerAgenda → OracleAnswer
```

## 5. Testes

- **Contrato do `EventStore`** rodado nas duas impls (append/query/filtros/
  delete/deleteWhere/clear/ordenação).
- **Derivação**: dado um conjunto de eventos, deriva o `DayState` esperado
  (sleepDebt correto, agenda correta, sem sono → sleepDebt 0).
- **Right-to-forget**: após `deleteWhere`, a re-derivação reflete a remoção.
- **End-to-end**: eventos → derivação → `answerAgenda` → `OracleAnswer` válido
  (determinístico, campos coerentes).

## 6. Fora de escopo (YAGNI)

Cripto (SQLCipher), aprendizado Bayesiano dos traços, time-series/feature store
completos, sync, UI. A interface `EventStore` e o `DayStateDeriver` deixam tudo
isso plugável depois sem tocar consumidores.

## 7. Critério de sucesso

A partir de eventos registrados, o sistema deriva um `DayState` correto e
alimenta o motor produzindo um `OracleAnswer` — com right-to-forget funcionando e
paridade de comportamento entre as impls em memória e SQLite. Tudo testado,
`dart analyze` limpo.
