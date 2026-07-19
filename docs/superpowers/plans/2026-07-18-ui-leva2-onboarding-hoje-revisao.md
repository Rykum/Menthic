# UI Leva 2 — Onboarding, Hoje real e Revisão noturna — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fechar o primeiro loop de valor: cold-start (3 perguntas → priors), Hoje real rendendo o `OracleAnswer` do engine a partir de eventos, e Revisão noturna que grava desfechos e atualiza o twin via `TwinLearner`.

**Architecture:** Eventos como fonte da verdade num `PersistentEventStore` (wrapper do `InMemoryEventStore` com snapshot JSON em shared_preferences). `DayState` derivado por `DayStateDeriver`; aprendizado por `TwinLearner`; priors serializados por codec próprio. Três features novas (`onboarding/`, `today/`, `review/`) sobre o design system da leva 1.

**Tech Stack:** Flutter 3.32.4 · pacotes `oracle_engine`/`oracle_store`/`oracle_learning` já ligados por path · flutter_riverpod · go_router · shared_preferences.

## Global Constraints

- Os 4 pacotes `engine/`, `store/`, `calibration/`, `learning/` **não são modificados**.
- Nenhum widget usa cor hex direto — só tokens de `design/tokens.dart`.
- `flutter analyze` limpo e `dart format .` ao fim de cada task.
- `ts` de todo evento gravado = `DateTime.now().toUtc()` (o `DayStateDeriver` janela em UTC).
- Rota `home` deixa de existir: vira `hoje` (`/hoje`). `features/home/` vira `features/today/`.
- Textos em pt-BR como no spec (ex.: "Você rende melhor de manhã, à tarde ou à noite?").

---

### Task 1: Codec de priors (`priors_codec.dart`)

**Files:**
- Create: `app/lib/data/priors_codec.dart`
- Test: `app/test/data/priors_codec_test.dart`

**Interfaces:**
- Consumes: `TraitPriors`, `NormalPrior`, `BetaPrior`, `GammaPrior` de `package:oracle_engine/oracle_engine.dart`.
- Produces: `Map<String, dynamic> priorsToJson(TraitPriors p)` e `TraitPriors priorsFromJson(Map<String, dynamic> j)`.

- [ ] **Step 1: Escrever o teste**

Create `app/test/data/priors_codec_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:oracle_engine/oracle_engine.dart';
import 'package:menthic/data/priors_codec.dart';

void main() {
  test('round-trip do prior neutro', () {
    final j = priorsToJson(TraitPriors.neutral);
    final p = priorsFromJson(j);
    expect(p.phi.mean, 14.0);
    expect(p.phi.sd, 2.5);
    expect(p.p0.a, 6);
    expect(p.p0.b, 4);
    expect(p.rho.a, 2);
    expect(p.rho.b, 5);
    expect(p.s.shape, 3);
    expect(p.s.scale, 0.05);
    expect(p.o.mean, 0.20);
    expect(p.o.sd, 0.10);
    expect(p.r.shape, 5);
    expect(p.r.scale, 0.05);
  });

  test('round-trip de prior customizado', () {
    const custom = TraitPriors(
      phi: NormalPrior(10.0, 2.5),
      p0: BetaPrior(6, 4),
      rho: BetaPrior(5.25, 1.75),
      s: GammaPrior(3, 0.05),
      o: NormalPrior(0.25, 0.10),
      r: GammaPrior(5, 0.05),
    );
    final p = priorsFromJson(priorsToJson(custom));
    expect(p.phi.mean, 10.0);
    expect(p.rho.a, 5.25);
    expect(p.rho.b, 1.75);
    expect(p.o.mean, 0.25);
  });
}
```

- [ ] **Step 2: Rodar (deve falhar)**

Run: `cd app && flutter test test/data/priors_codec_test.dart`
Expected: FAIL — URI de `priors_codec.dart` não existe.

- [ ] **Step 3: Implementar**

Create `app/lib/data/priors_codec.dart`:
```dart
import 'package:oracle_engine/oracle_engine.dart';

/// Serialização dos hiperparâmetros do twin (shared_preferences, fase 0).
Map<String, dynamic> priorsToJson(TraitPriors p) => {
  'phi': {'mean': p.phi.mean, 'sd': p.phi.sd},
  'p0': {'a': p.p0.a, 'b': p.p0.b},
  'rho': {'a': p.rho.a, 'b': p.rho.b},
  's': {'shape': p.s.shape, 'scale': p.s.scale},
  'o': {'mean': p.o.mean, 'sd': p.o.sd},
  'r': {'shape': p.r.shape, 'scale': p.r.scale},
};

double _d(Map<String, dynamic> m, String k) => (m[k] as num).toDouble();

TraitPriors priorsFromJson(Map<String, dynamic> j) {
  Map<String, dynamic> sub(String k) => (j[k] as Map).cast<String, dynamic>();
  return TraitPriors(
    phi: NormalPrior(_d(sub('phi'), 'mean'), _d(sub('phi'), 'sd')),
    p0: BetaPrior(_d(sub('p0'), 'a'), _d(sub('p0'), 'b')),
    rho: BetaPrior(_d(sub('rho'), 'a'), _d(sub('rho'), 'b')),
    s: GammaPrior(_d(sub('s'), 'shape'), _d(sub('s'), 'scale')),
    o: NormalPrior(_d(sub('o'), 'mean'), _d(sub('o'), 'sd')),
    r: GammaPrior(_d(sub('r'), 'shape'), _d(sub('r'), 'scale')),
  );
}
```

- [ ] **Step 4: Rodar (deve passar)**

