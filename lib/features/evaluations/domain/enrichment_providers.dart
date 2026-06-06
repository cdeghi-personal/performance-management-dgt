import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/auto_evaluation_model.dart';
import '../data/models/cycle_model.dart';
import '../data/models/lider_evaluation_model.dart';
import '../data/repositories/colaborador_repository.dart';
import '../data/repositories/cycle_repository.dart';
import '../presentation/resolved_eval.dart';
import 'evaluation_providers.dart';

// ── Listas enriquecidas (tela de listagem) ────────────────────────────────────

/// Avaliações mescladas do usuário: auto-avaliações + avaliações recebidas do gestor,
/// ordenadas por ciclo (mais recente primeiro), depois por última atualização.
final resolvedMyEvalsProvider =
    FutureProvider<List<ResolvedMyEval>>((ref) async {
  final autoEvals = await ref.watch(autoEvaluationsProvider.future);
  final liderEvals = await ref.watch(myReceivedLiderEvaluationsProvider.future);

  final resolvedAuto = autoEvals.isEmpty
      ? <ResolvedAutoEval>[]
      : await _resolveAutoList(ref, autoEvals);

  final resolvedLider = liderEvals.isEmpty
      ? <ResolvedLiderEval>[]
      : await _resolveLiderList(ref, liderEvals);

  final merged = <ResolvedMyEval>[
    ...resolvedAuto.map(ResolvedMyAutoEval.new),
    ...resolvedLider.map(ResolvedMyLiderEvalReceived.new),
  ];

  merged.sort((a, b) {
    final cmp = b.sortCycleDate.compareTo(a.sortCycleDate);
    if (cmp != 0) return cmp;
    return b.sortLastUpdate.compareTo(a.sortLastUpdate);
  });

  return merged;
});

/// Avaliações do time do gestor no ciclo ativo com dados resolvidos.
final resolvedTeamEvalsProvider =
    FutureProvider<List<ResolvedLiderEval>>((ref) async {
  final evals = await ref.watch(myCurrentCycleTeamProvider.future);
  if (evals.isEmpty) return [];
  final resolved = await _resolveLiderList(ref, evals);
  resolved.sort((a, b) {
    final cmp = (b.cycleDate ?? b.eval.creationDate)
        .compareTo(a.cycleDate ?? a.eval.creationDate);
    if (cmp != 0) return cmp;
    return (b.eval.lastUpdate ?? b.eval.creationDate)
        .compareTo(a.eval.lastUpdate ?? a.eval.creationDate);
  });
  return resolved;
});

// ── Itens individuais (telas de detalhe) ─────────────────────────────────────

/// Auto-avaliação do ciclo ativo do usuário logado com período resolvido.
final resolvedMyAutoEvalProvider =
    FutureProvider<ResolvedAutoEval?>((ref) async {
  final eval = await ref.watch(myAutoEvaluationProvider.future);
  if (eval == null) return null;
  final list = await _resolveAutoList(ref, [eval]);
  return list.firstOrNull;
});

/// Auto-avaliação por ID (histórico) com período resolvido.
final resolvedAutoEvalByIdProvider =
    FutureProvider.family<ResolvedAutoEval?, String>((ref, evalId) async {
  if (evalId.isEmpty) return null;
  final eval = await ref.watch(autoEvaluationByIdProvider(evalId).future);
  if (eval == null) return null;
  final list = await _resolveAutoList(ref, [eval]);
  return list.firstOrNull;
});

/// Avaliação do gestor por ID com dados resolvidos (histórico ou recebida).
final resolvedLiderEvalByIdProvider =
    FutureProvider.family<ResolvedLiderEval?, String>((ref, evalId) async {
  if (evalId.isEmpty) return null;
  final eval = await ref.watch(liderEvaluationByIdProvider(evalId).future);
  if (eval == null) return null;
  final list = await _resolveLiderList(ref, [eval]);
  return list.firstOrNull;
});

