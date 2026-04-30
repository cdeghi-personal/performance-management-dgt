# Performance Management DGT — Contexto do Projeto

## O que é este projeto

App mobile (iOS + Android) de gestão de desempenho dos funcionários da **DGT Consultoria**.
Backend: plataforma BPM **SYDLE ONE** (sydle.one) — expõe REST API para todos os dados.

## Stack

- **Flutter 3.x** + **Dart 3.x**
- **flutter_riverpod** — state management
- **go_router** — navegação declarativa
- **dio** — HTTP client (integração SYDLE)
- **flutter_secure_storage** — sessão local
- **freezed** + **json_serializable** — serialização (rodar `dart run build_runner build`)
- **fl_chart** / **percent_indicator** — gráficos e barras de progresso
- **table_calendar** — calendário de reuniões

## Integração SYDLE ONE — Modelo Real

### Endpoint padrão

Todas as chamadas são **HTTP POST**:
```
POST https://<org>.sydle.one/api/1/main/<pacote>/<classe>/<metodo>
```

### Headers obrigatórios (fixos em toda chamada)

```
Authorization: Basic <TOKEN_BASE64_SERVICO>   ← token da conta de serviço do app
X-Explorer-Account-Token: <organizacao>
Content-Type: application/json
```

### NÃO existe GET/PUT/DELETE — tudo é POST

### Autenticação do usuário

- Chama `/appDgt/authorization/login` com `{username, password}`
- Resposta: `{"status": "OK"}` ou `{"status": "NOK"}`
- Se OK → salvar sessão local (MVP: sem expiração, usuário fica logado até logout)
- A requisição HTTP usa o token fixo de serviço — não tem token por usuário no MVP

### Respostas de busca (_search)

Padrão Elasticsearch. Sempre acessar via:
```dart
SydleSearchResponse.fromJson(json, (source) => Model.fromJson(source))
// ou manualmente: json['hits']['hits'][i]['_source']
```

### Configuração (nunca hardcodar)

```bash
flutter run \
  --dart-define=SYDLE_ORG=<organizacao> \
  --dart-define=SYDLE_AUTH_TOKEN="Basic <base64>"
```

## Estrutura de pastas

```
lib/
  main.dart
  app.dart
  core/
    config/
      app_config.dart          # SYDLE_ORG + SYDLE_AUTH_TOKEN via dart-define
    api/
      api_constants.dart       # SydlePackage, SydleClass, SydleMethod
      sydle_client.dart        # Dio POST-only + headers fixos
      sydle_search_response.dart  # Parser Elasticsearch + helpers de query
    auth/
      auth_token_storage.dart  # FlutterSecureStorage (username, displayName, userId)
    error/
      sydle_exception.dart     # SydleException, SydleAuthException, SydleNotFoundException
    router/app_router.dart
    shell/main_shell.dart
    theme/app_colors.dart      # Paleta DGT (primary #1A3C6E, accent #00A896)
    theme/app_theme.dart
    utils/date_utils.dart
  features/
    auth/                      # login OK/NOK, sessão local, AuthNotifier
    dashboard/                 # KPIs + ações rápidas
    goals/                     # Metas anuais (GoalStatus, KeyResult)
    evaluations/               # Avaliações semestrais
    feedback/                  # Feedbacks pontuais
    meetings/                  # Reuniões executivas
    promotions/                # Feedback de promoção
    quotas/                    # Programa de Cotas DGT
  shared/widgets/
```

## Como implementar um novo método SYDLE

```dart
// Em features/<modulo>/data/<modulo>_repository.dart:
final data = await _client.call(
  SydlePackage.performance,   // pacote
  SydleClass.goal,            // classe
  SydleMethod.search,         // método
  body: matchAllQuery(),      // query Elasticsearch
);
final result = SydleSearchResponse.fromJson(
  data as Map<String, dynamic>,
  Goal.fromJson,
);
```

## Módulos

| Módulo | Acesso | Descrição |
|---|---|---|
| Dashboard | Todos | KPIs do ciclo + atalhos |
| Metas | Todos | Ciclo anual, Key Results, progresso |
| Avaliações | Todos / gestor | Semestrais: auto → gestor → calibração |
| Feedbacks | Todos | Pontuais, por tipo e visibilidade |
| Reuniões | Gestor/Diretor | Grupo executivo sobre performance |
| Promoções | Gestor/Diretor | Solicitações + feedback de promoção |
| Cotas DGT | Gestor/Diretor | Raça, gênero, PcD, LGBTQIA+ |

## Roles

| Role | Acesso |
|---|---|
| `employee` | Próprias metas, avaliações, feedbacks |
| `manager` | Time direto + reuniões + promoções + cotas |
| `director` | Todos os dados + calibração executiva |
| `admin` | Configurações |

## Para rodar

```bash
flutter pub get
flutter run \
  --dart-define=SYDLE_ORG=suaOrg \
  --dart-define=SYDLE_AUTH_TOKEN="Basic xxx"
```

## Build produção

```bash
flutter build appbundle \
  --dart-define=SYDLE_ORG=suaOrg \
  --dart-define=SYDLE_AUTH_TOKEN="Basic xxx"
```