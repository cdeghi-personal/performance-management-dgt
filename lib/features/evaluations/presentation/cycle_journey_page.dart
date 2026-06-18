import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart' as du;
import '../../../shared/widgets/cycle_badge.dart';
import '../../../shared/widgets/dgt_app_bar.dart';
import '../../auth/domain/auth_provider.dart';
import '../data/models/auto_evaluation_model.dart';
import '../data/models/cycle_model.dart';
import '../data/repositories/cycle_repository.dart';
import '../domain/evaluation_providers.dart';

class CycleJourneyPage extends ConsumerStatefulWidget {
  const CycleJourneyPage({super.key});

  @override
  ConsumerState<CycleJourneyPage> createState() => _CycleJourneyPageState();
}

class _CycleJourneyPageState extends ConsumerState<CycleJourneyPage> {
  List<TabPhase>? _localPhases;
  Cycle? _originalCycle;
  bool _saving = false;

  bool get _hasChanges {
    if (_localPhases == null || _originalCycle == null) return false;
    final original = _originalCycle!.tabPhases;
    if (_localPhases!.length != original.length) return false;
    for (var i = 0; i < _localPhases!.length; i++) {
      if (_localPhases![i].status != original[i].status) return true;
      if (_localPhases![i].planDate != original[i].planDate) return true;
    }
    return false;
  }

