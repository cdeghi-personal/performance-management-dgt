import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/avatar_initials.dart';
import '../../../shared/widgets/cycle_badge.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/domain/auth_provider.dart';
import '../../evaluations/data/models/cycle_model.dart';
import '../../evaluations/domain/evaluation_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(activeCycleProvider);
      ref.invalidate(pendingAutoEvaluationsProvider);
      ref.invalidate(pendingLiderEvaluationsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isManager = ref.watch(isManagerProvider);
    final firstName = user?.name.split(' ').first ?? 'usuário';
    final pendingAutoCount =
        ref.watch(pendingAutoEvaluationsProvider).valueOrNull?.length ?? 0;
    final pendingLiderCount = isManager
        ? ref.watch(pendingLiderEvaluationsProvider).valueOrNull?.length ?? 0
        : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(firstName: firstName, name: user?.name ?? '')),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const _SectionLabel(label: 'Pendências'),
                const SizedBox(height: 8),
                _PendingCard(
                  isManager: isManager,
                  pendingAutoCount: pendingAutoCount,
                  pendingLiderCount: pendingLiderCount,
                  onTap: (route) => context.go(route),
                ),
                if (isManager) ...[
                  const SizedBox(height: 16),
                  const _SectionLabel(label: 'Resumo do ciclo'),
                  const SizedBox(height: 8),
                  const _KpiGrid(),
                ],
                const SizedBox(height: 16),
                const _SectionLabel(label: 'Etapa atual'),
                const SizedBox(height: 8),
                const _MiniStepper(),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  final String firstName;
  final String name;
  const _Header({required this.firstName, required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cycleAsync = ref.watch(activeCycleProvider);
    final pendingAutoCount =
        ref.watch(pendingAutoEvaluationsProvider).valueOrNull?.length ?? 0;
    final isManager = ref.watch(isManagerProvider);
    final pendingLiderCount = isManager
        ? ref.watch(pendingLiderEvaluationsProvider).valueOrNull?.length ?? 0
        : 0;
    final totalPending = pendingAutoCount + pendingLiderCount;

    return Container(
      color: AppColors.darkGray,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo-dgt-digitaltransformation_fundo_escuro.png',
                height: 30,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Olá,',
                      style: TextStyle(color: AppColors.lightGray, fontSize: 12)),
                  Text(
                    firstName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              AvatarInitials(name: name.isEmpty ? 'U' : name, size: 36),
            ],
          ),
          const SizedBox(height: 16),
          // Badge dinâmico do ciclo ativo
          cycleAsync.when(
            data: (cycle) => cycle != null
                ? CycleBadge(cycle: cycle)
                : const SizedBox.shrink(),
            loading: () => const CycleBadgeSkeleton(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 14),
          // Pendências
          Row(
            children: [
              const Expanded(
                child: Text('Pendências no ciclo',
                    style: TextStyle(color: AppColors.lightGray, fontSize: 11)),
              ),
              Text(
                '$totalPending item${totalPending != 1 ? 's' : ''}',
                style: const TextStyle(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


// ── Seção label ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.midGray,
          letterSpacing: 0.5,
        ),
      );
}

// ── Card de pendências ────────────────────────────────────────────────────────

class _PendingCard extends StatelessWidget {
  final bool isManager;
  final int pendingAutoCount;
  final int pendingLiderCount;
  final void Function(String route) onTap;

  const _PendingCard({
    required this.isManager,
    required this.pendingAutoCount,
    required this.pendingLiderCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasAuto = pendingAutoCount > 0;
    final hasLider = isManager && pendingLiderCount > 0;

    if (!hasAuto && !hasLider) {
      return _DgtCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_circle_outline_rounded,
                    color: Color(0xFF66BB6A), size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Nenhuma pendência no momento',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
      );
    }

    return _DgtCard(
      child: Column(
        children: [
          if (hasAuto)
            _PendingItem(
              icon: Icons.warning_amber_rounded,
              iconColor: AppColors.primary,
              iconBg: const Color(0xFFFEF3DC),
              title: 'Auto-avaliação pendente',
              subtitle: '$pendingAutoCount avaliação${pendingAutoCount > 1 ? 'ões' : ''} aguardando',
              onTap: () => onTap('/avaliacoes/auto'),
              showDivider: hasLider,
            ),
          if (hasLider)
            _PendingItem(
              icon: Icons.info_outline_rounded,
              iconColor: AppColors.statusCompleted,
              iconBg: const Color(0xFFE3F2FD),
              title: 'Avaliação de colaboradores',
              subtitle: '$pendingLiderCount colaborador${pendingLiderCount > 1 ? 'es' : ''} aguardando envio',
              onTap: () => onTap('/avaliacoes'),
              showDivider: false,
            ),
        ],
      ),
    );
  }
}

class _PendingItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  const _PendingItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.lightGray, size: 18),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 64, endIndent: 16),
      ],
    );
  }
}

// ── KPI Grid ─────────────────────────────────────────────────────────────────

class _KpiGrid extends ConsumerWidget {
  const _KpiGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile    = ref.watch(currentProfileProvider);
    final cycleAsync = ref.watch(activeCycleProvider);
    final cycle      = cycleAsync.valueOrNull;

    // HR vê todas as avaliações do ciclo; leader vê apenas as do próprio time
    final evalsAsync = profile?.isHR == true
        ? ref.watch(teamEvaluationsProvider)
        : ref.watch(liderEvaluationsProvider);

