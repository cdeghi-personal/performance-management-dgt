import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart' as du;
import '../../../shared/widgets/avatar_initials.dart';
import '../../../shared/widgets/dgt_app_bar.dart';
import '../../auth/domain/auth_provider.dart';
import '../../profile/data/employee_perfil_model.dart';
import '../../profile/domain/profile_providers.dart';
import '../data/models/auto_evaluation_model.dart';
import '../data/models/cycle_model.dart';
import '../data/models/lider_evaluation_model.dart';
import '../data/models/tab_goal_model.dart';
import '../data/repositories/colaborador_repository.dart';
import '../data/repositories/lider_evaluation_repository.dart';
import '../domain/evaluation_providers.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String _cycleStatusLabel(CycleStatus s) {
  switch (s) {
    case CycleStatus.onGoing:    return 'Em andamento';
    case CycleStatus.finished:   return 'Finalizado';
    case CycleStatus.cancelled:  return 'Cancelado';
    case CycleStatus.notStarted: return 'Não iniciado';
  }
}

String _classLabel(String raw) {
  switch (raw) {
    case 'aboveLevel': return 'Acima do nível';
    case 'atLevel':    return 'No nível';
    case 'belowLevel': return 'Abaixo do nível';
    default:           return raw.isNotEmpty ? raw : '—';
  }
}

String _statusLabel(EvaluationStatus s) {
  switch (s) {
    case EvaluationStatus.notStarted: return 'Não iniciada';
    case EvaluationStatus.onGoing:    return 'Em andamento';
    case EvaluationStatus.finished:   return 'Concluída';
    case EvaluationStatus.cancelled:  return 'Cancelada';
  }
}

class _FilterItem {
  final String id;
  final String label;
  const _FilterItem({required this.id, required this.label});
}

// ── Page ──────────────────────────────────────────────────────────────────────

class EqualizationPage extends ConsumerStatefulWidget {
  const EqualizationPage({super.key});

  @override
  ConsumerState<EqualizationPage> createState() => _EqualizationPageState();
}

