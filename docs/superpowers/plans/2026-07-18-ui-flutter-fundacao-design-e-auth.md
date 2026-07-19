# UI Flutter — Fundação (Design System + Splash/Login/Cadastro) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Criar o app Flutter `app/` com um design system glass+neumorphism (paleta mint fiel aos protótipos) e as três telas de entrada (Splash, Login, Cadastro) com auth stub local, rodando no Chrome.

**Architecture:** Novo pacote Flutter na raiz consome os 4 pacotes Dart headless por `path`. Um design system em `lib/design/` (tokens + widgets base) é a fonte única do visual; cada tela se compõe desses widgets. Auth é um serviço local (`shared_preferences`) sem backend. Navegação por `go_router`, estado por `flutter_riverpod`.

**Tech Stack:** Flutter 3.32.4 · Dart 3.8.1 · go_router · flutter_riverpod · shared_preferences · google_fonts (Fredoka display, Nunito corpo).

## Global Constraints

- Flutter stable ≥ 3.32.4; Dart ≥ 3.8.1. Alvo de dev: **Chrome/Web** (`-d chrome`).
- Os 4 pacotes em `engine/`, `store/`, `calibration/`, `learning/` **não são modificados**.
- Nenhum widget referencia cor hex direto — só tokens de `design/tokens.dart`.
- Paleta exata (fiel ao protótipo): `mint #7BCCD1`, `cyanLight #A2F7FD`, `mintDeep #6CB7BC`, `highlight #DCFDFF`, `blueAccent #42C8ED`, `neutralGray #9F9C9C`.
- Auth é **stub local** sem rede; não é sistema de segurança real.
- `flutter analyze` limpo e `dart format .` aplicado ao fim de cada task.
- Fontes via `google_fonts` (Fredoka/Nunito) nesta leva; bundle offline (spec §4.2) fica p/ hardening de Android — **desvio consciente do spec** para reduzir fragilidade.
- Textos dos protótipos mantidos como estão, incluindo "Cadastar" e "Não possuo conta".

---

### Task 1: Scaffold do app Flutter + wiring dos pacotes + roda no Chrome

**Files:**
- Create: `app/` (projeto Flutter via CLI)
- Modify: `app/pubspec.yaml`
- Modify: `.gitignore` (ignorar build/ e .dart_tool do app)
- Test: `app/test/smoke_test.dart`

**Interfaces:**
- Produces: pacote Flutter `menthic` compilável; deps `go_router`, `flutter_riverpod`, `shared_preferences`, `google_fonts` disponíveis; `oracle_engine`/`oracle_store`/`oracle_calibration`/`oracle_learning` resolvidos por path.

- [ ] **Step 1: Criar o projeto Flutter**

Run (a partir da raiz `C:\Users\Ppica\Menthic`):
```bash
flutter create --platforms=web,android --org com.munhoz --project-name menthic app
```
Expected: cria `app/` com estrutura padrão; termina com "All done!".

- [ ] **Step 2: Reescrever `app/pubspec.yaml`**

```yaml
name: menthic
description: "Project Oracle — Menthic: UI Flutter."
publish_to: 'none'
version: 0.1.0

environment:
  sdk: ^3.8.1

dependencies:
  flutter:
    sdk: flutter
  go_router: ^14.2.0
  flutter_riverpod: ^2.5.1
  shared_preferences: ^2.3.2
  google_fonts: ^6.2.1
  oracle_engine:
    path: ../engine
  oracle_store:
    path: ../store
  oracle_calibration:
    path: ../calibration
  oracle_learning:
    path: ../learning

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/textures/
    - assets/img/
```

- [ ] **Step 3: Instalar dependências**

Run: `cd app && flutter pub get`
Expected: "Got dependencies!" sem erros de resolução (os pacotes path devem ter `environment: sdk` compatível — já têm).

- [ ] **Step 4: Escrever o smoke test**

Substitua `app/test/widget_test.dart` por `app/test/smoke_test.dart` (apague o antigo):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app builds a MaterialApp', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('menthic'))),
    );
    expect(find.text('menthic'), findsOneWidget);
  });
}
```
Run: `rm app/test/widget_test.dart`

- [ ] **Step 5: Rodar o teste**

Run: `cd app && flutter test`
Expected: PASS (1 test).

- [ ] **Step 6: Confirmar que compila no Chrome**

Run: `cd app && flutter build web --no-tree-shake-icons`
Expected: "✓ Built build/web" sem erros.

- [ ] **Step 7: Ajustar `.gitignore` da raiz** (adicione ao final, se ainda não cobrir):
```
app/build/
app/.dart_tool/
app/.flutter-plugins
app/.flutter-plugins-dependencies
```

- [ ] **Step 8: Commit**
```bash
git add app .gitignore
git commit -m "feat(app): scaffold Flutter menthic ligado aos 4 pacotes headless"
```

---

### Task 2: Extrair textura de fundo e logo do Google dos SVGs

**Files:**
- Create: `app/assets/textures/paper.jpg`
- Create: `app/assets/img/google_g.png`
- Create (temp): `scripts/extract_svg_assets.mjs` (script node, commitado p/ reprodutibilidade)

**Interfaces:**
- Produces: asset `assets/textures/paper.jpg` (fundo) e `assets/img/google_g.png` (logo do botão Google).

- [ ] **Step 1: Escrever o extractor**

Create `scripts/extract_svg_assets.mjs`:
```javascript
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';

function firstDataUri(svgPath, mime) {
  const svg = readFileSync(svgPath, 'utf8');
  const re = new RegExp(`data:image/${mime};base64,([A-Za-z0-9+/=]+)`);
  const m = svg.match(re);
  if (!m) throw new Error(`no ${mime} in ${svgPath}`);
  return Buffer.from(m[1], 'base64');
}

