# Leva 7 — Firebase auth + sync — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Auth real (Firebase e-mail/senha) e event store sincronizado no Firestore, local-first; motor intacto no dispositivo; testes com fakes.

**Architecture:** `AuthService` abstrato (LocalAuth = default/testes; FirebaseAuthService = produção); `FirestoreEventStore` como terceira implementação do contrato `EventStore`; seleção nos providers por `Firebase.apps` + login; regras Firestore por uid.

## Global Constraints
- Pacotes core intactos; mudanças só em `app/` + arquivos de projeto Firebase na raiz.
- Suíte existente continua verde sem inicializar Firebase.
- `dart format` + analyze limpos.

### Task 1: deps + bootstrap
**Files:** Modify `app/pubspec.yaml` (firebase_core, firebase_auth, cloud_firestore; dev: fake_cloud_firestore, firebase_auth_mocks) · Modify `app/lib/main.dart` (init em try/catch)
- [ ] pub get resolve → suíte existente verde → commit `feat(app): bootstrap Firebase (menthic) com fallback local`

### Task 2: AuthService + FirebaseAuthService
**Files:** Modify `app/lib/features/auth/local_auth.dart` (extrai `AuthService`; `authProvider`) · Create `app/lib/features/auth/firebase_auth_service.dart` · Modify telas (`localAuthProvider`→`authProvider`) · Test `app/test/features/auth/firebase_auth_service_test.dart`
- [ ] testes red (mocks: signUp loga; senha<6 → AuthException; signOut) → implementar → suíte inteira verde → commit `feat(auth): Firebase Auth email/senha atras do AuthService`

### Task 3: FirestoreEventStore + seleção no provider
**Files:** Create `app/lib/data/firestore_event_store.dart` · Modify `app/lib/data/providers.dart` (seleção) · Test `app/test/data/firestore_event_store_test.dart` (fake_cloud_firestore)
- [ ] testes red (append/all/query janela+tipo/deleteById/clear) → implementar → suíte verde → commit `feat(data): FirestoreEventStore (users/{uid}/events) offline-first`

### Task 4: regras + provisionamento + smoke real
**Files:** Create `firestore.rules`, `firebase.json` (raiz)
- [ ] usuário roda o bloco gcloud no Cloud Shell (APIs + database + provider e-mail) → `firebase deploy --only firestore:rules` → smoke no Chrome (cadastro real → evento aparece no Firestore) → READMEs → merge --no-ff na main → suíte no merge → push