class _EqualizationPageState extends ConsumerState<EqualizationPage> {
  final Map<String, EvaluationClassification?> _classifications = {};
  final Map<String, bool> _topPerformers = {};
  final Map<String, TextEditingController> _meetingNotesCtrls = {};
  final Set<String> _selectedLevels     = {};
  final Set<String> _selectedAppraisers = {};
  final Set<String> _selectedStatuses   = {};
  bool _showAdvancedFilters = false;
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _meetingNotesCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _tryInitialize(List<LiderEvaluation> evals) {
    if (_initialized) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialized) return;
      setState(() {
        for (final e in evals) {
          _classifications[e.id] = e.classification;
          _topPerformers[e.id]   = e.topPerformer;
          if (!_meetingNotesCtrls.containsKey(e.id)) {
            _meetingNotesCtrls[e.id] =
                TextEditingController(text: e.commentsPerfMeeting ?? '');
          }
        }
        _initialized = true;
      });
    });
  }

  Future<void> _save(List<LiderEvaluation> evals) async {
    if (evals.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(liderEvaluationRepositoryProvider);
      for (final e in evals) {
        final localClass = _classifications[e.id];
        final localTop   = _topPerformers[e.id] ?? e.topPerformer;
        final localNotes = _meetingNotesCtrls[e.id]?.text.trim() ?? '';
        final changed = localClass != e.classification ||
            localTop != e.topPerformer ||
            localNotes != (e.commentsPerfMeeting ?? '');
        if (!changed) continue;
        await repo.update(LiderEvaluation(
          id:                   e.id,
          cycleId:              e.cycleId,
          cyclePeriod:          e.cyclePeriod,
          cycleYear:            e.cycleYear,
          status:               e.status,
          employeeId:           e.employeeId,
          employeeName:         e.employeeName,
          appraiserId:          e.appraiserId,
          appraiserName:        e.appraiserName,
          behavioralEvaluation: e.behavioralEvaluation,
          technicalEvaluation:  e.technicalEvaluation,
          goals:                e.goals,
          attentionPoints:      e.attentionPoints,
          strengths:            e.strengths,
          feedback:             e.feedback,
          actionPlan:           e.actionPlan,
          nextGoals:            e.nextGoals,
          classification:       localClass,
          topPerformer:         localTop,
          commentsPerfMeeting:  localNotes.isEmpty ? null : localNotes,
          evaluationDate:       e.evaluationDate,
          feedbackDate:         e.feedbackDate,
          finishedDate:         e.finishedDate,
          creationDate:         e.creationDate,
          lastUpdate:           e.lastUpdate,
        ));
      }
      if (!mounted) return;
      ref.invalidate(equalizationEvalsProvider);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Equalização salva!'),
        backgroundColor: AppColors.statusOnTrack,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao salvar: $e'),
        backgroundColor: AppColors.statusBehind,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double _behavioralAvg(LiderEvaluation eval) {
    final scores = eval.behavioralEvaluation
        .where((t) => t.evaluation != null)
        .map((t) => t.evaluation!.toDouble())
        .toList();
    if (scores.isEmpty) return 0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  double _technicalAvg(LiderEvaluation eval) {
    final scores = eval.technicalEvaluation
        .where((t) => t.evaluation != null)
        .map((t) => t.evaluation!.toDouble())
        .toList();
    if (scores.isEmpty) return 0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  void _showDetails(BuildContext context, LiderEvaluation eval) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailsSheet(
        evalId: eval.id,
        fallbackName: eval.employeeName.isNotEmpty ? eval.employeeName : 'Colaborador',
      ),
    );
  }

  void _showFilter(
    BuildContext context, {
    required String title,
    required List<_FilterItem> items,
    required Set<String> selected,
    required void Function(Set<String>) onApply,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        title: title,
        items: items,
        selected: Set.from(selected),
        onApply: (result) {
          if (mounted) onApply(result);
        },
      ),
    );
  }

  void _showPerfilSheet(BuildContext context, String employeeId, String name) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmployeePerfilSheet(
        employeeId: employeeId,
        employeeName: name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile     = ref.watch(currentProfileProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Employees must not access equalization.
    if (profile?.isEmployee == true) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: DgtAppBar.simple(title: 'Equalização'),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 40, color: AppColors.textDisabled),
              SizedBox(height: 12),
              Text('Acesso restrito a gestores e RH.',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    // Use scoped providers — leader sees only their team; HR sees all.
    final evalsAsync    = ref.watch(equalizationEvalsProvider);
    final colaborsAsync = ref.watch(equalizationColaboradoresProvider);
    final perfilsAsync  = ref.watch(equalizationEmployeePerfilsProvider);
    final cycleAsync    = ref.watch(activeCycleProvider);

    evalsAsync.whenData(_tryInitialize);

    final evals     = evalsAsync.valueOrNull ?? [];
    final colabors  = colaborsAsync.valueOrNull ?? {};
    final perfilMap = perfilsAsync.valueOrNull ?? {};
    final cycle     = cycleAsync.valueOrNull;
    final meetingActive = cycle?.meetingPhase?.status == PhaseStatus.onGoing;
    final isHR      = profile?.isHR ?? false;

    final contextLine = cycle != null
        ? '${cycle.period} ${cycle.year} · ${_cycleStatusLabel(cycle.status)}'
        : 'Ciclo ativo';

    // careerLevel sourced from employeeProfile (authoritative) — not colaboradorDGT.
    final levelItems = (evals
            .map((e) => perfilMap[e.employeeId]?.careerLevel ?? '')
            .where((l) => l.isNotEmpty)
            .toSet()
            .toList()
          ..sort())
        .map((l) => _FilterItem(id: l, label: l))
        .toList();

    // Appraiser items — derived from real liderEvaluation data.
    final appraiserSeen = <String>{};
    final appraiserItems = <_FilterItem>[];
    for (final e in evals) {
      if (e.appraiserId.isNotEmpty && appraiserSeen.add(e.appraiserId)) {
        final name = colabors[e.appraiserId]?.name.isNotEmpty == true
            ? colabors[e.appraiserId]!.name
            : (e.appraiserName.isNotEmpty ? e.appraiserName : e.appraiserId);
        appraiserItems.add(_FilterItem(id: e.appraiserId, label: name));
      }
    }
    appraiserItems.sort((a, b) => a.label.compareTo(b.label));

    // Status items — derived from statuses present in the dataset.
    final statusSeen = <EvaluationStatus>{};
    for (final e in evals) {
      statusSeen.add(e.status);
    }
    final statusItems = EvaluationStatus.values
        .where(statusSeen.contains)
        .map((s) => _FilterItem(id: s.name, label: _statusLabel(s)))
        .toList();

    // Apply AND filter across all three dimensions.
    final filtered = evals.where((e) {
      final level = perfilMap[e.employeeId]?.careerLevel ?? '';
      final levelOk = _selectedLevels.isEmpty || _selectedLevels.contains(level);
      final appraiserOk = _selectedAppraisers.isEmpty || _selectedAppraisers.contains(e.appraiserId);
      final statusOk = _selectedStatuses.isEmpty || _selectedStatuses.contains(e.status.name);
      return levelOk && appraiserOk && statusOk;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DgtAppBar.detail(
        typeLabel: 'Equalização',
        contextLine: contextLine,
      ),
      body: evalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro ao carregar avaliações: $e')),
        data: (_) => ListView(
          children: [
            // Dashboard computed over the FILTERED dataset.
            _DistributionDashboard(
              classifications:
                  {for (final e in filtered) e.id: _classifications[e.id]},
              topPerformers:
                  {for (final e in filtered) e.id: _topPerformers[e.id] ?? false},
              total: filtered.length,
            ),
            // Filtro de nível de carreira — sempre visível.
            if (levelItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _FilterButton(
                  label: 'Nível de carreira',
                  items: levelItems,
                  selected: _selectedLevels,
                  onTap: () => _showFilter(
                    context,
                    title: 'Filtrar por nível de carreira',
                    items: levelItems,
                    selected: _selectedLevels,
                    onApply: (r) => setState(() {
                      _selectedLevels..clear()..addAll(r);
                    }),
                  ),
                ),
              ),
            // Chip de filtros avançados + expansão animada.
            if (appraiserItems.length > 1 || statusItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chip toggle
                    GestureDetector(
                      onTap: () => setState(
                          () => _showAdvancedFilters = !_showAdvancedFilters),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: (_selectedAppraisers.isNotEmpty ||
                                  _selectedStatuses.isNotEmpty)
                              ? AppColors.darkGray.withValues(alpha: 0.06)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (_selectedAppraisers.isNotEmpty ||
                                    _selectedStatuses.isNotEmpty)
                                ? AppColors.darkGray
                                : AppColors.border,
                            width: (_selectedAppraisers.isNotEmpty ||
                                    _selectedStatuses.isNotEmpty)
                                ? 1.0
                                : 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Filtros avançados',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500)),
                            if (_selectedAppraisers.isNotEmpty ||
                                _selectedStatuses.isNotEmpty) ...[
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.darkGray,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_selectedAppraisers.length + _selectedStatuses.length}',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                            const SizedBox(width: 4),
                            AnimatedRotation(
                              turns: _showAdvancedFilters ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(Icons.expand_more_rounded,
                                  size: 16, color: AppColors.midGray),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Filtros avançados expandidos com animação.
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      child: _showAdvancedFilters
                          ? Column(
                              children: [
                                if (appraiserItems.length > 1) ...[
                                  const SizedBox(height: 8),
                                  _FilterButton(
                                    label: 'Gestor avaliador',
                                    items: appraiserItems,
                                    selected: _selectedAppraisers,
                                    onTap: () => _showFilter(
                                      context,
                                      title: 'Filtrar por gestor avaliador',
                                      items: appraiserItems,
                                      selected: _selectedAppraisers,
                                      onApply: (r) => setState(() {
                                        _selectedAppraisers..clear()..addAll(r);
                                      }),
                                    ),
                                  ),
                                ],
                                if (statusItems.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  _FilterButton(
                                    label: 'Status da avaliação',
                                    items: statusItems,
                                    selected: _selectedStatuses,
                                    onTap: () => _showFilter(
                                      context,
                                      title: 'Filtrar por status',
                                      items: statusItems,
                                      selected: _selectedStatuses,
                                      onApply: (r) => setState(() {
                                        _selectedStatuses..clear()..addAll(r);
                                      }),
                                    ),
                                  ),
                                ],
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                decoration: BoxDecoration(
                  color: meetingActive
                      ? const Color(0xFFFEF9ED)
                      : AppColors.statusDraftBg,
                  border: Border.all(
                    color: meetingActive
                        ? const Color(0xFFFCE7A0)
                        : AppColors.border,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  meetingActive
                      ? 'Fase de reunião ativa. Revise e ajuste as classificações antes de confirmar.'
                      : 'A fase de reunião ainda não está ativa. Classificações serão liberadas quando a reunião for iniciada.',
                  style: TextStyle(
                    fontSize: 12,
                    color: meetingActive
                        ? AppColors.statusAtRisk
                        : AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('TIME',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.midGray,
                            letterSpacing: 0.5)),
                  ),
                  for (final e in filtered) ...[
                    _EmployeeCard(
                      eval: e,
                      colaborador: colabors[e.employeeId],
                      careerLevel: perfilMap[e.employeeId]?.careerLevel ?? '',
                      appraiserName: colabors[e.appraiserId]?.name.isNotEmpty == true
                          ? colabors[e.appraiserId]!.name
                          : e.appraiserName,
                      behavioralAvg: _behavioralAvg(e),
                      technicalAvg:  _technicalAvg(e),
                      classification: _classifications[e.id],
                      topPerformer:   _topPerformers[e.id] ?? false,
                      meetingNotesCtrl: _meetingNotesCtrls[e.id],
                      meetingActive: meetingActive,
                      showTopPerformer: isHR ||
                          (currentUser != null &&
                              e.appraiserId == currentUser.colaboradorId),
                      onClassificationChanged: meetingActive
                          ? (c) => setState(() => _classifications[e.id] = c)
                          : null,
                      onTopPerformerToggle: meetingActive
                          ? () => setState(() => _topPerformers[e.id] =
                              !(_topPerformers[e.id] ?? false))
                          : null,
                      onDetailTap: () => _showDetails(context, e),
                      onPerfilTap: () {
                        final name = colabors[e.employeeId]?.name.isNotEmpty == true
                            ? colabors[e.employeeId]!.name
                            : (e.employeeName.isNotEmpty ? e.employeeName : 'Colaborador');
                        _showPerfilSheet(context, e.employeeId, name);
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: meetingActive
          ? _ActionBar(saving: _saving, onSave: () => _save(evals))
          : null,
    );
  }
}

// ── Generic filter button ─────────────────────────────────────────────────────

class _FilterButton extends StatelessWidget {
  final String label;
  final List<_FilterItem> items;
  final Set<String> selected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.items,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilter = selected.isNotEmpty;
    final String valueLabel;
    if (!hasFilter) {
      valueLabel = 'Todos';
    } else if (selected.length == 1) {
      valueLabel = items.firstWhere(
        (i) => i.id == selected.first,
        orElse: () => _FilterItem(id: selected.first, label: selected.first),
      ).label;
    } else {
      valueLabel = '${selected.length} selecionados';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: hasFilter
              ? AppColors.darkGray.withValues(alpha: 0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasFilter ? AppColors.darkGray : AppColors.border,
            width: hasFilter ? 1.0 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.filter_list_rounded,
                size: 16,
                color: hasFilter ? AppColors.darkGray : AppColors.midGray),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.midGray)),
                  Text(valueLabel,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: hasFilter
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: hasFilter
                              ? AppColors.darkGray
                              : AppColors.textDisabled)),
                ],
              ),
            ),
            Icon(Icons.expand_more_rounded,
                size: 18,
                color: hasFilter ? AppColors.darkGray : AppColors.midGray),
          ],
        ),
      ),
    );
  }
}

// ── Generic filter sheet ──────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final String title;
  final List<_FilterItem> items;
  final Set<String> selected;
  final void Function(Set<String>) onApply;

  const _FilterSheet({
    required this.title,
    required this.items,
    required this.selected,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final Set<String> _local;

  @override
  void initState() {
    super.initState();
    _local = Set.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(widget.title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ),
                if (_local.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _local.clear()),
                    child: const Text('Limpar',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500)),
                  ),
              ],
            ),
          ),
          for (final item in widget.items)
            InkWell(
              onTap: () => setState(() {
                if (_local.contains(item.id)) {
                  _local.remove(item.id);
                } else {
                  _local.add(item.id);
                }
              }),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(item.label,
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textPrimary)),
                    ),
                    Icon(
                      _local.contains(item.id)
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      color: _local.contains(item.id)
                          ? AppColors.primary
                          : AppColors.textDisabled,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(Set.from(_local));
                  Navigator.of(context).pop();
                },
                child: const Text('Aplicar filtro'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Distribution dashboard ────────────────────────────────────────────────────

class _DistributionDashboard extends StatelessWidget {
  final Map<String, EvaluationClassification?> classifications;
  final Map<String, bool> topPerformers;
  final int total;

  const _DistributionDashboard({
    required this.classifications,
    required this.topPerformers,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final aboveCount =
        classifications.values.where((c) => c == EvaluationClassification.aboveLevel).length;
    final atCount =
        classifications.values.where((c) => c == EvaluationClassification.atLevel).length;
    final belowCount =
        classifications.values.where((c) => c == EvaluationClassification.belowLevel).length;
    final pendingCount = classifications.values.where((c) => c == null).length;
    final topCount     = topPerformers.values.where((v) => v).length;

    String pct(int n) =>
        total == 0 ? '0%' : '${(n / total * 100).round()}%';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            total == 0 ? 'Distribuição' : 'Distribuição · $total colaborador${total != 1 ? 'es' : ''}',
            style: const TextStyle(color: AppColors.lightGray, fontSize: 11),
          ),
          const SizedBox(height: 10),
          if (total > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Row(
                children: [
                  if (aboveCount > 0) _DistSeg(color: AppColors.classAcima,   flex: aboveCount),
                  if (aboveCount > 0 && (atCount + belowCount + pendingCount) > 0)
                    const SizedBox(width: 2),
                  if (atCount > 0) _DistSeg(color: AppColors.classNoNivel, flex: atCount),
                  if (atCount > 0 && (belowCount + pendingCount) > 0)
                    const SizedBox(width: 2),
                  if (belowCount > 0) _DistSeg(color: AppColors.classAbaixo,  flex: belowCount),
                  if (belowCount > 0 && pendingCount > 0)
                    const SizedBox(width: 2),
                  if (pendingCount > 0) _DistSeg(color: AppColors.lightGray,  flex: pendingCount),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              _KpiCell(label: 'Acima',    value: pct(aboveCount), color: AppColors.classAcima),
              _KpiCell(label: 'No nível', value: pct(atCount),    color: AppColors.classNoNivel),
              _KpiCell(label: 'Abaixo',   value: pct(belowCount), color: AppColors.classAbaixo),
              _KpiCell(label: 'Pendente', value: '$pendingCount', color: AppColors.lightGray),
              _KpiCell(label: 'Top', value: '$topCount',          color: AppColors.classTop, last: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool last;
  const _KpiCell({
    required this.label,
    required this.value,
    required this.color,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: last ? 0 : 6),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      fontSize: 9, color: AppColors.lightGray)),
            ],
          ),
        ),
      );
}

class _DistSeg extends StatelessWidget {
  final Color color;
  final int flex;
  const _DistSeg({required this.color, required this.flex});

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Container(height: 8, color: color),
      );
}