mkdirSync('app/assets/textures', { recursive: true });
mkdirSync('app/assets/img', { recursive: true });

const jpg = firstDataUri('engine/lib/src/spalsh screenM.svg', 'jpeg');
writeFileSync('app/assets/textures/paper.jpg', jpg);
console.log('paper.jpg', jpg.length, 'bytes');

const png = firstDataUri('engine/lib/src/Login M.svg', 'png');
writeFileSync('app/assets/img/google_g.png', png);
console.log('google_g.png', png.length, 'bytes');
```

- [ ] **Step 2: Rodar o extractor**

Run (da raiz): `node scripts/extract_svg_assets.mjs`
Expected: imprime "paper.jpg <N> bytes" e "google_g.png <N> bytes" com N > 1000.

- [ ] **Step 3: Verificar os arquivos**

Run: `ls -la app/assets/textures/paper.jpg app/assets/img/google_g.png`
Expected: ambos existem e não vazios.

- [ ] **Step 4: Commit**
```bash
git add scripts/extract_svg_assets.mjs app/assets
git commit -m "chore(app): extrai textura de fundo e logo Google dos SVGs para assets"
```

---

### Task 3: Tokens de design e tema

**Files:**
- Create: `app/lib/design/tokens.dart`
- Create: `app/lib/design/theme.dart`
- Test: `app/test/design/tokens_test.dart`

**Interfaces:**
- Produces: `class MColors` (mint, cyanLight, mintDeep, highlight, blueAccent, neutralGray, shadowDark), `class MRadius` (pill, card=22), `class MSpace` (xs..xl), `class MBlur` (glass=18, neu=8), `ThemeData menthicTheme()`.

- [ ] **Step 1: Escrever o teste dos tokens**

Create `app/test/design/tokens_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menthic/design/tokens.dart';

void main() {
  test('paleta fiel ao protótipo', () {
    expect(MColors.mint, const Color(0xFF7BCCD1));
    expect(MColors.cyanLight, const Color(0xFFA2F7FD));
    expect(MColors.mintDeep, const Color(0xFF6CB7BC));
    expect(MColors.highlight, const Color(0xFFDCFDFF));
    expect(MColors.blueAccent, const Color(0xFF42C8ED));
    expect(MColors.neutralGray, const Color(0xFF9F9C9C));
  });

  test('raio do card = 22 (protótipo)', () {
    expect(MRadius.card, 22.0);
  });
}
```

- [ ] **Step 2: Rodar (deve falhar)**

Run: `cd app && flutter test test/design/tokens_test.dart`
Expected: FAIL — "Target of URI doesn't exist: 'package:menthic/design/tokens.dart'".

- [ ] **Step 3: Escrever os tokens**

Create `app/lib/design/tokens.dart`:
```dart
import 'package:flutter/material.dart';

/// Paleta exata extraída dos protótipos SVG. Nenhum widget usa hex direto.
abstract final class MColors {
  static const mint = Color(0xFF7BCCD1);
  static const cyanLight = Color(0xFFA2F7FD);
  static const mintDeep = Color(0xFF6CB7BC);
  static const highlight = Color(0xFFDCFDFF);
  static const blueAccent = Color(0xFF42C8ED);
  static const neutralGray = Color(0xFF9F9C9C);

  /// Sombra escura do neumorphism (derivada do mintDeep, mais fechada).
  static const shadowDark = Color(0x33456B6E);

  /// Fill do vidro: cyanLight a 20% (fill-opacity="0.2" no SVG).
  static Color get glassFill => cyanLight.withValues(alpha: 0.20);
  static Color get glassBorder => Colors.white.withValues(alpha: 0.35);
}

abstract final class MRadius {
  static const pill = 36.5; // rx dos botões-pílula no SVG
  static const card = 22.0; // rx do card de vidro no SVG
  static const blob = 999.0;
}

abstract final class MSpace {
  static const xs = 6.0;
  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 28.0;
  static const xl = 40.0;
}

abstract final class MBlur {
  static const glass = 18.0; // sigma do BackdropFilter do card
  static const neu = 8.0; // blur das sombras neumórficas
}
```

- [ ] **Step 4: Escrever o tema**

Create `app/lib/design/theme.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

ThemeData menthicTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: MColors.mint,
      primary: MColors.mint,
      surface: MColors.cyanLight,
    ),
    scaffoldBackgroundColor: MColors.cyanLight,
  );
  return base.copyWith(
    textTheme: GoogleFonts.nunitoTextTheme(base.textTheme),
  );
}

/// Estilo do título "bolha" (Fredoka), aproximação da tipografia do protótipo.
TextStyle displayTitleStyle(double size) => GoogleFonts.fredoka(
  fontSize: size,
  fontWeight: FontWeight.w700,
  color: MColors.mint,
  shadows: const [
    Shadow(color: MColors.mintDeep, offset: Offset(1, 2), blurRadius: 2),
    Shadow(color: MColors.highlight, offset: Offset(-1, -1), blurRadius: 1),
  ],
);
```

- [ ] **Step 5: Rodar (deve passar)**

Run: `cd app && flutter test test/design/tokens_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Format + analyze + commit**
```bash
cd app && dart format . && flutter analyze
git add app/lib/design app/test/design
git commit -m "feat(design): tokens da paleta mint + tema (Fredoka/Nunito)"
```

---

### Task 4: Primitivas neumórficas (NeuButton e NeuInset)

**Files:**
- Create: `app/lib/design/neumorphic.dart`
- Test: `app/test/design/neumorphic_test.dart`

