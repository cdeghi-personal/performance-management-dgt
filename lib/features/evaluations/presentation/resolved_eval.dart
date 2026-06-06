import '../data/models/auto_evaluation_model.dart';
import '../data/models/lider_evaluation_model.dart';

/// Auto-avaliação com dados de exibição já resolvidos (período, nome do avaliado).
class ResolvedAutoEval {
  final AutoEvaluation eval;
  final String periodLabel;
  final String employeeName;
  final DateTime? cycleDate;

  const ResolvedAutoEval({
    required this.eval,
    required this.periodLabel,
    required this.employeeName,
    this.cycleDate,
  });
}

/// Avaliação do gestor com dados de exibição já resolvidos
/// (período, nome do avaliado, nome do avaliador).
class ResolvedLiderEval {
  final LiderEvaluation eval;
  final String periodLabel;
  final String employeeName;
  final String appraiserName;
  final DateTime? cycleDate;

  const ResolvedLiderEval({
    required this.eval,
    required this.periodLabel,
    required this.employeeName,
    required this.appraiserName,
    this.cycleDate,
  });
}

// ── Hierarquia para "Minhas Avaliações" (auto + recebidas do gestor) ──────────

sealed class ResolvedMyEval {
  DateTime get sortCycleDate;
  DateTime get sortLastUpdate;
}

final class ResolvedMyAutoEval extends ResolvedMyEval {
  final ResolvedAutoEval data;
  ResolvedMyAutoEval(this.data);

  @override
  DateTime get sortCycleDate => data.cycleDate ?? data.eval.creationDate;

  @override
  DateTime get sortLastUpdate => data.eval.lastUpdate ?? data.eval.creationDate;
}

final class ResolvedMyLiderEvalReceived extends ResolvedMyEval {
  final ResolvedLiderEval data;
  ResolvedMyLiderEvalReceived(this.data);

  @override
  DateTime get sortCycleDate => data.cycleDate ?? data.eval.creationDate;

  @override
  DateTime get sortLastUpdate => data.eval.lastUpdate ?? data.eval.creationDate;
}