Run: `cd app && flutter test test/data/priors_codec_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Format + analyze + commit**
```bash
cd app && dart format . && flutter analyze
git add app/lib/data app/test/data
git commit -m "feat(data): codec JSON dos TraitPriors"
```

---

### Task 2: `PersistentEventStore`

**Files:**
- Create: `app/lib/data/persistent_event_store.dart`
- Test: `app/test/data/persistent_event_store_test.dart`

**Interfaces:**
- Consumes: `EventStore`, `InMemoryEventStore`, `Event`, `EventDraft` de `package:oracle_store/oracle_store.dart`; `SharedPreferences`.
- Produces: `class PersistentEventStore implements EventStore` com `static Future<PersistentEventStore> open(SharedPreferences prefs)` e `static const storageKey = 'event_store_v1'`.

- [ ] **Step 1: Escrever o teste**

Create `app/test/data/persistent_event_store_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oracle_store/oracle_store.dart';
import 'package:menthic/data/persistent_event_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  EventDraft sono(double horas) => EventDraft(
    ts: DateTime.utc(2026, 7, 18, 8),
    type: EventTypes.sonoRegistrado,
    payload: {'horas': horas},
  );

  test('append persiste: novo open hidrata os mesmos eventos', () async {
    final prefs = await SharedPreferences.getInstance();
    final s1 = await PersistentEventStore.open(prefs);
    await s1.append(sono(6.0));
    await s1.append(sono(7.5));

    final s2 = await PersistentEventStore.open(prefs);
    final events = await s2.all();
    expect(events.length, 2);
    expect(events.first.type, EventTypes.sonoRegistrado);
    expect((events.last.payload['horas'] as num).toDouble(), 7.5);
  });

  test('deleteById persiste', () async {
    final prefs = await SharedPreferences.getInstance();
    final s1 = await PersistentEventStore.open(prefs);
    final e = await s1.append(sono(6.0));
    await s1.deleteById(e.id);

    final s2 = await PersistentEventStore.open(prefs);
    expect(await s2.all(), isEmpty);
  });

  test('clear persiste', () async {
    final prefs = await SharedPreferences.getInstance();
    final s1 = await PersistentEventStore.open(prefs);
    await s1.append(sono(6.0));
    await s1.clear();

    final s2 = await PersistentEventStore.open(prefs);
    expect(await s2.all(), isEmpty);
  });
}
```

- [ ] **Step 2: Rodar (deve falhar)**

Run: `cd app && flutter test test/data/persistent_event_store_test.dart`
Expected: FAIL — URI não existe.

- [ ] **Step 3: Implementar**

Create `app/lib/data/persistent_event_store.dart`:
```dart
import 'dart:convert';
import 'package:oracle_store/oracle_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// EventStore da fase 0 no web: delega ao InMemoryEventStore e espelha um
/// snapshot JSON em shared_preferences após cada mutação. Os ids são
/// renumerados a cada boot (hidratação re-appenda) — consumidores leem ids
/// sempre de query()/all(), nunca os guardam entre sessões.
class PersistentEventStore implements EventStore {
  static const storageKey = 'event_store_v1';
  final InMemoryEventStore _inner;
  final SharedPreferences _prefs;
  PersistentEventStore._(this._inner, this._prefs);

  static Future<PersistentEventStore> open(SharedPreferences prefs) async {
    final inner = InMemoryEventStore();
    final raw = prefs.getString(storageKey);
    if (raw != null) {
      for (final item in jsonDecode(raw) as List) {
        final m = (item as Map).cast<String, dynamic>();
        await inner.append(
          EventDraft(
            ts: DateTime.parse(m['ts'] as String),
            type: m['type'] as String,
            payload: (m['payload'] as Map).cast<String, dynamic>(),
            origin: m['origin'] as String,
          ),
        );
      }
    }
    return PersistentEventStore._(inner, prefs);
  }

  Future<void> _save() async {
    final events = await _inner.all();
    await _prefs.setString(
      storageKey,
      jsonEncode([
        for (final e in events)
          {
            'ts': e.ts.toIso8601String(),
            'type': e.type,
            'payload': e.payload,
            'origin': e.origin,
          },
      ]),
    );
  }

  @override
  Future<Event> append(EventDraft draft) async {
    final e = await _inner.append(draft);
    await _save();
    return e;
  }

  @override
  Future<List<Event>> query({
    DateTime? from,
    DateTime? to,
    List<String>? types,
  }) => _inner.query(from: from, to: to, types: types);

  @override
  Future<List<Event>> all() => _inner.all();

  @override
  Future<void> deleteById(int id) async {
    await _inner.deleteById(id);
    await _save();
  }

  @override
  Future<void> deleteWhere({
    DateTime? from,
    DateTime? to,
    List<String>? types,
  }) async {
    await _inner.deleteWhere(from: from, to: to, types: types);
    await _save();
  }

  @override
  Future<void> clear() async {
    await _inner.clear();
    await _save();
  }

  @override
  Future<void> close() => _inner.close();
}
```

- [ ] **Step 4: Rodar (deve passar)**

Run: `cd app && flutter test test/data/persistent_event_store_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Format + analyze + commit**
```bash
cd app && dart format . && flutter analyze
git add app/lib/data/persistent_event_store.dart app/test/data/persistent_event_store_test.dart
git commit -m "feat(data): PersistentEventStore (InMemory + snapshot em shared_preferences)"
```

---

### Task 3: Providers e repositório de priors

**Files:**
- Create: `app/lib/data/providers.dart`
- Test: `app/test/data/providers_test.dart`

**Interfaces:**
- Consumes: `PersistentEventStore.open`, `priorsToJson`/`priorsFromJson`, `TraitPriors.neutral`.
- Produces:
  - `final eventStoreProvider = FutureProvider<EventStore>(...)`
  - `class PriorsRepo { Future<TraitPriors> load(); Future<void> save(TraitPriors p); Future<bool> onboarded(); Future<void> setOnboarded(); }`
  - `final priorsRepoProvider = Provider<PriorsRepo>(...)`
  - chaves: `kPriorsKey = 'twin_priors_v1'`, `kOnboardedKey = 'onboarded'`.

- [ ] **Step 1: Escrever o teste**

Create `app/test/data/providers_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oracle_engine/oracle_engine.dart';
import 'package:menthic/data/providers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('PriorsRepo: neutro quando vazio, round-trip após save', () async {
    final repo = PriorsRepo();
    final p0 = await repo.load();
    expect(p0.phi.mean, TraitPriors.neutral.phi.mean);

    const custom = TraitPriors(
      phi: NormalPrior(10.0, 2.5),
      p0: BetaPrior(6, 4),
      rho: BetaPrior(5.25, 1.75),
      s: GammaPrior(3, 0.05),
      o: NormalPrior(0.25, 0.10),
      r: GammaPrior(5, 0.05),
    );
    await repo.save(custom);
    final p1 = await repo.load();
    expect(p1.phi.mean, 10.0);
    expect(p1.rho.a, 5.25);
  });

  test('onboarded: false por padrão, true após setOnboarded', () async {
    final repo = PriorsRepo();
    expect(await repo.onboarded(), false);
    await repo.setOnboarded();
    expect(await repo.onboarded(), true);
  });

  test('eventStoreProvider resolve um store utilizável', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = await container.read(eventStoreProvider.future);
    expect(await store.all(), isEmpty);
  });
}
```

- [ ] **Step 2: Rodar (deve falhar)**

Run: `cd app && flutter test test/data/providers_test.dart`
Expected: FAIL — URI não existe.

- [ ] **Step 3: Implementar**

Create `app/lib/data/providers.dart`:
```dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oracle_engine/oracle_engine.dart';
import 'package:oracle_store/oracle_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'persistent_event_store.dart';
import 'priors_codec.dart';

const kPriorsKey = 'twin_priors_v1';
const kOnboardedKey = 'onboarded';

final eventStoreProvider = FutureProvider<EventStore>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return PersistentEventStore.open(prefs);
});

/// Persistência dos priors do twin e da flag de onboarding.
class PriorsRepo {
  Future<TraitPriors> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kPriorsKey);
    if (raw == null) return TraitPriors.neutral;
    return priorsFromJson((jsonDecode(raw) as Map).cast<String, dynamic>());
  }

  Future<void> save(TraitPriors p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPriorsKey, jsonEncode(priorsToJson(p)));
  }

  Future<bool> onboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kOnboardedKey) ?? false;
  }

  Future<void> setOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kOnboardedKey, true);
  }
}

final priorsRepoProvider = Provider<PriorsRepo>((ref) => PriorsRepo());
```