**Interfaces:**
- Consumes: `MColors`, `MRadius`, `MBlur` de `tokens.dart`.
- Produces:
  - `NeuButton({required Widget child, VoidCallback? onTap, double radius, EdgeInsets padding, Color? color})` — superfície **em relevo**.
  - `NeuInset({required Widget child, double radius, EdgeInsets padding, Color? color})` — superfície **afundada** (inner-shadow via CustomPainter).

- [ ] **Step 1: Escrever o teste**

Create `app/test/design/neumorphic_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menthic/design/neumorphic.dart';

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('NeuButton chama onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(NeuButton(onTap: () => taps++, child: const Text('ok'))),
    );
    await tester.tap(find.text('ok'));
    expect(taps, 1);
  });

  testWidgets('NeuInset renderiza o filho', (tester) async {
    await tester.pumpWidget(_host(const NeuInset(child: Text('dentro'))));
    expect(find.text('dentro'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Rodar (deve falhar)**

Run: `cd app && flutter test test/design/neumorphic_test.dart`
Expected: FAIL — URI de `neumorphic.dart` não existe.

- [ ] **Step 3: Implementar as primitivas**

Create `app/lib/design/neumorphic.dart`:
```dart
import 'package:flutter/material.dart';
import 'tokens.dart';

/// Superfície em relevo: sombra clara em cima-esquerda, escura embaixo-direita.
class NeuButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final EdgeInsets padding;
  final Color? color;
  const NeuButton({
    super.key,
    required this.child,
    this.onTap,
    this.radius = MRadius.pill,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? MColors.mint,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: const [
            BoxShadow(
              color: MColors.highlight,
              offset: Offset(-4, -4),
              blurRadius: MBlur.neu,
            ),
            BoxShadow(
              color: MColors.shadowDark,
              offset: Offset(5, 6),
              blurRadius: MBlur.neu + 2,
            ),
          ],
        ),
        child: Center(widthFactor: 1, heightFactor: 1, child: child),
      ),
    );
  }
}

