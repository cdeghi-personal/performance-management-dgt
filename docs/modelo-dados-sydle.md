# Modelo de Dados — Performance Management DGT
## Classes para criar no SYDLE ONE

---

## Pacotes sugeridos

| Pacote SYDLE | Conteúdo |
|---|---|
| `appDgt` | Autorização (já existe) |
| `hrm` | Pessoas, funcionários, departamentos |
| `performance` | Ciclos, metas, avaliações, feedbacks, reuniões, promoções, cotas |

---

## Pacote: `hrm`

---

### Classe: `employee`

| Campo | Tipo SYDLE | Obrigatório | Descrição |
|---|---|---|---|
| `username` | Text | Sim | Login do usuário (igual ao do SYDLE) |
| `displayName` | Text | Sim | Nome completo para exibição |
| `email` | Text | Sim | E-mail corporativo |
| `role` | Enum | Sim | `employee` \| `manager` \| `director` \| `admin` |
| `departmentId` | Reference → `department` | Não | Departamento do funcionário |
| `managerId` | Reference → `employee` | Não | Gestor direto |
| `active` | Boolean | Sim | Se o funcionário está ativo |
| `avatarUrl` | Text | Não | URL da foto de perfil |
| `admissionDate` | Date | Não | Data de admissão |
| `currentRole` | Text | Não | Cargo atual (texto livre) |

**Métodos sugeridos:**
- `getProfile` — retorna dados do funcionário autenticado
- `findByDepartment` — busca funcionários por departamento
- `findByManager` — lista subordinados diretos de um gestor

---

### Classe: `department`

| Campo | Tipo SYDLE | Obrigatório | Descrição |
|---|---|---|---|
| `name` | Text | Sim | Nome do departamento |
| `managerId` | Reference → `employee` | Não | Gestor responsável |
| `active` | Boolean | Sim | Se o departamento está ativo |

---

### Classe: `competency`
*(tabela de configuração — competências avaliadas)*

| Campo | Tipo SYDLE | Obrigatório | Descrição |
|---|---|---|---|
| `name` | Text | Sim | Nome da competência (ex: "Liderança") |
| `description` | Text | Não | Descrição detalhada |
| `active` | Boolean | Sim | Se está ativa no ciclo |

---

## Pacote: `performance`

---

### Classe: `performanceCycle`

| Campo | Tipo SYDLE | Obrigatório | Descrição |
|---|---|---|---|
| `year` | Text | Sim | Ano do ciclo (ex: `"2025"`) |
| `status` | Enum | Sim | `draft` \| `active` \| `closed` |
| `startDate` | Date | Sim | Início do ciclo |
| `endDate` | Date | Sim | Fim do ciclo |
| `description` | Text | Não | Observações sobre o ciclo |

**Métodos sugeridos:**
- `getActiveCycle` — retorna o ciclo com status `active`

---

### Classe: `goal`
*(metas anuais)*

| Campo | Tipo SYDLE | Obrigatório | Descrição |
|---|---|---|---|
| `title` | Text | Sim | Título da meta |
| `description` | Text | Não | Descrição detalhada |
| `type` | Enum | Sim | `individual` \| `team` \| `company` |
| `status` | Enum | Sim | `draft` \| `active` \| `atRisk` \| `behind` \| `completed` \| `cancelled` |
| `cycleId` | Reference → `performanceCycle` | Sim | Ciclo ao qual a meta pertence |
| `ownerId` | Reference → `employee` | Sim | Responsável pela meta |
| `progressPercent` | Number (0–100) | Sim | Progresso atual em % |
| `dueDate` | Date | Sim | Data-limite para conclusão |
| `parentGoalId` | Reference → `goal` | Não | Meta pai (para cascateamento) |

**Métodos sugeridos:**
- `findByCycle` — metas de um ciclo
- `findByEmployee` — metas de um funcionário
- `updateProgress` — atualiza `progressPercent`

---

### Classe: `keyResult`
*(resultados-chave vinculados a uma meta)*

| Campo | Tipo SYDLE | Obrigatório | Descrição |
|---|---|---|---|
| `goalId` | Reference → `goal` | Sim | Meta pai |
| `title` | Text | Sim | Descrição do resultado-chave |
| `currentValue` | Number | Sim | Valor atual |
| `targetValue` | Number | Sim | Valor alvo |
| `unit` | Text | Sim | Unidade (`%`, `R$`, `unidades`, etc.) |
| `dueDate` | Date | Sim | Prazo do resultado-chave |

**Métodos sugeridos:**
- `findByGoal` — resultados-chave de uma meta
- `updateValue` — atualiza `currentValue`

---

### Classe: `evaluation`
*(avaliações semestrais)*

