// Embedded — nunca tem endpoint próprio.
// Sempre salvo dentro de autoEvaluation._update ou liderEvaluation._update.
class TabEvaluation {
  final String? id;
  final String criterionId;
  final int? evaluation; // 0–10

  const TabEvaluation({
    this.id,
    required this.criterionId,
    this.evaluation,
  });

  factory TabEvaluation.fromJson(Map<String, dynamic> json) {
    // criterion vem como referência {_id: ..., _classId: ...} ou string direta
    final criterion = json['criterion'];
    final criterionId = criterion is Map<String, dynamic>
        ? criterion['_id'] as String
        : criterion as String? ?? '';

    return TabEvaluation(
      id:          json['_id'] as String?,
      criterionId: criterionId,
      evaluation:  json['evaluation'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) '_id': id,
    'criterion': {'_id': criterionId},
    if (evaluation != null) 'evaluation': evaluation,
  };
}

/// Agrupa um conjunto de critérios de avaliação com seu título dinâmico vindo do SYDLE.
/// Substitui os campos fixos behavioralEvaluation/technicalEvaluation.
class EvaluationGroup {
  final String title;
  final List<TabEvaluation> criteria;

  const EvaluationGroup({required this.title, required this.criteria});

  /// Média das notas preenchidas do grupo (0 se nenhuma nota).
  double get average {
    final scored = criteria.where((t) => t.evaluation != null).toList();
    if (scored.isEmpty) return 0;
    return scored.map((t) => t.evaluation!.toDouble()).reduce((a, b) => a + b) /
        scored.length;
  }

  /// Rótulo em português para exibição na UI.
  String get displayTitle {
    switch (title) {
      case 'behavioral':  return 'Comportamental';
      case 'technical':   return 'Técnico';
      case 'delivery':    return 'Entregas';
      case 'governance':  return 'Governança';
      case 'compliance':  return 'Conformidade';
      default:            return title.isNotEmpty ? title : 'Critérios';
    }
  }
}