    final allEvals = evalsAsync.valueOrNull ?? [];

    // Para leader, filtra apenas o ciclo ativo
    final evals = (profile?.isHR == true || cycle == null)
        ? allEvals
        : allEvals.where((e) => e.cycleId == cycle.id).toList();

    final total     = evals.length;
    final completed = evals.where((e) => e.status.isReadOnly).length;
    final pending   = total - completed;
    final pct       = total == 0 ? 0 : (completed * 100 / total).round();

    if (evalsAsync.isLoading) {
      return const Row(children: [
        _KpiTile(label: 'Avaliações pendentes', value: '—', sub: 'carregando...'),
        SizedBox(width: 10),
        _KpiTile(label: '% Realizadas', value: '—', unit: '%', sub: 'carregando...'),
      ]);
    }

    return Row(
      children: [
        _KpiTile(
          label: 'Avaliações pendentes',
          value: '$pending',
          sub: total == 0 ? 'sem avaliações no ciclo' : 'de $total no ciclo',
        ),
        const SizedBox(width: 10),
        _KpiTile(
          label: '% Realizadas',
          value: '$pct',
          unit: '%',
          sub: '$completed concluída${completed != 1 ? 's' : ''}',
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final String sub;
  const _KpiTile({required this.label, required this.value, this.unit, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEBEBEB), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.midGray)),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkGray,
                    ),
                  ),
                  if (unit != null)
                    TextSpan(
                      text: unit,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.midGray,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.midGray)),
          ],
        ),
      ),
    );
  }
}

// ── Mini Stepper ──────────────────────────────────────────────────────────────

class _MiniStepper extends ConsumerWidget {
  const _MiniStepper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cycleAsync = ref.watch(activeCycleProvider);
    return cycleAsync.when(
      loading: () => const _DgtCard(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (cycle) {
        if (cycle == null) return const SizedBox.shrink();
        final steps = _buildPhaseSteps(cycle);
        return _DgtCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < steps.length; i++)
                  _MiniStep(
                    index: i + 1,
                    label: steps[i].label,
                    sub: steps[i].sub,
                    status: steps[i].stepStatus,
                    showDivider: i < steps.length - 1,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<_PhaseInfo> _buildPhaseSteps(Cycle cycle) {
    String fmt(DateTime? d) {
      if (d == null) return '';
      return 'Até ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    }

    CycleStepStatus toStep(PhaseStatus? s) {
      switch (s) {
        case PhaseStatus.finished:   return CycleStepStatus.done;
        case PhaseStatus.onGoing:    return CycleStepStatus.active;
        default:                     return CycleStepStatus.future;
      }
    }

    TabPhase? p(PhaseIdentifier id) => cycle.phaseFor(id);

    final started = p(PhaseIdentifier.started);
    return [
      _PhaseInfo(
        PhaseIdentifier.started.label,
        started?.planDate != null
            ? 'Início: ${started!.planDate!.day.toString().padLeft(2, '0')}/${started.planDate!.month.toString().padLeft(2, '0')}'
            : '',
        toStep(started?.status),
      ),
      _PhaseInfo(
        PhaseIdentifier.selfEvaluation.label,
        fmt(p(PhaseIdentifier.selfEvaluation)?.planDate),
        toStep(p(PhaseIdentifier.selfEvaluation)?.status),
      ),
      _PhaseInfo(
        PhaseIdentifier.leaderEvaluation.label,
        fmt(p(PhaseIdentifier.leaderEvaluation)?.planDate),
        toStep(p(PhaseIdentifier.leaderEvaluation)?.status),
      ),
      _PhaseInfo(
        PhaseIdentifier.evaluationMeeting.label,
        fmt(p(PhaseIdentifier.evaluationMeeting)?.planDate),
        toStep(p(PhaseIdentifier.evaluationMeeting)?.status),
      ),
      _PhaseInfo(
        PhaseIdentifier.results.label,
        fmt(p(PhaseIdentifier.results)?.planDate),
        toStep(p(PhaseIdentifier.results)?.status),
      ),
    ];
  }
}

class _PhaseInfo {
  final String label;
  final String sub;
  final CycleStepStatus stepStatus;
  const _PhaseInfo(this.label, this.sub, this.stepStatus);
}

class _MiniStep extends StatelessWidget {
  final int index;
  final String label;
  final String sub;
  final CycleStepStatus status;
  final bool showDivider;

  const _MiniStep({
    required this.index,
    required this.label,
    required this.sub,
    required this.status,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Widget content;

    switch (status) {
      case CycleStepStatus.done:
        bg = AppColors.darkGray;
        content = const Icon(Icons.check, size: 14, color: Colors.white);
        break;
      case CycleStepStatus.active:
        bg = AppColors.primary;
        content = Text('$index',
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.darkGray));
        break;
      case CycleStepStatus.notStarted:
      case CycleStepStatus.future:
        bg = const Color(0xFFF0F0F0);
        content = Text('$index',
            style: const TextStyle(fontSize: 11, color: AppColors.textDisabled));
        break;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Center(child: content),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                    if (sub.isNotEmpty)
                      Text(sub,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              StepStatusBadge(status: status),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

// ── DgtCard helper ────────────────────────────────────────────────────────────

class _DgtCard extends StatelessWidget {
  final Widget child;
  const _DgtCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: child,
      );
}