  void _initFromCycle(Cycle? cycle) {
    if (cycle == null) return;
    if (_originalCycle?.id == cycle.id) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _originalCycle = cycle;
        _localPhases = List.from(cycle.tabPhases);
      });
    });
  }

  void _updatePhase(int index, TabPhase updated) {
    setState(() {
      final copy = List<TabPhase>.from(_localPhases!);
      copy[index] = updated;
      _localPhases = copy;
    });
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair sem salvar?'),
        content: const Text(
            'Há alterações não salvas nas fases do ciclo. Deseja sair sem salvar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ficar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusBehind,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair sem salvar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _save() async {
    if (!_hasChanges || _saving) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Salvar alterações'),
        content: const Text('Confirmar alterações nas fases do ciclo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      final phases = List<TabPhase>.from(_localPhases!);
      print('[CycleJourney] updateCyclePhases id=${_originalCycle!.id} phases=${phases.map((p) => "${p.phase.sydleValue}:${p.status.sydleValue}").toList()}');
      await ref.read(cycleRepositoryProvider).updateCyclePhases(
            cycle: _originalCycle!,
            phases: phases,
          );
      print('[CycleJourney] updateCyclePhases OK');
      if (!mounted) return;
      // Atualiza _originalCycle para refletir o que foi salvo → _hasChanges = false.
      // NÃO zera para null: evita reinicializar com dado cacheado enquanto o provider recarrega.
      final savedCycle = Cycle(
        id:          _originalCycle!.id,
        period:      _originalCycle!.period,
        year:        _originalCycle!.year,
        status:      _originalCycle!.status,
        criteriaIds: _originalCycle!.criteriaIds,
        cycleDate:   _originalCycle!.cycleDate,
        tabPhases:   phases,
        creationDate: _originalCycle!.creationDate,
      );
      setState(() {
        _originalCycle = savedCycle;
        _localPhases   = phases;
      });
      ref.invalidate(activeCycleProvider);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ciclo atualizado com sucesso!'),
        backgroundColor: AppColors.statusOnTrack,
      ));
    } catch (e, stack) {
      print('[CycleJourney] updateCyclePhases error: $e\n$stack');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao salvar: $e'),
        backgroundColor: AppColors.statusBehind,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate(
      BuildContext context, int index, TabPhase phase) async {
    final initial = phase.planDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      _updatePhase(index, phase.copyWith(planDate: picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cycleAsync    = ref.watch(activeCycleProvider);
    final autoEvalAsync = ref.watch(myAutoEvaluationProvider);
    final profile       = ref.watch(currentProfileProvider);
    final isHR = profile?.isHR ?? false;

    cycleAsync.whenData(_initFromCycle);

    final displayPhases =
        _localPhases ?? cycleAsync.valueOrNull?.tabPhases ?? [];

    final activeIndex = () {
      int idx = -1;
      for (var i = 0; i < displayPhases.length; i++) {
        if (displayPhases[i].status == PhaseStatus.onGoing) idx = i;
      }
      return idx;
    }();

    final autoStatus = autoEvalAsync.valueOrNull?.status;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await _confirmDiscard();
        if (discard && context.mounted) context.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: DgtAppBar.simple(title: 'Jornada do ciclo'),
        body: cycleAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro ao carregar ciclo: $e')),
          data: (cycle) {
            if (cycle == null) {
              return const Center(
                child: Text('Nenhum ciclo ativo encontrado.',
                    style: TextStyle(color: AppColors.textSecondary)),
              );
            }

            final progress = _computeProgress(displayPhases);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                _CycleHeader(cycle: cycle, progress: progress),
                const SizedBox(height: 20),
                if (isHR)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined,
                            size: 14, color: AppColors.midGray),
                        SizedBox(width: 6),
                        Text(
                          'Você pode editar status e prazo de cada fase.',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                Stack(
                  children: [
                    Positioned(
                      left: 19,
                      top: 24,
                      bottom: 24,
                      width: 2,
                      child: Container(color: AppColors.border),
                    ),
                    Column(
                      children: [
                        for (var i = 0; i < displayPhases.length; i++)
                          _PhaseRow(
                            phase: displayPhases[i],
                            number: i + 1,
                            showYouAreHere: i == activeIndex,
                            autoEvalStatus: autoStatus,
                            onStatusChanged: isHR
                                ? (s) => _updatePhase(
                                    i, displayPhases[i].copyWith(status: s))
                                : null,
                            onPlanDatePick: isHR
                                ? () =>
                                    _pickDate(context, i, displayPhases[i])
                                : null,
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: isHR
            ? _SaveBar(
                hasChanges: _hasChanges,
                saving: _saving,
                onSave: _save,
              )
            : null,
      ),
    );
  }

  static double _computeProgress(List<TabPhase> phases) {
    if (phases.isEmpty) return 0;
    final done =
        phases.where((p) => p.status == PhaseStatus.finished).length;
    return done / phases.length;
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _CycleHeader extends StatelessWidget {
  final Cycle cycle;
  final double progress;
  const _CycleHeader({required this.cycle, required this.progress});

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkGray,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ciclo atual',
              style: TextStyle(color: AppColors.lightGray, fontSize: 12)),
          const SizedBox(height: 6),
          CycleBadge(cycle: cycle),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text('Progresso geral',
                    style: TextStyle(
                        color: AppColors.lightGray, fontSize: 11)),
              ),
              Text('$pct%',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Linha de fase ─────────────────────────────────────────────────────────────

class _PhaseRow extends StatelessWidget {
  final TabPhase phase;
  final int number;
  final bool showYouAreHere;
  final EvaluationStatus? autoEvalStatus;
  final ValueChanged<PhaseStatus>? onStatusChanged;
  final VoidCallback? onPlanDatePick;

  const _PhaseRow({
    required this.phase,
    required this.number,
    this.showYouAreHere = false,
    this.autoEvalStatus,
    this.onStatusChanged,
    this.onPlanDatePick,
  });

  bool get _isActive   => phase.status == PhaseStatus.onGoing;
  bool get _isDone     => phase.status == PhaseStatus.finished;
  bool get _isUpcoming => phase.status == PhaseStatus.notStarted;

  bool get _completedByUser =>
      phase.phase == PhaseIdentifier.selfEvaluation &&
      _isActive &&
      autoEvalStatus == EvaluationStatus.finished;

  bool get _showCta =>
      _isActive &&
      phase.phase == PhaseIdentifier.selfEvaluation &&
      autoEvalStatus != null &&
      autoEvalStatus != EvaluationStatus.cancelled &&
      !_completedByUser;

  String get _desc {
    switch (phase.phase) {
      case PhaseIdentifier.started:
        return 'Ciclo aberto: RH definiu os critérios de avaliação e as expectativas por nível para este período.';
      case PhaseIdentifier.selfEvaluation:
        return 'Cada colaborador / prestador avalia seus próprios critérios e registra pontos de desenvolvimento.';
      case PhaseIdentifier.evaluationMeeting:
        return 'Reunião da liderança para revisão conjunta de todas as avaliações do grupo, balizando os resultados por nível de carreira.';
      case PhaseIdentifier.leaderEvaluation:
        return 'Gestor registra no app a nota de cada critério e seus comentários sobre o colaborador / prestador avaliado.';
      case PhaseIdentifier.results:
        return 'Cada colaborador / prestador recebe o retorno oficial do seu resultado anual: classificação final, reajuste de mérito ou promoção.';
    }
  }

  Widget _buildStatusChip() {
    if (_completedByUser) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.statusOnTrackBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Concluída para você',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.statusOnTrack),
        ),
      );
    }
    return _StatusChip(status: phase.status);
  }

  @override
  Widget build(BuildContext context) {
    final circleBg = _isDone
        ? AppColors.darkGray
        : _isActive
            ? AppColors.primary
            : AppColors.surface;

    final circleBorder = _isActive
        ? Border.all(color: AppColors.primary, width: 1.5)
        : _isUpcoming
            ? Border.all(color: AppColors.border, width: 1.5)
            : null;

    final circleContent = _isDone
        ? const Icon(Icons.check, size: 16, color: Colors.white)
        : Text(
            '$number',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _isActive ? AppColors.darkGray : AppColors.textDisabled,
            ),
          );

    final bool hrMode = onStatusChanged != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: circleBg,
              shape: BoxShape.circle,
              border: circleBorder,
              boxShadow: _isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Center(child: circleContent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: (_isActive || hrMode)
                  ? const EdgeInsets.all(14)
                  : const EdgeInsets.only(top: 6, bottom: 6),
              decoration: (_isActive || hrMode)
                  ? BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _isActive
                              ? AppColors.primary
                              : AppColors.border,
                          width: _isActive ? 1.5 : 0.5),
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showYouAreHere)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Você está aqui',
                          style: TextStyle(
                              color: AppColors.darkGray,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                  _buildStatusChip(),
                  const SizedBox(height: 5),
                  Text(phase.phase.label,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(_desc,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.5)),
                  if (phase.planDate != null && !hrMode) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Prazo: ${du.formatDate(phase.planDate!)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: _isActive
                            ? AppColors.primary
                            : AppColors.textDisabled,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (_completedByUser) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Auto-avaliação finalizada.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                  if (_showCta) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.go('/avaliacoes/auto'),
                        child: const Text('Ir para auto-avaliação'),
                      ),
                    ),
                  ],
                  // ── HR edit controls ──────────────────────────────────────
                  if (hrMode) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    _PhaseEditControls(
                      phase: phase,
                      onStatusChanged: onStatusChanged!,
                      onPlanDatePick: onPlanDatePick,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── HR edit controls (status dropdown + date picker) ─────────────────────────

class _PhaseEditControls extends StatelessWidget {
  final TabPhase phase;
  final ValueChanged<PhaseStatus> onStatusChanged;
  final VoidCallback? onPlanDatePick;

  const _PhaseEditControls({
    required this.phase,
    required this.onStatusChanged,
    required this.onPlanDatePick,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: DropdownButton<PhaseStatus>(
              value: phase.status,
              isExpanded: true,
              underline: const SizedBox(),
              isDense: true,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textPrimary),
              icon: const Icon(Icons.expand_more,
                  size: 18, color: AppColors.midGray),
              dropdownColor: AppColors.surface,
              items: PhaseStatus.values
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.label),
                      ))
                  .toList(),
              onChanged: (s) {
                if (s != null) onStatusChanged(s);
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onPlanDatePick,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppColors.midGray),
                const SizedBox(width: 6),
                Text(
                  phase.planDate != null
                      ? du.formatDate(phase.planDate!)
                      : 'Definir prazo',
                  style: TextStyle(
                    fontSize: 12,
                    color: phase.planDate != null
                        ? AppColors.textPrimary
                        : AppColors.textDisabled,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Chip de status ────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final PhaseStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    Color bg;

    switch (status) {
      case PhaseStatus.finished:
        label = 'Concluída';
        color = AppColors.statusOnTrack;
        bg    = AppColors.statusOnTrackBg;
        break;
      case PhaseStatus.onGoing:
        label = 'Em andamento';
        color = AppColors.statusAtRisk;
        bg    = AppColors.statusAtRiskBg;
        break;
      case PhaseStatus.notStarted:
        label = 'Em breve';
        color = AppColors.textDisabled;
        bg    = AppColors.statusDraftBg;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w500, color: color)),
    );
  }
}

// ── Save bar (HR only) ────────────────────────────────────────────────────────

class _SaveBar extends StatelessWidget {
  final bool hasChanges;
  final bool saving;
  final VoidCallback onSave;
  const _SaveBar(
      {required this.hasChanges,
      required this.saving,
      required this.onSave});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border:
              Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (hasChanges && !saving) ? onSave : null,
            child: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.darkGray))
                : const Text('Salvar alterações →'),
          ),
        ),
      );
}
