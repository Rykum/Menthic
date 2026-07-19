# Leva 6 — Motor de Estratégias (design)

**Data:** 2026-07-19 · **Status:** aprovado ("va para leva 6") · **Base:** análise do RFC v3, item 5 — a promessa não cumprida do mockup doc 06 §6 ("Se seu objetivo é terminar tudo → mover estudo p/ 8h → ~74%").

## 1. Objetivo

O sistema passa a **sugerir estratégias**: perturbações candidatas do dia,
avaliadas pelo mesmo simulador, ranqueadas pelo ganho estimado — nunca
decidindo, sempre mostrando números do motor com faixa. Inclui o log de
aceitação que destrava o meta-aprendizado futuro (RFC v3 #17).

## 2. Design

### 2.1 Engine (fase 0.6 — `oracle_engine` ganha `strategies.dart`)
```dart
class Strategy {
  final String id;        // 'mover_pico' | 'cortar_menor_prioridade' | 'menos_debito_sono'
  final String label;     // pt-BR pronto p/ UI
  final OracleAnswer answer; // cenário completo (estimate/low/high/confidence/…)
  final double delta;     // answer.estimate − baseline.estimate
}
List<Strategy> suggestStrategies(DayState state, TraitPriors priors,
    {int observedDays = 0, int seed = 0, int max = 3})
```
Geradores de candidatos (busca local sobre o simulador existente):
1. **mover_pico** — o compromisso tipo `foco` mais longo tem o `start` movido
   para `priors.phi.mean` (média do pico circadiano). Label: `mover
   '<cid>' para ~<h>h`.
2. **cortar_menor_prioridade** — remove o compromisso de menor prioridade
   (só se houver 2+ e o menor tiver prioridade < a máxima do dia). Label:
   `cortar '<cid>'`.
3. **menos_debito_sono** — se `sleepDebt >= 1`, simula com 1h a menos de
   débito. Label: `com 1h a menos de débito de sono`.

Regras de honestidade: baseline e candidatos usam o **mesmo seed**
(comparação pareada — deltas determinísticos e com menos ruído Monte Carlo);
só entram estratégias com `delta > 0.01`; ordenadas por delta desc; `max` 3.

### 2.2 App
- `AnswerCard` ganha parâmetros opcionais `strategies` e `onStrategyTap`;
  renderiza a seção **"Se seu objetivo é terminar tudo"** no estilo do mockup:
  `▸ <label> → ~74% (65–80%) · +11 pts`.
- **Hoje**: `_compute` também chama `suggestStrategies` (mesmos inputs);
  tocar numa estratégia alterna "marcada" e grava evento
  `estrategia_aceita` (payload `{id, label, delta}`) — a matéria-prima do
  meta-aprendizado. Tipo novo de evento só no app (`EventTypes` não muda; o
  store aceita qualquer `type` — usar a string `'estrategia_aceita'`).
- **Simular**: mostra as estratégias do cenário hipotético (sem log — nada é
  gravado na tela Simular, coerente com a leva 3).

## 3. Testes
- Engine (`dart test`): dia com débito de sono alto + foco longo fora do pico
  → `mover_pico` e `menos_debito_sono` aparecem com delta > 0; dia sem
  débito e 1 compromisso → sem `menos_debito_sono`/`cortar`; determinismo
  (duas chamadas idênticas → mesmos deltas); nunca mais que `max`.
- App: Hoje com previsão mostra a seção de estratégias quando houver alguma;
  tap grava `estrategia_aceita`; Simular renderiza sem gravar.

## 4. Fora de escopo
Pesos de utilidade configuráveis (U(y) — entra com o Motor de Objetivos);
aplicar estratégia na agenda real; meta-aprendizado da adesão (#17).
