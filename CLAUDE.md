# Performance Management DGT — Contexto do Projeto

## O que é este projeto

App mobile (iOS + Android) de gestão de desempenho dos funcionários da **DGT Consultoria**.
Backend: plataforma BPM **SYDLE ONE** (sydle.one) — expõe REST API para todos os dados.

## Stack

- **Flutter 3.x** + **Dart 3.x**
- **flutter_riverpod** — state management
- **go_router** — navegação declarativa
- **dio** — HTTP client (integração SYDLE)
- **flutter_secure_storage** — sessão local (web usa localStorage automaticamente)
- **freezed** + **json_serializable** — serialização (rodar `dart run build_runner build`)
- **fl_chart** / **percent_indicator** — gráficos e barras de progresso
- **google_fonts** — tipografia (Inter)

## Integração SYDLE ONE — Modelo Real

### Endpoint padrão

Todas as chamadas são **HTTP POST**:
```
POST https://<org>.sydle.one/api/1/main/<pacote>/<classe>/<metodo>
```

### Headers obrigatórios nas chamadas de negócio

```
Authorization: Bearer <token_do_usuario>   ← injetado automaticamente pelo AuthInterceptor
X-Explorer-Account-Token: <organizacao>
Content-Type: application/json
```

### NÃO existe GET/PUT/DELETE — tudo é POST (exceto autenticação)

### URL base — identificador da aplicação

Todas as chamadas (negócio + autenticação) usam o mesmo `<identificadorDaAplicacao>`:

```
https://<org>.sydle.one/api/1/<identificadorDaAplicacao>/...
```

O identificador desta aplicação é **`perfManagement`**. Ele deve estar configurado em **todos os orgs SYDLE** que o app acessar (dev, prod, etc.). Se um org não tiver essa aplicação criada, todas as chamadas retornarão 401 — incluindo o login.

⚠️ **Se o login falhar com 401 em um novo org:** verifique se a aplicação `perfManagement` está criada no painel administrativo daquele org no SYDLE ONE.

### Autenticação do usuário — fluxo real

1. **`GET /<identificadorDaAplicacao>/sys/auth/signIn`** com `Authorization: Basic base64(login:senha)` — endpoint nativo do SYDLE ONE
   - URL completa: `https://<org>.sydle.one/api/1/perfManagement/sys/auth/signIn`
   - Headers obrigatórios: `X-Explorer-Account-Token: <org>` e `Authorization: Basic <base64>`
   - Resposta: `{ "code": "...", "name": "...", "login": "...", "accessToken": { "token": "<JWT>", "payload": { "exp": <unix_sec>, "sessionId": "..." } } }`
   - O Bearer token resultante é armazenado no `SessionManager` e injetado pelo `AuthInterceptor` em todas as chamadas seguintes
2. **Search `projetosDGT.colaboradorDGT`** onde `user._id == sess.code` → obtém o `colaboradorId`
3. **Search `perfMngt.employeeProfile`** onde `employee._id == colaboradorId` → obtém o `profile` (employee/leader/hr)

O token expira conforme `payload.exp`. `SessionManager.hasValidSession()` valida expiração + presença do `colaboradorId`.

**Implementação:** `AuthService` (signIn/signOut) + `AuthRepository` (orquestra as 3 fases) + `AuthInterceptor` (injeta Bearer).

### Respostas de busca (_search)

Padrão Elasticsearch. Sempre acessar via:
```dart
SydleSearchResponse.fromJson(json, (source) => Model.fromJson(source))
// ou manualmente: json['hits']['hits'][i]['_source']
```

### Campos de sistema SYDLE (presentes em todo objeto)

| Campo SYDLE | Tipo | Uso |
|---|---|---|
| `_id` | String | ID do objeto |
| `_creationDate` | int (ms) | Data de criação |
| `_lastUpdate` | int (ms) | Data da última alteração |

Sempre mapear `_lastUpdate` nos modelos como `DateTime? lastUpdate`.

### Campos de referência (objetos relacionados)

SYDLE embute referências como `{"_id": "...", "name": "...", ...}`. Para extrair o nome, tentar múltiplas chaves com `_refName()`:

```dart
static String _refName(dynamic ref) {
  if (ref is! Map<String, dynamic>) return '';
  for (final key in ['name', 'nomeCompleto', 'nome', 'displayName', 'fullName']) {
    final v = ref[key];
    if (v is String && v.isNotEmpty) return v;
  }
  return '';
}
```

### Pacotes SYDLE em uso

| Constante | Valor | Classes |
|---|---|---|
| `SydlePackage.appDgt` | `'appDgt'` | `authorization` |
| `SydlePackage.perfMngt` | `'perfMngt'` | `cycle`, `criterion`, `autoEvaluation`, `leaderEvaluation`, `employeeProfile` |
| `SydlePackage.projetosDGT` | `'projetosDGT'` | `colaboradorDGT` |

`SydleClass.liderEvaluation` tem valor `'leaderEvaluation'` (inglês, nome real no SYDLE).
`SydleClass.colaboradorDGT` tem valor `'colaboradorDGT'` — usa pacote `projetosDGT`, não `perfMngt`.
`SydleClass.employeeProfile` tem valor `'employeeProfile'` — usa pacote `perfMngt`.

### Typo no SYDLE: `EvaluationMetting`