| Campo | Tipo SYDLE | Obrigatório | Descrição |
|---|---|---|---|
| `employeeId` | Reference → `employee` | Sim | Funcionário avaliado |
| `evaluatorId` | Reference → `employee` | Sim | Gestor avaliador |
| `semester` | Text | Sim | Semestre (ex: `"2025-S1"`, `"2025-S2"`) |
| `cycleId` | Reference → `performanceCycle` | Sim | Ciclo da avaliação |
| `status` | Enum | Sim | `pending` \| `inProgress` \| `completed` \| `calibrated` |
| `selfScore` | Enum | Não | `exceedsExpectations` \| `meetsExpectations` \| `partiallyMeets` \| `doesNotMeet` |
| `managerScore` | Enum | Não | Mesmo enum de `selfScore` |
| `finalScore` | Enum | Não | Resultado final pós-calibração |
| `selfComments` | Text (longo) | Não | Comentários da autoavaliação |
| `managerComments` | Text (longo) | Não | Comentários do gestor |
| `competencyScores` | List → `competencyScore` | Não | Notas por competência (ver abaixo) |
| `completedAt` | DateTime | Não | Data de conclusão |

**Métodos sugeridos:**
- `findByEmployee` — avaliações de um funcionário
- `findByEvaluator` — avaliações conduzidas por um gestor
- `submitSelfEvaluation` — envia autoavaliação
- `submitManagerEvaluation` — envia avaliação do gestor
- `calibrate` — gestor/diretor define `finalScore`

---

### Subdocumento: `competencyScore`
*(embutido dentro de `evaluation.competencyScores`)*

| Campo | Tipo SYDLE | Obrigatório | Descrição |
|---|---|---|---|
| `competencyId` | Reference → `competency` | Sim | Competência avaliada |
| `selfScore` | Enum | Não | Nota do próprio funcionário |
| `managerScore` | Enum | Não | Nota do gestor |
| `comment` | Text | Não | Comentário específico |

---

### Classe: `feedbackEntry`
*(feedbacks pontuais)*

| Campo | Tipo SYDLE | Obrigatório | Descrição |
|---|---|---|---|
| `type` | Enum | Sim | `positive` \| `developmental` \| `recognition` |
| `fromId` | Reference → `employee` | Sim | Quem deu o feedback |
| `toId` | Reference → `employee` | Sim | Quem recebeu |
| `message` | Text (longo) | Sim | Mensagem do feedback |
| `visibility` | Enum | Sim | `publicVisible` \| `managerOnly` \| `private` |
| `relatedGoalId` | Reference → `goal` | Não | Meta relacionada (opcional) |
| `cycleId` | Reference → `performanceCycle` | Não | Ciclo de referência |

**Métodos sugeridos:**
- `findReceived` — feedbacks recebidos por um funcionário
- `findGiven` — feedbacks dados por um funcionário
- `findByEmployee` — todos os feedbacks (recebidos + dados)

---

### Classe: `executiveMeeting`
*(reuniões formais do grupo executivo sobre performance)*

| Campo | Tipo SYDLE | Obrigatório | Descrição |
|---|---|---|---|
| `title` | Text | Sim | Título/pauta principal da reunião |
| `status` | Enum | Sim | `scheduled` \| `inProgress` \| `completed` \| `cancelled` |
| `scheduledAt` | DateTime | Sim | Data e hora agendadas |
| `facilitatorId` | Reference → `employee` | Sim | Facilitador da reunião |
| `participantIds` | List → Reference → `employee` | Não | Participantes |
| `agendaItems` | List → `meetingAgendaItem` | Não | Itens de pauta (ver abaixo) |
| `notes` | Text (longo) | Não | Notas gerais da reunião |
| `completedAt` | DateTime | Não | Data de encerramento |

**Métodos sugeridos:**
- `findByFacilitator`
- `findUpcoming` — próximas reuniões agendadas
- `addAgendaItem`
- `complete` — encerra a reunião

---

### Subdocumento: `meetingAgendaItem`
*(embutido dentro de `executiveMeeting.agendaItems`)*

| Campo | Tipo SYDLE | Obrigatório | Descrição |
|---|---|---|---|
| `employeeId` | Reference → `employee` | Sim | Funcionário discutido |
| `topic` | Text | Sim | Assunto do item |
| `discussion` | Text (longo) | Não | Registro da discussão |
| `actionItems` | Text (longo) | Não | Ações definidas |
| `reviewed` | Boolean | Sim | Se o item foi revisado |

---

### Classe: `promotionRequest`
*(solicitações de promoção)*