// ── Employee card ─────────────────────────────────────────────────────────────

class _EmployeeCard extends ConsumerWidget {
  final LiderEvaluation eval;
  final ColaboradorDGT? colaborador;
  final String careerLevel;
  final String appraiserName;
  final double behavioralAvg;
  final double technicalAvg;
  final EvaluationClassification? classification;
  final bool topPerformer;
  final TextEditingController? meetingNotesCtrl;
  final bool meetingActive;
  final bool showTopPerformer;
  final ValueChanged<EvaluationClassification?>? onClassificationChanged;
  final VoidCallback? onTopPerformerToggle;
  final VoidCallback onDetailTap;
  final VoidCallback onPerfilTap;

  const _EmployeeCard({
    required this.eval,
    required this.colaborador,
    required this.careerLevel,
    required this.appraiserName,
    required this.behavioralAvg,
    required this.technicalAvg,
    required this.classification,
    required this.topPerformer,
    required this.meetingNotesCtrl,
    required this.meetingActive,
    required this.showTopPerformer,
    required this.onClassificationChanged,
    required this.onTopPerformerToggle,
    required this.onDetailTap,
    required this.onPerfilTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoAsync = ref.watch(autoEvaluationForEmployeeProvider(eval.employeeId));

    final name  = colaborador?.name.isNotEmpty == true
        ? colaborador!.name
        : (eval.employeeName.isNotEmpty ? eval.employeeName : 'Colaborador');
    final level = careerLevel;

    final autoStatus   = autoAsync.valueOrNull?.status;
    final liderStatus  = eval.status;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row: avatar / name+level / avg / perfil / detail ───
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AvatarInitials(name: name, size: 38),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary)),
                      if (level.isNotEmpty)
                        Text(level,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      if (appraiserName.isNotEmpty)
                        Text('Gestor: $appraiserName',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textDisabled)),
                    ],
                  ),
                ),
                _AvgPair(behavioral: behavioralAvg, technical: technicalAvg),
                const SizedBox(width: 8),
                // Perfil button
                GestureDetector(
                  onTap: onPerfilTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: const Text(
                      'Perfil',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.midGray),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Detail (?) button
                GestureDetector(
                  onTap: onDetailTap,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: const Icon(Icons.info_outline_rounded,
                        size: 16, color: AppColors.midGray),
                  ),
                ),
              ],
            ),

            // ── Status badges ──────────────────────────────────────────────
            const SizedBox(height: 8),
            Row(
              children: [
                _EvalStatusBadge(
                  prefix: 'Auto',
                  status: autoStatus,
                  loading: autoAsync.isLoading,
                ),
                const SizedBox(width: 6),
                _EvalStatusBadge(
                  prefix: 'Gestor',
                  status: liderStatus,
                ),
              ],
            ),

            if (meetingActive) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // ── Classification + TopPerformer row ──────────────────────
              Row(
                children: [
                  Expanded(
                    child: _ClassificationDropdown(
                      value: classification,
                      enabled: meetingActive,
                      onChanged: onClassificationChanged,
                    ),
                  ),
                  if (showTopPerformer) ...[
                    const SizedBox(width: 8),
                    _TopToggle(
                      isTop: topPerformer,
                      onToggle: onTopPerformerToggle,
                    ),
                  ],
                ],
              ),

              // ── Meeting notes ──────────────────────────────────────────
              if (meetingNotesCtrl != null) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: meetingNotesCtrl,
                  maxLines: 2,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Notas da reunião (opcional)',
                    hintStyle: const TextStyle(
                        fontSize: 12, color: AppColors.textDisabled),
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
              ],
            ],

            // ── Read-only classification badge when meeting not active ───
            if (!meetingActive && classification != null) ...[
              const SizedBox(height: 8),
              _ClassificationBadge(classification: classification!),
            ],
          ],
        ),
      ),
    );
  }
}