/// Superfície afundada: inner-shadow desenhada por CustomPainter
/// (Flutter não tem BoxShadow interno nativo).
class NeuInset extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final Color? color;
  const NeuInset({
    super.key,
    required this.child,
    this.radius = MRadius.pill,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _InsetPainter(
        base: color ?? MColors.mintDeep,
        radius: radius,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _InsetPainter extends CustomPainter {
  final Color base;
  final double radius;
  _InsetPainter({required this.base, required this.radius});

  void _innerShadow(
    Canvas c,
    RRect rrect,
    Color color,
    Offset offset,
    double blur,
  ) {
    c.save();
    c.clipRRect(rrect);
    final bounds = rrect.outerRect.inflate(blur * 3 + offset.distance);
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(bounds)
      ..addRRect(rrect.shift(offset));
    final paint = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    c.drawPath(path, paint);
    c.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas.drawRRect(rrect, Paint()..color = base);
    // Sombra escura vinda de cima-esquerda (afunda o topo).
    _innerShadow(
      canvas,
      rrect,
      MColors.shadowDark,
      const Offset(4, 4),
      MBlur.neu,
    );
    // Luz vinda de baixo-direita.
    _innerShadow(
      canvas,
      rrect,
      MColors.highlight.withValues(alpha: 0.6),
      const Offset(-3, -3),
      MBlur.neu,
    );
  }

  @override
  bool shouldRepaint(_InsetPainter old) =>
      old.base != base || old.radius != radius;
}
```

- [ ] **Step 4: Rodar (deve passar)**

Run: `cd app && flutter test test/design/neumorphic_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Format + analyze + commit**
```bash
cd app && dart format . && flutter analyze
git add app/lib/design/neumorphic.dart app/test/design/neumorphic_test.dart
git commit -m "feat(design): primitivas neumórficas NeuButton (relevo) e NeuInset (afundado)"
```

---

### Task 5: Widgets de vidro e cenário (GlassCard, MenthicScaffold, FloatingBlobs, DisplayTitle, PillField, GoogleButton)

**Files:**
- Create: `app/lib/design/glass.dart` (GlassCard)
- Create: `app/lib/design/scaffold.dart` (MenthicScaffold + FloatingBlobs)
- Create: `app/lib/design/widgets.dart` (DisplayTitle, PillField, GoogleButton)
- Create: `app/lib/design/design.dart` (barrel export)
- Test: `app/test/design/widgets_test.dart`

**Interfaces:**
- Consumes: `tokens.dart`, `theme.dart` (`displayTitleStyle`), `neumorphic.dart` (`NeuInset`).
- Produces:
  - `GlassCard({required Widget child, EdgeInsets padding, double radius})`
  - `MenthicScaffold({required Widget child, bool blobs})`
  - `FloatingBlobs()`
  - `DisplayTitle(String text, {double size})`
  - `PillField({required String label, required TextEditingController controller, bool obscure, TextInputType? keyboardType})`
  - `GoogleButton({VoidCallback? onTap})`
  - barrel `design/design.dart` reexportando tokens/theme/neumorphic/glass/scaffold/widgets.

- [ ] **Step 1: Escrever o teste**

Create `app/test/design/widgets_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menthic/design/design.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('MenthicScaffold + GlassCard renderizam o filho', (tester) async {
    await tester.pumpWidget(
      _host(
        const MenthicScaffold(
          child: GlassCard(child: Text('conteúdo')),
        ),
      ),
    );
    expect(find.text('conteúdo'), findsOneWidget);
  });

  testWidgets('DisplayTitle mostra o texto', (tester) async {
    await tester.pumpWidget(_host(const DisplayTitle('Menthic')));
    expect(find.text('Menthic'), findsOneWidget);
  });

  testWidgets('PillField digita e obscurece', (tester) async {
    final ctrl = TextEditingController();
    await tester.pumpWidget(
      _host(PillField(label: 'senha:', controller: ctrl, obscure: true)),
    );
    await tester.enterText(find.byType(TextField), 'segredo');
    expect(ctrl.text, 'segredo');
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.obscureText, true);
  });

  testWidgets('GoogleButton chama onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(GoogleButton(onTap: () => taps++)));
    await tester.tap(find.textContaining('Google'));
    expect(taps, 1);
  });
}
```

- [ ] **Step 2: Rodar (deve falhar)**

Run: `cd app && flutter test test/design/widgets_test.dart`
Expected: FAIL — URI de `design/design.dart` não existe.

- [ ] **Step 3: Implementar GlassCard**

Create `app/lib/design/glass.dart`:
```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'tokens.dart';

/// Card de vidro fosco: blur do fundo + fill translúcido + borda clara + sombra.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(MSpace.lg),
    this.radius = MRadius.card,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: MColors.shadowDark,
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: MBlur.glass, sigmaY: MBlur.glass),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: MColors.glassFill,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: MColors.glassBorder, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Implementar MenthicScaffold + FloatingBlobs**

Create `app/lib/design/scaffold.dart`:
```dart
import 'package:flutter/material.dart';
import 'tokens.dart';
import 'neumorphic.dart';

/// Base de toda tela: textura de fundo + blobs decorativos + conteúdo.
class MenthicScaffold extends StatelessWidget {
  final Widget child;
  final bool blobs;
  const MenthicScaffold({super.key, required this.child, this.blobs = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/textures/paper.jpg', fit: BoxFit.cover),
          if (blobs) const FloatingBlobs(),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

/// Círculos mint flutuantes; alguns são anéis com miolo afundado (protótipo).
class FloatingBlobs extends StatelessWidget {
  const FloatingBlobs({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        Widget ring(double size) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MColors.mint.withValues(alpha: 0.25),
          ),
          child: Center(
            child: NeuInset(
              radius: MRadius.blob,
              padding: EdgeInsets.all(size * 0.14),
              color: MColors.mint,
              child: SizedBox(width: size * 0.5, height: size * 0.5),
            ),
          ),
        );
        Widget dot(double size, double opacity) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MColors.mint.withValues(alpha: opacity),
          ),
        );
        return Stack(
          children: [
            Positioned(left: w * 0.28, top: h * 0.06, child: dot(40, 0.5)),
            Positioned(left: w * 0.18, top: h * 0.58, child: ring(150)),
            Positioned(right: w * 0.10, top: h * 0.34, child: dot(120, 0.18)),
            Positioned(left: w * 0.08, bottom: h * 0.14, child: dot(120, 0.2)),
            Positioned(right: w * 0.12, bottom: h * 0.10, child: ring(150)),
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 5: Implementar DisplayTitle, PillField, GoogleButton**

Create `app/lib/design/widgets.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';
import 'theme.dart';
import 'neumorphic.dart';

/// Título "bolha" — aproximação da tipografia do protótipo.
class DisplayTitle extends StatelessWidget {
  final String text;
  final double size;
  const DisplayTitle(this.text, {super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: displayTitleStyle(size));
  }
}

/// Rótulo mint + campo afundado (NeuInset) com TextField sem borda.
class PillField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  const PillField({
    super.key,
    required this.label,
    required this.controller,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.fredoka(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: MColors.mintDeep,
            ),
          ),
        ),
        NeuInset(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            style: GoogleFonts.nunito(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isCollapsed: true,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

/// Pílula branca "Continuar com o Google" (logo extraído do SVG).
class GoogleButton extends StatelessWidget {
  final VoidCallback? onTap;
  const GoogleButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return NeuButton(
      onTap: onTap,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/img/google_g.png', width: 24, height: 24),
          const SizedBox(width: 12),
          Text(
            'Continuar com o Google',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Criar o barrel export**

Create `app/lib/design/design.dart`:
```dart
export 'tokens.dart';
export 'theme.dart';
export 'neumorphic.dart';
export 'glass.dart';
export 'scaffold.dart';
export 'widgets.dart';
```

- [ ] **Step 7: Rodar (deve passar)**

Run: `cd app && flutter test test/design/widgets_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 8: Format + analyze + commit**
```bash
cd app && dart format . && flutter analyze
git add app/lib/design app/test/design/widgets_test.dart
git commit -m "feat(design): GlassCard, MenthicScaffold+blobs, DisplayTitle, PillField, GoogleButton"
```

---

### Task 6: Serviço de auth local (LocalAuth) + provider

**Files:**
- Create: `app/lib/features/auth/local_auth.dart`
- Test: `app/test/features/auth/local_auth_test.dart`

**Interfaces:**
- Consumes: `shared_preferences`, `flutter_riverpod`.
- Produces:
  - `class LocalAuth` com `Future<bool> isLoggedIn()`, `Future<void> signIn(String email, String password)`, `Future<void> signUp({required String email, required String password, required String confirm, required String phone})`, `Future<void> signInWithGoogle()`, `Future<void> signOut()`, `Future<String?> currentEmail()`.
  - Lança `AuthException(String message)` em validação inválida.
  - `final localAuthProvider = Provider<LocalAuth>((ref) => LocalAuth());`

- [ ] **Step 1: Escrever o teste**

Create `app/test/features/auth/local_auth_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menthic/features/auth/local_auth.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('estado inicial: não logado', () async {
    expect(await LocalAuth().isLoggedIn(), false);
  });

  test('signIn válido loga e guarda email', () async {
    final auth = LocalAuth();
    await auth.signIn('a@b.com', 'segredo');
    expect(await auth.isLoggedIn(), true);
    expect(await auth.currentEmail(), 'a@b.com');
  });

  test('signIn com senha curta lança AuthException', () async {
    expect(
      () => LocalAuth().signIn('a@b.com', '123'),
      throwsA(isA<AuthException>()),
    );
  });

  test('signUp com confirmação divergente lança AuthException', () async {
    expect(
      () => LocalAuth().signUp(
        email: 'a@b.com',
        password: 'segredo',
        confirm: 'outra',
        phone: '11999',
      ),
      throwsA(isA<AuthException>()),
    );
  });

  test('signUp válido loga', () async {
    final auth = LocalAuth();
    await auth.signUp(
      email: 'a@b.com',
      password: 'segredo',
      confirm: 'segredo',
      phone: '11999',
    );
    expect(await auth.isLoggedIn(), true);
  });

  test('signOut desloga', () async {
    final auth = LocalAuth();
    await auth.signIn('a@b.com', 'segredo');
    await auth.signOut();
    expect(await auth.isLoggedIn(), false);
  });
}
```

- [ ] **Step 2: Rodar (deve falhar)**

Run: `cd app && flutter test test/features/auth/local_auth_test.dart`
Expected: FAIL — URI de `local_auth.dart` não existe.

- [ ] **Step 3: Implementar LocalAuth**

Create `app/lib/features/auth/local_auth.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Auth stub LOCAL — sem backend, sem rede. Portão local até existir servidor.
/// Não é um sistema de segurança: não valida credenciais contra nada.
class LocalAuth {
  static const _kLogged = 'logged_in';
  static const _kEmail = 'user_email';

  Future<bool> isLoggedIn() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kLogged) ?? false;
  }

  Future<String?> currentEmail() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kEmail);
  }

  Future<void> signIn(String email, String password) async {
    if (!email.contains('@')) throw AuthException('E-mail inválido.');
    if (password.length < 6) {
      throw AuthException('Senha precisa de ao menos 6 caracteres.');
    }
    await _persist(email);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String confirm,
    required String phone,
  }) async {
    if (!email.contains('@')) throw AuthException('E-mail inválido.');
    if (password.length < 6) {
      throw AuthException('Senha precisa de ao menos 6 caracteres.');
    }
    if (password != confirm) throw AuthException('As senhas não conferem.');
    await _persist(email);
  }

  Future<void> signInWithGoogle() async {
    // Stub visual: sem SDK real do Google.
    await _persist('google_user@local');
  }

  Future<void> signOut() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kLogged);
    await p.remove(_kEmail);
  }

  Future<void> _persist(String email) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kLogged, true);
    await p.setString(_kEmail, email);
  }
}

final localAuthProvider = Provider<LocalAuth>((ref) => LocalAuth());
```

- [ ] **Step 4: Rodar (deve passar)**

Run: `cd app && flutter test test/features/auth/local_auth_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5: Format + analyze + commit**
```bash
cd app && dart format . && flutter analyze
git add app/lib/features/auth/local_auth.dart app/test/features/auth
git commit -m "feat(auth): LocalAuth stub local (shared_preferences) + provider"
```

---

### Task 7: Router (go_router) + bootstrap do app

**Files:**
- Create: `app/lib/router.dart`
- Create: `app/lib/features/home/home_screen.dart` (placeholder mínimo, expandido na Task 11)
- Create: `app/lib/features/auth/splash_screen.dart` (placeholder mínimo, expandido na Task 8)
- Create: `app/lib/features/auth/login_screen.dart` (placeholder mínimo, expandido na Task 9)
- Create: `app/lib/features/auth/cadastro_screen.dart` (placeholder mínimo, expandido na Task 10)
- Modify: `app/lib/main.dart`
- Test: `app/test/router_test.dart`

**Interfaces:**
- Consumes: telas das features.
- Produces: `GoRouter menthicRouter` com rotas nomeadas `splash` (`/`), `login` (`/login`), `cadastro` (`/cadastro`), `home` (`/home`). `main()` roda `ProviderScope(child: MenthicApp())`.

- [ ] **Step 1: Escrever placeholders mínimos das 4 telas** (serão substituídas nas tasks seguintes)

Create `app/lib/features/auth/splash_screen.dart`:
```dart
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('splash')));
}
```

Create `app/lib/features/auth/login_screen.dart`:
```dart
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('login')));
}
```

Create `app/lib/features/auth/cadastro_screen.dart`:
```dart
import 'package:flutter/material.dart';

class CadastroScreen extends StatelessWidget {
  const CadastroScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('cadastro')));
}
```

Create `app/lib/features/home/home_screen.dart`:
```dart
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('home')));
}
```

- [ ] **Step 2: Escrever o router**

Create `app/lib/router.dart`:
```dart
import 'package:go_router/go_router.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/cadastro_screen.dart';
import 'features/home/home_screen.dart';

final menthicRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/cadastro',
      name: 'cadastro',
      builder: (context, state) => const CadastroScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);
```

- [ ] **Step 3: Reescrever main.dart**

Replace `app/lib/main.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'design/theme.dart';
import 'router.dart';

void main() => runApp(const ProviderScope(child: MenthicApp()));

class MenthicApp extends StatelessWidget {
  const MenthicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Menthic',
      debugShowCheckedModeBanner: false,
      theme: menthicTheme(),
      routerConfig: menthicRouter,
    );
  }
}
```

- [ ] **Step 4: Escrever o teste do router**

Create `app/test/router_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:menthic/router.dart';

void main() {
  test('router tem as 4 rotas nomeadas', () {
    final names = menthicRouter.configuration.routes
        .whereType<GoRoute>()
        .map((r) => r.name)
        .toSet();
    expect(names, {'splash', 'login', 'cadastro', 'home'});
  });

  testWidgets('rota inicial mostra a splash', (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: menthicRouter),
    );
    expect(find.text('splash'), findsOneWidget);
  });
}
```

- [ ] **Step 5: Rodar (deve passar)**

Run: `cd app && flutter test test/router_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Format + analyze + commit**
```bash
cd app && dart format . && flutter analyze
git add app/lib/router.dart app/lib/main.dart app/lib/features app/test/router_test.dart
git commit -m "feat(app): go_router (splash/login/cadastro/home) + bootstrap Riverpod"
```

