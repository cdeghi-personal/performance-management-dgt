import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/avatar_initials.dart';
import '../../../shared/widgets/dgt_app_bar.dart';
import '../../../shared/widgets/read_only_banner.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/domain/auth_provider.dart';
import '../data/models/auto_evaluation_model.dart';
import '../data/models/cycle_model.dart';
import '../data/models/lider_evaluation_model.dart';
import '../data/models/tab_evaluation_model.dart';
import '../data/models/tab_goal_model.dart';
import '../domain/enrichment_providers.dart';
import '../domain/evaluation_providers.dart';
import '../data/repositories/lider_evaluation_repository.dart';
import 'evaluation_display_model.dart';

class ManagerEvaluationPage extends ConsumerStatefulWidget {
  /// Ciclo ativo: passa [employeeId] para carregar a avaliação do ciclo vigente (editável).
  /// Histórico: passa [evalId] para carregar uma avaliação específica por ID (read-only).
  final String? employeeId;
  final String? evalId;
  const ManagerEvaluationPage({super.key, this.employeeId, this.evalId})
      : assert(employeeId != null || evalId != null,
            'ManagerEvaluationPage requer employeeId ou evalId');

  @override
  ConsumerState<ManagerEvaluationPage> createState() => _ManagerEvaluationPageState();
}

class _ManagerEvaluationPageState extends ConsumerState<ManagerEvaluationPage> {
  final Map<String, int> _scores = {};
  final _strengthsCtrl  = TextEditingController();
  final _attentionCtrl  = TextEditingController();
  final _feedbackCtrl   = TextEditingController();
  final _actionPlanCtrl = TextEditingController();
  final List<GoalAchievement?> _goalAchievements = [];
  final List<TextEditingController> _nextGoalCtrls = [];
  EvaluationClassification? _classification;
  bool _topPerformer  = false;
  bool _selfExpanded  = false;
  bool _initialized   = false;
  bool _saving        = false;

  @override
  void dispose() {
    _strengthsCtrl.dispose();
    _attentionCtrl.dispose();
    _feedbackCtrl.dispose();
    _actionPlanCtrl.dispose();
    for (final c in _nextGoalCtrls) { c.dispose(); }
    super.dispose();
  }

