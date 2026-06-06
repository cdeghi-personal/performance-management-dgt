import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart' as du;
import '../../../shared/widgets/dgt_app_bar.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/domain/auth_provider.dart';
import '../data/models/criterion_model.dart';
import '../data/models/lider_evaluation_model.dart';
import '../domain/enrichment_providers.dart';
import '../domain/evaluation_providers.dart';
import 'evaluation_display_model.dart';

class ReceivedEvaluationPage extends ConsumerWidget {
  final String evalId;
  const ReceivedEvaluationPage({super.key, required this.evalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evalAsync     = ref.watch(liderEvaluationByIdProvider(evalId));
    final resolvedAsync = ref.watch(resolvedLiderEvalByIdProvider(evalId));
    final criteriaAsync = ref.watch(cycleCriteriaProvider);
    final currentUser   = ref.watch(currentUserProvider);
    final isManager     = ref.watch(isManagerProvider);

    final eval     = evalAsync.valueOrNull;
    final resolved = resolvedAsync.valueOrNull;
    final displayModel = resolved != null
        ? EvaluationDisplayModel.fromResolvedLiderReceived(
            resolved, currentUserName: currentUser?.name)
        : (eval != null
            ? EvaluationDisplayModel.fromLiderEvaluationReceived(
                eval, currentUserName: currentUser?.name)
            : null);

    // TopPerformer só visível para gestores que são o próprio avaliador
    final showTopPerformer = isManager &&
        eval != null &&
        eval.appraiserId == (currentUser?.colaboradorId ?? '');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DgtAppBar.detail(
        typeLabel: displayModel?.typeLabel ?? 'Avaliação do Gestor',
        personLabel: displayModel?.personLabel,
        contextLine: displayModel?.headerContextLine ?? '',
      ),
      body: evalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro ao carregar: $e')),
        data: (eval) {
          if (eval == null) {
            return const Center(
              child: Text('Avaliação não encontrada.',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }

          final criteriaMap = <String, String>{};
          final criteria = criteriaAsync.valueOrNull;
          if (criteria != null) {
            for (final c in [
              ...criteria[CriterionType.behavioral] ?? [],
              ...criteria[CriterionType.technical] ?? [],
            ]) {
              criteriaMap[c.id] = c.name;
            }
          }

          final hasResult = eval.classification != null ||
              (showTopPerformer && eval.topPerformer);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (hasResult) ...[
                _ClassificationCard(
                    eval: eval, showTopPerformer: showTopPerformer),
                const SizedBox(height: 16),
              ],

              if (eval.behavioralEvaluation.isNotEmpty) ...[
                const _SectionLabel(label: 'Critérios comportamentais'),
                const SizedBox(height: 8),
                for (final t in eval.behavioralEvaluation) ...[
                  _ScoreCard(
                    name: criteriaMap[t.criterionId] ?? t.criterionId,
                    score: t.evaluation,
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
              ],

              if (eval.technicalEvaluation.isNotEmpty) ...[
                const _SectionLabel(label: 'Critérios técnicos'),
                const SizedBox(height: 8),
                for (final t in eval.technicalEvaluation) ...[
                  _ScoreCard(
                    name: criteriaMap[t.criterionId] ?? t.criterionId,
                    score: t.evaluation,
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
              ],

              if (_hasNotes(eval)) ...[
                const _SectionLabel(label: 'Comentários do gestor'),
                const SizedBox(height: 8),
                if (eval.strengths?.isNotEmpty == true)
                  _NoteCard(label: 'Pontos positivos', text: eval.strengths!),
                if (eval.attentionPoints?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  _NoteCard(
                      label: 'Pontos de atenção',
                      text: eval.attentionPoints!),
                ],
                if (eval.feedback?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  _NoteCard(label: 'Feedback', text: eval.feedback!),
                ],
                if (eval.actionPlan?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  _NoteCard(
                      label: 'Plano de desenvolvimento',
                      text: eval.actionPlan!),
                ],
              ],

              if (eval.nextGoals.isNotEmpty) ...[
                const SizedBox(height: 16),
                const _SectionLabel(label: 'Metas para o próximo período'),
                const SizedBox(height: 8),
                _NextGoalsCard(nextGoals: eval.nextGoals),
              ],

              const SizedBox(height: 16),
              _DateFooter(
                creationDate: eval.creationDate,
                lastUpdate: eval.lastUpdate,
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  bool _hasNotes(LiderEvaluation e) =>
      e.strengths?.isNotEmpty == true ||
      e.attentionPoints?.isNotEmpty == true ||
      e.feedback?.isNotEmpty == true ||
      e.actionPlan?.isNotEmpty == true;
}

// ── Card de classificação (só aparece quando há classificação ou top performer) ─

class _ClassificationCard extends StatelessWidget {
  final LiderEvaluation eval;
  final bool showTopPerformer;
  const _ClassificationCard(
      {required this.eval, this.showTopPerformer = false});

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
            if (eval.classification != null)
              ClassificationBadge(classification: eval.classification!.label),
            if (showTopPerformer && eval.topPerformer) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusAtRiskBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Top Performer',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary),
                ),
              ),
            ],
          ],
        ),
      );
}

// ── Metas para o próximo período (read-only) ──────────────────────────────────

class _NextGoalsCard extends StatelessWidget {
  final List<String> nextGoals;
  const _NextGoalsCard({required this.nextGoals});

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
            for (var i = 0; i < nextGoals.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: const BoxDecoration(
                      color: AppColors.statusAtRiskBg,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(nextGoals[i],
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.4)),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
}

// ── Score card (read-only slider visual) ────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final String name;
  final int? score;
  const _ScoreCard({required this.name, required this.score});

  @override
  Widget build(BuildContext context) {
    final value = score ?? 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value / 10,
                    minHeight: 6,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.midGray),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '$value',
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w500, color: AppColors.midGray),
          ),
        ],
      ),
    );
  }
}

// ── Note card ────────────────────────────────────────────────────────────────

class _NoteCard extends StatelessWidget {
  final String label;
  final String text;
  const _NoteCard({required this.label, required this.text});

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
            Text(text,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
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

// ── Date footer ───────────────────────────────────────────────────────────────

class _DateFooter extends StatelessWidget {
  final DateTime creationDate;
  final DateTime? lastUpdate;
  const _DateFooter({required this.creationDate, this.lastUpdate});

  @override
  Widget build(BuildContext context) => Column(
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
      );
}
