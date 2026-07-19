# UI Leva 3 — Simular, Meu Twin e Calibração (design)

**Data:** 2026-07-19 · **Status:** aprovado ("faça direto") · **Base:** análise do RFC v2 (`docs/rfc/2026-07-19-analise-rfc-v2-foco-app-flutter.md`)

## 1. Objetivo

Tornar visíveis na UI os três pilares do RFC v2 que já existem no núcleo:
exploração "E se..." (Simular), Reality Model com incerteza (Meu Twin) e
autoavaliação do sistema (Calibração). Completa as 5 telas do doc 06 §9.

Fora de escopo: Life Graph, estados latentes, integrações externas, decay de
confiança, LLM.

## 2. Componentes

### 2.1 Simular (`/simular`, feature `simulate/`)
- Estado local hipotético inicializado do dia real (sono + agenda de hoje via
  eventos); editável: campo de sono, adicionar/remover compromissos (sheet
  igual ao da Hoje, versão local).
- Cada mudança recalcula `answerAgenda(DayState hipotético, priors)` e
  re-renderiza o `AnswerCard` (reuso direto).
- **Nada é gravado** — banner "cenário hipotético · nada foi salvo".

### 2.2 Meu Twin (`/twin`, feature `twin/`)
- Renderiza os 6 traços dos priors salvos, cada um com: nome amigável, valor
  central legível (φ → "pico ~10h", p0/ρ → %, s/r → por hora, o → % de
  subestimação), e rótulo de incerteza (alta/média/baixa) derivado da
  dispersão do prior.
- Cabeçalho de evidência: "N dia(s) com desfecho registrados".
- Regra de incerteza (helper puro `trait_view.dart`):
  Normal → sd relativo; Beta → sd da Beta; Gamma → cv = 1/√shape;
  limiares: baixa < 0.15, média < 0.35, alta ≥ 0.35 (dispersão relativa).

### 2.3 Calibração (`/calibracao`, feature `calibration/`)
- Pareamento (helper puro `pairing.dart`): por dia UTC, a **última**
  `previsao_emitida` do dia + desfecho real do dia = todos os compromissos
  prioridade ≥ 2 daquele dia com `tarefa_concluida`. Dias sem previsão ou sem
  nenhum desfecho registrado são ignorados.
- Tela: n de pares, Brier (`brierScore`), acerto médio ("previsto ~P% ·
  aconteceu em Q% dos dias" via `calibrationInTheLarge`/baseRate), lista dos
  pares (data · previsto% · ✓/✗). Com n < 10: aviso "ainda poucos dados para
  avaliar a calibração" (o gate formal do pacote usa minN=120; a tela mostra o
  que há, com honestidade).

### 2.4 Navegação
- Hoje ganha uma linha de atalhos (3 `NeuButton`s pequenos): "Simular",
  "Meu Twin", "Calibração" → `goNamed`.
- Rotas novas: `simular` (`/simular`), `twin` (`/twin`), `calibracao`
  (`/calibracao`). Total: 9 rotas nomeadas.

## 3. Testes

- `pairing.dart`: previsão+desfechos completos → outcome 1; com prio ≥2 não
  concluída → 0; dia sem desfecho ignorado; usa a última previsão do dia.
- `trait_view.dart`: rótulos de incerteza nos limiares; formatação dos 6.
- Simular: editar sono recalcula o card; nenhum evento novo persiste.
- Meu Twin: com priors de arquétipo manhã → mostra "10" no pico.
- Calibração: 2 dias seedados → 2 pares e Brier correto na tela.
- Rotas: teste do router com 9 nomes; atalhos da Hoje navegam.
- `flutter analyze` limpo; suíte inteira; verificação visual no Chrome.

## 4. Riscos

- Simular recalcula Monte Carlo a cada edição — ok no web (algumas centenas
  de simulações); debounce não necessário na fase 0.
- Calibração com histórico N=1 será quase vazia — é o comportamento honesto
  esperado (mostra o aviso de poucos dados).