// Average pair widget
class _AvgPair extends StatelessWidget {
  final double behavioral;
  final double technical;
  const _AvgPair({required this.behavioral, required this.technical});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AvgCell(label: 'C', value: behavioral),
          const SizedBox(width: 8),
          _AvgCell(label: 'T', value: technical),
        ],
      );
}

class _AvgCell extends StatelessWidget {
  final String label;
  final double value;
  const _AvgCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value.toStringAsFixed(1),
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray),
          ),
          Text(
            label,
            style: const TextStyle(
                fontSize: 10,
                color: AppColors.midGray,
                fontWeight: FontWeight.w500),
          ),
        ],
      );
}

// Evaluation status badge
class _EvalStatusBadge extends StatelessWidget {
  final String prefix;
  final EvaluationStatus? status;
  final bool loading;
  const _EvalStatusBadge({
    required this.prefix,
    required this.status,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    String label;

    if (loading || status == null) {
      color = AppColors.textDisabled;
      bg    = AppColors.statusDraftBg;
      label = loading ? '…' : 'Não iniciada';
    } else {
      switch (status!) {
        case EvaluationStatus.finished:
          color = AppColors.statusOnTrack;
          bg    = AppColors.statusOnTrackBg;
          label = 'Concluída';
          break;
        case EvaluationStatus.onGoing:
          color = AppColors.statusAtRisk;
          bg    = AppColors.statusAtRiskBg;
          label = 'Em andamento';
          break;
        case EvaluationStatus.cancelled:
          color = AppColors.statusBehind;
          bg    = AppColors.statusBehindBg;
          label = 'Cancelada';
          break;
        case EvaluationStatus.notStarted:
          color = AppColors.textDisabled;
          bg    = AppColors.statusDraftBg;
          label = 'Não iniciada';
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$prefix: $label',
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w500, color: color),
      ),
    );
  }
}

