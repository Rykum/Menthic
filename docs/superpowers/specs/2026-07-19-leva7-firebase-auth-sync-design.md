# Leva 7 — Firebase: auth real + sync do event store (design)

**Data:** 2026-07-19 · **Status:** aprovado ("pegue o cli do meu firebase e siga seu plano") · **Base:** análise RFC v4 §5 — local-first + Firebase; projeto `menthic` (apps web/android registrados via flutterfire, `lib/firebase_options.dart` gerado).

## 1. Objetivo

Trocar o portão local por autenticação real (Firebase Auth e-mail/senha) e
sincronizar o event store no Firestore (offline-first: o cache do Firestore
mantém o app funcional sem rede; sync automático quando online). O motor
continua 100% no dispositivo.

## 2. Design

### 2.1 Autenticação
- `AuthService` (abstract): `isLoggedIn/signIn/signUp/signInWithGoogle/signOut/currentEmail` — a interface que o `LocalAuth` já tem.
- `LocalAuth implements AuthService` (inalterado — continua sendo o default
  dos testes e o fallback sem Firebase).
- `FirebaseAuthService implements AuthService` (firebase_auth): signIn/signUp
  e-mail/senha mapeando `FirebaseAuthException` → `AuthException` pt-BR;
  `signInWithGoogle` lança `AuthException('ainda não disponível')` por ora
  (o botão mostra o aviso).
- `authProvider = Provider<AuthService>`: usa Firebase quando
  `Firebase.apps` não está vazio; senão `LocalAuth`. Telas trocam
  `localAuthProvider` → `authProvider` (mecânico). Testes de widget seguem
  com `LocalAuth` (não inicializam Firebase).

### 2.2 Event store no Firestore
- `FirestoreEventStore implements EventStore`: coleção
  `users/{uid}/events`, campos `id` (int, `microsecondsSinceEpoch` no
  append), `ts` (Timestamp), `type`, `payload`, `origin`. Queries por
  `ts`/`type` no cliente sobre o resultado ordenado (volume N=1; sem índices
  compostos). `deleteById` por query no campo `id`.
- `eventStoreProvider`: Firebase ativo **e** usuário logado →
  `FirestoreEventStore(uid)`; senão `PersistentEventStore` (como hoje).
- Offline: `persistenceEnabled` no Firestore (cache local) — o dia a dia
  funciona sem rede e sincroniza sozinho.
- Migração dos eventos locais existentes: fora desta leva (documentado);
  priors/onboarded continuam em shared_preferences por dispositivo (priors
  são recomputáveis dos eventos).

### 2.3 Regras de segurança
`firestore.rules`: `users/{uid}/{document=**}` legível/gravável apenas por
`request.auth.uid == uid`. Deploy via `firebase deploy --only firestore:rules`
(após o backend ser provisionado).

### 2.4 Bootstrap
`main()`: `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
em try/catch — sem Firebase (testes, plataformas não configuradas) o app segue
no modo local.

## 3. Provisionamento (Cloud Shell do usuário)
APIs `firestore.googleapis.com` + `identitytoolkit.googleapis.com`, criação do
database e provider e-mail/senha — comandos entregues ao usuário (gcloud não
está na máquina local).

## 4. Testes
- `FirestoreEventStore` com `fake_cloud_firestore`: append/all/query por
  janela e tipo/deleteById/clear.
- `FirebaseAuthService` com `firebase_auth_mocks`: signUp válido loga; senha
  curta → `AuthException`; signOut desloga.
- Suíte existente permanece verde sem tocar Firebase (LocalAuth default).
- Smoke real no Chrome (cadastro → evento no Firestore) após provisionamento.