/// Avaliação do gestor para um colaborador no ciclo ativo, com dados resolvidos.
final resolvedLiderEvalForEmployeeProvider =
    FutureProvider.family<ResolvedLiderEval?, String>((ref, employeeId) async {
  final eval =
      await ref.watch(liderEvaluationForEmployeeProvider(employeeId).future);
  if (eval == null) return null;
  final list = await _resolveLiderList(ref, [eval]);
  return list.firstOrNull;
});

// ── Helpers internos ──────────────────────────────────────────────────────────

Future<Map<String, Cycle>> _fetchCycles(Ref ref, List<String> cycleIds) async {
  final unique = cycleIds.where((id) => id.isNotEmpty).toSet().toList();
  if (unique.isEmpty) return {};

  final activeCycle = await ref.read(activeCycleProvider.future);
  final result = <String, Cycle>{};
  if (activeCycle != null) result[activeCycle.id] = activeCycle;

  final missing = unique.where((id) => !result.containsKey(id)).toList();
  if (missing.isNotEmpty) {
    final fetched = await ref.read(cycleRepositoryProvider).getByIds(missing);
    result.addAll(fetched);
  }
  return result;
}

Future<Map<String, String>> _fetchNames(
    Ref ref, List<String> personIds) async {
  final unique = personIds.where((id) => id.isNotEmpty).toSet().toList();
  if (unique.isEmpty) return {};
  return ref.read(colaboradorRepositoryProvider).getNamesByIds(unique);
}

String _resolvePeriod(Cycle? cycle, String fallbackPeriod, int fallbackYear) {
  if (cycle != null && cycle.period.isNotEmpty && cycle.year > 0) {
    return '${cycle.period} ${cycle.year}';
  }
  if (fallbackPeriod.isNotEmpty && fallbackYear > 0) {
    return '$fallbackPeriod $fallbackYear';
  }
  return '—';
}

DateTime _cycleSortDate(Cycle? cycle) =>
    cycle?.cycleDate ?? cycle?.creationDate ?? DateTime(2000);

/// Para auto-avaliações: só precisa resolver o período — o nome do avaliado
/// vem de currentUserProvider na UI (evita chamada extra de colaboradorDGT).
Future<List<ResolvedAutoEval>> _resolveAutoList(
    Ref ref, List<AutoEvaluation> evals) async {
  final cycleIds = evals.map((e) => e.cycleId).toList();
  final cycleMap = await _fetchCycles(ref, cycleIds);

  return evals.map((e) {
    final cycle = cycleMap[e.cycleId];
    return ResolvedAutoEval(
      eval: e,
      periodLabel: _resolvePeriod(cycle, e.cyclePeriod, e.cycleYear),
      employeeName: '',
      cycleDate: _cycleSortDate(cycle),
    );
  }).toList();
}

/// Para avaliações do gestor: resolve período + nomes de avaliado e avaliador.
Future<List<ResolvedLiderEval>> _resolveLiderList(
    Ref ref, List<LiderEvaluation> evals) async {
  final cycleIds = evals.map((e) => e.cycleId).toList();
  final personIds = [
    ...evals.map((e) => e.employeeId),
    ...evals.map((e) => e.appraiserId),
  ];

  final cycleMap = await _fetchCycles(ref, cycleIds);
  final nameMap = await _fetchNames(ref, personIds);

  return evals.map((e) {
    final cycle = cycleMap[e.cycleId];
    return ResolvedLiderEval(
      eval: e,
      periodLabel: _resolvePeriod(cycle, e.cyclePeriod, e.cycleYear),
      employeeName: nameMap[e.employeeId] ??
          (e.employeeName.isNotEmpty ? e.employeeName : 'Nome não encontrado'),
      appraiserName: nameMap[e.appraiserId] ??
          (e.appraiserName.isNotEmpty
              ? e.appraiserName
              : 'Nome não encontrado'),
      cycleDate: _cycleSortDate(cycle),
    );
  }).toList();
}