// Read-only classification badge
class _ClassificationBadge extends StatelessWidget {
  final EvaluationClassification classification;
  const _ClassificationBadge({required this.classification});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    switch (classification) {
      case EvaluationClassification.aboveLevel:
        color = AppColors.classAcima;
        bg    = AppColors.classAcimaBg;
        break;
      case EvaluationClassification.atLevel:
        color = AppColors.classNoNivel;
        bg    = AppColors.classNoNivelBg;
        break;
      case EvaluationClassification.belowLevel:
        color = AppColors.classAbaixo;
        bg    = AppColors.classAbaixoBg;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        classification.label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w500, color: color),
      ),
    );
  }
}

class _ClassificationDropdown extends StatelessWidget {
  final EvaluationClassification? value;
  final bool enabled;
  final ValueChanged<EvaluationClassification?>? onChanged;
  const _ClassificationDropdown({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    if (value == null) {
      color = AppColors.midGray;
      bg    = AppColors.background;
    } else {
      switch (value!) {
        case EvaluationClassification.belowLevel:
          color = AppColors.statusBehind;
          bg    = AppColors.statusBehindBg;
          break;
        case EvaluationClassification.atLevel:
          color = AppColors.statusCompleted;
          bg    = AppColors.statusCompletedBg;
          break;
        case EvaluationClassification.aboveLevel:
          color = AppColors.statusOnTrack;
          bg    = AppColors.statusOnTrackBg;
          break;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: DropdownButton<EvaluationClassification?>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        isDense: true,
        style: TextStyle(
            fontSize: 13, color: color, fontWeight: FontWeight.w500),
        icon: Icon(Icons.expand_more, color: color, size: 18),
        dropdownColor: AppColors.surface,
        hint: const Text('Classificar…',
            style: TextStyle(
                fontSize: 13,
                color: AppColors.midGray,
                fontWeight: FontWeight.w400)),
        items: const [
          DropdownMenuItem(
            value: EvaluationClassification.aboveLevel,
            child: Text('Acima do nível'),
          ),
          DropdownMenuItem(
            value: EvaluationClassification.atLevel,
            child: Text('No nível'),
          ),
          DropdownMenuItem(
            value: EvaluationClassification.belowLevel,
            child: Text('Abaixo do nível'),
          ),
        ],
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}

class _TopToggle extends StatelessWidget {
  final bool isTop;
  final VoidCallback? onToggle;
  const _TopToggle({required this.isTop, required this.onToggle});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onToggle,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 22,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isTop ? AppColors.primary : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(11),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment:
                    isTop ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Top\nPerformer',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 9,
                  color: isTop ? AppColors.primary : AppColors.midGray,
                  fontWeight:
                      isTop ? FontWeight.w600 : FontWeight.w400),
            ),
          ],
        ),
      );
}

