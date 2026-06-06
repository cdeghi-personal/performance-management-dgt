import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/cycle_badge.dart';
import '../../../shared/widgets/dgt_app_bar.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/domain/auth_provider.dart';
import '../data/models/auto_evaluation_model.dart';
import '../domain/enrichment_providers.dart';
import '../domain/evaluation_providers.dart';
import 'evaluation_display_model.dart';
import 'resolved_eval.dart';

class EvaluationsScreen extends ConsumerWidget {
  const EvaluationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isManager  = ref.watch(isManagerProvider);
    final cycleAsync = ref.watch(activeCycleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DgtAppBar.simple(title: 'Avaliações'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          cycleAsync.when(
            data: (cycle) => cycle != null
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: CycleBadge(cycle: cycle),
                  )
                : const SizedBox.shrink(),
            loading: () => const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: CycleBadgeSkeleton(),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // ── Jornada do ciclo ───────────────────────────────────────────────
          _EvalCard(
            icon: Icons.route_rounded,
            iconBg: AppColors.statusAtRiskBg,
            iconColor: AppColors.primary,
            title: 'Jornada do ciclo',
            subtitle: 'Acompanhe todas as etapas da avaliação',
            badge: const StepStatusBadge(status: CycleStepStatus.active),
            onTap: () => context.go('/avaliacoes/jornada'),
          ),
          const SizedBox(height: 16),

          // ── Minhas avaliações (auto + avaliações do gestor) ──────────────────
          const _MyEvalsList(),
          const SizedBox(height: 16),

          // ── Seção do gestor ────────────────────────────────────────────────
          if (isManager) ...[
            const _SectionLabel(label: 'Gestor — Time'),
            const SizedBox(height: 8),
            _TeamEvalList(),
            const SizedBox(height: 10),
            _EvalCard(
              icon: Icons.balance_rounded,
              iconBg: AppColors.statusDraftBg,
              iconColor: AppColors.midGray,
              title: 'Equalização',
              subtitle: 'Classificação final do time',
              badge: const StepStatusBadge(status: CycleStepStatus.future),
              onTap: () => context.go('/avaliacoes/equalizacao'),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Lista mesclada de avaliações do usuário (auto + recebidas do gestor) ──────

enum _MyEvaluationsFilter { currentCycle, allCycles }

class _MyEvalsList extends ConsumerStatefulWidget {
  const _MyEvalsList();

  @override
  ConsumerState<_MyEvalsList> createState() => _MyEvalsListState();
}

class _MyEvalsListState extends ConsumerState<_MyEvalsList> {
  _MyEvaluationsFilter _filter = _MyEvaluationsFilter.currentCycle;

  @override
  Widget build(BuildContext context) {
    final evalsAsync    = ref.watch(resolvedMyEvalsProvider);
    final activeCycleId = ref.watch(activeCycleProvider).valueOrNull?.id;
    final currentUser   = ref.watch(currentUserProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header + filter toggle
        Row(
          children: [
            const Text(
              'MINHAS AVALIAÇÕES',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.midGray,
                  letterSpacing: 0.5),
            ),
            const Spacer(),
            _FilterToggle(
              value: _filter,
              onChanged: (f) => setState(() => _filter = f),
            ),
          ],
        ),
        const SizedBox(height: 8),
        evalsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (evals) {
            final filtered =
                _filter == _MyEvaluationsFilter.currentCycle && activeCycleId != null
                    ? evals.where((e) => switch (e) {
                        ResolvedMyAutoEval(:final data) =>
                          data.eval.cycleId == activeCycleId,
                        ResolvedMyLiderEvalReceived(:final data) =>
                          data.eval.cycleId == activeCycleId,
                      }).toList()
                    : evals;

            if (filtered.isEmpty) {
              return _EvalCard(
                icon: Icons.edit_note_rounded,
                iconBg: AppColors.statusCompletedBg,
                iconColor: AppColors.statusCompleted,
                title: 'Avaliações',
                subtitle: 'Nenhuma avaliação encontrada',
                badge: const StepStatusBadge(status: CycleStepStatus.future),
                onTap: () {},
              );
            }
            return Column(
              children: [
                for (var i = 0; i < filtered.length; i++) ...[
                  switch (filtered[i]) {
                    ResolvedMyAutoEval(:final data) => _AutoEvalCard(
                        resolved: data, currentUserName: currentUser?.name),
                    ResolvedMyLiderEvalReceived(:final data) =>
                      _ReceivedLiderEvalCard(
                          resolved: data, currentUserName: currentUser?.name),
                  },
                  if (i < filtered.length - 1) const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

// ── Compact filter toggle ─────────────────────────────────────────────────────

class _FilterToggle extends StatelessWidget {
  final _MyEvaluationsFilter value;
  final ValueChanged<_MyEvaluationsFilter> onChanged;
  const _FilterToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FilterChip(
              label: 'Ciclo atual',
              selected: value == _MyEvaluationsFilter.currentCycle,
              onTap: () => onChanged(_MyEvaluationsFilter.currentCycle),
            ),
            _FilterChip(
              label: 'Todos',
              selected: value == _MyEvaluationsFilter.allCycles,
              onTap: () => onChanged(_MyEvaluationsFilter.allCycles),
            ),
          ],
        ),
      );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppColors.textPrimary : AppColors.midGray,
            ),
          ),
        ),
      );
}

// ── Card de auto-avaliação ────────────────────────────────────────────────────

class _AutoEvalCard extends StatelessWidget {
  final ResolvedAutoEval resolved;
  final String? currentUserName;
  const _AutoEvalCard({required this.resolved, this.currentUserName});

  CycleStepStatus get _badge {
    switch (resolved.eval.status) {
      case EvaluationStatus.finished:
      case EvaluationStatus.cancelled:
        return CycleStepStatus.done;
      case EvaluationStatus.onGoing:
        return CycleStepStatus.active;
      case EvaluationStatus.notStarted:
        return CycleStepStatus.notStarted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = EvaluationDisplayModel.fromResolvedAuto(
      resolved,
      currentUserName: currentUserName,
    );
    return _EvalCard(
      icon: Icons.edit_note_rounded,
      iconBg: AppColors.statusCompletedBg,
      iconColor: AppColors.statusCompleted,
      title: model.typeLabel,
      subtitle: model.cardLine1,
      detail: model.cardLine2,
      extra: model.lastUpdateLabel,
      badge: StepStatusBadge(status: _badge),
      onTap: () => resolved.eval.isReadOnly
          ? context.go('/avaliacoes/auto/${resolved.eval.id}')
          : context.go('/avaliacoes/auto'),
    );
  }
}

class _ReceivedLiderEvalCard extends StatelessWidget {
  final ResolvedLiderEval resolved;
  final String? currentUserName;
  const _ReceivedLiderEvalCard({required this.resolved, this.currentUserName});

  CycleStepStatus get _badge {
    switch (resolved.eval.status) {
      case EvaluationStatus.finished:
      case EvaluationStatus.cancelled:
        return CycleStepStatus.done;
      case EvaluationStatus.onGoing:
        return CycleStepStatus.active;
      case EvaluationStatus.notStarted:
        return CycleStepStatus.notStarted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = EvaluationDisplayModel.fromResolvedLiderReceived(
      resolved,
      currentUserName: currentUserName,
    );
    return _EvalCard(
      icon: Icons.fact_check_rounded,
      iconBg: const Color(0xFFEDE7F6),
      iconColor: const Color(0xFF7E57C2),
      title: model.typeLabel,
      subtitle: model.cardLine1,
      detail: model.cardLine2,
      extra: model.lastUpdateLabel,
      badge: StepStatusBadge(status: _badge),
      onTap: () => context.go('/avaliacoes/recebida/${resolved.eval.id}'),
    );
  }
}

// ── Lista do time (gestor) ────────────────────────────────────────────────────

class _TeamEvalList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evalsAsync = ref.watch(resolvedTeamEvalsProvider);
    return evalsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.statusBehindBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.statusBehind, width: 0.5),
        ),
        child: Text('Erro ao carregar time: $e',
            style: const TextStyle(fontSize: 12, color: AppColors.statusBehind)),
      ),
      data: (evals) {
        if (evals.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Text(
              'Nenhum colaborador encontrado.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < evals.length; i++) ...[
              _TeamMemberCard(resolved: evals[i]),
              if (i < evals.length - 1) const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _TeamMemberCard extends StatelessWidget {
  final ResolvedLiderEval resolved;
  const _TeamMemberCard({required this.resolved});

  CycleStepStatus get _badge {
    switch (resolved.eval.status) {
      case EvaluationStatus.finished:
      case EvaluationStatus.cancelled:
        return CycleStepStatus.done;
      case EvaluationStatus.onGoing:
        return CycleStepStatus.active;
      case EvaluationStatus.notStarted:
        return CycleStepStatus.notStarted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = EvaluationDisplayModel.fromResolvedLiderManager(resolved);
    return _EvalCard(
      icon: Icons.person_rounded,
      iconBg: AppColors.statusOnTrackBg,
      iconColor: AppColors.statusOnTrack,
      title: model.personLabel,
      subtitle: model.cardLine2,
      extra: model.lastUpdateLabel,
      badge: StepStatusBadge(status: _badge),
      // Avaliação em andamento → abre formulário por employeeId (ciclo ativo)
      // Avaliação finalizada → abre detalhe read-only por evalId (histórico)
      onTap: () => resolved.eval.isReadOnly
          ? context.go('/avaliacoes/gestor/historico/${resolved.eval.id}')
          : context.go('/avaliacoes/gestor/${resolved.eval.employeeId}'),
    );
  }
}

// ── Card reutilizável ─────────────────────────────────────────────────────────

class _EvalCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? detail;
  final String? extra;
  final Widget badge;
  final VoidCallback onTap;

  const _EvalCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.detail,
    this.extra,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    if (detail != null) ...[
                      const SizedBox(height: 2),
                      Text(detail!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                    if (extra != null) ...[
                      const SizedBox(height: 2),
                      Text(extra!,
                          style: const TextStyle(fontSize: 11, color: AppColors.textDisabled)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              badge,
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.lightGray, size: 18),
            ],
          ),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label.toUpperCase(),
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w500,
            color: AppColors.midGray, letterSpacing: 0.5),
      );
}