- [ ] **Step 4: Rodar (deve passar)**

Run: `cd app && flutter test test/data/providers_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Format + analyze + commit**
```bash
cd app && dart format . && flutter analyze
git add app/lib/data/providers.dart app/test/data/providers_test.dart
git commit -m "feat(data): providers do event store + PriorsRepo (priors/onboarded)"
```

---

### Task 4: Rotas novas + redirect em 3 vias (telas placeholder)

**Files:**
- Create: `app/lib/features/onboarding/onboarding_screen.dart` (placeholder; real na Task 5)
- Create: `app/lib/features/today/today_screen.dart` (conteúdo da antiga Home; real na Task 6)
- Create: `app/lib/features/review/review_screen.dart` (placeholder; real na Task 7)
- Delete: `app/lib/features/home/home_screen.dart`, `app/test/features/home/home_test.dart`
- Modify: `app/lib/router.dart`
- Modify: `app/lib/features/auth/splash_screen.dart` (redirect 3 vias)
- Modify: `app/lib/features/auth/login_screen.dart` (2× `goNamed('home')` → `'hoje'`)
- Modify: `app/lib/features/auth/cadastro_screen.dart` (2× `goNamed('home')` → `'hoje'`)
- Modify: `app/test/router_test.dart`, `app/test/features/auth/splash_test.dart`, `app/test/features/auth/login_test.dart`, `app/test/features/auth/cadastro_test.dart`
- Test: `app/test/features/today/today_test.dart`

**Interfaces:**
- Consumes: `PriorsRepo.onboarded()` via `priorsRepoProvider`.
- Produces: rotas nomeadas `splash`, `login`, `cadastro`, `onboarding` (`/onboarding`), `hoje` (`/hoje`), `revisao` (`/revisao`); `OnboardingScreen`, `TodayScreen`, `ReviewScreen`.

- [ ] **Step 1: Placeholders**

Create `app/lib/features/onboarding/onboarding_screen.dart`:
```dart
import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('onboarding')));
}
```

Create `app/lib/features/review/review_screen.dart`:
```dart
import 'package:flutter/material.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('revisao')));
}
```

Create `app/lib/features/today/today_screen.dart` (conteúdo da antiga Home, classe renomeada):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../design/design.dart';
import '../auth/local_auth.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

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
                  Text('Bem-vindo 👋', style: displayTitleStyle(26)),
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

Delete os antigos:
```bash
rm app/lib/features/home/home_screen.dart app/test/features/home/home_test.dart
```

- [ ] **Step 2: Router**

Replace `app/lib/router.dart`:
```dart
import 'package:go_router/go_router.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/cadastro_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/today/today_screen.dart';
import 'features/review/review_screen.dart';

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
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/hoje',
      name: 'hoje',
      builder: (context, state) => const TodayScreen(),
    ),
    GoRoute(
      path: '/revisao',
      name: 'revisao',
      builder: (context, state) => const ReviewScreen(),
    ),
  ],
);
```

- [ ] **Step 3: Splash em 3 vias**

Em `app/lib/features/auth/splash_screen.dart`, troque o `addStatusListener` do `initState` por:
```dart
    _c.addStatusListener((s) async {
      if (s == AnimationStatus.completed && mounted) {
        final logged = await ref.read(localAuthProvider).isLoggedIn();
        if (!mounted) return;
        if (!logged) {
          context.goNamed('login');
          return;
        }
        final onboarded = await ref.read(priorsRepoProvider).onboarded();
        if (!mounted) return;
        context.goNamed(onboarded ? 'hoje' : 'onboarding');
      }
    });
```
E adicione o import no topo (junto aos existentes):
```dart
import '../../data/providers.dart';
```

- [ ] **Step 4: Login/Cadastro navegam para `hoje`**

Em `app/lib/features/auth/login_screen.dart` e `app/lib/features/auth/cadastro_screen.dart`, substitua **todas** as ocorrências de `context.goNamed('home')` por `context.goNamed('hoje')` (2 em cada arquivo: `_submit` e o `GoogleButton`).

- [ ] **Step 5: Atualizar os testes existentes**

Em `app/test/router_test.dart`, troque o teste dos nomes:
```dart
  test('router tem as 6 rotas nomeadas', () {
    final names = menthicRouter.configuration.routes
        .whereType<GoRoute>()
        .map((r) => r.name)
        .toSet();
    expect(names, {
      'splash',
      'login',
      'cadastro',
      'onboarding',
      'hoje',
      'revisao',
    });
  });
```

Replace `app/test/features/auth/splash_test.dart` (3 destinos):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menthic/features/auth/splash_screen.dart';
import 'package:menthic/features/auth/login_screen.dart';
import 'package:menthic/features/onboarding/onboarding_screen.dart';
import 'package:menthic/features/today/today_screen.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', name: 'splash', builder: (c, s) => const SplashScreen()),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (c, s) => const LoginScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (c, s) => const OnboardingScreen(),
    ),
    GoRoute(path: '/hoje', name: 'hoje', builder: (c, s) => const TodayScreen()),
  ],
);

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(child: MaterialApp.router(routerConfig: _router())),
  );
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('deslogado → login', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _pump(tester);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('logado sem onboarding → onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({'logged_in': true});
    await _pump(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('logado e onboarded → hoje', (tester) async {
    SharedPreferences.setMockInitialValues({
      'logged_in': true,
      'onboarded': true,
    });
    await _pump(tester);
    expect(find.byType(TodayScreen), findsOneWidget);
  });
}
```

Em `app/test/features/auth/login_test.dart` e `app/test/features/auth/cadastro_test.dart`:
- troque o import `home_screen.dart` por `package:menthic/features/today/today_screen.dart`;
- no router de teste, troque `GoRoute(path: '/home', name: 'home', builder: (c, s) => const HomeScreen())` por `GoRoute(path: '/hoje', name: 'hoje', builder: (c, s) => const TodayScreen())`;
- troque `expect(find.byType(HomeScreen), findsOneWidget)` por `expect(find.byType(TodayScreen), findsOneWidget)`.

Create `app/test/features/today/today_test.dart` (herda o teste do Sair):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menthic/features/today/today_screen.dart';
import 'package:menthic/features/auth/login_screen.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/hoje',
  routes: [
    GoRoute(path: '/hoje', name: 'hoje', builder: (c, s) => const TodayScreen()),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (c, s) => const LoginScreen(),
    ),
  ],
);