// ── Employee profile bottom sheet ─────────────────────────────────────────────

class _EmployeePerfilSheet extends ConsumerWidget {
  final String employeeId;
  final String employeeName;
  const _EmployeePerfilSheet({
    required this.employeeId,
    required this.employeeName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilAsync = ref.watch(
        employeeProfileByEmployeeIdProvider(employeeId));

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: perfilAsync.when(
          loading: () => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(strokeWidth: 2),
                const SizedBox(height: 12),
                Text(employeeName,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textSecondary)),
              ],
            ),
          ),
          error: (e, _) => Center(
            child: Text('Erro ao carregar perfil: $e',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.statusBehind)),
          ),
          data: (perfil) => ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  AvatarInitials(name: employeeName, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      employeeName,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (perfil == null) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Perfil complementar não encontrado.',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textDisabled),
                    ),
                  ),
                ),
              ] else ...[
                _PerfilInfoCard(perfil: perfil),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PerfilInfoCard extends StatelessWidget {
  final EmployeePerfil perfil;
  const _PerfilInfoCard({required this.perfil});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          _PerfilRow(
              label: 'Nível de carreira',
              value: perfil.careerLevel),
          _PerfilRow(
              label: 'Cargo / função',
              value: perfil.function),
          _PerfilRow(
              label: 'Data de admissão',
              value: perfil.hiringDate != null
                  ? du.formatDate(perfil.hiringDate!)
                  : ''),
          const _PerfilDividerLabel(label: 'ÚLTIMO CICLO'),
          _PerfilRow(
              label: 'Classificação',
              value: _classLabel(perfil.classificacationLastCycle)),
          _PerfilRow(
              label: 'Top Performer',
              value: perfil.topPerformer ? 'Sim' : 'Não'),
          const _PerfilDividerLabel(label: 'CICLO ANTERIOR'),
          _PerfilRow(
              label: 'Classificação',
              value: _classLabel(perfil.classificacationPreviousCycle)),
          _PerfilRow(
              label: 'Top Performer',
              value: perfil.topPerformerUltimoCiclo ? 'Sim' : 'Não',
              last: true),
        ],
      ),
    );
  }
}