A fase de reunião de avaliações é persistida como `'EvaluationMetting'` (dois t's) — isso é um typo no backend SYDLE ONE. O `PhaseIdentifier.fromString` já trata isso:
```dart
case 'EvaluationMetting': return PhaseIdentifier.evaluationMeeting;
```

### Configuração (nunca hardcodar)

```bash
flutter run --dart-define=SYDLE_ORG=<organizacao>
```

## Perfis de usuário (`UserProfile`)

Três perfis existentes no sistema — usar apenas estes:

| Perfil | Enum | Acesso |
|---|---|---|
| `employee` | `UserProfile.employee` | Próprias avaliações, metas, feedbacks |
| `leader` | `UserProfile.leader` | Time direto + equalização + promoções + cotas |
| `HR` | `UserProfile.hr` | Todos os dados + configurações |

```dart
// Providers disponíveis em auth_provider.dart:
currentProfileProvider   // UserProfile?
isManagerProvider        // true para leader e HR (acesso à equalização e time)
```

`isManagerProvider` retorna `true` para `leader` e `HR`. Nunca usar strings de role diretamente — usar `UserProfile` enum e seus getters (`isLeader`, `isHR`, `isEmployee`, `canAccessEqualization`).

## Design System DGT

### Paleta de cores (`AppColors`)

```dart
primary   = Color(0xFFFCB017)  // amarelo principal — botões, destaques, etapa ativa
secondary = Color(0xFFFED402)  // amarelo secundário
darkGray  = Color(0xFF3A3A3A)  // headers, textos principais, AppBar
midGray   = Color(0xFF787878)  // subtítulos, labels secundários
lightGray = Color(0xFFD3D3D3)  // bordas, placeholders
background = Color(0xFFF5F5F5) // fundo geral (Scaffold)
surface    = Color(0xFFFFFFFF) // cards
```

### Tipografia

Inter (Google Fonts). Pesos: 400 (regular) e 500 (medium). Sem serifa.

### Padrão de card

```dart
// Card padrão
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: AppColors.border, width: 0.5),
  ),
)

// Card destacado (etapa ativa, seção de notas do gestor)
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: AppColors.primary, width: 1.5),
  ),
)
```

**NUNCA usar `Border()` com lados não-uniformes junto com `borderRadius`** — causa erro de renderização no Flutter. Sempre usar `Border.all()` quando há `borderRadius`.

### Botões

```dart
// Primário (amarelo)
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.darkGray,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    padding: EdgeInsets.symmetric(vertical: 14),
  ),
)

// Secundário (outline escuro)
OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: AppColors.darkGray,
    side: BorderSide(color: AppColors.darkGray, width: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    padding: EdgeInsets.symmetric(vertical: 14),
  ),
)
```

### Padrão de AppBar — `DgtAppBar`

Todo AppBar do app usa o widget centralizado `DgtAppBar` (`shared/widgets/dgt_app_bar.dart`). Fundo sempre `AppColors.darkGray`, logo DGT embutida.

```dart
// Telas principais e de detalhe simples
DgtAppBar.simple(title: 'Título', subtitle: 'subtítulo opcional', actions: [...])

// Telas de detalhe de avaliação (3 linhas: tipo / pessoa / contexto)
DgtAppBar.detail(
  typeLabel: 'Auto-Avaliação',   // linha 1
  personLabel: 'Nome',           // linha 2 (omitida se null/vazio)
  contextLine: 'Período · Status', // linha 3
  actions: [...],
)
// detail usa toolbarHeight: 68 para acomodar 3 linhas
```

**NUNCA usar `AppBar(...)` diretamente** — usar sempre `DgtAppBar.simple()` ou `DgtAppBar.detail()`.

### `EvaluationDisplayModel` — ViewModel centralizado

Toda tela de avaliação usa `EvaluationDisplayModel` (`evaluations/presentation/evaluation_display_model.dart`) para construir textos dos cards e headers. Proibido montar texto de período/status/avaliador manualmente nas telas.

```dart
// Factories resolvidas (preferir sempre que resolved* disponível):
EvaluationDisplayModel.fromResolvedAuto(r, currentUserName: name)
EvaluationDisplayModel.fromResolvedLiderReceived(r, currentUserName: name)
EvaluationDisplayModel.fromResolvedLiderManager(r)

// Factories brutas (fallback durante carregamento):
EvaluationDisplayModel.fromAutoEvaluation(eval, currentUserName: name)
EvaluationDisplayModel.fromLiderEvaluationReceived(eval, currentUserName: name)
EvaluationDisplayModel.fromLiderEvaluationManager(eval)

// Campos:
// typeLabel         — "Auto-Avaliação" / "Avaliação do Gestor"
// personLabel       — nome do usuário (auto) ou do colaborador (gestor)
// cardLine1         — período (auto) ou "Avaliador: nome" / "Avaliado: nome"
// cardLine2         — "período · Status: X"
// lastUpdateLabel   — "Atualizado em DD/MM/YYYY" (nullable)
// headerContextLine — linha de contexto para DgtAppBar.detail()
```

### Padrão de card de lista (`_EvalCard`)

O widget `_EvalCard` em `evaluations_screen.dart` tem quatro campos:
- `title` — nome do item (14px, w500)
- `subtitle` — período + status ou informação adicional (12px, textSecondary)
- `detail` (opcional) — linha extra entre subtitle e extra (12px, textSecondary)
- `extra` (opcional) — data de última alteração (11px, textDisabled)

### Padrão de rodapé de datas (`_DateFooter`)

Toda tela de detalhe de avaliação deve ter um rodapé com:
```dart
_DateFooter(creationDate: eval.creationDate, lastUpdate: eval.lastUpdate)
```
Mostra "Criado em DD/MM/YYYY" e "Atualizado em DD/MM/YYYY" em texto pequeno (11px, textDisabled).

## Navegação

`BottomNavigationBar` com tabs adaptados por perfil:

| Tab | Ícone | Rota | Perfis |
|-----|-------|------|--------|
| Home | grid_view_rounded | `/dashboard` | todos |
| Avaliações | checklist_rounded | `/avaliacoes` | todos |
| Metas | track_changes_rounded | `/metas` | todos |
| Equalização | balance_rounded | `/avaliacoes/equalizacao` | leader, HR |
| Perfil | person_outline_rounded | `/perfil` | todos |

A tab **Equalização** só aparece para `leader` e `HR` (`isManagerProvider == true`).

## Estrutura de pastas

```
lib/
  main.dart
  app.dart
  core/
    config/
      app_config.dart               # SYDLE_ORG via dart-define
    api/
      api_constants.dart            # SydlePackage, SydleClass, SydleMethod
      sydle_client.dart             # Dio POST-only + headers fixos
      sydle_search_response.dart    # Parser Elasticsearch + helpers de query
    auth/
      auth_token_storage.dart       # FlutterSecureStorage (username, displayName, userId)
    error/
      sydle_exception.dart          # SydleException, SydleAuthException, SydleNotFoundException
    router/app_router.dart
    shell/main_shell.dart           # BottomNavigationBar com 5 tabs (role-aware)
    theme/
      app_colors.dart               # Paleta DGT amarelo/escuro
      app_theme.dart
    utils/date_utils.dart
  features/
    auth/                           # Login, sessão local, AuthNotifier
    dashboard/                      # Header escuro, pendências, KPIs, mini-stepper
    evaluations/
      data/
        models/
          auto_evaluation_model.dart   # AutoEvaluation + EvaluationStatus
          lider_evaluation_model.dart  # LiderEvaluation + EvaluationClassification
          cycle_model.dart             # Cycle + TabPhase + PhaseIdentifier + PhaseStatus + toJson()
          criterion_model.dart         # Criterion + CriterionType
          tab_evaluation_model.dart    # TabEvaluation (embedded)
          tab_goal_model.dart          # TabGoal (embedded)
        repositories/
          auto_evaluation_repository.dart
          lider_evaluation_repository.dart  # inclui getAllByEmployee + getFinishedByEmployee
          cycle_repository.dart             # inclui getByIds(List<String>) + updateCyclePhases()
          criterion_repository.dart
          colaborador_repository.dart       # ColaboradorDGT model + getAll() + getNamesByIds + getDetailsByIds → projetosDGT.colaboradorDGT
      domain/
        evaluation_providers.dart    # Todos os providers de avaliação brutos
        enrichment_providers.dart    # Providers resolvidos (período + nomes via API)
      presentation/
        evaluation_display_model.dart  # ViewModel centralizado — factories raw + fromResolved*
        resolved_eval.dart             # ResolvedAutoEval, ResolvedLiderEval, ResolvedMyEval (sealed)
        evaluations_screen.dart        # Lista principal — filtro Ciclo Atual / Todos
        cycle_journey_page.dart        # Stepper vertical — CTA para todos os perfis quando auto-avaliação pendente
        self_evaluation_page.dart      # Sliders 0-10 + campos qualitativos (edit + read-only)
        manager_evaluation_page.dart   # Avaliação do gestor: critérios + qualitativo + classificação + TopPerformer
        equalization_page.dart         # Equalização: escopo por perfil + KPI + filtro nível + cards + modal "?" + modal "Perfil"
        received_evaluation_page.dart  # Avaliação recebida (read-only): critérios + notas + nextGoals
    goals/                          # Metas anuais — HR vê todos, leader vê time
    profile/
      data/
        employee_perfil_model.dart    # EmployeePerfil + campos de ciclo anterior
        employee_perfil_repository.dart  # getByEmployeeId → perfMngt.employeeProfile
      domain/
        profile_providers.dart        # myEmployeePerfilProvider + employeeProfileByEmployeeIdProvider
      presentation/
        profile_page.dart             # Perfil do usuário logado com dados de EmployeePerfil
    feedback/                       # Feedbacks pontuais (existente, não roteado ainda)
    promotions/                     # Promoções (existente, não roteado ainda)
    quotas/                         # Cotas DGT (existente, não roteado ainda)
    splash/
      splash_screen.dart              # Tela animada de abertura (tachômetro DGT)
  shared/
    widgets/
      avatar_initials.dart          # Avatar com iniciais do nome
      cycle_badge.dart              # CycleBadge + CycleBadgeSkeleton
      dgt_app_bar.dart              # DgtAppBar.simple() e DgtAppBar.detail() — usar em TODAS as telas
      status_badge.dart             # StepStatusBadge, ClassificationBadge
      read_only_banner.dart         # Banner "somente leitura" para avaliações finalizadas
      empty_state.dart
```

## Rotas

```
/splash                                  → SplashScreen (fora do shell, rota inicial)
/login                                   → LoginScreen (fora do shell)
/dashboard                               → DashboardScreen
/avaliacoes                              → EvaluationsScreen
/avaliacoes/jornada                      → CycleJourneyPage
/avaliacoes/auto                         → SelfEvaluationPage (ciclo ativo, editável)
/avaliacoes/auto/:evalId                 → SelfEvaluationPage(evalId) (histórico, read-only)
/avaliacoes/gestor/:employeeId           → ManagerEvaluationPage(employeeId) — ciclo ativo (editável)
/avaliacoes/gestor/historico/:evalId     → ManagerEvaluationPage(evalId) — histórico (read-only)
/avaliacoes/recebida/:evalId             → ReceivedEvaluationPage (avaliação recebida, read-only)
/avaliacoes/equalizacao                  → EqualizationPage (leader, HR)
/metas                                   → GoalsScreen
/perfil                                  → ProfilePage
```

Guard de autenticação no router: não autenticado → `/login`; autenticado em `/login` → `/dashboard`.

## Modelos de dados — campos importantes

### `Cycle`
- `tabPhases: List<TabPhase>` — fases do ciclo vindas do SYDLE (substitui campos de data individuais)
- `cycleDate: DateTime?` — data de referência do ciclo para ordenação
- `creationDate: DateTime` — data de criação no SYDLE (`_creationDate`)
- Getters de conveniência: `selfEvalPhase`, `leaderEvalPhase`, `meetingPhase`, `resultsPhase`
- `criteriaIds: List<String>` — IDs dos critérios associados ao ciclo
- `toJson()` — serializa o ciclo completo para uso com `_update` (SYDLE não suporta `_patch` em arrays embedded como `tabPhases`)

### `EmployeePerfil`
- Modelo em `profile/data/employee_perfil_model.dart`, buscado via `perfMngt.employeeProfile`
- `employeeId: String` — referência ao colaborador (extraído de `json['employee']['_id']`)
- `careerLevel: String` — nível de carreira atual
- `function: String` — cargo/função
- `hiringDate: DateTime?` — data de admissão
- `classificacationLastCycle: String` — classificação no último ciclo (**typo SYDLE intencional**: dois 'a' em "classificacation")
- `topPerformer: bool` — top performer no último ciclo
- `classificacationPreviousCycle: String` — classificação no ciclo anterior ao último
- `topPerformerUltimoCiclo: bool` — top performer no ciclo anterior

### `TabPhase`
- `phase: PhaseIdentifier` — enum: `started`, `selfEvaluation`, `leaderEvaluation`, `evaluationMeeting`, `results`
- `status: PhaseStatus` — enum: `notStarted`, `onGoing`, `finished`
- `planDate: DateTime?` — prazo planejado
- SYDLE usa o typo `'EvaluationMetting'` → mapeado corretamente no `fromString`

### `AutoEvaluation`
- `status: EvaluationStatus` — valores SYDLE em camelCase: `'notStarted'`, `'onGoing'`, `'finished'`, `'cancelled'`
- `isReadOnly` — `true` quando `finished` ou `cancelled`
- `cycleId` — ID do ciclo ao qual pertence (usado para filtro de Ciclo Atual)
- `cyclePeriod`, `cycleYear` — extraídos da referência `cycle` embedded
- `lastUpdate: DateTime?` — data da última alteração (`_lastUpdate` SYDLE)
- `Goals` — nota: o array de metas usa `'Goals'` com G maiúsculo no JSON SYDLE

### `LiderEvaluation`
- Mesmos campos de status que `AutoEvaluation`
- `cycleId` — ID do ciclo ao qual pertence (usado para filtro de Ciclo Atual)
- `employeeId`, `employeeName: String` — colaborador avaliado (usa `_refName()`)
- `appraiserId`, `appraiserName: String` — gestor avaliador (usa `_refName()`)
- `lastUpdate: DateTime?` — data da última alteração (`_lastUpdate` SYDLE)
- `classification: EvaluationClassification?` — `aboveLevel`, `atLevel`, `belowLevel`
- `topPerformer: bool` — independente da classificação
- `commentsPerfMeeting: String?` — comentário da reunião de avaliação (campo real no SYDLE: `'commentsPerfMeeting'`)

### `CycleStatus` vs `EvaluationStatus`

Atenção: os enums de status usam capitalização diferente no SYDLE:
- `CycleStatus`: valores com inicial maiúscula — `'OnGoing'`, `'Finished'`, `'Cancelled'`
- `EvaluationStatus` (auto + lider): valores em camelCase — `'onGoing'`, `'finished'`, `'cancelled'`

## Camada de enriquecimento (`enrichment_providers.dart`)

O SYDLE embute referências de objetos relacionados apenas com o `_id`, sem campos extras.
Por isso, `cyclePeriod`, `cycleYear`, `employeeName` e `appraiserName` chegam vazios.
A camada de enriquecimento resolve esses dados via chamadas adicionais ao backend.

### Tipos resolvidos (`resolved_eval.dart`)

```dart
// Dados enriquecidos com período resolvido e nomes:
ResolvedAutoEval  { eval, periodLabel, employeeName, cycleDate }
ResolvedLiderEval { eval, periodLabel, employeeName, appraiserName, cycleDate }

// Hierarquia selada para lista unificada "Minhas Avaliações":
sealed class ResolvedMyEval {
  DateTime get sortCycleDate;
  DateTime get sortLastUpdate;
}
final class ResolvedMyAutoEval extends ResolvedMyEval         { final ResolvedAutoEval data; }
final class ResolvedMyLiderEvalReceived extends ResolvedMyEval { final ResolvedLiderEval data; }
```

`cycleDate` em ambos os tipos usa `cycle.cycleDate ?? cycle.creationDate` para ordenação. É `null` apenas se o ciclo não foi encontrado.

### Ordenação padrão

Todas as listas de avaliações são ordenadas por:
1. `cycleDate` DESC (ciclo mais recente primeiro)
2. `lastUpdate` DESC (mais recentemente modificada primeiro, dentro do mesmo ciclo)

Aplicar sempre — tanto em "Ciclo Atual" quanto em "Todos os Ciclos".

### Providers de enriquecimento

| Provider | Fonte bruta | Resolve |
|---|---|---|
| `resolvedMyEvalsProvider` | `autoEvaluationsProvider` + `myReceivedLiderEvaluationsProvider` | período + nomes; mescla + ordena |
| `resolvedTeamEvalsProvider` | `myCurrentCycleTeamProvider` | período + nomes; ordena |
| `resolvedMyAutoEvalProvider` | `myAutoEvaluationProvider` | período |
| `resolvedAutoEvalByIdProvider(id)` | `autoEvaluationByIdProvider` | período |
| `resolvedLiderEvalByIdProvider(id)` | `liderEvaluationByIdProvider` | período + nomes |
| `resolvedLiderEvalForEmployeeProvider(id)` | `liderEvaluationForEmployeeProvider` | período + nomes |

### Regras de uso

- **Telas de listagem**: sempre usar providers `resolved*` — nunca os brutos.
- **Telas de detalhe**: watch do provider raw (para form state) + watch do `resolved*` (para AppBar/displayModel). O `displayModel` usa `fromResolved*` quando disponível, caindo de volta no `from*` bruto durante o carregamento.
- **Nomes de colaboradores**: buscados em batch via `ColaboradorRepository.getNamesByIds()` (POST para `projetosDGT.colaboradorDGT`).
- **Períodos de ciclo**: o ciclo ativo (`activeCycleProvider`) é reaproveitado; ciclos históricos são buscados em batch via `CycleRepository.getByIds()`.
- **Auto-avaliação**: `employeeName` em `ResolvedAutoEval` fica vazio — a UI usa `currentUserProvider?.name` diretamente.

### `ColaboradorDGT` e `ColaboradorRepository` (`colaborador_repository.dart`)

```dart
class ColaboradorDGT {
  final String id;
  final String name;
  final String careerLevel; // tenta: careerLevel, nivelCarreira, nivel, cargo, senioridade
}

// Lista todos os colaboradores DGT (size: 200)
ColaboradorRepository.getAll() → List<ColaboradorDGT>

// Busca nomes por IDs — resultado simplificado
ColaboradorRepository.getNamesByIds(List<String> ids) → Map<String, String>

// Busca dados completos (nome + nível de carreira) por IDs
ColaboradorRepository.getDetailsByIds(List<String> ids) → Map<String, ColaboradorDGT>

// POST para SydlePackage.projetosDGT / SydleClass.colaboradorDGT
```

Usar `getAll()` quando o contexto exige a lista completa (ex.: GoalsScreen para HR).
Usar `getDetailsByIds` quando o nível de carreira for necessário para um subconjunto (equalização).
Usar `getNamesByIds` apenas para enriquecimento simples de nome.

## Providers de avaliação (`evaluation_providers.dart`)

| Provider | Tipo | Descrição |
|---|---|---|
| `activeCycleProvider` | `FutureProvider<Cycle?>` | Ciclo ativo global — carregado uma vez |
| `autoEvaluationsProvider` | `FutureProvider<List<AutoEvaluation>>` | Histórico completo de auto-avaliações do usuário (todos os status) |
| `myAutoEvaluationProvider` | `FutureProvider<AutoEvaluation?>` | Auto-avaliação do usuário no ciclo ativo |
| `autoEvaluationByIdProvider` | `FutureProvider.family<AutoEvaluation?, String>` | Auto-avaliação por ID (histórico) |
| `myReceivedLiderEvaluationsProvider` | `FutureProvider<List<LiderEvaluation>>` | Avaliações do gestor **finalizadas** recebidas pelo usuário (`status==finished` apenas) |
| `liderEvaluationByIdProvider` | `FutureProvider.family<LiderEvaluation?, String>` | Avaliação do gestor por ID |
| `myCurrentCycleTeamProvider` | `FutureProvider<List<LiderEvaluation>>` | Avaliações do time do gestor no ciclo ativo (todos os status) |
| `liderEvaluationForEmployeeProvider` | `FutureProvider.family<LiderEvaluation?, String>` | Avaliação de um colaborador específico pelo gestor logado |
| `autoEvaluationForEmployeeProvider` | `FutureProvider.family<AutoEvaluation?, String>` | Auto-avaliação de um colaborador no ciclo ativo — usado pela EqualizationPage |
| `autoEvalForLiderEvalProvider` | `FutureProvider.family<AutoEvaluation?, String>` | Auto-avaliação para ManagerEvaluationPage — key `"employeeId:cycleId"` derivada da LiderEvaluation; prioriza `finished`, cai para qualquer status |
| `cycleCriteriaProvider` | `FutureProvider<Map<CriterionType, List<Criterion>>>` | Critérios do ciclo ativo por tipo |
| `teamEvaluationsProvider` | `FutureProvider<List<LiderEvaluation>>` | Todas as avaliações do ciclo (HR, sem filtro de perfil) |
| `teamColaboradoresProvider` | `FutureProvider<Map<String, ColaboradorDGT>>` | Dados completos (nome + nível) derivado de `teamEvaluationsProvider` |
| `allColaboradoresProvider` | `FutureProvider<List<ColaboradorDGT>>` | Todos os colaboradores DGT — usado pela GoalsScreen (HR) |
| `equalizationEvalsProvider` | `FutureProvider<List<LiderEvaluation>>` | Avaliações com escopo por perfil: leader=time próprio, HR=todo o ciclo |
| `equalizationColaboradoresProvider` | `FutureProvider<Map<String, ColaboradorDGT>>` | Dados completos derivados de `equalizationEvalsProvider` — escopo correto por perfil |

## Providers de perfil (`profile/domain/profile_providers.dart`)

| Provider | Tipo | Descrição |
|---|---|---|
| `myEmployeePerfilProvider` | `FutureProvider<EmployeePerfil?>` | Perfil complementar do usuário logado |
| `employeeProfileByEmployeeIdProvider` | `FutureProvider.family<EmployeePerfil?, String>` | Perfil complementar de qualquer colaborador por ID — usado pela EqualizationPage |

## Regras de negócio transversais

### LiderEvaluation em "Minhas Avaliações" — somente `finished`

Na seção "Minhas Avaliações" da `EvaluationsScreen`, avaliações do gestor (leaderEvaluation) **nunca** aparecem com status `onGoing`, `notStarted` ou `cancelled` — somente `finished`.
Isso se aplica tanto ao filtro "Ciclo Atual" quanto a "Todos os Ciclos".
`myReceivedLiderEvaluationsProvider` já garante isso via `getFinishedByEmployee`.

### TopPerformer — confidencialidade

O campo `topPerformer` de `LiderEvaluation` é visível conforme o perfil:

| Perfil | Visibilidade |
|---|---|
| `HR` | sempre vê |
| `leader` | somente quando `eval.appraiserId == currentUser.colaboradorId` |
| `employee` | nunca vê |

```dart
final showTopPerformer = profile.isHR ||
    (currentUser != null && eval.appraiserId == currentUser.colaboradorId);
```

A classificação (`classification`) pode ser exibida para todos; o TopPerformer é confidencial ao gestor avaliador (e ao RH).

### Navegação após salvar rascunho

Toda ação "Salvar rascunho" deve navegar para `/avaliacoes` após o salvamento:
```dart
if (!finalize) context.go('/avaliacoes');
```
Ações "Finalizar" permanecem na mesma tela e exibem SnackBar de confirmação.

## ManagerEvaluationPage — gate da classificação

A seção "Resultado final" (classification + TopPerformer) só aparece quando a fase de reunião está ativa:

```dart
final cycle         = activeCycleProvider.valueOrNull;
final meetingActive = cycle?.meetingPhase?.status == PhaseStatus.onGoing;
final meetingFinished = cycle?.meetingPhase?.status == PhaseStatus.finished;
```

| Condição | Widget exibido |
|---|---|
| `!isReadOnly && isManager && meetingActive` | `_ClassificationSection` (editável) |
| `(isReadOnly || meetingFinished) && classification != null` | `_ResultFinalCard` (read-only) |
| `meetingPhase.status == notStarted` | nenhum dos dois |

Isso impede que gestor classifique o colaborador antes da reunião de avaliações acontecer.

## EqualizationPage — padrões

### Controle de acesso

`employee` não tem acesso à tela de equalização. No início de `build()`:
```dart
if (profile?.isEmployee == true) {
  return Scaffold(
    appBar: DgtAppBar.simple(title: 'Equalização'),
    body: Center(child: /* ícone cadeado + "Acesso restrito a gestores e RH." */),
  );
}
```

### Escopo por perfil (providers)

- **HR**: usa `getByCycle(cycle.id)` — vê todos os colaboradores do ciclo
- **Leader**: usa `getByAppraisersAndCycle(appraiserId: userId, cycleId: cycle.id)` — vê apenas o seu time

Providers corretos para a EqualizationPage:
- `equalizationEvalsProvider` — lista de avaliações com escopo correto
- `equalizationColaboradoresProvider` — colaboradores derivados do escopo correto

**Nunca** usar `teamEvaluationsProvider` / `teamColaboradoresProvider` na EqualizationPage — esses são sem filtro de perfil.

### Header

Usa `DgtAppBar.detail()` (não `simple()`) com:
- `typeLabel: 'Equalização'`
- `contextLine: '${cycle.period} ${cycle.year} · ${_cycleStatusLabel(cycle.status)}'`
- `bottom:` com a barra de filtros quando houver filtros ativos

```dart
String _cycleStatusLabel(CycleStatus s) {
  switch (s) {
    case CycleStatus.onGoing:    return 'Em andamento';
    case CycleStatus.finished:   return 'Finalizado';
    case CycleStatus.cancelled:  return 'Cancelado';
    case CycleStatus.notStarted: return 'Não iniciado';
  }
}
```

### Filtros — estrutura de 3 filtros com filtros avançados

A EqualizationPage tem **3 filtros multi-select** com lógica AND entre eles:

1. **Nível de carreira** — sempre visível (chips horizontais, dados de `equalizationColaboradoresProvider`)
2. **Gestor** — oculto atrás do chip "Filtros avançados" (dados de `eval.appraiserName`)
3. **Status** — oculto atrás do chip "Filtros avançados" (status da avaliação do gestor)

O chip "Filtros avançados" usa `AnimatedSize` para expandir/recolher os filtros opcionais. Quando há filtros avançados ativos, o chip exibe um badge numérico com a contagem.

O filtro de gestor só é exibido quando há mais de 1 gestor na lista (irrelevante para `leader` que só vê o próprio time).

Todos os filtros operam sobre dashboard **e** lista de cards. Sem seleção em um filtro = todos os itens desse filtro passam.

### Dashboard de distribuição

5 KPI cells calculados sobre o conjunto **filtrado**:
- % Acima do nível / % No nível / % Abaixo / N Pendente / N Top Performer

### Card do colaborador (`_EmployeeCard`)

É um `ConsumerWidget` — watch `autoEvaluationForEmployeeProvider(eval.employeeId)` por card (família de provider cacheada). Exibe:

- Nome, nível de carreira, nome do gestor (de `equalizationColaboradoresProvider`)
- **Médias comportamental (C) e técnica (T)**: 18px, `AppColors.darkGray`, `FontWeight.w600`
- **Badges de status**: `_EvalStatusBadge` para Auto e Gestor (cores: verde=finished, âmbar=onGoing, vermelho=cancelled, cinza=notStarted)
- Dropdown de classificação + toggle TopPerformer + campo de commentsPerfMeeting: **somente quando `meetingActive`**
- Badge de classificação read-only quando `!meetingActive && classification != null`
- **Botão "Perfil"** (ao lado do "?"): abre `_EmployeePerfilSheet` com dados de `EmployeePerfil`

### Botão "?" — `_DetailsSheet`

Bottom sheet **somente leitura** com dados reais de `LiderEvaluation`:

- Campos qualitativos sempre exibidos (strengths, attentionPoints, feedback, actionPlan) — valor ou "Não informado" (italic, textDisabled)
- Metas do período: `eval.goals` com `GoalAchievement` → "Atingida / Parcial / Não atingida"; `—` se sem registro
- Metas para o próximo período: `eval.nextGoals`
- Comentário da reunião: `eval.commentsPerfMeeting` (se preenchido)

**Proibido** mostrar mock, lorem ipsum ou dados estáticos no modal.

### Botão "Perfil" — `_EmployeePerfilSheet`

`ConsumerWidget` que watch `employeeProfileByEmployeeIdProvider(employeeId)`. Exibe em `DraggableScrollableSheet`:
- Seção **ÚLTIMO CICLO**: `classificacationLastCycle`, `topPerformer`
- Seção **CICLO ANTERIOR**: `classificacationPreviousCycle`, `topPerformerUltimoCiclo`
- Outros dados: `careerLevel`, `function`, `hiringDate` (formatada)
- Fallback: "Perfil complementar não encontrado" quando `EmployeePerfil == null`

### Salvamento (update completo)

```dart
repo.update(LiderEvaluation(
  ...e fields...,
  classification:      localClass,
  topPerformer:        localTop,
  commentsPerfMeeting: localNotes.isEmpty ? null : localNotes,
));
// Após salvar: invalidar equalizationEvalsProvider (não teamEvaluationsProvider)
ref.invalidate(equalizationEvalsProvider);
```

Botão "Salvar equalização" visível **somente quando `meetingActive`**.

## CycleJourneyPage — regras de negócio

- Renderiza `cycle.tabPhases` diretamente (não inventa etapas)
- Percentual de progresso = fases com `PhaseStatus.finished` / total de fases (sem crédito parcial para `onGoing`)
- "Você está aqui" aparece somente na fase `onGoing` de maior índice

### Lógica do CTA "Ir para auto-avaliação" — todos os perfis

O CTA aplica-se a **todos os perfis** (employee, leader e HR). O status da fase `selfEvaluation` é cruzado com o status individual da auto-avaliação do usuário (`myAutoEvaluationProvider`):

| Fase selfEvaluation | Auto-avaliação do usuário | Chip exibido | CTA |
|---|---|---|---|
| `onGoing` | `finished` | "Concluída para você" (verde) | Não |
| `onGoing` | `notStarted` / `onGoing` / `null` | "Em andamento" | Sim |
| `finished` | qualquer | "Concluída" | Não |
| `notStarted` | qualquer | "Em breve" | Não |

`_completedByUser`: fase `selfEvaluation` + ativa + `autoEvalStatus == finished`.
`_showCta`: fase ativa + `selfEvaluation` + `autoEvalStatus != null` + `autoEvalStatus != cancelled` + `!_completedByUser`.

Isso é apenas visual — nenhum status no backend é alterado.

## EvaluationsScreen — "Minhas Avaliações"

### Filtro Ciclo Atual / Todos os Ciclos

A seção "Minhas Avaliações" tem um toggle compacto inline com o título:

```dart
enum _MyEvaluationsFilter { currentCycle, allCycles }
// Default: currentCycle
```

| Filtro | Conteúdo |
|---|---|
| Ciclo Atual | Auto-avaliação do usuário no ciclo ativo + leaderEvaluations finalizadas do ciclo ativo |
| Todos os Ciclos | Todas as auto-avaliações + todas as leaderEvaluations finalizadas (histórico completo) |

O filtro opera sobre `resolvedMyEvalsProvider` (já mesclado e ordenado) comparando `eval.cycleId == activeCycleId`.

**Escopo do filtro**: afeta apenas "Minhas Avaliações". A seção "Gestor — Time" não é filtrada.

### Lista mesclada (`resolvedMyEvalsProvider`)

Busca `autoEvaluationsProvider` + `myReceivedLiderEvaluationsProvider`, resolve período e nomes, mescla em `List<ResolvedMyEval>`, e ordena por `cycleDate DESC → lastUpdate DESC`.

A renderização usa `switch` sobre a classe selada:
```dart
switch (item) {
  ResolvedMyAutoEval(:final data)          => _AutoEvalCard(...)
  ResolvedMyLiderEvalReceived(:final data) => _ReceivedLiderEvalCard(...)
}
```

## GoalsScreen — regras de negócio

### Escopo por perfil

- **HR**: lista `allColaboradoresProvider` (todos os colaboradores DGT via `getAll()`)
- **Leader**: lista `myCurrentCycleTeamProvider` + `teamColaboradoresProvider` (apenas time direto)
- **Employee**: vê apenas as próprias metas

### Regra de edição

```dart
final canEdit = !isActiveCycle;
```

Edição de metas **só é permitida fora do ciclo ativo**. Durante o ciclo ativo, a tela exibe a mensagem:
> "Ciclo de avaliação em andamento. Para incluir metas para o período corrente não é possível; para incluir metas para o próximo ciclo, adicione diretamente na avaliação do profissional."

Metas do próximo ciclo são inseridas diretamente via `nextGoals` na avaliação do colaborador (campo da `LiderEvaluation`).

## ProfilePage — padrões

Tela `/perfil`. Exibe:
- Dados básicos do usuário logado (nome, email/username via `currentUserProvider`)
- Card `_PerfilCard` com dados de `myEmployeePerfilProvider`: nível de carreira, função, data de admissão, classificação do último ciclo
- `topPerformer` exibido **somente para leader e HR** (employee não vê)
- Fallback `_InfoNotFound` quando `EmployeePerfil == null`
- Botão de logout
- Número de versão discreto abaixo do botão: `Text('v1.0.0 · 01/06/2026', style: TextStyle(fontSize: 11, color: AppColors.textDisabled))`

## Processo de negócio — fluxo do ciclo

1. RH configura critérios e ciclo (fases em `tabPhases`)
2. Colaborador faz **auto-avaliação** no app (sliders 0–10 + campos qualitativos)
3. Gestor realiza **reunião de avaliações** presencialmente — a reunião é para repassar TODAS as avaliações do grupo e balizar resultados por nível de carreira (fora do app)
4. Gestor registra **avaliação individual** no app após a reunião
5. RH conduz **equalização** com líderes
6. **Classificação final:** Abaixo do nível / No nível / Acima do nível / Top Performer
7. Colaborador recebe retorno oficial (classificação + reajuste de mérito ou promoção)
8. Ciclo encerrado pelo RH

## Como implementar um novo método SYDLE

```dart
// Em features/<modulo>/data/<modulo>_repository.dart:
final data = await _client.call(
  SydlePackage.perfMngt,       // pacote
  SydleClass.autoEvaluation,   // classe
  SydleMethod.search,          // método
  body: {
    'query': {'term': {'employee._id': userId}},
    'sort': [{'_creationDate': {'order': 'desc'}}],
    'size': 20,
  },
) as Map<String, dynamic>;
final result = SydleSearchResponse.fromJson(data, AutoEvaluation.fromJson);
```

Para busca por ID:
```dart
body: {
  'query': {'term': {'_id': objectId}},
  'size': 1,
}
// Retorna: SydleSearchResponse.fromJson(data, Model.fromJson).firstOrNull
```

Para `colaboradorDGT` (nomes de colaboradores), usar `SydlePackage.projetosDGT` — não `perfMngt`.

### Atualizar arrays embedded (tabPhases) — usar `_update`, não `_patch`

O SYDLE ONE não persiste arrays embedded (como `tabPhases`) via `_patch`. Sempre usar `_update` com o payload completo do objeto:

```dart
// cycle_repository.dart — updateCyclePhases
await _client.call(
  SydlePackage.perfMngt, SydleClass.cycle, SydleMethod.update,
  body: {
    '_id': cycle.id,
    'period': cycle.period,
    'year': cycle.year,
    'status': cycle.status.sydleValue,
    'criteria': cycle.criteriaIds.map((id) => {'_id': id}).toList(),
    if (cycle.cycleDate != null) 'cycleDate': cycle.cycleDate!.millisecondsSinceEpoch,
    'tabPhases': phases.map((p) => p.toJson()).toList(),
  },
);
```

Usar `Cycle.toJson()` ou montar o payload manualmente — nunca usar `_patch` para campos de array.

## Regras de compatibilidade Flutter Web (dart2js)

Estas regras evitam crashes silenciosos no Flutter Web:

- **Nunca usar record destructuring** `final (a, b) = switch(...)` — usar `switch` statement tradicional
- **Nunca usar named records em `const`** `(dot: Color(...), label: '...')` — usar classe com `const` constructor
- **Nunca usar `withOpacity()`** — usar `withValues(alpha: x)` (depreciado no Flutter 3.22+)
- **Nunca usar `background:` no `ColorScheme.fromSeed`** — removido no Flutter 3.27+
- **Nunca usar `AppTheme.dark()`** — app usa `ThemeMode.light` fixo, sem dark theme
- **Nunca usar `Border()` não-uniforme com `borderRadius`** — causa erro de render; sempre usar `Border.all()`
- **`DropdownButtonFormField`: usar `initialValue:` em vez de `value:`** — `value:` foi depreciado após Flutter 3.33
- **`Switch`: usar `activeThumbColor:` em vez de `activeColor:`** — `activeColor` foi depreciado após Flutter 3.31
- Switch expressions simples (`switch (x) { 'a' => ..., _ => ... }`) são OK
- Sealed class + switch expressions (`switch (item) { SomeType() => ... }`) são OK

## Credenciais de desenvolvimento

- Org: `dgt-consultoria-dev`
- Rodar via VSCode (F5 com config "Performance DGT (dev)") ou:

```bash
flutter run --dart-define=SYDLE_ORG=dgt-consultoria-dev
```

## Para rodar

```bash
flutter pub get
flutter run --dart-define=SYDLE_ORG=dgt-consultoria-dev
```

## Build produção (AAB para Play Store)

### Org de produção

`dgt-consultoria` (não confundir com `dgt-consultoria-dev`).

### ⚠️ SEMPRE incrementar o versionCode antes de gerar um novo AAB

A Play Store **rejeita** AABs com versionCode repetido ou igual ao já publicado.
O versionCode é o número após o `+` na linha `version:` do `pubspec.yaml`:

```yaml
version: 1.0.0+2   # o "+2" é o versionCode
```

Antes de qualquer `flutter build appbundle --release`, incremente esse número:
```yaml
# Antes: version: 1.0.0+2
# Depois: version: 1.0.0+3
```

Versão atual publicada: **1.0.0+3** (Play Store) — após fix do URL de autenticação.

### Comando de build

```bash
flutter build appbundle --release --dart-define=SYDLE_ORG=dgt-consultoria
```

O AAB gerado fica em `build/app/outputs/bundle/release/app-release.aab`.

### APK de teste (Android)

```bash
flutter build apk --debug --dart-define=SYDLE_ORG=dgt-consultoria
# ou produção:
flutter build apk --release --dart-define=SYDLE_ORG=dgt-consultoria
```

## Android — Configurações de release

### Assinatura (key.properties)

O arquivo `android/key.properties` (não versionado — está no `.gitignore`) aponta para o keystore:

```properties
storePassword=<senha>
keyPassword=<senha>
keyAlias=dgt-performance
storeFile=C:/Users/cdegh/androidKeys/dgt-performance.jks
```

O `android/app/build.gradle.kts` lê esse arquivo e configura `signingConfigs.release`.

### Permissão de internet (AndroidManifest.xml)

O `<uses-permission android:name="android.permission.INTERNET"/>` é **obrigatório** no `android/app/src/main/AndroidManifest.xml`. Sem ele o app não consegue conectar à API SYDLE em dispositivos Android — o login falha com `Failed host lookup`.

### Gradle JVM heap (gradle.properties)

```properties
org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=2G -XX:ReservedCodeCacheSize=512m
```

Não exceder a RAM disponível da máquina. Com 8GB de RAM física, o máximo seguro é `-Xmx4G`.

## Splash Screen (`features/splash/splash_screen.dart`)

Tela animada de abertura exibida antes de `/login` ou `/dashboard`. É a `initialLocation` do GoRouter.

### Animação

- `AnimationController` de 3000ms com `SingleTickerProviderStateMixin`
- `_fadeIn`: `Interval(0.0, 0.13)` — logo e texto aparecem suavemente
- `_needle`: `Interval(0.10, 0.90, curve: Curves.easeInOut)` — agulha varre de 0 a 82%
- Após `ctrl.forward()` + 1500ms de delay → navega para `/dashboard` (autenticado) ou `/login`

### Tachômetro (`_TachometerPainter`)

```dart
class _TachometerPainter extends CustomPainter {
  _TachometerPainter(this._animation) : super(repaint: _animation);
  // ...
}
```

**Crítico:** `super(repaint: _animation)` faz o Flutter repintar o `CustomPaint` a cada frame da animação. Sem isso a tela fica estática.

- Arco: `startAngle = π` (9h), `sweepAngle = π` (sentido horário até 3h, passando pelo topo)
- Centro do arco posicionado na borda inferior do widget para semicírculo na metade superior
- Zonas de cor: verde (0–42%), amarelo (42–70%), vermelho (70–100%)
- Agulha: cor `AppColors.primary` (#FCB017) com glow, hub circle no centro
- Fundo: `AppColors.darkGray` (#3A3A3A)
- Meta da agulha: 82% (high performance)

### Router

```dart
// app_router.dart
initialLocation: '/splash',
GoRoute(path: '/splash', builder: (ctx, _) => const SplashScreen()),
// Redirect: '/splash' é isento — if (isSplash) return null;
```

## iOS — Limitação

Build para iOS requer **macOS + Xcode**. Não é possível gerar IPA no Windows.
Para publicar na Apple Store, usar um Mac ou serviço de CI com runner macOS (ex.: Codemagic, GitHub Actions com `macos-latest`).
