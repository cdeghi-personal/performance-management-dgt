import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/auth_provider.dart';
import '../../profile/data/employee_perfil_model.dart';
import '../../profile/data/employee_perfil_repository.dart';
import '../data/models/auto_evaluation_model.dart';
import '../data/models/criterion_model.dart';
import '../data/models/cycle_model.dart';
import '../data/models/lider_evaluation_model.dart';
import '../data/repositories/auto_evaluation_repository.dart';
import '../data/repositories/colaborador_repository.dart';
import '../data/repositories/criterion_repository.dart';
import '../data/repositories/cycle_repository.dart';
import '../data/repositories/lider_evaluation_repository.dart';

// ── Ciclo ativo ───────────────────────────────────────────────────────────────

/// Ciclo ativo global — carregado uma vez no boot.
/// Todas as telas consomem daqui — nunca buscam o ciclo individualmente.
final activeCycleProvider = FutureProvider<Cycle?>((ref) {
  return ref.read(cycleRepositoryProvider).getActiveCycle();
});

// ── Auto-avaliações ───────────────────────────────────────────────────────────

/// Histórico completo das auto-avaliações do usuário logado.
final autoEvaluationsProvider = FutureProvider<List<AutoEvaluation>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  return ref.read(autoEvaluationRepositoryProvider).getByEmployee(userId);
});

/// Pendências de auto-avaliação do usuário logado no ciclo ativo.
final pendingAutoEvaluationsProvider = FutureProvider<List<AutoEvaluation>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final cycle  = await ref.watch(activeCycleProvider.future);
  if (userId == null || cycle == null) return [];

  return ref
      .read(autoEvaluationRepositoryProvider)
      .getPendingByEmployee(employeeId: userId, cycleId: cycle.id);
});

// ── Avaliações do gestor ──────────────────────────────────────────────────────

/// Histórico completo das avaliações do gestor (como avaliador).
final liderEvaluationsProvider = FutureProvider<List<LiderEvaluation>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  return ref.read(liderEvaluationRepositoryProvider).getByAppraiser(userId);
});

/// Pendências de avaliação do time do gestor no ciclo ativo.
final pendingLiderEvaluationsProvider = FutureProvider<List<LiderEvaluation>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final cycle  = await ref.watch(activeCycleProvider.future);
  if (userId == null || cycle == null) return [];

  return ref
      .read(liderEvaluationRepositoryProvider)
      .getPendingByAppraiser(appraiserId: userId, cycleId: cycle.id);
});

/// Avaliações do gestor finalizadas onde o usuário logado é o AVALIADO.
/// Somente status==finished aparece em "Minhas Avaliações" (regra de negócio).
final myReceivedLiderEvaluationsProvider = FutureProvider<List<LiderEvaluation>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  return ref.read(liderEvaluationRepositoryProvider).getFinishedByEmployee(userId);
});

/// Avaliações do time do gestor logado no ciclo ativo (todos os status) — tela de avaliações.
final myCurrentCycleTeamProvider = FutureProvider<List<LiderEvaluation>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final cycle  = await ref.watch(activeCycleProvider.future);
  if (userId == null || cycle == null) return [];
  return ref
      .read(liderEvaluationRepositoryProvider)
      .getByAppraisersAndCycle(appraiserId: userId, cycleId: cycle.id);
});

/// Avaliações do time no ciclo ativo para a EqualizationPage (leader/HR).
final teamEvaluationsProvider = FutureProvider<List<LiderEvaluation>>((ref) async {
  final cycle = await ref.watch(activeCycleProvider.future);
  if (cycle == null) return [];
  return ref.read(liderEvaluationRepositoryProvider).getByCycle(cycle.id);
});

// ── Avaliações individuais (telas de formulário) ──────────────────────────────

/// Auto-avaliação do usuário logado no ciclo ativo.
final myAutoEvaluationProvider = FutureProvider<AutoEvaluation?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final cycle  = await ref.watch(activeCycleProvider.future);
  if (userId == null || cycle == null) return null;
  return ref.read(autoEvaluationRepositoryProvider)
      .getByEmployeeAndCycle(employeeId: userId, cycleId: cycle.id);
});

/// LiderEvaluation onde o usuário logado é o EMPLOYEE (para jornada do ciclo).
final myLiderEvaluationProvider = FutureProvider<LiderEvaluation?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final cycle  = await ref.watch(activeCycleProvider.future);
  if (userId == null || cycle == null) return null;
  return ref.read(liderEvaluationRepositoryProvider)
      .getByEmployeeAndCycle(employeeId: userId, cycleId: cycle.id);
});

/// Auto-avaliação por ID (para histórico — leitura).
final autoEvaluationByIdProvider =
    FutureProvider.family<AutoEvaluation?, String>((ref, evalId) async {
  if (evalId.isEmpty) return null;
  return ref.read(autoEvaluationRepositoryProvider).getById(evalId);
});

/// LiderEvaluation por ID (para avaliação recebida — leitura).
final liderEvaluationByIdProvider =
    FutureProvider.family<LiderEvaluation?, String>((ref, evalId) async {
  if (evalId.isEmpty) return null;
  return ref.read(liderEvaluationRepositoryProvider).getById(evalId);
});

/// Auto-avaliação de um colaborador específico no ciclo ativo (referência para o gestor).
/// Usado pela EqualizationPage (_EmployeeCard) — sempre usa o ciclo ativo.
final autoEvaluationForEmployeeProvider =
    FutureProvider.family<AutoEvaluation?, String>((ref, employeeId) async {
  final cycle = await ref.watch(activeCycleProvider.future);
  if (cycle == null) return null;
  return ref.read(autoEvaluationRepositoryProvider)
      .getByEmployeeAndCycle(employeeId: employeeId, cycleId: cycle.id);
});