class _PerfilRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;
  const _PerfilRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final display = value.isNotEmpty ? value : 'Não informado';
    final isEmpty = value.isEmpty;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  display,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isEmpty
                        ? AppColors.textDisabled
                        : AppColors.textPrimary,
                    fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!last)
          const Divider(height: 1, indent: 14, endIndent: 14,
              color: AppColors.border),
      ],
    );
  }
}

class _PerfilDividerLabel extends StatelessWidget {
  final String label;
  const _PerfilDividerLabel({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        color: AppColors.border.withValues(alpha: 0.4),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.midGray,
              letterSpacing: 0.5),
        ),
      );
}

// ── Details bottom sheet ──────────────────────────────────────────────────────

class _DetailsSheet extends ConsumerWidget {
  final String evalId;
  final String fallbackName;
  const _DetailsSheet({required this.evalId, required this.fallbackName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evalAsync = ref.watch(liderEvaluationByIdProvider(evalId));

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: evalAsync.when(
          loading: () => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(strokeWidth: 2),
                const SizedBox(height: 12),
                Text(fallbackName,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textSecondary)),
              ],
            ),
          ),
          error: (e, _) => Center(
            child: Text('Erro ao carregar detalhes: $e',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.statusBehind)),
          ),
          data: (eval) {
            if (eval == null) {
              return const Center(
                child: Text('Avaliação não encontrada.',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textDisabled)),
              );
            }
            final name = eval.employeeName.isNotEmpty
                ? eval.employeeName
                : fallbackName;
            return ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(name,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(eval.status.label,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 16),

                _DetailField(
                  dotColor: const Color(0xFFA5D6A7),
                  label: 'Pontos fortes',
                  value: eval.strengths,
                ),
                _DetailField(
                  dotColor: AppColors.primary,
                  label: 'Pontos de atenção',
                  value: eval.attentionPoints,
                ),
                _DetailField(
                  dotColor: const Color(0xFF90CAF9),
                  label: 'Feedback geral',
                  value: eval.feedback,
                ),
                _DetailField(
                  dotColor: const Color(0xFFCEB6F6),
                  label: 'Plano de ação',
                  value: eval.actionPlan,
                ),

                const _SheetSectionLabel(label: 'Metas do período'),
                if (eval.goals.isEmpty)
                  const _EmptyValue()
                else
                  for (final g in eval.goals) _GoalRow(goal: g),

                const _SheetSectionLabel(
                    label: 'Metas para o próximo período'),
                if (eval.nextGoals.isEmpty)
                  const _EmptyValue()
                else
                  for (var i = 0; i < eval.nextGoals.length; i++)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Text('${i + 1}',
                                style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(eval.nextGoals[i],
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                    height: 1.4)),
                          ),
                        ],
                      ),
                    ),

                if (eval.commentsPerfMeeting?.isNotEmpty == true) ...[
                  const _SheetSectionLabel(label: 'Comentário da reunião'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(eval.commentsPerfMeeting!,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.5)),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  final Color dotColor;
  final String label;
  final String? value;
  const _DetailField({
    required this.dotColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: dotColor.withValues(alpha: 0.12),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: dotColor, shape: BoxShape.circle)),
                  const SizedBox(width: 7),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: value != null && value!.isNotEmpty
                  ? Text(value!,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.5))
                  : const _EmptyValue(),
            ),
          ],
        ),
      );
}

class _EmptyValue extends StatelessWidget {
  const _EmptyValue();

  @override
  Widget build(BuildContext context) => const Text(
        'Não informado',
        style: TextStyle(
            fontSize: 13,
            color: AppColors.textDisabled,
            fontStyle: FontStyle.italic),
      );
}

class _SheetSectionLabel extends StatelessWidget {
  final String label;
  const _SheetSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.midGray,
                letterSpacing: 0.5)),
      );
}

class _GoalRow extends StatelessWidget {
  final TabGoal goal;
  const _GoalRow({required this.goal});

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
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
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
          const SizedBox(width: 8),
          if (achColor != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: achColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(achLabel,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: achColor)),
            )
          else
            const Text('—',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textDisabled)),
        ],
      ),
    );
  }
}

// ── Action bar ────────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final bool saving;
  final VoidCallback onSave;
  const _ActionBar({required this.saving, required this.onSave});

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
            onPressed: saving ? null : onSave,
            child: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.darkGray))
                : const Text('Salvar equalização →'),
          ),
        ),
      );
}
