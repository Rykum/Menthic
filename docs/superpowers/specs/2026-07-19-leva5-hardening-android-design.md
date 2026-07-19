# Leva 5 — Hardening Android: fontes offline, previsão re-hidratada, build APK

**Data:** 2026-07-19 · **Status:** aprovado ("pode seguir seu plano") · **Nota do usuário:** banco de dados futuro = **Firebase** (SQLite descartado do roadmap; o snapshot em shared_preferences segue até a integração Firebase).

## 1. Objetivo

Deixar o app saudável fora do Chrome-dev: sem dependência de rede em runtime
(fontes embutidas), sem estado perdido em reload (Hoje re-hidrata a previsão
do dia) e compilando para Android (APK).

## 2. Design

### 2.1 Fontes embutidas (remove `google_fonts`)
- `scripts/fetch_fonts.mjs`: baixa TTFs estáticos via API css2 com User-Agent
  simples (que recebe URLs .ttf): Fredoka 600/700 e Nunito 400/500/600/700 →
  `app/assets/fonts/` (commitados; licença OFL).
- `pubspec.yaml`: declara as famílias `Fredoka` e `Nunito` com os pesos;
  remove a dependência `google_fonts`.
- `app/lib/design/fonts.dart`: helpers `fredoka({...})`/`nunito({...})`
  (mesma assinatura usada hoje) → única mudança nos call sites é o import;
  `theme.dart` troca `GoogleFonts.nunitoTextTheme(...)` por
  `textTheme.apply(fontFamily: 'Nunito')` e `GoogleFonts.fredoka` pelo helper.

### 2.2 Hoje re-hidrata a previsão do dia
- Hoje o card some ao recarregar a página (estado só em memória). O `_reload`
  passa a verificar se existe `previsao_emitida` hoje; se sim, recomputa o
  `OracleAnswer` com os mesmos inputs (determinístico, seed 0) **sem** emitir
  novo evento. `_prever` continua sendo o único que grava.

### 2.3 Build Android
- Licenças do SDK aceitas; `flutter build apk --debug` verde é o critério
  (emulador fica fora do escopo desta leva).

## 3. Testes
- Suíte inteira continua verde sem `google_fonts` (os testes não referenciam o
  pacote diretamente).
- Novo teste na Hoje: com `previsao_emitida` de hoje seedada, a tela abre já
  mostrando o card e **não** grava nova previsão.
- `flutter build web` e `flutter build apk --debug` verdes.

## 4. Fora de escopo
Firebase (auth/sync) — próxima leva, exige projeto/config do usuário; ícone e
splash nativos do Android; emulador.
