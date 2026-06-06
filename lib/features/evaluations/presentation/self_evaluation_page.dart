import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart' as du;
import '../../../shared/widgets/dgt_app_bar.dart';
import '../../../shared/widgets/read_only_banner.dart';
import '../../auth/domain/auth_provider.dart';
import '../data/models/auto_evaluation_model.dart';
import '../data/models/criterion_model.dart';
import '../data/models/tab_evaluation_model.dart';
import '../data/models/tab_goal_model.dart';
import '../domain/enrichment_providers.dart';
import '../domain/evaluation_providers.dart';
import '../data/repositories/auto_evaluation_repository.dart';
import 'evaluation_display_model.dart';

class SelfEvaluationPage extends ConsumerStatefulWidget {
  final String? evalId;
  const SelfEvaluationPage({super.key, this.evalId});

  @override
  ConsumerState<SelfEvaluationPage> createState() => _SelfEvaluationPageState();
}

class _SelfEvaluationPageState extends ConsumerState<SelfEvaluationPage> {
  final Map<String, int> _scores = {};
  final _strengthsCtrl  = TextEditingController();
  final _attentionCtrl  = TextEditingController();
  final _feedbackCtrl   = TextEditingController();
  final _actionPlanCtrl = TextEditingController();
  // GoalAchievement por índice (paralelo a eval.goals)
  final List<GoalAchievement?> _goalAchievements = [];
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _strengthsCtrl.dispose();
    _attentionCtrl.dispose();
    _feedbackCtrl.dispose();
    _actionPlanCtrl.dispose();
    super.dispose();
  }

  void _tryInitialize(
    Map<CriterionType, List<Criterion>>? criteria,
    AutoEvaluation? eval,
  ) {
    if (_initialized || criteria == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialized) return;
      setState(() {
        final allCriteria = [
          ...criteria[CriterionType.behavioral] ?? [],
          ...criteria[CriterionType.technical] ?? [],
        ];
        for (final c in allCriteria) {
          _scores[c.id] = 5;
        }

        if (eval != null) {
          for (final t in eval.behavioralEvaluation) {
            if (t.evaluation != null) _scores[t.criterionId] = t.evaluation!;
          }
          for (final t in eval.technicalEvaluation) {
            if (t.evaluation != null) _scores[t.criterionId] = t.evaluation!;
          }
          _strengthsCtrl.text  = eval.strengths ?? '';
          _attentionCtrl.text  = eval.attentionPoints ?? '';
          _feedbackCtrl.text   = eval.feedback ?? '';
          _actionPlanCtrl.text = eval.actionPlan ?? '';

          // Inicializa estado das metas
          _goalAchievements.clear();
          for (final g in eval.goals) {
            _goalAchievements.add(g.achieve);
          }
        }
        _initialized = true;
      });
    });
  }

  double get _completionRatio {
    if (_scores.isEmpty) return 0;
    final filled = _scores.values.where((s) => s > 0).length;
    return filled / _scores.length;
  }

  List<TabEvaluation> _buildTabList(List<Criterion> criteria) => criteria
      .map((c) => TabEvaluation(criterionId: c.id, evaluation: _scores[c.id]))
      .toList();

  Future<void> _save({required bool finalize}) async {
    final eval     = ref.read(myAutoEvaluationProvider).valueOrNull;
    final criteria = ref.read(cycleCriteriaProvider).valueOrNull;
    if (eval == null || criteria == null || _saving) return;

    setState(() => _saving = true);
    try {
      // Reconstrói goals com os achievements atualizados
      final updatedGoals = <TabGoal>[];
      for (var i = 0; i < eval.goals.length; i++) {
        final original = eval.goals[i];
        updatedGoals.add(TabGoal(
          id:      original.id,
          goal:    original.goal,
          achieve: i < _goalAchievements.length ? _goalAchievements[i] : original.achieve,
        ));
      }

      final updated = AutoEvaluation(
        id:          eval.id,
        cycleId:     eval.cycleId,
        status:      finalize ? EvaluationStatus.finished : EvaluationStatus.onGoing,
        employeeId:  eval.employeeId,
        appraiserId: eval.appraiserId,
        behavioralEvaluation: _buildTabList(criteria[CriterionType.behavioral] ?? []),
        technicalEvaluation:  _buildTabList(criteria[CriterionType.technical] ?? []),
        goals:           updatedGoals,
        strengths:       _strengthsCtrl.text.trim().isEmpty ? null : _strengthsCtrl.text.trim(),
        attentionPoints: _attentionCtrl.text.trim().isEmpty ? null : _attentionCtrl.text.trim(),
        feedback:        _feedbackCtrl.text.trim().isEmpty ? null : _feedbackCtrl.text.trim(),
        actionPlan:      _actionPlanCtrl.text.trim().isEmpty ? null : _actionPlanCtrl.text.trim(),
        nextGoals:       eval.nextGoals,
        creationDate:    eval.creationDate,
      );
      await ref.read(autoEvaluationRepositoryProvider).update(updated);
      if (!mounted) return;
      ref.invalidate(myAutoEvaluationProvider);
      if (!finalize) {
        context.go('/avaliacoes');
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Avaliação enviada!'),
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

  @override
  Widget build(BuildContext context) {
    final criteriaAsync   = ref.watch(cycleCriteriaProvider);
    final myEvalAsync     = ref.watch(myAutoEvaluationProvider);
    final byIdAsync       = ref.watch(autoEvaluationByIdProvider(widget.evalId ?? ''));
    final evalAsync       = widget.evalId != null ? byIdAsync : myEvalAsync;
    final resolvedAsync   = widget.evalId != null
        ? ref.watch(resolvedAutoEvalByIdProvider(widget.evalId!))
        : ref.watch(resolvedMyAutoEvalProvider);

    criteriaAsync.whenData((criteria) {
      evalAsync.whenData((eval) => _tryInitialize(criteria, eval));
    });

    final currentUser = ref.watch(currentUserProvider);
    final eval        = evalAsync.valueOrNull;
    final isReadOnly  = eval?.isReadOnly ?? false;
    final criteria    = criteriaAsync.valueOrNull;
    final behavioral  = criteria?[CriterionType.behavioral] ?? [];
    final technical   = criteria?[CriterionType.technical] ?? [];
    final goals       = eval?.goals ?? [];

    final resolved    = resolvedAsync.valueOrNull;
    final displayModel = resolved != null
        ? EvaluationDisplayModel.fromResolvedAuto(
            resolved,
            currentUserName: currentUser?.name,
          )
        : (eval != null
            ? EvaluationDisplayModel.fromAutoEvaluation(
                eval,
                currentUserName: currentUser?.name,
              )
            : null);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DgtAppBar.detail(
        typeLabel: displayModel?.typeLabel ?? 'Auto-Avaliação',
        personLabel: displayModel?.personLabel,
        contextLine: displayModel?.headerContextLine ?? '',
        actions: [
          if (!criteriaAsync.isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(_completionRatio * 100).round()}%',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: _completionRatio,
            minHeight: 3,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
      body: Column(
        children: [
          if (isReadOnly && eval?.status != null)
            ReadOnlyBanner(status: eval!.status),
          Expanded(
            child: criteriaAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro ao carregar critérios: $e')),
              data: (_) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _HintBox(
                    text: isReadOnly
                        ? 'Esta avaliação está em modo somente leitura.'
                        : 'Avalie com base no seu desempenho real — seja honesto. '
                            'Preencha antes da reunião com seu gestor.',
                  ),

                  // Critérios comportamentais
                  if (behavioral.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const _SectionLabel(label: 'Critérios comportamentais'),
                    const SizedBox(height: 8),
                    for (final c in behavioral) ...[
                      _CriterionCard(
                        name: c.name,
                        score: (_scores[c.id] ?? 5).toDouble(),
                        isReadOnly: isReadOnly,
                        onChanged: (v) => setState(() => _scores[c.id] = v.round()),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],

                  // Critérios técnicos
                  if (technical.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    const _SectionLabel(label: 'Critérios técnicos'),
                    const SizedBox(height: 8),
                    for (final c in technical) ...[
                      _CriterionCard(
                        name: c.name,
                        score: (_scores[c.id] ?? 5).toDouble(),
                        isReadOnly: isReadOnly,
                        onChanged: (v) => setState(() => _scores[c.id] = v.round()),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],

                  // Metas do período
                  if (goals.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    const _SectionLabel(label: 'Metas do período'),
                    const SizedBox(height: 8),
                    for (var i = 0; i < goals.length; i++) ...[
                      _GoalCard(
                        goal: goals[i].goal ?? 'Meta ${i + 1}',
                        achievement: i < _goalAchievements.length
                            ? _goalAchievements[i]
                            : null,
                        isReadOnly: isReadOnly,
                        onChanged: (v) => setState(() {
                          while (_goalAchievements.length <= i) {
                            _goalAchievements.add(null);
                          }
                          _goalAchievements[i] = v;
                        }),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],

                  // Comentários qualitativos
                  const SizedBox(height: 6),
                  const _SectionLabel(label: 'Comentários qualitativos'),
                  const SizedBox(height: 8),
                  _QualitativeCard(
                    label: 'Pontos positivos',
                    hint: 'O que você fez bem neste ciclo?',
                    ctrl: _strengthsCtrl,
                    isReadOnly: isReadOnly,
                  ),
                  const SizedBox(height: 10),
                  _QualitativeCard(
                    label: 'Pontos de atenção',
                    hint: 'O que pode melhorar?',
                    ctrl: _attentionCtrl,
                    isReadOnly: isReadOnly,
                  ),
                  const SizedBox(height: 10),
                  _QualitativeCard(
                    label: 'Feedback',
                    hint: 'Como avalia o seu ciclo de forma geral?',
                    ctrl: _feedbackCtrl,
                    isReadOnly: isReadOnly,
                  ),
                  const SizedBox(height: 10),
                  _QualitativeCard(
                    label: 'Plano de desenvolvimento',
                    hint: 'Quais ações você planeja tomar?',
                    ctrl: _actionPlanCtrl,
                    isReadOnly: isReadOnly,
                  ),
                  if (eval != null) ...[
                    const SizedBox(height: 24),
                    _DateFooter(
                      creationDate: eval.creationDate,
                      lastUpdate: eval.lastUpdate,
                    ),
                  ],
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
              onSaveDraft: () => _save(finalize: false),
              onSubmit: () => _save(finalize: true),
            ),
    );
  }
}

// ── Componentes ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w500,
          color: AppColors.midGray, letterSpacing: 0.5,
        ),
      );
}

class _HintBox extends StatelessWidget {
  final String text;
  const _HintBox({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF9ED),
          border: Border.all(color: const Color(0xFFFCE7A0)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💡', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.statusAtRisk, height: 1.5)),
            ),
          ],
        ),
      );
}

class _CriterionCard extends StatelessWidget {
  final String name;
  final double score;
  final bool isReadOnly;
  final ValueChanged<double> onChanged;
  const _CriterionCard({
    required this.name,
    required this.score,
    required this.isReadOnly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary)),
                ),
                Text(
                  score.toInt().toString(),
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w500,
                      color: isReadOnly ? AppColors.midGray : AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('0', style: TextStyle(fontSize: 11, color: AppColors.textDisabled)),
                Expanded(
                  child: Slider(
                    value: score,
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
        ),
      );
}

class _GoalCard extends StatelessWidget {
  final String goal;
  final GoalAchievement? achievement;
  final bool isReadOnly;
  final ValueChanged<GoalAchievement?> onChanged;

  const _GoalCard({
    required this.goal,
    required this.achievement,
    required this.isReadOnly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(goal,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Row(
              children: [
                _AchievementChip(
                  label: 'Sim',
                  color: AppColors.statusOnTrack,
                  bg: AppColors.statusOnTrackBg,
                  selected: achievement == GoalAchievement.yes,
                  disabled: isReadOnly,
                  onTap: () => onChanged(GoalAchievement.yes),
                ),
                const SizedBox(width: 8),
                _AchievementChip(
                  label: 'Parcial',
                  color: AppColors.statusAtRisk,
                  bg: AppColors.statusAtRiskBg,
                  selected: achievement == GoalAchievement.partial,
                  disabled: isReadOnly,
                  onTap: () => onChanged(GoalAchievement.partial),
                ),
                const SizedBox(width: 8),
                _AchievementChip(
                  label: 'Não',
                  color: AppColors.statusBehind,
                  bg: AppColors.statusBehindBg,
                  selected: achievement == GoalAchievement.no,
                  disabled: isReadOnly,
                  onTap: () => onChanged(GoalAchievement.no),
                ),
              ],
            ),
          ],
        ),
      );
}

class _AchievementChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _AchievementChip({
    required this.label,
    required this.color,
    required this.bg,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: disabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color : AppColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 1.5 : 0.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : AppColors.midGray,
            ),
          ),
        ),
      );
}

class _QualitativeCard extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController ctrl;
  final bool isReadOnly;
  const _QualitativeCard({
    required this.label,
    required this.hint,
    required this.ctrl,
    required this.isReadOnly,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
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
        ),
      );
}

class _ActionBar extends StatelessWidget {
  final bool saving;
  final VoidCallback onSaveDraft;
  final VoidCallback onSubmit;
  const _ActionBar({
    required this.saving,
    required this.onSaveDraft,
    required this.onSubmit,
  });

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
                onPressed: saving ? null : onSaveDraft,
                child: const Text('Salvar rascunho'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: saving ? null : onSubmit,
                child: saving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.darkGray))
                    : const Text('Enviar avaliação →'),
              ),
            ),
          ],
        ),
      );
}

class _DateFooter extends StatelessWidget {
  final DateTime creationDate;
  final DateTime? lastUpdate;
  const _DateFooter({required this.creationDate, this.lastUpdate});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Criado em ${du.formatDate(creationDate)}',
                style: const TextStyle(fontSize: 11, color: AppColors.textDisabled)),
            if (lastUpdate != null) ...[
              const SizedBox(height: 2),
              Text('Atualizado em ${du.formatDate(lastUpdate!)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textDisabled)),
            ],
          ],
        ),
      );
}