---

### Task 8: Tela Splash (fiel ao protótipo) + redirect

**Files:**
- Modify: `app/lib/features/auth/splash_screen.dart`
- Test: `app/test/features/auth/splash_test.dart`

**Interfaces:**
- Consumes: `design/design.dart`, `localAuthProvider`, `go_router`.
- Produces: `SplashScreen` (ConsumerStatefulWidget) que, após load, navega p/ `home` se logado, senão `login`.

- [ ] **Step 1: Escrever o teste**

Create `app/test/features/auth/splash_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menthic/features/auth/splash_screen.dart';
import 'package:menthic/features/auth/login_screen.dart';
import 'package:menthic/features/home/home_screen.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (c, s) => const SplashScreen()),
    GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
    GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
  ],
);

void main() {
  testWidgets('deslogado → vai para login', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: _router())),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('logado → vai para home', (tester) async {
    SharedPreferences.setMockInitialValues({'logged_in': true});
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: _router())),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
```

- [ ] **Step 2: Rodar (deve falhar)**

Run: `cd app && flutter test test/features/auth/splash_test.dart`
Expected: FAIL — a splash placeholder não navega.

- [ ] **Step 3: Implementar a Splash**

Replace `app/lib/features/auth/splash_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../design/design.dart';
import 'local_auth.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) async {
      if (s == AnimationStatus.completed && mounted) {
        final logged = await ref.read(localAuthProvider).isLoggedIn();
        if (!mounted) return;
        context.goNamed(logged ? 'home' : 'login');
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MenthicScaffold(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const SizedBox(height: MSpace.xl),
          const DisplayTitle('Menthic', size: 60),
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) => NeuInset(
              radius: MRadius.blob,
              padding: const EdgeInsets.all(48),
              color: MColors.mint,
              child: Text(
                '${(_c.value * 100).round()}%',
                style: displayTitleStyle(40),
              ),
            ),
          ),
          Text(
            'By Munhoz',
            style: TextStyle(
              color: MColors.neutralGray,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Rodar (deve passar)**

Run: `cd app && flutter test test/features/auth/splash_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Format + analyze + commit**
```bash
cd app && dart format . && flutter analyze
git add app/lib/features/auth/splash_screen.dart app/test/features/auth/splash_test.dart
git commit -m "feat(auth): tela Splash (título bolha + progresso afundado) com redirect por sessão"
```

---

### Task 9: Tela Login (fiel ao protótipo)

**Files:**
- Modify: `app/lib/features/auth/login_screen.dart`
- Test: `app/test/features/auth/login_test.dart`

**Interfaces:**
- Consumes: `design/design.dart`, `localAuthProvider`, `go_router`.
- Produces: `LoginScreen` que autentica via `LocalAuth.signIn` → `home`; link "Não possuo conta" → `cadastro`.

- [ ] **Step 1: Escrever o teste**