void main() {
  testWidgets('Sair desloga e volta ao login', (tester) async {
    SharedPreferences.setMockInitialValues({'logged_in': true});
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: _router())),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sair'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
```

- [ ] **Step 6: Rodar a suíte inteira**

Run: `cd app && flutter test`
Expected: PASS (todos; nenhum teste referencia mais `home`).

- [ ] **Step 7: Format + analyze + commit**
```bash
cd app && dart format . && flutter analyze
git add -A app/lib app/test
git commit -m "feat(app): rotas onboarding/hoje/revisao + splash em 3 vias (home vira hoje)"
```

---

### Task 5: Onboarding real (arquétipos → priors)

**Files:**
- Create: `app/lib/features/onboarding/archetype.dart`
- Modify: `app/lib/features/onboarding/onboarding_screen.dart`
- Test: `app/test/features/onboarding/archetype_test.dart`
- Test: `app/test/features/onboarding/onboarding_test.dart`

**Interfaces:**
- Consumes: `PriorsRepo` (`priorsRepoProvider`), design system, `go_router`.
- Produces: `TraitPriors archetypePriors({required String periodo, required int adiar, required int subestima})` — `periodo ∈ {'manha','tarde','noite'}`, `adiar`/`subestima ∈ 1..5`.

- [ ] **Step 1: Teste do arquétipo (puro)**

Create `app/test/features/onboarding/archetype_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:menthic/features/onboarding/archetype.dart';

void main() {
  test('manhã/5/5 → μ_φ=10, ρ média 0.75, o μ=0.25', () {
    final p = archetypePriors(periodo: 'manha', adiar: 5, subestima: 5);
    expect(p.phi.mean, 10.0);
    expect(p.phi.sd, 2.5);
    expect(p.rho.a / (p.rho.a + p.rho.b), closeTo(0.75, 1e-9));
    expect(p.rho.a + p.rho.b, closeTo(7.0, 1e-9));
    expect(p.o.mean, closeTo(0.25, 1e-9));
    expect(p.o.sd, 0.10);
  });

  test('tarde/1/1 → μ_φ=14, ρ média 0.15, o μ=0.05', () {
    final p = archetypePriors(periodo: 'tarde', adiar: 1, subestima: 1);
    expect(p.phi.mean, 14.0);
    expect(p.rho.a / (p.rho.a + p.rho.b), closeTo(0.15, 1e-9));
    expect(p.o.mean, closeTo(0.05, 1e-9));
  });

  test('noite → μ_φ=18.5; demais traços seguem o neutro', () {
    final p = archetypePriors(periodo: 'noite', adiar: 3, subestima: 3);
    expect(p.phi.mean, 18.5);
    expect(p.p0.a, 6);
    expect(p.p0.b, 4);
    expect(p.s.shape, 3);
    expect(p.r.shape, 5);
  });
}
```

- [ ] **Step 2: Rodar (deve falhar)**

Run: `cd app && flutter test test/features/onboarding/archetype_test.dart`
Expected: FAIL — URI não existe.

- [ ] **Step 3: Implementar o arquétipo**

Create `app/lib/features/onboarding/archetype.dart`:
```dart
import 'package:oracle_engine/oracle_engine.dart';

/// Cold-start do doc 10 A.3: 3 respostas → priors de φ, ρ e o.
/// Demais traços partem do prior neutro (A.2).
TraitPriors archetypePriors({
  required String periodo,
  required int adiar,
  required int subestima,
}) {
  const n = TraitPriors.neutral;
  final muPhi = switch (periodo) {
    'manha' => 10.0,
    'noite' => 18.5,
    _ => 14.0,
  };
  // ρ: Beta com média 0.15·resposta, mantendo a força do prior neutro (a+b=7).
  final m = (0.15 * adiar).clamp(0.05, 0.95);
  const strength = 7.0;
  return TraitPriors(
    phi: NormalPrior(muPhi, n.phi.sd),
    p0: n.p0,
    rho: BetaPrior(strength * m, strength * (1 - m)),
    s: n.s,
    o: NormalPrior(0.05 * subestima, 0.10),
    r: n.r,
  );
}
```

- [ ] **Step 4: Rodar (deve passar)**

Run: `cd app && flutter test test/features/onboarding/archetype_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Teste da tela**

Create `app/test/features/onboarding/onboarding_test.dart`:
```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menthic/data/providers.dart';
import 'package:menthic/features/onboarding/onboarding_screen.dart';
import 'package:menthic/features/today/today_screen.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (c, s) => const OnboardingScreen(),
    ),
    GoRoute(path: '/hoje', name: 'hoje', builder: (c, s) => const TodayScreen()),
  ],
);

Future<void> _tap(WidgetTester t, String label) async {
  await t.ensureVisible(find.text(label));
  await t.pumpAndSettle();
  await t.tap(find.text(label));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('manhã/5/5 salva priors do arquétipo e vai para hoje', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'logged_in': true});
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: _router())),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('rende melhor'), findsOneWidget);
    await _tap(tester, 'manhã');
    expect(find.textContaining('adiar tarefas chatas'), findsOneWidget);
    await _tap(tester, '5');
    expect(find.textContaining('subestima'), findsOneWidget);
    await _tap(tester, '5');

    expect(find.byType(TodayScreen), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(kOnboardedKey), true);
    final j =
        (jsonDecode(prefs.getString(kPriorsKey)!) as Map)
            .cast<String, dynamic>();
    expect(((j['phi'] as Map)['mean'] as num).toDouble(), 10.0);
    final rho = (j['rho'] as Map).cast<String, num>();
    expect(
      rho['a']!.toDouble() / (rho['a']!.toDouble() + rho['b']!.toDouble()),
      closeTo(0.75, 1e-9),
    );
    expect(((j['o'] as Map)['mean'] as num).toDouble(), closeTo(0.25, 1e-9));
  });
}
```

- [ ] **Step 6: Rodar (deve falhar)**

Run: `cd app && flutter test test/features/onboarding/onboarding_test.dart`
Expected: FAIL — placeholder não tem as perguntas.

- [ ] **Step 7: Implementar a tela**

Replace `app/lib/features/onboarding/onboarding_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/providers.dart';
import '../../design/design.dart';
import 'archetype.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  String? _periodo;
  int? _adiar;

  Future<void> _finish(int subestima) async {
    final priors = archetypePriors(
      periodo: _periodo!,
      adiar: _adiar!,
      subestima: subestima,
    );
    final repo = ref.read(priorsRepoProvider);
    await repo.save(priors);
    await repo.setOnboarded();
    if (mounted) context.goNamed('hoje');
  }

  Widget _option(String label, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(bottom: MSpace.sm),
    child: NeuButton(
      onTap: onTap,
      child: Text(
        label,
        style: GoogleFonts.fredoka(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: MColors.highlight,
        ),
      ),
    ),
  );

  Widget _scale(void Function(int) onPick) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 1; i <= 5; i++)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MSpace.xs),
          child: NeuButton(
            onTap: () => onPick(i),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Text(
              '$i',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: MColors.highlight,
              ),
            ),
          ),
        ),
    ],
  );

  Widget _question(String text) => Padding(
    padding: const EdgeInsets.only(bottom: MSpace.md),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.fredoka(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: MColors.mintDeep,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final steps = <Widget>[
      Column(
        children: [
          _question('Você rende melhor de manhã, à tarde ou à noite?'),
          _option('manhã', () => setState(() {
            _periodo = 'manha';
            _step = 1;
          })),
          _option('tarde', () => setState(() {
            _periodo = 'tarde';
            _step = 1;
          })),
          _option('noite', () => setState(() {
            _periodo = 'noite';
            _step = 1;
          })),
        ],
      ),
      Column(
        children: [
          _question('Costuma adiar tarefas chatas?\n(1 nunca … 5 sempre)'),
          _scale((v) => setState(() {
            _adiar = v;
            _step = 2;
          })),
        ],
      ),
      Column(
        children: [
          _question(
            'Ao planejar, você subestima quanto as coisas demoram?\n'
            '(1 nunca … 5 sempre)',
          ),
          _scale(_finish),
        ],
      ),
    ];

    return MenthicScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: MSpace.md),
            const DisplayTitle('Menthic', size: 44),
            const SizedBox(height: MSpace.sm),
            Text('${_step + 1} de 3', style: displayTitleStyle(20)),
            const SizedBox(height: MSpace.md),
            GlassCard(child: steps[_step]),
            const SizedBox(height: MSpace.md),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 8: Rodar (deve passar)**

Run: `cd app && flutter test test/features/onboarding/`
Expected: PASS (4 tests).

- [ ] **Step 9: Format + analyze + commit**
```bash
cd app && dart format . && flutter analyze
git add app/lib/features/onboarding app/test/features/onboarding
git commit -m "feat(onboarding): cold-start em 3 perguntas -> priors por arquetipo"
```

---

### Task 6: Hoje real (entrada do dia + render do OracleAnswer)

**Files:**
- Create: `app/lib/features/today/answer_card.dart`
- Modify: `app/lib/features/today/today_screen.dart`
- Modify: `app/test/features/today/today_test.dart` (adiciona os testes novos; mantém o do Sair)

**Interfaces:**
- Consumes: `eventStoreProvider`, `priorsRepoProvider`, `DayStateDeriver`, `answerAgenda`, `EventTypes`, drafts `sonoRegistrado`/`compromissoCriado` de `oracle_store`.
- Produces: `AnswerCard({required OracleAnswer answer, required int observedDays})`.

- [ ] **Step 1: Testes novos da Hoje**

Replace `app/test/features/today/today_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menthic/features/today/today_screen.dart';
import 'package:menthic/features/auth/login_screen.dart';
import 'package:menthic/features/review/review_screen.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/hoje',
  routes: [
    GoRoute(path: '/hoje', name: 'hoje', builder: (c, s) => const TodayScreen()),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (c, s) => const LoginScreen(),
    ),
    GoRoute(
      path: '/revisao',
      name: 'revisao',
      builder: (c, s) => const ReviewScreen(),
    ),
  ],
);

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(child: MaterialApp.router(routerConfig: _router())),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester t, String label) async {
  await t.ensureVisible(find.text(label).first);
  await t.pumpAndSettle();
  await t.tap(find.text(label).first);
  await t.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'logged_in': true}));

  testWidgets('registra sono, adiciona compromisso e prevê o dia', (
    tester,
  ) async {
    await _pump(tester);

    await tester.enterText(find.byKey(const Key('sono')), '6');
    await _tap(tester, 'Registrar sono');
    expect(find.textContaining('Sono de hoje: 6'), findsOneWidget);

    await _tap(tester, 'Adicionar compromisso');
    await tester.enterText(find.byKey(const Key('nome')), 'estudo');
    await tester.enterText(find.byKey(const Key('inicio')), '9');
    await tester.enterText(find.byKey(const Key('duracao')), '2');
    await _tap(tester, 'Salvar');
    expect(find.text('estudo'), findsOneWidget);

    await _tap(tester, 'Prever meu dia');
    expect(find.text('Cumprir a agenda de hoje'), findsOneWidget);
    expect(find.textContaining('faixa provável'), findsOneWidget);
    expect(find.textContaining('confiança'), findsOneWidget);
    expect(find.text('Limitações'), findsOneWidget);
  });

  testWidgets('Sair desloga e volta ao login', (tester) async {
    await _pump(tester);
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
```

- [ ] **Step 2: Rodar (deve falhar)**

Run: `cd app && flutter test test/features/today/today_test.dart`
Expected: FAIL — a tela atual não tem campos nem previsão.

- [ ] **Step 3: Implementar o AnswerCard**

Create `app/lib/features/today/answer_card.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oracle_engine/oracle_engine.dart';
import '../../design/design.dart';

/// Render fiel do OracleAnswer (doc 06 §6). Nenhum número inventado:
/// tudo vem do engine; aqui só formatamos.
class AnswerCard extends StatelessWidget {
  final OracleAnswer answer;
  final int observedDays;
  const AnswerCard({
    super.key,
    required this.answer,
    required this.observedDays,
  });

  String get _confLabel => switch (answer.confidence) {
    Confidence.alta => 'alta',
    Confidence.media => 'média',
    Confidence.baixa => 'baixa',
  };

  String _forca(double d) {
    final a = d.abs();
    if (a >= 0.08) return 'forte';
    if (a >= 0.04) return 'média';
    return 'fraca';
  }

  TextStyle get _body => GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: MColors.mintDeep,
  );

  TextStyle get _section => GoogleFonts.fredoka(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: MColors.mintDeep,
  );

  @override
  Widget build(BuildContext context) {
    final pct = (answer.estimate * 100).round();
    final lo = (answer.low * 100).round();
    final hi = (answer.high * 100).round();
    final factors = [...answer.factors]
      ..sort((a, b) => b.delta.abs().compareTo(a.delta.abs()));

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cumprir a agenda de hoje', style: _section),
          const SizedBox(height: MSpace.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('~$pct%', style: displayTitleStyle(44)),
              const SizedBox(width: MSpace.md),
              Expanded(child: RangeBar(low: answer.low, high: answer.high)),
            ],
          ),
          const SizedBox(height: MSpace.xs),
          Text('faixa provável $lo–$hi%', style: _body),
          Text(
            'confiança: $_confLabel · $observedDays dia(s) com desfecho seus',
            style: _body,
          ),
          if (observedDays < 7)
            Text(
              'ainda baseado mais em padrões gerais que nos seus',
              style: _body.copyWith(color: MColors.neutralGray),
            ),
          if (factors.isNotEmpty) ...[
            const SizedBox(height: MSpace.md),
            Text('O que mais pesou', style: _section),
            const SizedBox(height: MSpace.xs),
            for (final f in factors.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${f.delta >= 0 ? '↑' : '↓'} ${f.label}'
                  '   ${_forca(f.delta)}',
                  style: _body,
                ),
              ),
          ],
          const SizedBox(height: MSpace.md),
          Text('Limitações', style: _section),
          const SizedBox(height: MSpace.xs),
          for (final l in answer.limitations)
            Text('• $l', style: _body),
        ],
      ),
    );
  }
}