  /// Inicializa scores e campos de texto a partir da avaliação salva.
  /// Apenas critérios presentes em criteriaMap (ativos no ciclo) são inicializados.
  void _tryInitialize(
    Map<String, String> criteriaMap,
    LiderEvaluation? eval,
  ) {
    if (_initialized || criteriaMap.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialized) return;
      setState(() {
        if (eval != null) {
          for (final group in eval.groups) {
            for (final t in group.criteria) {
              if (criteriaMap.containsKey(t.criterionId)) {
                _scores[t.criterionId] = t.evaluation ?? 5;
              }
            }
          }
          _strengthsCtrl.text  = eval.strengths ?? '';
          _attentionCtrl.text  = eval.attentionPoints ?? '';
          _feedbackCtrl.text   = eval.feedback ?? '';
          _actionPlanCtrl.text = eval.actionPlan ?? '';

          _goalAchievements.clear();
          for (final g in eval.goals) { _goalAchievements.add(g.achieve); }

          for (final c in _nextGoalCtrls) { c.dispose(); }
          _nextGoalCtrls.clear();
          for (final g in eval.nextGoals) {
            _nextGoalCtrls.add(TextEditingController(text: g));
          }
          if (_nextGoalCtrls.isEmpty) {
            _nextGoalCtrls.add(TextEditingController());
          }
          _classification = eval.classification;
          _topPerformer   = eval.topPerformer;
        }
        _initialized = true;
      });
    });
  }

  /// Média geral de todos os critérios ativos preenchidos pelo gestor.
  double get _media {
    if (_scores.isEmpty) return 0;
    return _scores.values.map((v) => v.toDouble()).reduce((a, b) => a + b) /
        _scores.length;
  }

  /// Reconstrói a lista de TabEvaluation de um grupo a partir dos scores locais.
  List<TabEvaluation> _rebuildGroup(
    List<TabEvaluation> original,
    Map<String, String> criteriaMap,
  ) =>
      original
          .where((t) => criteriaMap.containsKey(t.criterionId))
          .map((t) => TabEvaluation(
                id: t.id,
                criterionId: t.criterionId,
                evaluation: _scores[t.criterionId],
              ))
          .toList();

  Future<void> _save({required bool finalize}) async {
    final eval        = ref.read(liderEvaluationForEmployeeProvider(widget.employeeId!)).valueOrNull;
    final rawCriteria = ref.read(cycleCriteriaProvider).valueOrNull;
    if (eval == null || rawCriteria == null || _saving) return;

    final criteriaMap = {
      for (final c in rawCriteria.values.expand((l) => l)) c.id: c.name,
    };

    setState(() => _saving = true);
    try {
      final updatedGoals = <TabGoal>[];
      for (var i = 0; i < eval.goals.length; i++) {
        final g = eval.goals[i];
        updatedGoals.add(TabGoal(
          id:      g.id,
          goal:    g.goal,
          achieve: i < _goalAchievements.length ? _goalAchievements[i] : g.achieve,
        ));
      }
      final nextGoalsList = _nextGoalCtrls
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final updated = LiderEvaluation(
        id:          eval.id,
        cycleId:     eval.cycleId,
        status:      finalize ? EvaluationStatus.finished : EvaluationStatus.onGoing,
        employeeId:  eval.employeeId,
        appraiserId: eval.appraiserId,
        tytleGroup1: eval.tytleGroup1,
        group1:      _rebuildGroup(eval.group1, criteriaMap),
        tytleGroup2: eval.tytleGroup2,
        group2:      _rebuildGroup(eval.group2, criteriaMap),
        tytleGroup3: eval.tytleGroup3,
        group3:      eval.group3 != null ? _rebuildGroup(eval.group3!, criteriaMap) : null,
        tytleGroup4: eval.tytleGroup4,
        group4:      eval.group4 != null ? _rebuildGroup(eval.group4!, criteriaMap) : null,
        goals:           updatedGoals,
        strengths:       _strengthsCtrl.text.trim().isEmpty ? null : _strengthsCtrl.text.trim(),
        attentionPoints: _attentionCtrl.text.trim().isEmpty ? null : _attentionCtrl.text.trim(),
        feedback:        _feedbackCtrl.text.trim().isEmpty ? null : _feedbackCtrl.text.trim(),
        actionPlan:      _actionPlanCtrl.text.trim().isEmpty ? null : _actionPlanCtrl.text.trim(),
        nextGoals:       nextGoalsList,
        classification:  _classification,
        topPerformer:    _topPerformer,
        creationDate:    eval.creationDate,
      );
      await ref.read(liderEvaluationRepositoryProvider).update(updated);
      if (!mounted) return;
      ref.invalidate(liderEvaluationForEmployeeProvider(widget.employeeId!));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(finalize ? 'Avaliação enviada!' : 'Rascunho salvo.'),
        backgroundColor: finalize ? AppColors.statusOnTrack : AppColors.midGray,
      ));
      if (!finalize) context.go('/avaliacoes');
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

  @override
  Widget build(BuildContext context) {
    final criteriaAsync = ref.watch(cycleCriteriaProvider);
    final evalAsync     = widget.evalId != null
        ? ref.watch(liderEvaluationByIdProvider(widget.evalId!))
        : ref.watch(liderEvaluationForEmployeeProvider(widget.employeeId!));

    final eval = evalAsync.valueOrNull;
    final autoEvalKey = (eval != null &&
            eval.employeeId.isNotEmpty &&
            eval.cycleId.isNotEmpty)
        ? '${eval.employeeId}:${eval.cycleId}'
        : '';
    final autoEvalAsync = ref.watch(autoEvalForLiderEvalProvider(autoEvalKey));
    final resolvedAsync = widget.evalId != null
        ? ref.watch(resolvedLiderEvalByIdProvider(widget.evalId!))
        : ref.watch(resolvedLiderEvalForEmployeeProvider(widget.employeeId!));
    final cycleAsync = ref.watch(activeCycleProvider);
    final isManager  = ref.watch(isManagerProvider);

    // Mapa plano criterionId → nome (somente critérios ativos no ciclo)
    final rawCriteria = criteriaAsync.valueOrNull;
    final criteriaMap = rawCriteria == null
        ? <String, String>{}
        : {for (final c in rawCriteria.values.expand((l) => l)) c.id: c.name};

    criteriaAsync.whenData((_) {
      evalAsync.whenData((liderEval) => _tryInitialize(criteriaMap, liderEval));
    });

    final isReadOnly  = (widget.evalId != null) || (eval?.isReadOnly ?? false);
    final evalStatus  = eval?.status;
    final autoEval    = autoEvalAsync.valueOrNull;
    final cycle           = cycleAsync.valueOrNull;
    final meetingActive   = cycle?.meetingPhase?.status == PhaseStatus.onGoing;
    final meetingFinished = cycle?.meetingPhase?.status == PhaseStatus.finished;
    final cycleLabel      = cycle != null
        ? '${cycle.period} ${cycle.year}'
        : 'Ciclo atual';

    final resolved     = resolvedAsync.valueOrNull;
    final displayModel = resolved != null
        ? EvaluationDisplayModel.fromResolvedLiderManager(resolved)
        : (eval != null
            ? EvaluationDisplayModel.fromLiderEvaluationManager(eval)
            : null);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DgtAppBar.detail(
        typeLabel: displayModel?.typeLabel ?? 'Avaliação do Gestor',
        personLabel: displayModel?.personLabel,
        contextLine: displayModel?.headerContextLine ?? '',
      ),
      body: Column(
        children: [
          if (isReadOnly && evalStatus != null)
            ReadOnlyBanner(status: evalStatus),
          Expanded(
            child: criteriaAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro ao carregar critérios: $e')),
              data: (_) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ColaboradorCard(
                    name: eval?.employeeName.isNotEmpty == true
                        ? eval!.employeeName
                        : 'Colaborador',
                    subtitle: cycleLabel,
                  ),
                  const SizedBox(height: 16),

                  const _SectionLabel(label: 'Auto-avaliação do colaborador'),
                  const SizedBox(height: 8),
                  _SelfEvalCard(
                    expanded: _selfExpanded,
                    autoEval: autoEval,
                    criteriaMap: criteriaMap,
                    evalGroups: eval?.groups ?? [],
                    onToggle: () => setState(() => _selfExpanded = !_selfExpanded),
                  ),
                  const SizedBox(height: 16),

                  const _SectionLabel(label: 'Notas do gestor'),
                  const SizedBox(height: 8),
                  _ManagerScoresCard(
                    evalGroups: eval?.groups ?? [],
                    criteriaMap: criteriaMap,
                    scores:     _scores,
                    autoEval:   autoEval,
                    media:      _media,
                    isReadOnly: isReadOnly,
                    onImport: () {
                      if (autoEval == null) return;
                      setState(() {
                        for (final group in autoEval.groups) {
                          for (final t in group.criteria) {
                            if (t.evaluation != null &&
                                criteriaMap.containsKey(t.criterionId)) {
                              _scores[t.criterionId] = t.evaluation!;
                            }
                          }
                        }
                      });
                    },
                    onChanged: (id, v) => setState(() => _scores[id] = v.round()),
                  ),
                  const SizedBox(height: 16),

                  if (eval != null && eval.goals.isNotEmpty) ...[
                    const _SectionLabel(label: 'Metas do período'),
                    const SizedBox(height: 8),
                    _GoalsSection(
                      goals:        eval.goals,
                      achievements: _goalAchievements,
                      isReadOnly:   isReadOnly,
                      onChanged: (i, v) => setState(() {
                        while (_goalAchievements.length <= i) {
                          _goalAchievements.add(null);
                        }
                        _goalAchievements[i] = v;
                      }),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const _SectionLabel(label: 'Avaliação qualitativa'),
                  const SizedBox(height: 8),
                  _QualitativeSection(
                    strengthsCtrl:  _strengthsCtrl,
                    attentionCtrl:  _attentionCtrl,
                    feedbackCtrl:   _feedbackCtrl,
                    actionPlanCtrl: _actionPlanCtrl,
                    isReadOnly:     isReadOnly,
                  ),
                  const SizedBox(height: 16),

                  if (!isReadOnly && isManager && meetingActive) ...[
                    const _SectionLabel(label: 'Resultado final'),
                    const SizedBox(height: 8),
                    _ClassificationSection(
                      classification: _classification,
                      topPerformer: _topPerformer,
                      onClassificationChanged: (v) => setState(() => _classification = v),
                      onTopPerformerChanged: (v) => setState(() => _topPerformer = v),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if ((isReadOnly || meetingFinished) && _classification != null) ...[
                    const _SectionLabel(label: 'Resultado final'),
                    const SizedBox(height: 8),
                    _ResultFinalCard(
                        classification: _classification!, topPerformer: _topPerformer),
                    const SizedBox(height: 16),
                  ],

                  const _SectionLabel(label: 'Metas para o próximo período'),
                  const SizedBox(height: 8),
                  _NextGoalsSection(
                    controllers: _nextGoalCtrls,
                    isReadOnly:  isReadOnly,
                    onAdd: () => setState(() {
                      _nextGoalCtrls.add(TextEditingController());
                    }),
                    onRemove: (i) => setState(() {
                      _nextGoalCtrls[i].dispose();
                      _nextGoalCtrls.removeAt(i);
                    }),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isReadOnly
          ? null
          : _ActionBar(
              saving: _saving,
              onSave: () => _save(finalize: false),
              onFinalize: () => _save(finalize: true),
            ),
    );
  }
}

// ── Seção A ───────────────────────────────────────────────────────────────────

class _ColaboradorCard extends StatelessWidget {
  final String name;
  final String subtitle;
  const _ColaboradorCard({required this.name, required this.subtitle});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkGray,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            AvatarInitials(name: name, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── Seção B — Auto-avaliação do colaborador ───────────────────────────────────

class _SelfEvalCard extends StatelessWidget {
  final bool expanded;
  final AutoEvaluation? autoEval;
  final Map<String, String> criteriaMap;
  final List<EvaluationGroup> evalGroups;
  final VoidCallback onToggle;

  const _SelfEvalCard({
    required this.expanded,
    required this.autoEval,
    required this.criteriaMap,
    required this.evalGroups,
    required this.onToggle,
  });

  double get _avg {
    if (autoEval == null) return 0;
    final scores = autoEval!.groups
        .expand((g) => g.criteria)
        .where((t) => t.evaluation != null && criteriaMap.containsKey(t.criterionId))
        .map((t) => t.evaluation!.toDouble())
        .toList();
    if (scores.isEmpty) return 0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  Map<String, int> get _scoreMap {
    if (autoEval == null) return {};
    final map = <String, int>{};
    for (final group in autoEval!.groups) {
      for (final t in group.criteria) {
        if (t.evaluation != null) map[t.criterionId] = t.evaluation!;
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final scoreMap = _scoreMap;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: Text('👤', style: TextStyle(fontSize: 14))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ver auto-avaliação',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary)),
                        Text(
                          autoEval == null
                              ? 'Não enviada'
                              : 'Média: ${_avg.toStringAsFixed(1)} · ${autoEval!.status.label}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.lightGray,
                  ),
                ],
              ),
            ),
          ),
          if (expanded && autoEval != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Critérios exibidos por grupo — apenas ativos no ciclo
                  for (final group in evalGroups) ...[
                    if (group.criteria.any((t) => criteriaMap.containsKey(t.criterionId))) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          group.displayTitle.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w500,
                              color: AppColors.textDisabled, letterSpacing: 0.5),
                        ),
                      ),
                      for (final t in group.criteria)
                        if (criteriaMap.containsKey(t.criterionId))
                          _AutoRow(
                            label: criteriaMap[t.criterionId]!,
                            score: scoreMap[t.criterionId]?.toDouble(),
                          ),
                      const SizedBox(height: 8),
                    ],
                  ],
                  if (autoEval!.strengths != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '"${autoEval!.strengths}"',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic, height: 1.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AutoRow extends StatelessWidget {
  final String label;
  final double? score;
  const _AutoRow({required this.label, required this.score});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
            ),
            Text(
              score != null ? score!.toInt().toString() : '—',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: score != null ? AppColors.primary : AppColors.textDisabled),
            ),
          ],
        ),
      );
}

// ── Seção C — Notas do gestor ─────────────────────────────────────────────────

class _ManagerScoresCard extends StatelessWidget {
  final List<EvaluationGroup> evalGroups;
  final Map<String, String> criteriaMap;
  final Map<String, int> scores;
  final AutoEvaluation? autoEval;
  final double media;
  final bool isReadOnly;
  final VoidCallback onImport;
  final void Function(String criterionId, double value) onChanged;

  const _ManagerScoresCard({
    required this.evalGroups,
    required this.criteriaMap,
    required this.scores,
    required this.autoEval,
    required this.media,
    required this.isReadOnly,
    required this.onImport,
    required this.onChanged,
  });

  Map<String, int> get _autoScoreMap {
    if (autoEval == null) return {};
    final map = <String, int>{};
    for (final group in autoEval!.groups) {
      for (final t in group.criteria) {
        if (t.evaluation != null) map[t.criterionId] = t.evaluation!;
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final autoScoreMap = _autoScoreMap;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: isReadOnly
            ? Border.all(color: AppColors.border, width: 0.5)
            : Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Critérios',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary)),
              ),
              if (!isReadOnly && autoEval != null)
                GestureDetector(
                  onTap: onImport,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.statusAtRiskBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('↓ Importar da auto-aval.',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w500,
                            color: AppColors.primary)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Grupos dinâmicos — apenas critérios ativos no ciclo
          for (final group in evalGroups) ...[
            if (group.criteria.any((t) => criteriaMap.containsKey(t.criterionId))) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  group.displayTitle.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w500,
                      color: AppColors.textDisabled, letterSpacing: 0.5),
                ),
              ),
              for (var i = 0; i < group.criteria.length; i++) ...[
                if (criteriaMap.containsKey(group.criteria[i].criterionId)) ...[
                  if (i > 0) const Divider(height: 16),
                  _CriterionSlider(
                    label:        criteriaMap[group.criteria[i].criterionId]!,
                    selfRef:      (autoScoreMap[group.criteria[i].criterionId] ?? 0).toDouble(),
                    managerScore: (scores[group.criteria[i].criterionId] ?? 5).toDouble(),
                    isReadOnly:   isReadOnly,
                    onChanged:    (v) => onChanged(group.criteria[i].criterionId, v),
                  ),
                ],
              ],
              const SizedBox(height: 12),
            ],
          ],

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Nota média final',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ),
                Text(
                  media.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CriterionSlider extends StatelessWidget {
  final String label;
  final double selfRef;
  final double managerScore;
  final bool isReadOnly;
  final ValueChanged<double> onChanged;

  const _CriterionSlider({
    required this.label,
    required this.selfRef,
    required this.managerScore,
    required this.isReadOnly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final diff = managerScore - selfRef;

    Color deltaColor;
    Color deltaBg;
    String deltaText;
    if (diff > 0) {
      deltaColor = AppColors.statusOnTrack;
      deltaBg    = AppColors.statusOnTrackBg;
      deltaText  = '+${diff.toInt()}';
    } else if (diff < 0) {
      deltaColor = AppColors.statusBehind;
      deltaBg    = AppColors.statusBehindBg;
      deltaText  = '${diff.toInt()}';
    } else {
      deltaColor = AppColors.midGray;
      deltaBg    = AppColors.background;
      deltaText  = '=';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary)),
                  Text('Auto-avaliação: ${selfRef.toInt()}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textDisabled)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: deltaBg, borderRadius: BorderRadius.circular(20)),
              child: Text(deltaText,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w500, color: deltaColor)),
            ),
            const SizedBox(width: 8),
            Text(
              managerScore.toInt().toString(),
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w500,
                  color: isReadOnly ? AppColors.midGray : AppColors.primary),
            ),
          ],
        ),
        Row(
          children: [
            const Text('0', style: TextStyle(fontSize: 11, color: AppColors.textDisabled)),
            Expanded(
              child: Slider(
                value: managerScore,
                min: 0,
                max: 10,
                divisions: 10,
                activeColor: isReadOnly ? AppColors.lightGray : AppColors.primary,
                onChanged: isReadOnly ? null : onChanged,
              ),
            ),
            const Text('10', style: TextStyle(fontSize: 11, color: AppColors.textDisabled)),
          ],
        ),
      ],
    );
  }
}