Create `app/test/features/auth/login_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menthic/features/auth/login_screen.dart';
import 'package:menthic/features/auth/cadastro_screen.dart';
import 'package:menthic/features/home/home_screen.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
    GoRoute(path: '/cadastro', builder: (c, s) => const CadastroScreen()),
    GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
  ],
);

Future<void> _pump(WidgetTester t) async {
  SharedPreferences.setMockInitialValues({});
  await t.pumpWidget(
    ProviderScope(child: MaterialApp.router(routerConfig: _router())),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets('login válido navega para home', (tester) async {
    await _pump(tester);
    await tester.enterText(find.byType(TextField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextField).at(1), 'segredo');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('link "Não possuo conta" vai para cadastro', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Não possuo conta'));
    await tester.pumpAndSettle();
    expect(find.byType(CadastroScreen), findsOneWidget);
  });

  testWidgets('senha curta mostra erro e não navega', (tester) async {
    await _pump(tester);
    await tester.enterText(find.byType(TextField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextField).at(1), '123');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.textContaining('6 caracteres'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Rodar (deve falhar)**

Run: `cd app && flutter test test/features/auth/login_test.dart`
Expected: FAIL — placeholder não tem campos/botões.

- [ ] **Step 3: Implementar o Login**

Replace `app/lib/features/auth/login_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../design/design.dart';
import 'local_auth.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _senha = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    try {
      await ref.read(localAuthProvider).signIn(_email.text, _senha.text);
      if (mounted) context.goNamed('home');
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MenthicScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: MSpace.md),
            const DisplayTitle('Menthic'),
            const SizedBox(height: MSpace.md),
            GlassCard(
              child: Column(
                children: [
                  PillField(label: 'email:', controller: _email),
                  const SizedBox(height: MSpace.md),
                  PillField(
                    label: 'senha:',
                    controller: _senha,
                    obscure: true,
                  ),
                  const SizedBox(height: MSpace.sm),
                  Text('ou', style: displayTitleStyle(22)),
                  const SizedBox(height: MSpace.sm),
                  GoogleButton(
                    onTap: () async {
                      await ref.read(localAuthProvider).signInWithGoogle();
                      if (context.mounted) context.goNamed('home');
                    },
                  ),
                  const SizedBox(height: MSpace.lg),
                  NeuButton(
                    onTap: _submit,
                    radius: MRadius.blob,
                    padding: const EdgeInsets.all(56),
                    child: Text('Entrar', style: displayTitleStyle(34)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MSpace.md),
            NeuButton(
              onTap: () => context.goNamed('cadastro'),
              color: MColors.cyanLight,
              child: Text(
                'Não possuo conta',
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: MColors.mintDeep,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: MSpace.md),
            Text(
              'By Munhoz',
              style: TextStyle(
                color: MColors.neutralGray,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Rodar (deve passar)**

Run: `cd app && flutter test test/features/auth/login_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Format + analyze + commit**
```bash
cd app && dart format . && flutter analyze
git add app/lib/features/auth/login_screen.dart app/test/features/auth/login_test.dart
git commit -m "feat(auth): tela Login (glass + pill fields + Entrar) ligada ao LocalAuth"
```

---

### Task 10: Tela Cadastro (fiel ao protótipo)

**Files:**
- Modify: `app/lib/features/auth/cadastro_screen.dart`
- Test: `app/test/features/auth/cadastro_test.dart`

**Interfaces:**
- Consumes: `design/design.dart`, `localAuthProvider`, `go_router`.
- Produces: `CadastroScreen` com 4 campos; `signUp` → `home`; "já possuo conta" → `login`.

- [ ] **Step 1: Escrever o teste**

Create `app/test/features/auth/cadastro_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menthic/features/auth/cadastro_screen.dart';
import 'package:menthic/features/auth/login_screen.dart';
import 'package:menthic/features/home/home_screen.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/cadastro',
  routes: [
    GoRoute(path: '/cadastro', builder: (c, s) => const CadastroScreen()),
    GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
    GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
  ],
);

Future<void> _pump(WidgetTester t) async {
  SharedPreferences.setMockInitialValues({});
  await t.pumpWidget(
    ProviderScope(child: MaterialApp.router(routerConfig: _router())),
  );
  await t.pumpAndSettle();
}

Future<void> _fill(WidgetTester t, String senha, String confirm) async {
  await t.enterText(find.byType(TextField).at(0), 'a@b.com');
  await t.enterText(find.byType(TextField).at(1), senha);
  await t.enterText(find.byType(TextField).at(2), confirm);
  await t.enterText(find.byType(TextField).at(3), '11999');
}

void main() {
  testWidgets('senhas divergentes bloqueiam', (tester) async {
    await _pump(tester);
    await _fill(tester, 'segredo', 'outra');
    await tester.tap(find.text('Cadastar'));
    await tester.pumpAndSettle();
    expect(find.byType(CadastroScreen), findsOneWidget);
    expect(find.textContaining('não conferem'), findsOneWidget);
  });

  testWidgets('cadastro válido navega para home', (tester) async {
    await _pump(tester);
    await _fill(tester, 'segredo', 'segredo');
    await tester.tap(find.text('Cadastar'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('"já possuo conta" vai para login', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('já possuo conta'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
```

- [ ] **Step 2: Rodar (deve falhar)**

Run: `cd app && flutter test test/features/auth/cadastro_test.dart`
Expected: FAIL — placeholder não tem campos.

- [ ] **Step 3: Implementar o Cadastro**

Replace `app/lib/features/auth/cadastro_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../design/design.dart';
import 'local_auth.dart';

class CadastroScreen extends ConsumerStatefulWidget {
  const CadastroScreen({super.key});
  @override
  ConsumerState<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends ConsumerState<CadastroScreen> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirm = TextEditingController();
  final _fone = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    _confirm.dispose();
    _fone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    try {
      await ref
          .read(localAuthProvider)
          .signUp(
            email: _email.text,
            password: _senha.text,
            confirm: _confirm.text,
            phone: _fone.text,
          );
      if (mounted) context.goNamed('home');
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MenthicScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: MSpace.md),
            const DisplayTitle('Menthic'),
            const SizedBox(height: MSpace.md),
            GlassCard(
              child: Column(
                children: [
                  PillField(label: 'email:', controller: _email),
                  const SizedBox(height: MSpace.sm),
                  PillField(
                    label: 'senha:',
                    controller: _senha,
                    obscure: true,
                  ),
                  const SizedBox(height: MSpace.sm),
                  PillField(
                    label: 'Confirmar Senha:',
                    controller: _confirm,
                    obscure: true,
                  ),
                  const SizedBox(height: MSpace.sm),
                  PillField(
                    label: 'Telefone:',
                    controller: _fone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: MSpace.md),
                  Text('ou', style: displayTitleStyle(22)),
                  const SizedBox(height: MSpace.sm),
                  GoogleButton(
                    onTap: () async {
                      await ref.read(localAuthProvider).signInWithGoogle();
                      if (context.mounted) context.goNamed('home');
                    },
                  ),
                  const SizedBox(height: MSpace.lg),
                  NeuButton(
                    onTap: _submit,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 28,
                    ),
                    child: Text('Cadastar', style: displayTitleStyle(34)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MSpace.md),
            NeuButton(
              onTap: () => context.goNamed('login'),
              color: MColors.cyanLight,
              child: Text(
                'já possuo conta',
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: MColors.mintDeep,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: MSpace.md),
            Text(
              'By Munhoz',
              style: TextStyle(
                color: MColors.neutralGray,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Rodar (deve passar)**

Run: `cd app && flutter test test/features/auth/cadastro_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Format + analyze + commit**
```bash
cd app && dart format . && flutter analyze
git add app/lib/features/auth/cadastro_screen.dart app/test/features/auth/cadastro_test.dart
git commit -m "feat(auth): tela Cadastro (4 campos) ligada ao LocalAuth"
```

---

### Task 11: Home placeholder (prova o shell) + logout

**Files:**
- Modify: `app/lib/features/home/home_screen.dart`
- Test: `app/test/features/home/home_test.dart`

**Interfaces:**
- Consumes: `design/design.dart`, `localAuthProvider`, `go_router`.
- Produces: `HomeScreen` mostrando saudação + botão "Sair" (`signOut` → `login`).

- [ ] **Step 1: Escrever o teste**

Create `app/test/features/home/home_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menthic/features/home/home_screen.dart';
import 'package:menthic/features/auth/login_screen.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
    GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
  ],
);

void main() {
  testWidgets('Sair desloga e volta ao login', (tester) async {
    SharedPreferences.setMockInitialValues({'logged_in': true});
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: _router())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
```

- [ ] **Step 2: Rodar (deve falhar)**

Run: `cd app && flutter test test/features/home/home_test.dart`
Expected: FAIL — placeholder não tem botão "Sair".

- [ ] **Step 3: Implementar a Home placeholder**

Replace `app/lib/features/home/home_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../design/design.dart';
import '../auth/local_auth.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MenthicScaffold(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const DisplayTitle('Menthic'),
            const SizedBox(height: MSpace.lg),
            GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bem-vindo 👋',
                    style: displayTitleStyle(26),
                  ),
                  const SizedBox(height: MSpace.sm),
                  Text(
                    'A tela Hoje (render do OracleAnswer) chega na próxima leva.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: MColors.mintDeep, fontSize: 16),
                  ),
                  const SizedBox(height: MSpace.lg),
                  NeuButton(
                    onTap: () async {
                      await ref.read(localAuthProvider).signOut();
                      if (context.mounted) context.goNamed('login');
                    },
                    child: Text('Sair', style: displayTitleStyle(24)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Rodar (deve passar)**

Run: `cd app && flutter test test/features/home/home_test.dart`
Expected: PASS (1 test).

- [ ] **Step 5: Rodar a suíte inteira**

Run: `cd app && flutter test`
Expected: PASS (todos os testes de todas as tasks).

- [ ] **Step 6: Verificação visual manual no Chrome**

Run: `cd app && flutter run -d chrome`
Expected: abre no Chrome; Splash anima "0%→100%" e vai ao Login; comparar Login/Cadastro lado a lado com `scratchpad/login.png` e `scratchpad/cadastro.png`; "Entrar"/"Cadastar" chegam na Home; "Sair" volta ao Login.

- [ ] **Step 7: Format + analyze + commit**
```bash
cd app && dart format . && flutter analyze
git add app/lib/features/home/home_screen.dart app/test/features/home/home_test.dart
git commit -m "feat(home): Home placeholder com logout (prova o shell de navegação)"
```

---

### Task 12: README do app + atualização do README raiz

**Files:**
- Create: `app/README.md`
- Modify: `README.md` (raiz)

**Interfaces:**
- Produces: documentação de como rodar o app e do estado (design system + 3 telas prontas).

- [ ] **Step 1: Escrever `app/README.md`**
```markdown
# menthic (app Flutter)

UI do Project Oracle sobre os 4 pacotes headless.

## Rodar (dev)
```bash
cd app
flutter pub get
flutter run -d chrome
```

## Estado
- Design system glass+neumorphism (`lib/design/`), paleta mint fiel aos protótipos.
- Telas: Splash, Login, Cadastro (auth stub local), Home placeholder.
- Próxima leva: Onboarding + Home real (render do OracleAnswer ligado ao engine).
```

- [ ] **Step 2: Atualizar o bloco de status do README raiz**

Modify `README.md` — trocar a linha de status para refletir que a UI começou:
```markdown
**Status:** 🧠 Núcleo headless completo · 🎨 UI Flutter iniciada
(design system + Splash/Login/Cadastro). Próximo: Home real (OracleAnswer).
```

- [ ] **Step 3: Commit**
```bash
git add app/README.md README.md
git commit -m "docs(app): README do app + status da UI no README raiz"
```

---

## Self-Review (executado)

**1. Cobertura do spec:**
- §3 scaffold + wiring → Task 1 ✅
- §4.2 textura/logo → Task 2 ✅; fontes → `google_fonts` (Task 3), desvio consciente documentado em Global Constraints ✅
- §4.1 tokens → Task 3 ✅
- §4.3 GlassCard/NeuButton/NeuInset/PillField/DisplayTitle/FloatingBlobs/MenthicScaffold/GoogleButton → Tasks 4–5 ✅
- §3.1 LocalAuth (stub) → Task 6 ✅
- §3.2 go_router + redirect → Tasks 7–8 ✅
- §5.1 Splash → Task 8 ✅; §5.2 Login → Task 9 ✅; §5.3 Cadastro → Task 10 ✅; §5.4 Home placeholder → Task 11 ✅
- §6 verificação (Chrome + widget tests + analyze/format) → distribuída + Task 11 Step 6 ✅
- Nota: a "galeria de widgets" do spec §6 foi substituída pela verificação visual das telas reais no Chrome (Task 11 Step 6) — mais fiel ao objetivo. Desvio menor e intencional.

**2. Placeholders:** nenhum "TBD/TODO/etc" — todo passo tem código/comando completo. As telas "placeholder" das Tasks 7 são explicitamente substituídas nas Tasks 8–11.

**3. Consistência de tipos:** `MColors/MRadius/MSpace/MBlur` usados igual em todas as tasks; `LocalAuth` (isLoggedIn/signIn/signUp/signInWithGoogle/signOut/currentEmail) idêntico entre Task 6 e consumidores; rotas nomeadas (`splash/login/cadastro/home`) idênticas entre Task 7 e telas; `displayTitleStyle`/`DisplayTitle`/`NeuButton`/`NeuInset`/`GlassCard`/`PillField`/`GoogleButton`/`MenthicScaffold` com assinaturas consistentes.
