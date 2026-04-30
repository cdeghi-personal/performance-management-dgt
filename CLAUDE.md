# Performance Management DGT — Contexto do Projeto

## O que é este projeto

App mobile (iOS + Android) de gestão de desempenho dos funcionários da **DGT Consultoria**.
Backend: plataforma BPM **SYDLE ONE** (sydle.one) — expõe REST API para todos os dados.

## Stack

- **Flutter 3.x** + **Dart 3.x**
- **flutter_riverpod** — state management
- **go_router** — navegação declarativa
- **dio** — HTTP client (integração SYDLE)
- **flutter_secure_storage** — tokens JWT
- **freezed** + **json_serializable** — serialização (rodar `dart run build_runner build`)
- **fl_chart** / **percent_indicator** — gráficos e barras de progresso
- **table_calendar** — calendário de reuniões

## Estrutura de pastas

```
lib/
  main.dart                   # Entry point
  app.dart                    # MaterialApp.router + tema + locale
  core/
    api/
      api_constants.dart      # Endpoints SYDLE (ajustar após documentação)
      sydle_client.dart       # Dio client + interceptor de token + refresh automático
    auth/
      auth_token_storage.dart # FlutterSecureStorage (access_token, refresh_token, user_id)
    router/
      app_router.dart         # GoRouter com redirect por auth state
    shell/
      main_shell.dart         # NavigationBar com 5 destinos
    theme/
      app_colors.dart         # Paleta DGT (primary #1A3C6E, accent #00A896)
      app_theme.dart          # ThemeData light/dark
    utils/
      date_utils.dart         # formatDate, semesterLabel, daysUntil etc.
  features/
    auth/                     # Login, AuthUser, AuthNotifier (Riverpod AsyncNotifier)
    dashboard/                # KPIs + ações rápidas
    goals/                    # Metas anuais (GoalStatus, KeyResult, GoalFormScreen)
    evaluations/              # Avaliações semestrais (autoavaliação + gestor + calibração)
    feedback/                 # Feedbacks pontuais (FeedbackType, visibilidade)
    meetings/                 # Reuniões executivas de performance
    promotions/               # Feedback de promoção (PromotionStatus)
    quotas/                   # Programa de Cotas DGT (QuotaTarget, fillRate)
  shared/
    widgets/
      empty_state.dart        # AppEmptyState + AppLoadingIndicator
```

## Integração SYDLE ONE

- Base URL configurada via `--dart-define=SYDLE_BASE_URL=https://...` no build
- Todos os endpoints em `core/api/api_constants.dart` — **ajustar após documentação oficial**
- Token JWT salvo em `flutter_secure_storage` — refresh automático no interceptor do Dio (HTTP 401)
- Ao receber documentação SYDLE: preencher `data/` repositories de cada feature

## Módulos do app

| Módulo | Acesso | Descrição |
|---|---|---|
| Dashboard | Todos | KPIs do ciclo + atalhos |
| Metas | Todos | Ciclo anual, Key Results, progresso |
| Avaliações | Todos / gestor | Semestrais: autoavaliação → gestor → calibração executiva |
| Feedbacks | Todos | Pontuais, por tipo e visibilidade |
| Reuniões | Gestor/Diretor | Reuniões formais do grupo executivo sobre performance |
| Promoções | Gestor/Diretor | Solicitações + feedback de promoção |
| Cotas DGT | Gestor/Diretor | Programa de Cotas — raça, gênero, PcD, LGBTQIA+ |

## Roles

| Role | Acesso |
|---|---|
| `employee` | Próprias metas, avaliações, feedbacks recebidos/enviados |
| `manager` | Time direto + reuniões + promoções + cotas |
| `director` | Todos os dados + calibração executiva |
| `admin` | Configurações do sistema |

## Para começar (após instalar Flutter)

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Configurar SYDLE

```bash
flutter run --dart-define=SYDLE_BASE_URL=https://app.sydle.one/api
```

## Build para produção

```bash
# Android
flutter build apk --dart-define=SYDLE_BASE_URL=https://...
flutter build appbundle --dart-define=SYDLE_BASE_URL=https://...

# iOS
flutter build ios --dart-define=SYDLE_BASE_URL=https://...
```