| Campo | Tipo SYDLE | Obrigatório | Descrição |
|---|---|---|---|
| `employeeId` | Reference → `employee` | Sim | Candidato à promoção |
| `currentRole` | Text | Sim | Cargo atual |
| `targetRole` | Text | Sim | Cargo pretendido |
| `requestedById` | Reference → `employee` | Sim | Quem solicitou (gestor/RH) |
| `status` | Enum | Sim | `pending` \| `underReview` \| `approved` \| `rejected` \| `onHold` |
| `requestedAt` | Date | Sim | Data da solicitação |
| `justification` | Text (longo) | Sim | Justificativa da promoção |
| `managerEndorsement` | Text (longo) | Não | Endosso do gestor direto |
| `hrComments` | Text (longo) | Não | Comentários do RH |
| `executiveDecision` | Text (longo) | Não | Decisão do grupo executivo |
| `decisionAt` | Date | Não | Data da decisão |
| `isQuotaRelated` | Boolean | Sim | Se faz parte do Programa de Cotas |
| `cycleId` | Reference → `performanceCycle` | Não | Ciclo de referência |
| `relatedMeetingId` | Reference → `executiveMeeting` | Não | Reunião onde foi discutida |

**Métodos sugeridos:**
- `findByEmployee`
- `findPending` — todas as solicitações abertas
- `approve` — muda status para `approved`
- `reject` — muda status para `rejected`

---

### Classe: `quotaProgram`
*(Programa de Cotas DGT — cabeçalho)*

| Campo | Tipo SYDLE | Obrigatório | Descrição |
|---|---|---|---|
| `cycleYear` | Text | Sim | Ano de referência (ex: `"2025"`) |
| `targets` | List → `quotaTarget` | Sim | Metas de cotas (ver abaixo) |
| `updatedAt` | DateTime | Sim | Última atualização |

**Métodos sugeridos:**
- `getByYear` — retorna o programa de um ano
- `updateCounts` — atualiza contadores reais

---

### Subdocumento: `quotaTarget`
*(embutido dentro de `quotaProgram.targets`)*

| Campo | Tipo SYDLE | Obrigatório | Descrição |
|---|---|---|---|
| `category` | Enum | Sim | `race` \| `gender` \| `disability` \| `lgbtq` \| `other` |
| `label` | Text | Sim | Nome exibido (ex: "Negros e Pardos") |
| `targetCount` | Number (int) | Sim | Meta de vagas/posições |
| `currentCount` | Number (int) | Sim | Quantidade atual |
| `level` | Text | Sim | Nível: `entry` \| `mid` \| `senior` \| `leadership` \| `all` |
| `notes` | Text | Não | Observações |

---

## Resumo de Enums

| Enum | Valores |
|---|---|
| `employee.role` | `employee`, `manager`, `director`, `admin` |
| `goal.type` | `individual`, `team`, `company` |
| `goal.status` | `draft`, `active`, `atRisk`, `behind`, `completed`, `cancelled` |
| `evaluation.status` | `pending`, `inProgress`, `completed`, `calibrated` |
| `evaluationScore` | `exceedsExpectations`, `meetsExpectations`, `partiallyMeets`, `doesNotMeet` |
| `feedback.type` | `positive`, `developmental`, `recognition` |
| `feedback.visibility` | `publicVisible`, `managerOnly`, `private` |
| `meeting.status` | `scheduled`, `inProgress`, `completed`, `cancelled` |
| `promotion.status` | `pending`, `underReview`, `approved`, `rejected`, `onHold` |
| `quota.category` | `race`, `gender`, `disability`, `lgbtq`, `other` |
| `cycle.status` | `draft`, `active`, `closed` |

---

## Relacionamentos

```
performanceCycle ─── goal (1:N)
goal ─────────────── keyResult (1:N)
goal ─────────────── goal (parentGoalId — hierarquia)
employee ────────────evaluation (1:N como avaliado)
employee ────────────evaluation (1:N como avaliador)
evaluation ──────────competencyScore (1:N embutido)
employee ────────────feedbackEntry (1:N como emissor)
employee ────────────feedbackEntry (1:N como receptor)
executiveMeeting ────meetingAgendaItem (1:N embutido)
employee ────────────promotionRequest (1:N como candidato)
quotaProgram ────────quotaTarget (1:N embutido)
```

---

## Mapeamento: Flutter Model → Classe SYDLE

| Flutter (lib/features/*/domain/) | Pacote SYDLE | Classe SYDLE |
|---|---|---|
| `AuthUser` | `appDgt` | `authorization` + `employee` |
| `Goal` | `performance` | `goal` |
| `KeyResult` | `performance` | `keyResult` |
| `Evaluation` | `performance` | `evaluation` |
| `CompetencyScore` | `performance` | subdoc de `evaluation` |
| `FeedbackEntry` | `performance` | `feedbackEntry` |
| `ExecutiveMeeting` | `performance` | `executiveMeeting` |
| `MeetingAgendaItem` | `performance` | subdoc de `executiveMeeting` |
| `PromotionRequest` | `performance` | `promotionRequest` |
| `QuotaProgram` | `performance` | `quotaProgram` |
| `QuotaTarget` | `performance` | subdoc de `quotaProgram` |