/// Barra da faixa provável: trilho claro + segmento mint entre low e high
/// + marcador na estimativa.
class RangeBar extends StatelessWidget {
  final double low;
  final double high;
  const RangeBar({super.key, required this.low, required this.high});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          return Stack(
            children: [
              Container(
                width: w,
                height: 14,
                decoration: BoxDecoration(
                  color: MColors.highlight,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              Positioned(
                left: w * low,
                child: Container(
                  width: w * (high - low),
                  height: 14,
                  decoration: BoxDecoration(
                    color: MColors.mint,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Implementar a TodayScreen real**

Replace `app/lib/features/today/today_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oracle_engine/oracle_engine.dart';
import 'package:oracle_store/oracle_store.dart';
import '../../data/providers.dart';
import '../../design/design.dart';
import '../auth/local_auth.dart';
import 'answer_card.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});
  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _CommitmentRow {
  final int eventId;
  final String nome;
  final double inicio;
  final double duracao;
  final bool aversivo;
  const _CommitmentRow({
    required this.eventId,
    required this.nome,
    required this.inicio,
    required this.duracao,
    required this.aversivo,
  });
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  final _sono = TextEditingController();
  double? _sonoHoje;
  List<_CommitmentRow> _agenda = [];
  OracleAnswer? _answer;
  int _observedDays = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _sono.dispose();
    super.dispose();
  }

  (DateTime, DateTime) _todayWindow() {
    final now = DateTime.now().toUtc();
    final from = DateTime.utc(now.year, now.month, now.day);
    return (from, from.add(const Duration(days: 1)));
  }

  Future<void> _reload() async {
    final store = await ref.read(eventStoreProvider.future);
    final (from, to) = _todayWindow();
    final events = await store.query(from: from, to: to);

    double? sono;
    final agenda = <_CommitmentRow>[];
    for (final e in events) {
      if (e.type == EventTypes.sonoRegistrado) {
        sono = (e.payload['horas'] as num).toDouble();
      }
      if (e.type == EventTypes.compromissoCriado) {
        agenda.add(
          _CommitmentRow(
            eventId: e.id,
            nome: e.payload['cid'] as String,
            inicio: (e.payload['inicio'] as num).toDouble(),
            duracao: (e.payload['dur_prevista'] as num).toDouble(),
            aversivo: (e.payload['aversivo'] as bool?) ?? false,
          ),
        );
      }
    }
    if (!mounted) return;
    setState(() {
      _sonoHoje = sono;
      _agenda = agenda;
    });
  }

  double? _num(String raw) => double.tryParse(raw.replaceAll(',', '.'));

  Future<void> _registrarSono() async {
    final horas = _num(_sono.text);
    if (horas == null) return;
    final store = await ref.read(eventStoreProvider.future);
    await store.append(
      sonoRegistrado(ts: DateTime.now().toUtc(), horas: horas),
    );
    _sono.clear();
    await _reload();
  }

  Future<void> _removerCompromisso(int eventId) async {
    final store = await ref.read(eventStoreProvider.future);
    await store.deleteById(eventId);
    await _reload();
  }

  Future<void> _prever() async {
    final store = await ref.read(eventStoreProvider.future);
    final priors = await ref.read(priorsRepoProvider).load();
    final now = DateTime.now().toUtc();
    final state = await const DayStateDeriver().derive(store, now);

    final outcomes = await store.query(
      types: [EventTypes.tarefaConcluida, EventTypes.tarefaNaoConcluida],
    );
    final days = outcomes
        .map((e) => '${e.ts.year}-${e.ts.month}-${e.ts.day}')
        .toSet();

    final answer = answerAgenda(
      state,
      priors,
      observedDays: days.length,
      seed: 0,
    );
    await store.append(
      EventDraft(
        ts: now,
        type: EventTypes.previsaoEmitida,
        payload: {
          'estimate': answer.estimate,
          'low': answer.low,
          'high': answer.high,
        },
      ),
    );
    if (!mounted) return;
    setState(() {
      _answer = answer;
      _observedDays = days.length;
    });
  }

  Future<void> _abrirSheetCompromisso() async {
    final nome = TextEditingController();
    final inicio = TextEditingController();
    final duracao = TextEditingController();
    var aversivo = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MColors.cyanLight,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (sheetContext, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PillField(
                key: const Key('nome'),
                label: 'nome:',
                controller: nome,
              ),
              const SizedBox(height: MSpace.sm),
              PillField(
                key: const Key('inicio'),
                label: 'início (hora 0–24):',
                controller: inicio,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: MSpace.sm),
              PillField(
                key: const Key('duracao'),
                label: 'duração (horas):',
                controller: duracao,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: MSpace.sm),
              Row(
                children: [
                  Switch(
                    value: aversivo,
                    activeColor: MColors.mintDeep,
                    onChanged: (v) => setSheetState(() => aversivo = v),
                  ),
                  Text(
                    'tarefa chata (aversiva)',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: MColors.mintDeep,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MSpace.md),
              Center(
                child: NeuButton(
                  onTap: () async {
                    final ini = _num(inicio.text);
                    final dur = _num(duracao.text);
                    if (nome.text.isEmpty || ini == null || dur == null) {
                      return;
                    }
                    final store = await ref.read(eventStoreProvider.future);
                    await store.append(
                      compromissoCriado(
                        ts: DateTime.now().toUtc(),
                        cid: nome.text,
                        inicio: ini,
                        durPrevista: dur,
                        tipo: 'foco',
                        aversivo: aversivo,
                      ),
                    );
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                  child: Text('Salvar', style: displayTitleStyle(24)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    nome.dispose();
    inicio.dispose();
    duracao.dispose();
    await _reload();
  }

  TextStyle get _body => GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: MColors.mintDeep,
  );

  @override
  Widget build(BuildContext context) {
    return MenthicScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: MSpace.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const DisplayTitle('Hoje', size: 44),
                IconButton(
                  icon: const Icon(Icons.logout, color: MColors.mintDeep),
                  onPressed: () async {
                    await ref.read(localAuthProvider).signOut();
                    if (context.mounted) context.goNamed('login');
                  },
                ),
              ],
            ),
            const SizedBox(height: MSpace.sm),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_sonoHoje != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: MSpace.sm),
                      child: Text(
                        'Sono de hoje: ${_sonoHoje!.toStringAsFixed(1)}h',
                        style: _body,
                      ),
                    ),
                  PillField(
                    key: const Key('sono'),
                    label: 'dormi (horas):',
                    controller: _sono,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: MSpace.sm),
                  Center(
                    child: NeuButton(
                      onTap: _registrarSono,
                      child: Text('Registrar sono', style: displayTitleStyle(20)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MSpace.md),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Compromissos de hoje',
                    style: GoogleFonts.fredoka(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: MColors.mintDeep,
                    ),
                  ),
                  const SizedBox(height: MSpace.sm),
                  if (_agenda.isEmpty)
                    Text('nenhum ainda', style: _body)
                  else
                    for (final c in _agenda)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${c.nome} · ${c.inicio.toStringAsFixed(0)}h · '
                              '${c.duracao.toStringAsFixed(1)}h'
                              '${c.aversivo ? ' · chata' : ''}',
                              style: _body,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: MColors.neutralGray,
                              size: 20,
                            ),
                            onPressed: () => _removerCompromisso(c.eventId),
                          ),
                        ],
                      ),
                  const SizedBox(height: MSpace.sm),
                  Center(
                    child: NeuButton(
                      onTap: _abrirSheetCompromisso,
                      color: MColors.cyanLight,
                      child: Text(
                        'Adicionar compromisso',
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: MColors.mintDeep,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MSpace.md),
            Center(
              child: NeuButton(
                onTap: _prever,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 24,
                ),
                child: Text('Prever meu dia', style: displayTitleStyle(28)),
              ),
            ),
            if (_answer != null) ...[
              const SizedBox(height: MSpace.md),
              AnswerCard(answer: _answer!, observedDays: _observedDays),
              const SizedBox(height: MSpace.md),
              Center(
                child: NeuButton(
                  onTap: () => context.goNamed('revisao'),
                  color: MColors.cyanLight,
                  child: Text(
                    'Revisão do dia',
                    style: GoogleFonts.fredoka(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: MColors.mintDeep,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: MSpace.lg),
          ],
        ),
      ),
    );
  }
}
```

Nota: `PillField` da leva 1 já aceita `key` via construtor (`super.key`).

- [ ] **Step 5: Rodar (deve passar)**

Run: `cd app && flutter test test/features/today/today_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Format + analyze + commit**
```bash
cd app && dart format . && flutter analyze
git add app/lib/features/today app/test/features/today
git commit -m "feat(today): Hoje real — sono + agenda por eventos e render do OracleAnswer"
```

---

### Task 7: Revisão noturna (desfechos + TwinLearner)

**Files:**
- Modify: `app/lib/features/review/review_screen.dart`
- Test: `app/test/features/review/review_test.dart`

**Interfaces:**
- Consumes: `eventStoreProvider`, `priorsRepoProvider`, `TwinLearner` de `package:oracle_learning/oracle_learning.dart`, `EventTypes`, draft `tarefaConcluida`.
- Produces: tela `/revisao` que grava `tarefa_concluida`/`tarefa_nao_concluida`/`humor_registrado` e salva os priors atualizados.

- [ ] **Step 1: Escrever o teste**

Create `app/test/features/review/review_test.dart`:
```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menthic/data/providers.dart';
import 'package:menthic/features/review/review_screen.dart';
import 'package:menthic/features/today/today_screen.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/revisao',
  routes: [
    GoRoute(
      path: '/revisao',
      name: 'revisao',
      builder: (c, s) => const ReviewScreen(),
    ),
    GoRoute(path: '/hoje', name: 'hoje', builder: (c, s) => const TodayScreen()),
  ],
);

String _seedStore() {
  final now = DateTime.now().toUtc();
  return jsonEncode([
    {
      'ts': now.toIso8601String(),
      'type': 'compromisso_criado',
      'payload': {
        'cid': 'estudo',
        'inicio': 9.0,
        'dur_prevista': 2.0,
        'tipo': 'foco',
        'prioridade': 2,
        'aversivo': true,
      },
      'origin': 'manual',
    },
  ]);
}

Future<void> _tap(WidgetTester t, String label) async {
  await t.ensureVisible(find.text(label).first);
  await t.pumpAndSettle();
  await t.tap(find.text(label).first);
  await t.pumpAndSettle();
}

void main() {
  testWidgets(
    'marcar aversiva feita com atraso grava eventos e atualiza rho',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'logged_in': true,
        'event_store_v1': _seedStore(),
      });
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: _router())),
      );
      await tester.pumpAndSettle();

      expect(find.text('estudo'), findsOneWidget);
      await _tap(tester, 'feito');
      await _tap(tester, '30 min');
      await _tap(tester, 'Salvar revisão');

      expect(find.byType(TodayScreen), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      final events = jsonDecode(prefs.getString('event_store_v1')!) as List;
      final types = [for (final e in events) (e as Map)['type']];
      expect(types, contains('tarefa_concluida'));
      expect(types, contains('humor_registrado'));

      // rho: Beta(2,5) + 1 tentativa aversiva com atraso>0 => Beta(3,5).
      final j =
          (jsonDecode(prefs.getString(kPriorsKey)!) as Map)
              .cast<String, dynamic>();
      final rho = (j['rho'] as Map).cast<String, num>();
      expect(rho['a']!.toDouble(), closeTo(3.0, 1e-9));
      expect(rho['b']!.toDouble(), closeTo(5.0, 1e-9));
    },
  );

  testWidgets('não feito grava tarefa_nao_concluida', (tester) async {
    SharedPreferences.setMockInitialValues({
      'logged_in': true,
      'event_store_v1': _seedStore(),
    });
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: _router())),
    );
    await tester.pumpAndSettle();

    await _tap(tester, 'Salvar revisão');

    final prefs = await SharedPreferences.getInstance();
    final events = jsonDecode(prefs.getString('event_store_v1')!) as List;
    final types = [for (final e in events) (e as Map)['type']];
    expect(types, contains('tarefa_nao_concluida'));
  });
}
```

- [ ] **Step 2: Rodar (deve falhar)**

Run: `cd app && flutter test test/features/review/review_test.dart`
Expected: FAIL — placeholder não lista compromissos.

- [ ] **Step 3: Implementar a Revisão**

Replace `app/lib/features/review/review_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oracle_learning/oracle_learning.dart';
import 'package:oracle_store/oracle_store.dart';
import '../../data/providers.dart';
import '../../design/design.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});
  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewItem {
  final String cid;
  bool feito = false;
  int atrasoMin = 0;
  _ReviewItem(this.cid);
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  List<_ReviewItem> _items = [];
  int _humor = 3;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = await ref.read(eventStoreProvider.future);
    final now = DateTime.now().toUtc();
    final from = DateTime.utc(now.year, now.month, now.day);
    final events = await store.query(
      from: from,
      to: from.add(const Duration(days: 1)),
      types: [EventTypes.compromissoCriado],
    );
    if (!mounted) return;
    setState(() {
      _items = [
        for (final e in events) _ReviewItem(e.payload['cid'] as String),
      ];
    });
  }

  Future<void> _salvar() async {
    if (_saving) return;
    setState(() => _saving = true);
    final store = await ref.read(eventStoreProvider.future);
    final now = DateTime.now().toUtc();

    for (final item in _items) {
      if (item.feito) {
        await store.append(
          tarefaConcluida(
            ts: now,
            cid: item.cid,
            atrasoMin: item.atrasoMin.toDouble(),
          ),
        );
      } else {
        await store.append(
          EventDraft(
            ts: now,
            type: EventTypes.tarefaNaoConcluida,
            payload: {'cid': item.cid},
          ),
        );
      }
    }
    await store.append(
      EventDraft(
        ts: now,
        type: EventTypes.humorRegistrado,
        payload: {'humor': _humor},
      ),
    );

    final repo = ref.read(priorsRepoProvider);
    final prior = await repo.load();
    final updated = await const TwinLearner().learn(store, prior: prior);
    await repo.save(updated);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Twin atualizado com o seu dia.')),
    );
    context.goNamed('hoje');
  }

  TextStyle get _body => GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: MColors.mintDeep,
  );

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: MSpace.xs, bottom: MSpace.xs),
    child: NeuButton(
      onTap: onTap,
      color: selected ? MColors.mint : MColors.cyanLight,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: selected ? MColors.highlight : MColors.mintDeep,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MenthicScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: MSpace.sm),
            const Center(child: DisplayTitle('Revisão', size: 44)),
            const SizedBox(height: MSpace.md),
            if (_items.isEmpty)
              GlassCard(
                child: Text('Nenhum compromisso registrado hoje.', style: _body),
              )
            else
              for (final item in _items)
                Padding(
                  padding: const EdgeInsets.only(bottom: MSpace.sm),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.cid,
                          style: GoogleFonts.fredoka(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: MColors.mintDeep,
                          ),
                        ),
                        const SizedBox(height: MSpace.xs),
                        Row(
                          children: [
                            _chip('feito', item.feito, () {
                              setState(() => item.feito = true);
                            }),
                            _chip('não feito', !item.feito, () {
                              setState(() => item.feito = false);
                            }),
                          ],
                        ),
                        if (item.feito) ...[
                          const SizedBox(height: MSpace.xs),
                          Text('atraso:', style: _body),
                          Wrap(
                            children: [
                              for (final m in const [0, 15, 30, 60])
                                _chip('$m min', item.atrasoMin == m, () {
                                  setState(() => item.atrasoMin = m);
                                }),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: MSpace.sm),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Como foi o humor hoje? (1–5)', style: _body),
                  const SizedBox(height: MSpace.xs),
                  Wrap(
                    children: [
                      for (var i = 1; i <= 5; i++)
                        _chip('$i', _humor == i, () {
                          setState(() => _humor = i);
                        }),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: MSpace.md),
            Center(
              child: NeuButton(
                onTap: _salvar,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 24,
                ),
                child: Text('Salvar revisão', style: displayTitleStyle(26)),
              ),
            ),
            const SizedBox(height: MSpace.lg),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Rodar (deve passar)**

Run: `cd app && flutter test test/features/review/review_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Rodar a suíte inteira + format + analyze + commit**

Run: `cd app && flutter test`
Expected: PASS (todos).
```bash
cd app && dart format . && flutter analyze
git add app/lib/features/review app/test/features/review
git commit -m "feat(review): Revisao noturna — desfechos + humor + TwinLearner atualiza os priors"
```

---

### Task 8: Verificação no Chrome + READMEs

**Files:**
- Modify: `app/README.md`, `README.md`

**Interfaces:**
- Produces: verificação visual do fluxo completo e documentação atualizada.

- [ ] **Step 1: Rodar no Chrome (headless) e dirigir o fluxo**

Sobe o server e fotografa com o padrão da leva 1 (puppeteer-core no `scratchpad/`):
```bash
cd app && flutter run -d web-server --web-port=8123   # background
# node scratchpad/shoot.mjs /onboarding onboarding.png 8000  (após login/cadastro)
# dirigir: onboarding (3 taps) → hoje (sono+compromisso+prever) → revisao → salvar
```
Expected: onboarding mostra as 3 perguntas; hoje mostra o card do OracleAnswer com %, faixa e fatores; revisão salva e volta à hoje com snackbar. Olhar os screenshots.

- [ ] **Step 2: Atualizar `app/README.md`** (bloco "Estado"):
```markdown
## Estado
- Design system glass+neumorphism (`lib/design/`), paleta mint fiel aos protótipos.
- Telas: Splash, Login, Cadastro (auth stub local), Onboarding (cold-start →
  priors), Hoje (OracleAnswer real por eventos), Revisão noturna (desfechos →
  TwinLearner).
- Dados: eventos em `PersistentEventStore` (shared_preferences); priors do twin
  serializados; SQLite fica p/ hardening Android.
- Próxima leva: Simular, Meu Twin, Calibração.
```

- [ ] **Step 3: Atualizar o status do README raiz**:
```markdown
**Status:** 🧠 Núcleo headless completo · 🎨 UI Flutter com o loop diário
(Onboarding → Hoje/OracleAnswer → Revisão noturna). Próximo: Simular/Meu
Twin/Calibração.
```
(mantendo as 2 linhas seguintes do parágrafo como estão)

- [ ] **Step 4: Suíte final + commit**
```bash
cd app && flutter test && flutter analyze && flutter build web --no-tree-shake-icons
git add app/README.md README.md
git commit -m "docs(app): estado da leva 2 nos READMEs"
```

---

## Self-Review (executado)

**1. Cobertura do spec:** §2 store/priors → Tasks 1–3 ✅ · §3.2 onboarding+splash → Tasks 4–5 ✅ · §3.3 Hoje → Task 6 ✅ · §3.4 revisão → Task 7 ✅ · §3.5 rotas → Task 4 ✅ · §4 observedDays+shrinkage → Task 6 (`_prever`/`AnswerCard`) ✅ · §5 testes → distribuídos ✅ · verificação Chrome → Task 8 ✅.

**2. Placeholders:** nenhum TBD; os placeholders das telas na Task 4 são substituídos nas Tasks 5–7 explicitamente.

**3. Consistência:** `PersistentEventStore.open(prefs)`/`storageKey` iguais nas Tasks 2 e 7 (teste semeia `event_store_v1`); `kPriorsKey`/`kOnboardedKey` iguais nas Tasks 3, 5 e 7; `archetypePriors(periodo, adiar, subestima)` igual nas Tasks 5; rotas nomeadas (`onboarding`/`hoje`/`revisao`) iguais nas Tasks 4–7; `AnswerCard(answer, observedDays)` definido e usado na Task 6.
