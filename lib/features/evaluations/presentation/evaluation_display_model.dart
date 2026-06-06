import '../../../core/utils/date_utils.dart' as du;
import '../data/models/auto_evaluation_model.dart';
import '../data/models/lider_evaluation_model.dart';
import 'resolved_eval.dart';

class EvaluationDisplayModel {
  final String typeLabel;
  final String personLabel;
  // Linhas do card
  final String cardLine1;
  final String cardLine2;
  final String? lastUpdateLabel;
  // Linha de contexto do header
  final String headerContextLine;
  final bool isManagerEvaluation;

  const EvaluationDisplayModel({
    required this.typeLabel,
    required this.personLabel,
    required this.cardLine1,
    required this.cardLine2,
    this.lastUpdateLabel,
    required this.headerContextLine,
    required this.isManagerEvaluation,
  });

  factory EvaluationDisplayModel.fromAutoEvaluation(
    AutoEvaluation eval, {
    String? currentUserName,
  }) {
    final period = _period(eval.cyclePeriod, eval.cycleYear);
    final lastUpdate =
        eval.lastUpdate ?? eval.finishedDate ?? eval.evaluationDate;
    return EvaluationDisplayModel(
      typeLabel: 'Auto-Avaliação',
      personLabel: currentUserName ?? '',
      cardLine1: period,
      cardLine2: 'Status: ${eval.status.label}',
      lastUpdateLabel:
          lastUpdate != null ? 'Atualizado em ${du.formatDate(lastUpdate)}' : null,
      headerContextLine: '$period · Status: ${eval.status.label}',
      isManagerEvaluation: false,
    );
  }

  factory EvaluationDisplayModel.fromLiderEvaluationReceived(
    LiderEvaluation eval, {
    String? currentUserName,
  }) {
    final period = _period(eval.cyclePeriod, eval.cycleYear);
    final lastUpdate = eval.lastUpdate ?? eval.finishedDate;
    final appraiser =
        eval.appraiserName.isNotEmpty ? eval.appraiserName : 'Gestor';
    final employee = currentUserName ??
        (eval.employeeName.isNotEmpty ? eval.employeeName : '');
    return EvaluationDisplayModel(
      typeLabel: 'Avaliação do Gestor',
      personLabel: employee,
      cardLine1: 'Avaliador: $appraiser',
      cardLine2: '$period · Status: ${eval.status.label}',
      lastUpdateLabel:
          lastUpdate != null ? 'Atualizado em ${du.formatDate(lastUpdate)}' : null,
      headerContextLine:
          'Avaliado por $appraiser · $period · Status: ${eval.status.label}',
      isManagerEvaluation: true,
    );
  }

  factory EvaluationDisplayModel.fromLiderEvaluationManager(
    LiderEvaluation eval,
  ) {
    final period = _period(eval.cyclePeriod, eval.cycleYear);
    final lastUpdate = eval.lastUpdate ?? eval.finishedDate;
    final employee =
        eval.employeeName.isNotEmpty ? eval.employeeName : 'Colaborador';
    final appraiser =
        eval.appraiserName.isNotEmpty ? eval.appraiserName : 'Gestor';
    return EvaluationDisplayModel(
      typeLabel: 'Avaliação do Gestor',
      personLabel: employee,
      cardLine1: 'Avaliado: $employee',
      cardLine2: '$period · Status: ${eval.status.label}',
      lastUpdateLabel:
          lastUpdate != null ? 'Atualizado em ${du.formatDate(lastUpdate)}' : null,
      headerContextLine:
          'Avaliado por $appraiser · $period · Status: ${eval.status.label}',
      isManagerEvaluation: true,
    );
  }

  // ── Factories com dados pré-resolvidos (período e nomes via API) ─────────────

  factory EvaluationDisplayModel.fromResolvedAuto(
    ResolvedAutoEval r, {
    String? currentUserName,
  }) {
    final lastUpdate =
        r.eval.lastUpdate ?? r.eval.finishedDate ?? r.eval.evaluationDate;
    return EvaluationDisplayModel(
      typeLabel: 'Auto-Avaliação',
      personLabel: currentUserName ?? r.employeeName,
      cardLine1: r.periodLabel,
      cardLine2: 'Status: ${r.eval.status.label}',
      lastUpdateLabel:
          lastUpdate != null ? 'Atualizado em ${du.formatDate(lastUpdate)}' : null,
      headerContextLine: '${r.periodLabel} · Status: ${r.eval.status.label}',
      isManagerEvaluation: false,
    );
  }

  factory EvaluationDisplayModel.fromResolvedLiderReceived(
    ResolvedLiderEval r, {
    String? currentUserName,
  }) {
    final lastUpdate = r.eval.lastUpdate ?? r.eval.finishedDate;
    final employee = currentUserName ?? r.employeeName;
    return EvaluationDisplayModel(
      typeLabel: 'Avaliação do Gestor',
      personLabel: employee,
      cardLine1: 'Avaliador: ${r.appraiserName}',
      cardLine2: '${r.periodLabel} · Status: ${r.eval.status.label}',
      lastUpdateLabel:
          lastUpdate != null ? 'Atualizado em ${du.formatDate(lastUpdate)}' : null,
      headerContextLine:
          'Avaliado por ${r.appraiserName} · ${r.periodLabel} · Status: ${r.eval.status.label}',
      isManagerEvaluation: true,
    );
  }

  factory EvaluationDisplayModel.fromResolvedLiderManager(ResolvedLiderEval r) {
    final lastUpdate = r.eval.lastUpdate ?? r.eval.finishedDate;
    return EvaluationDisplayModel(
      typeLabel: 'Avaliação do Gestor',
      personLabel: r.employeeName,
      cardLine1: 'Avaliado: ${r.employeeName}',
      cardLine2: '${r.periodLabel} · Status: ${r.eval.status.label}',
      lastUpdateLabel:
          lastUpdate != null ? 'Atualizado em ${du.formatDate(lastUpdate)}' : null,
      headerContextLine:
          'Avaliado por ${r.appraiserName} · ${r.periodLabel} · Status: ${r.eval.status.label}',
      isManagerEvaluation: true,
    );
  }

  static String _period(String cyclePeriod, int cycleYear) {
    if (cyclePeriod.isNotEmpty && cycleYear > 0) return '$cyclePeriod $cycleYear';
    if (cycleYear > 0) return '$cycleYear';
    return '—';
  }
}
