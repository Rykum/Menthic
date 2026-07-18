# UI Flutter — Fundação: Design System + Telas de Entrada (Splash/Login/Cadastro)

**Project Oracle — Menthic** · Design doc · 2026-07-18 · Fase 1 (primeira leva de UI)

> Primeira leva da UI em Flutter sobre os 4 pacotes headless. Entrega o
> **scaffold do app**, o **design system reutilizável** (glassmorphism + neumorphism,
> paleta pastel mint) e as **três telas de entrada** fiéis aos protótipos do
> usuário (Splash, Login, Cadastro), com **auth como stub local** (local-first
> preservado) e navegação real. Roda no **Chrome/Web**; Android é o alvo final.

---

## 1. Objetivo e não-objetivos

**Objetivo desta leva:**
- Criar o pacote Flutter `app/` ligado por `path` aos 4 pacotes Dart puros.
- Construir um **design system** que torne "replicar o design nas próximas telas"
  uma tarefa trivial (widgets base + tokens + fontes + textura).
- Reproduzir **fielmente** os três protótipos SVG: Splash, Login, Cadastro.
- Auth funcional porém **sem backend** (stub local), preservando o princípio
  local-first do blueprint (doc 07).
- Navegação real com `go_router` e uma **Home placeholder** para "Entrar" ter destino.

**Não-objetivos (ficam para leva seguinte):**
- Render real do `OracleAnswer` na Home (ligado ao engine).
- Onboarding/cold-start, Simular, Revisão noturna, Meu Twin, Calibração.
- Backend/contas na nuvem, sync, Google Sign-In real, recuperação de senha.
- Coleta passiva (HealthKit/Calendar).

## 2. Decisões travadas (do brainstorm)

| Decisão | Escolha | Porquê |
|---|---|---|
| Auth | **Stub local** (`shared_preferences`) | Preserva local-first; destrava toda a UI; backend é plug-in futuro |
| Plataforma de dev | **Chrome/Web** | Preview instantâneo do trabalho visual; Android depois pro N=1 |
| Paleta | **Fiel ao protótipo** (aqua/mint) | Usuário pediu "faça igual"; virar "mais azul" depois = trocar 1 token |
| Navegação | `go_router` | URLs limpas no web + rotas nomeadas |
| Estado | `flutter_riverpod` | Leve agora, pronto p/ ligar engine/store depois |

## 3. Arquitetura do app

Novo pacote na raiz:

```
app/                      # pacote Flutter "menthic"
  pubspec.yaml            # depende de oracle_engine/store/calibration/learning via path
  assets/
    textures/paper.jpg    # extraído do JPEG embutido nos SVGs
    fonts/                # Fredoka (display) + Nunito (corpo)
  lib/
    main.dart             # bootstrap: ProviderScope + MenthicApp + router
    router.dart           # go_router: /splash /login /cadastro /home
    design/               # o design system (§4)
    features/
      auth/               # LocalAuth service + telas login/cadastro/splash
      home/               # Home placeholder
```

Os 4 pacotes headless **não mudam**. O app os consome como dependências.

### 3.1 Auth stub (`LocalAuth`)

- Serviço com `shared_preferences`: chaves `logged_in` (bool) e `user_email`.
- `signIn(email, senha)` / `signUp(...)`: validação mínima local (email não vazio,
  senha ≥ 6, confirmação bate no cadastro) → grava sessão → navega p/ `/home`.
- `signOut()`: limpa flag.
- Botão Google e "Continuar com o Google": **stub visual** (loga como
  `google_user@local`), sem SDK real. Documentado como placeholder.
- Sem rede, sem persistência de senha real (não é um sistema de segurança — é um
  portão local até o backend existir).

### 3.2 Roteamento

`go_router` com redirect: no boot, Splash decide destino pelo flag `logged_in`
(→ `/home`) ou (→ `/login`). Rotas: `/splash` (inicial), `/login`, `/cadastro`,
`/home`.

## 4. Design system (`lib/design/`)

O núcleo reutilizável. Objetivo: qualquer tela futura se monta compondo estes
widgets, sem reinventar o visual.

### 4.1 Tokens (`tokens.dart`)

Paleta exata extraída dos SVGs:

| Nome | Hex | Uso |
|---|---|---|
| `mint` (primário) | `#7BCCD1` | botões, círculos, ações |
| `cyanLight` | `#A2F7FD` | fill do vidro (@ opacidade 0.20), acentos |
| `mintDeep` | `#6CB7BC` | sombra/fundo dos campos afundados |
| `highlight` | `#DCFDFF` | brilho neumórfico (luz) |
| `blueAccent` | `#42C8ED` | detalhe (splash) |
| `neutralGray` | `#9F9C9C` | rodapé/legendas |

Também: raios (`rPill`, `rCard=22`), espaçamentos, `blurSigma` (glass),
specs de sombra neumórfica (offset/blur da luz e da sombra), durações de animação.

> **Nota de evolução:** deslocar tudo para "azul pastel" = mudar `mint`/`cyanLight`
> aqui. Nenhum widget referencia hex direto — só os tokens.

### 4.2 Tipografia e textura

- **Fontes bundladas** (offline-safe): *Fredoka* (títulos bolha, arredondada) e
  *Nunito* (corpo legível). Declaradas em `pubspec.yaml`.