// ── Seção D — Qualitativa ─────────────────────────────────────────────────────

class _QualitativeSection extends StatelessWidget {
  final TextEditingController strengthsCtrl;
  final TextEditingController attentionCtrl;
  final TextEditingController feedbackCtrl;
  final TextEditingController actionPlanCtrl;
  final bool isReadOnly;

  const _QualitativeSection({
    required this.strengthsCtrl,
    required this.attentionCtrl,
    required this.feedbackCtrl,
    required this.actionPlanCtrl,
    required this.isReadOnly,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAFBE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: Text('💬', style: TextStyle(fontSize: 13))),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Perspectiva do gestor',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary)),
                    Text('Preencha após a reunião de feedback',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _QualitField(
                  dotColor: const Color(0xFFA5D6A7),
                  label: 'Pontos fortes',
                  hint: 'O que este colaborador faz bem e deve continuar',
                  ctrl: strengthsCtrl,
                  isReadOnly: isReadOnly,
                ),
                const Divider(height: 20),
                _QualitField(
                  dotColor: const Color(0xFFFCB017),
                  label: 'Pontos de atenção',
                  hint: 'Comportamentos ou resultados que precisam melhorar',
                  ctrl: attentionCtrl,
                  isReadOnly: isReadOnly,
                ),
                const Divider(height: 20),
                _QualitField(
                  dotColor: const Color(0xFF90CAF9),
                  label: 'Feedback geral',
                  hint: 'Mensagem direta ao colaborador sobre o ciclo',
                  ctrl: feedbackCtrl,
                  isReadOnly: isReadOnly,
                ),
                const Divider(height: 20),
                _QualitField(
                  dotColor: const Color(0xFFCEB6F6),
                  label: 'Plano de ação',
                  hint: 'Próximos passos concretos acordados na reunião',
                  ctrl: actionPlanCtrl,
                  isReadOnly: isReadOnly,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QualitField extends StatelessWidget {
  final Color dotColor;
  final String label;
  final String hint;
  final TextEditingController ctrl;
  final bool isReadOnly;

  const _QualitField({
    required this.dotColor,
    required this.label,
    required this.hint,
    required this.ctrl,
    required this.isReadOnly,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(hint, style: const TextStyle(fontSize: 11, color: AppColors.textDisabled)),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            maxLines: 3,
            enabled: !isReadOnly,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: isReadOnly ? const Color(0xFFF5F5F5) : const Color(0xFFFAFAFA),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ],
      );
}

// ── Action bar ────────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onFinalize;
  const _ActionBar({required this.saving, required this.onSave, required this.onFinalize});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: saving ? null : onSave,
                child: const Text('Salvar'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: saving ? null : onFinalize,
                child: saving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkGray))
                    : const Text('Finalizar avaliação →'),
              ),
            ),
          ],
        ),
      );
}

