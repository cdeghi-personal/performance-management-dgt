import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/avatar_initials.dart';
import '../../../shared/widgets/dgt_app_bar.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../auth/domain/auth_provider.dart';
import '../../evaluations/data/models/cycle_model.dart';
import '../../evaluations/data/models/lider_evaluation_model.dart';
import '../../evaluations/data/models/tab_goal_model.dart';
import '../../evaluations/data/repositories/lider_evaluation_repository.dart';
import '../../evaluations/domain/evaluation_providers.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  String? _selectedEmployeeId;
  final _goalCtrl = TextEditingController();
  bool _adding = false;
  bool _saving = false;

  @override
  void dispose() {
    _goalCtrl.dispose();
    super.dispose();
  }

  Future<void> _addGoal(LiderEvaluation eval) async {
    final text = _goalCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    try {
      final updated = LiderEvaluation(
        id: eval.id,
        cycleId: eval.cycleId,
        cyclePeriod: eval.cyclePeriod,
        cycleYear: eval.cycleYear,
        status: eval.status,
        employeeId: eval.employeeId,
        employeeName: eval.employeeName,
        appraiserId: eval.appraiserId,
        appraiserName: eval.appraiserName,
        behavioralEvaluation: eval.behavioralEvaluation,
        technicalEvaluation: eval.technicalEvaluation,
        goals: eval.goals,
        attentionPoints: eval.attentionPoints,
        strengths: eval.strengths,
        feedback: eval.feedback,
        actionPlan: eval.actionPlan,
        nextGoals: [...eval.nextGoals, text],
        classification: eval.classification,
        topPerformer: eval.topPerformer,
        commentsPerfMeeting: eval.commentsPerfMeeting,
        evaluationDate: eval.evaluationDate,
        feedbackDate: eval.feedbackDate,
        finishedDate: eval.finishedDate,
        creationDate: eval.creationDate,
        lastUpdate: eval.lastUpdate,
      );
      await ref.read(liderEvaluationRepositoryProvider).update(updated);
      _goalCtrl.clear();
      setState(() => _adding = false);
      // Invalidate so the UI refreshes with the new goal
      ref.invalidate(liderEvaluationForEmployeeProvider(_selectedEmployeeId ?? ''));
      ref.invalidate(latestLiderEvalForEmployeeProvider(_selectedEmployeeId ?? ''));
      ref.invalidate(myLiderEvaluationProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Meta adicionada!'),
          backgroundColor: AppColors.statusOnTrack,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: AppColors.statusBehind,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);
    final isEmployee = profile?.isEmployee ?? true;
    final isHR       = profile?.isHR ?? false;

    if (isEmployee) return _buildEmployeeView(context, ref);
    return _buildManagerView(context, ref, isHR: isHR);
  }

  // ── Employee view (read-only) ───────────────────────────────────────────────

  Widget _buildEmployeeView(BuildContext context, WidgetRef ref) {
    final evalAsync = ref.watch(myLiderEvaluationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DgtAppBar.simple(title: 'Metas'),
      body: evalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro ao carregar metas: $e')),
        data: (eval) {
          if (eval == null) {
            return const Center(
              child: AppEmptyState(
                icon: Icons.track_changes_rounded,
                title: 'Nenhuma meta encontrada',
                subtitle:
                    'Suas metas aparecerão aqui quando o gestor as registrar.',
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (eval.goals.isNotEmpty) ...[
                const _SectionHeader(title: 'Metas do período'),
                const SizedBox(height: 8),
                for (final g in eval.goals) _CurrentGoalCard(goal: g),
                const SizedBox(height: 16),
              ],
              const _SectionHeader(title: 'Metas para o próximo período'),
              const SizedBox(height: 8),
              if (eval.nextGoals.isEmpty)
                const _EmptyGoals()
              else
                for (var i = 0; i < eval.nextGoals.length; i++)
                  _NextGoalCard(number: i + 1, text: eval.nextGoals[i]),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  // ── Manager / HR view (with employee selector + editing) ───────────────────

  Widget _buildManagerView(BuildContext context, WidgetRef ref,
      {required bool isHR}) {
    final cycleAsync = ref.watch(activeCycleProvider);
    final cycle = cycleAsync.valueOrNull;

    // HR: all DGT collaborators; leader: only their team in the active cycle.
    final allColabsAsync   = ref.watch(allColaboradoresProvider);
    final leaderEvalsAsync = ref.watch(myCurrentCycleTeamProvider);
    final teamColabsAsync  = ref.watch(teamColaboradoresProvider);

    final isLoading = isHR
        ? allColabsAsync.isLoading
        : leaderEvalsAsync.isLoading || teamColabsAsync.isLoading;

    // Build unique, sorted employee list from the correct source.
    final List<_EmployeeEntry> uniqueEmployees;
    final seen = <String>{};
    if (isHR) {
      final allColabs = allColabsAsync.valueOrNull ?? [];
      uniqueEmployees = allColabs
          .where((c) => c.id.isNotEmpty && seen.add(c.id))
          .map((c) => _EmployeeEntry(
              id: c.id, name: c.name.isNotEmpty ? c.name : 'Colaborador'))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    } else {
      final leaderEvals = leaderEvalsAsync.valueOrNull ?? [];
      final colabors    = teamColabsAsync.valueOrNull ?? {};
      uniqueEmployees = leaderEvals
          .map((ev) {
            final name = colabors[ev.employeeId]?.name.isNotEmpty == true
                ? colabors[ev.employeeId]!.name
                : (ev.employeeName.isNotEmpty ? ev.employeeName : 'Colaborador');
            return _EmployeeEntry(id: ev.employeeId, name: name);
          })
          .where((e) => e.id.isNotEmpty && seen.add(e.id))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    }

    // Watch the selected employee's eval.
    final evalAsync = _selectedEmployeeId == null
        ? null
        : isHR
            ? ref.watch(latestLiderEvalForEmployeeProvider(_selectedEmployeeId!))
            : ref.watch(liderEvaluationForEmployeeProvider(_selectedEmployeeId!));

    final isActiveCycle = cycle?.status == CycleStatus.onGoing;
    // Goals for the next period can only be added when the cycle is NOT active.
    final canEdit = !isActiveCycle;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DgtAppBar.simple(title: 'Metas'),
      body: Column(
        children: [
          // ── Employee selector ───────────────────────────────────────────
          if (uniqueEmployees.isEmpty && isLoading)
            const LinearProgressIndicator(minHeight: 2)
          else if (uniqueEmployees.isNotEmpty)
            _EmployeeSelector(
              employees: uniqueEmployees,
              selectedId: _selectedEmployeeId,
              onSelected: (id) => setState(() => _selectedEmployeeId = id),
            ),

          // ── Content area ────────────────────────────────────────────────
          Expanded(
            child: _selectedEmployeeId == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_search_outlined,
                            size: 48, color: AppColors.textDisabled),
                        const SizedBox(height: 12),
                        Text(
                          uniqueEmployees.isEmpty
                              ? 'Nenhum colaborador encontrado.'
                              : 'Selecione um colaborador acima.',
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : evalAsync == null
                    ? const SizedBox()
                    : evalAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) =>
                            Center(child: Text('Erro ao carregar metas: $e')),
                        data: (eval) => _buildGoalsList(
                          context,
                          eval: eval,
                          canEdit: canEdit,
                          isActiveCycle: isActiveCycle,
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList(
    BuildContext context, {
    required LiderEvaluation? eval,
    required bool canEdit,
    bool isActiveCycle = false,
  }) {
    if (eval == null) {
      return const Center(
        child: AppEmptyState(
          icon: Icons.track_changes_rounded,
          title: 'Nenhuma avaliação encontrada',
          subtitle:
              'Não há avaliação registrada para este colaborador.',
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Name header
        Row(
          children: [
            AvatarInitials(name: eval.employeeName, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eval.employeeName.isNotEmpty
                        ? eval.employeeName
                        : 'Colaborador',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary),
                  ),
                  if (eval.cyclePeriod.isNotEmpty)
                    Text(
                      '${eval.cyclePeriod} ${eval.cycleYear}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Metas do período (read-only) ───────────────────────────────
        if (eval.goals.isNotEmpty) ...[
          const _SectionHeader(title: 'Metas do período'),
          const SizedBox(height: 8),
          for (final g in eval.goals) _CurrentGoalCard(goal: g),
          const SizedBox(height: 16),
        ],

        // ── Metas próximo período ──────────────────────────────────────
        Row(
          children: [
            const Expanded(child: _SectionHeader(title: 'Metas para o próximo período')),
            if (canEdit && !_adding)
              GestureDetector(
                onTap: () => setState(() => _adding = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: AppColors.darkGray),
                      SizedBox(width: 4),
                      Text('Adicionar',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.darkGray)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (eval.nextGoals.isEmpty && !_adding)
          const _EmptyGoals()
        else ...[
          for (var i = 0; i < eval.nextGoals.length; i++)
            _NextGoalCard(number: i + 1, text: eval.nextGoals[i]),
        ],

        // ── Add goal form ──────────────────────────────────────────────
        if (_adding) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _goalCtrl,
                  autofocus: true,
                  maxLines: 3,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Descreva a meta para o próximo período…',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: AppColors.textDisabled),
                    filled: true,
                    fillColor: AppColors.background,
                    isDense: true,
                    contentPadding: const EdgeInsets.all(10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: AppColors.border, width: 0.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: AppColors.border, width: 0.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () {
                              _goalCtrl.clear();
                              setState(() => _adding = false);
                            },
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saving ? null : () => _addGoal(eval),
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.darkGray))
                          : const Text('Salvar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        if (!canEdit && isActiveCycle)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.statusDraftBg,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Ciclo de avaliação em andamento. Para incluir metas para o período corrente não é possível; para incluir metas para o próximo ciclo, adicione diretamente na avaliação do profissional.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Employee selector ─────────────────────────────────────────────────────────

class _EmployeeEntry {
  final String id;
  final String name;
  const _EmployeeEntry({required this.id, required this.name});
}

class _EmployeeSelector extends StatelessWidget {
  final List<_EmployeeEntry> employees;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  const _EmployeeSelector({
    required this.employees,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Guard: DropdownButton crashes if value is not null and not in items list.
    final safeValue =
        employees.any((e) => e.id == selectedId) ? selectedId : null;
    return Container(
        color: AppColors.surface,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.person_outline_rounded,
                size: 18, color: AppColors.midGray),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButton<String>(
                value: safeValue,
                hint: const Text('Selecionar colaborador',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textDisabled)),
                isExpanded: true,
                underline: const SizedBox(),
                isDense: true,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textPrimary),
                icon: const Icon(Icons.expand_more,
                    size: 18, color: AppColors.midGray),
                dropdownColor: AppColors.surface,
                items: employees
                    .map((e) => DropdownMenuItem(
                          value: e.id,
                          child: Text(e.name),
                        ))
                    .toList(),
                onChanged: (id) {
                  if (id != null) onSelected(id);
                },
              ),
            ),
          ],
        ),
      );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Text(
        title.toUpperCase(),
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.midGray,
            letterSpacing: 0.5),
      );
}

// ── Goal cards ────────────────────────────────────────────────────────────────

class _CurrentGoalCard extends StatelessWidget {
  final TabGoal goal;
  const _CurrentGoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    Color? achColor;
    String achLabel = '';
    if (goal.achieve != null) {
      switch (goal.achieve!) {
        case GoalAchievement.yes:
          achColor = const Color(0xFF4CAF50);
          achLabel = 'Atingida';
          break;
        case GoalAchievement.partial:
          achColor = const Color(0xFFF9A825);
          achLabel = 'Parcial';
          break;
        case GoalAchievement.no:
          achColor = const Color(0xFFE53935);
          achLabel = 'Não atingida';
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              goal.goal?.isNotEmpty == true ? goal.goal! : '—',
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.4),
            ),
          ),
          if (achColor != null) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: achColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(achLabel,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: achColor)),
            ),
          ],
        ],
      ),
    );
  }
}

class _NextGoalCard extends StatelessWidget {
  final int number;
  final String text;
  const _NextGoalCard({required this.number, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Text('$number',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.4)),
            ),
          ],
        ),
      );
}

class _EmptyGoals extends StatelessWidget {
  const _EmptyGoals();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Nenhuma meta definida.',
          style: TextStyle(
              fontSize: 13,
              color: AppColors.textDisabled,
              fontStyle: FontStyle.italic),
        ),
      );
}