/// Auto-avaliação para a ManagerEvaluationPage — usa o cycleId da própria LiderEvaluation,
/// não o ciclo ativo global. Suporta tanto avaliações do ciclo atual quanto históricas.
/// Key format: "employeeId:cycleId" (derivado de liderEvaluation.employeeId e .cycleId).
/// Prioriza status==finished; cai para qualquer status se não encontrar.
final autoEvalForLiderEvalProvider =
    FutureProvider.family<AutoEvaluation?, String>((ref, key) async {
  if (key.isEmpty) return null;
  final sep = key.indexOf(':');
  if (sep <= 0) return null;
  final employeeId = key.substring(0, sep);
  final cycleId    = key.substring(sep + 1);
  if (employeeId.isEmpty || cycleId.isEmpty) return null;
  return ref.read(autoEvaluationRepositoryProvider)
      .getByEmployeeAndCycleFinished(employeeId: employeeId, cycleId: cycleId);
});

/// Avaliação mais recente de um colaborador como AVALIADO (qualquer gestor, qualquer ciclo).
/// Usado pela GoalsScreen (HR) para localizar o registro onde persistir nextGoals.
final latestLiderEvalForEmployeeProvider =
    FutureProvider.family<LiderEvaluation?, String>((ref, employeeId) async {
  if (employeeId.isEmpty) return null;
  return ref.read(liderEvaluationRepositoryProvider).getLatestByEmployee(employeeId);
});

/// LiderEvaluation para um colaborador específico feita pelo gestor logado.
final liderEvaluationForEmployeeProvider =
    FutureProvider.family<LiderEvaluation?, String>((ref, employeeId) async {
  final userId = ref.watch(currentUserIdProvider);
  final cycle  = await ref.watch(activeCycleProvider.future);
  if (userId == null || cycle == null) return null;
  return ref.read(liderEvaluationRepositoryProvider).getByEmployeeAppraisersAndCycle(
        employeeId: employeeId,
        appraiserId: userId,
        cycleId: cycle.id,
      );
});

// ── Critérios ─────────────────────────────────────────────────────────────────

/// Critérios do ciclo ativo separados por tipo (behavioral / technical).
final cycleCriteriaProvider = FutureProvider<Map<CriterionType, List<Criterion>>>(
  (ref) async {
    final cycle = await ref.watch(activeCycleProvider.future);
    if (cycle == null || cycle.criteriaIds.isEmpty) {
      return {CriterionType.behavioral: [], CriterionType.technical: []};
    }
    return ref.read(criterionRepositoryProvider).getByCycle(cycle.criteriaIds);
  },
);

// ── Equalização ───────────────────────────────────────────────────────────────

/// Todos os colaboradores DGT — usado pela GoalsScreen (HR) para listar todos.
final allColaboradoresProvider = FutureProvider<List<ColaboradorDGT>>((ref) {
  return ref.read(colaboradorRepositoryProvider).getAll();
});

/// Avaliações para a Equalização — escopo por perfil.
/// Leader: somente seus avaliados (appraiser == currentUser). HR: todos do ciclo ativo.
final equalizationEvalsProvider = FutureProvider<List<LiderEvaluation>>((ref) async {
  final profile = ref.watch(currentProfileProvider);
  final cycle   = await ref.watch(activeCycleProvider.future);
  if (cycle == null) return [];

  if (profile?.isHR == true) {
    return ref.read(liderEvaluationRepositoryProvider).getByCycle(cycle.id);
  }
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  return ref.read(liderEvaluationRepositoryProvider)
      .getByAppraisersAndCycle(appraiserId: userId, cycleId: cycle.id);
});

/// ColaboradorDGT para a Equalização — derivado de equalizationEvalsProvider.
/// Contém somente os colaboradores e avaliadores do dataset permitido para o perfil.
final equalizationColaboradoresProvider =
    FutureProvider<Map<String, ColaboradorDGT>>((ref) async {
  final evals = await ref.watch(equalizationEvalsProvider.future);
  if (evals.isEmpty) return {};
  final ids = {
    ...evals.map((e) => e.employeeId),
    ...evals.map((e) => e.appraiserId),
  }.where((id) => id.isNotEmpty).toList();
  return ref.read(colaboradorRepositoryProvider).getDetailsByIds(ids);
});

/// EmployeePerfil em batch para a Equalização — fonte autoritativa do careerLevel.
/// Keyed por employeeId. Usa equalizationEvalsProvider para respeitar o escopo por perfil.
final equalizationEmployeePerfilsProvider =
    FutureProvider<Map<String, EmployeePerfil>>((ref) async {
  final evals = await ref.watch(equalizationEvalsProvider.future);
  if (evals.isEmpty) return {};
  final ids = evals
      .map((e) => e.employeeId)
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList();
  return ref.read(employeePerfilRepositoryProvider).getByEmployeeIds(ids);
});

/// Dados completos (nome + nível de carreira) dos colaboradores e avaliadores
/// do ciclo ativo — usado pela EqualizationPage para exibir nível e nome.
final teamColaboradoresProvider = FutureProvider<Map<String, ColaboradorDGT>>((ref) async {
  final evals = await ref.watch(teamEvaluationsProvider.future);
  if (evals.isEmpty) return {};
  final ids = {
    ...evals.map((e) => e.employeeId),
    ...evals.map((e) => e.appraiserId),
  }.where((id) => id.isNotEmpty).toList();
  return ref.read(colaboradorRepositoryProvider).getDetailsByIds(ids);
});