// ── Seção Metas do período ────────────────────────────────────────────────────

class _GoalsSection extends StatelessWidget {
  final List<TabGoal> goals;
  final List<GoalAchievement?> achievements;
  final bool isReadOnly;
  final void Function(int index, GoalAchievement? value) onChanged;

  const _GoalsSection({
    required this.goals,
    required this.achievements,
    required this.isReadOnly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          for (var i = 0; i < goals.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goals[i].goal ?? 'Meta ${i + 1}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _AchievChip(
                        label: 'Sim',
                        color: const Color(0xFF4CAF50),
                        bg: const Color(0xFFE8F5E9),
                        selected: i < achievements.length && achievements[i] == GoalAchievement.yes,
                        enabled: !isReadOnly,
                        onTap: () => onChanged(i, GoalAchievement.yes),
                      ),
                      const SizedBox(width: 8),
                      _AchievChip(
                        label: 'Parcial',
                        color: const Color(0xFFF9A825),
                        bg: const Color(0xFFFFF8E1),
                        selected: i < achievements.length && achievements[i] == GoalAchievement.partial,
                        enabled: !isReadOnly,
                        onTap: () => onChanged(i, GoalAchievement.partial),
                      ),
                      const SizedBox(width: 8),
                      _AchievChip(
                        label: 'Não',
                        color: const Color(0xFFE53935),
                        bg: const Color(0xFFFFEBEE),
                        selected: i < achievements.length && achievements[i] == GoalAchievement.no,
                        enabled: !isReadOnly,
                        onTap: () => onChanged(i, GoalAchievement.no),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AchievChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _AchievChip({
    required this.label,
    required this.color,
    required this.bg,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? color : AppColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? color : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      );
}

// ── Seção Metas para o próximo período ───────────────────────────────────────

class _NextGoalsSection extends StatelessWidget {
  final List<TextEditingController> controllers;
  final bool isReadOnly;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  const _NextGoalsSection({
    required this.controllers,
    required this.isReadOnly,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          for (var i = 0; i < controllers.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                      ),
                      const Spacer(),
                      if (!isReadOnly && controllers.length > 1)
                        GestureDetector(
                          onTap: () => onRemove(i),
                          child: const Icon(Icons.close,
                              size: 16, color: AppColors.textDisabled),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controllers[i],
                    enabled: !isReadOnly,
                    maxLines: null,
                    minLines: 2,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textPrimary, height: 1.5),
                    decoration: InputDecoration(
                      hintText: 'Descreva a meta para o próximo período',
                      hintStyle: const TextStyle(
                          fontSize: 12, color: AppColors.textDisabled),
                      filled: true,
                      fillColor: isReadOnly
                          ? const Color(0xFFF5F5F5)
                          : const Color(0xFFFAFAFA),
                      isDense: true,
                      contentPadding: const EdgeInsets.all(10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border, width: 0.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border, width: 0.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border, width: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!isReadOnly) ...[
            const Divider(height: 1),
            InkWell(
              onTap: onAdd,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Adicionar meta',
                        style: TextStyle(fontSize: 13, color: AppColors.primary,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Resultado final (editável) ────────────────────────────────────────────────

class _ClassificationSection extends StatelessWidget {
  final EvaluationClassification? classification;
  final bool topPerformer;
  final ValueChanged<EvaluationClassification?> onClassificationChanged;
  final ValueChanged<bool> onTopPerformerChanged;

  const _ClassificationSection({
    required this.classification,
    required this.topPerformer,
    required this.onClassificationChanged,
    required this.onTopPerformerChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Classificação',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          DropdownButtonFormField<EvaluationClassification>(
            initialValue: classification,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            hint: const Text('Selecionar classificação',
                style: TextStyle(fontSize: 13, color: AppColors.textDisabled)),
            items: EvaluationClassification.values
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.label,
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                    ))
                .toList(),
            onChanged: onClassificationChanged,
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Top Performer',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary)),
                    SizedBox(height: 2),
                    Text('Destaque excepcional no ciclo',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Switch(
                value: topPerformer,
                activeThumbColor: AppColors.primary,
                onChanged: onTopPerformerChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Resultado final (read-only) ───────────────────────────────────────────────

class _ResultFinalCard extends StatelessWidget {
  final EvaluationClassification classification;
  final bool topPerformer;
  const _ResultFinalCard({required this.classification, required this.topPerformer});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.military_tech_rounded,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            const Text('Resultado final',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const Spacer(),
            ClassificationBadge(classification: classification.label),
            if (topPerformer) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusAtRiskBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Top Performer',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500,
                        color: AppColors.primary)),
              ),
            ],
          ],
        ),
      );
}

// ── Section label ─────────────────────────────────────────────────────────────

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