- **Textura de fundo:** extrair o JPEG embutido em `spalsh screenM.svg` e salvar
  como `assets/textures/paper.jpg`. Fundo fiel ao protótipo.

### 4.3 Widgets base

| Widget | O que faz | Técnica |
|---|---|---|
| `MenthicScaffold` | Fundo texturizado + blobs; base de toda tela | `Stack` (texture → `FloatingBlobs` → conteúdo) |
| `GlassCard` | Card de vidro fosco translúcido | `BackdropFilter(ImageFilter.blur)` + fill `cyanLight`@0.2 + borda 1px + sombra |
| `NeuButton` | Botão/pílula **em relevo** | `Container` + duas `BoxShadow` (luz `highlight` cima-esq, sombra escura baixo-dir) |
| `NeuInset` | Superfície **afundada** (campos, botão "Entrar") | `CustomPainter` desenhando inner-shadow (Flutter não tem nativo) |
| `PillField` | Campo de input afundado | `NeuInset` + `TextField` sem borda |
| `DisplayTitle` | Título bolha ("Menthic") | Fredoka bold + inner-shadow via `ShaderMask`/overlay; textura de bolha aproximada e refinada no visual |
| `FloatingBlobs` | Círculos decorativos mint | camada de `Positioned` círculos com opacidades variadas |
| `GoogleButton` | Pílula branca "Continuar com o Google" | branco + logo G (asset PNG extraído do SVG) |

**Risco técnico conhecido — inner-shadow (neumorphism "afundado"):** o Flutter
não tem `BoxShadow` interno. `NeuInset` será um `CustomPainter` que pinta o
gradiente de sombra na borda interna. É o widget mais delicado; será construído e
validado visualmente primeiro (isolado), antes das telas.

**Aproximação honesta — título bolha:** o preenchimento de "água com gás" dos
protótipos é uma textura sobre os glifos. Reproduzo com fonte redonda + sombra
interna e (se necessário) um `ShaderMask` com textura de bolhas. Fica *próximo*,
não pixel-perfect; refino iterativo no preview.

## 5. As três telas (fiéis aos protótipos)

### 5.1 Splash (`/splash`)
- `MenthicScaffold` (textura + blobs neumórficos: anéis com círculo mint afundado).
- `DisplayTitle("Menthic")` centralizado-alto.
- Círculo central mint afundado com progresso "0%→100%" (contador simples animado).
- Rodapé "By Munhoz" em `neutralGray`.
- Após ~2s (ou fim do "load"), redireciona por `LocalAuth.logged_in`.

### 5.2 Login (`/login`)
- `GlassCard` central com: título "Menthic", labels "email:"/"senha:",
  dois `PillField`, divisor "ou", `GoogleButton`, botão circular `NeuInset`
  "Entrar", e pílula "Não possuo conta" → `/cadastro`.
- "Entrar" → `LocalAuth.signIn` → `/home`.
- Rodapé "By Munhoz".

### 5.3 Cadastro (`/cadastro`)
- Igual ao Login com **4** `PillField` (email, senha, Confirmar Senha, Telefone),
  "ou" + `GoogleButton`, pílula grande "Cadastar" (texto do protótipo mantido),
  e pílula "já possuo conta" → `/login`.
- "Cadastar" → valida (senha == confirmação) → `LocalAuth.signUp` → `/home`.

### 5.4 Home placeholder (`/home`)
- `MenthicScaffold` + `GlassCard` com "Bem-vindo" e um botão "Sair"
  (`LocalAuth.signOut` → `/login`). Só prova o shell; render do `OracleAnswer`
  vem na próxima leva.

## 6. Estratégia de verificação

- **Preview visual no Chrome:** `flutter run -d chrome` — comparar cada tela lado a
  lado com o PNG do protótipo correspondente.
- **Widget tests** para o comportamento (não o pixel):
  - Splash redireciona conforme `logged_in`.
  - Login com credenciais válidas navega p/ `/home`; "Não possuo conta" vai p/ `/cadastro`.
  - Cadastro com senhas divergentes bloqueia; iguais navegam p/ `/home`.
  - `LocalAuth` grava/lê/limpa sessão (fake `SharedPreferences`).
- **`flutter analyze` limpo** e `dart format`.
- Design system: uma tela-galeria interna (debug) que renderiza cada widget base
  isolado, para validar glass/neu antes de compor as telas.

## 7. Fora de escopo / próximas levas

Reusando este design system, as specs seguintes cobrem: Onboarding/cold-start,
Home real (`OracleAnswer` ↔ engine), Adicionar compromisso, Simular, Revisão
noturna, Meu Twin, Calibração, Objetivos (pesos de utilidade), Configurações/
Privacidade, Esqueci a senha, e o shell de navegação (bottom nav). ~14 telas.

## 8. Como amarra o resto do projeto

- Consome o contrato `OracleAnswer` (doc 2/6) — a Home real será o render do §6 do doc 06.
- Respeita local-first (doc 07): nenhum dado sai do dispositivo nesta leva.
- É a "UI crua" que a Fase 0/1 do roadmap (doc 08) pede para tornar o núcleo
  headless utilizável e, adiante, rodar o experimento N=1.
