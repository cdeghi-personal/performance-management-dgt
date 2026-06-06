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
