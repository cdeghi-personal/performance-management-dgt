enum EvaluationStatus { pending, inProgress, completed, calibrated }

enum EvaluationScore {
  exceedsExpectations,
  meetsExpectations,
  partiallyMeets,
  doesNotMeet,
}

class Evaluation {
  final String id;
  final String employeeId;
  final String employeeName;
  final String evaluatorId;
  final String evaluatorName;
  final String semester; // '2025-S1', '2025-S2'
  final EvaluationStatus status;
  final EvaluationScore? selfScore;
  final EvaluationScore? managerScore;
  final EvaluationScore? finalScore;
  final String? selfComments;
  final String? managerComments;
  final List<CompetencyScore> competencies;
  final DateTime? completedAt;

  const Evaluation({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.evaluatorId,
    required this.evaluatorName,
    required this.semester,
    required this.status,
    this.selfScore,
    this.managerScore,
    this.finalScore,
    this.selfComments,
    this.managerComments,
    this.competencies = const [],
    this.completedAt,
  });

  factory Evaluation.fromJson(Map<String, dynamic> json) => Evaluation(
        id: json['id'] as String,
        employeeId: json['employee_id'] as String,
        employeeName: json['employee_name'] as String? ?? '',
        evaluatorId: json['evaluator_id'] as String,
        evaluatorName: json['evaluator_name'] as String? ?? '',
        semester: json['semester'] as String,
        status: EvaluationStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => EvaluationStatus.pending,
        ),
        selfScore: _parseScore(json['self_score']),
        managerScore: _parseScore(json['manager_score']),
        finalScore: _parseScore(json['final_score']),
        selfComments: json['self_comments'] as String?,
        managerComments: json['manager_comments'] as String?,
        competencies: (json['competencies'] as List<dynamic>?)
                ?.map((e) => CompetencyScore.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
      );

  static EvaluationScore? _parseScore(dynamic v) {
    if (v == null) return null;
    return EvaluationScore.values.firstWhere(
      (e) => e.name == v,
      orElse: () => EvaluationScore.meetsExpectations,
    );
  }
}

class CompetencyScore {
  final String competencyId;
  final String competencyName;
  final EvaluationScore? selfScore;
  final EvaluationScore? managerScore;
  final String? comment;

  const CompetencyScore({
    required this.competencyId,
    required this.competencyName,
    this.selfScore,
    this.managerScore,
    this.comment,
  });

  factory CompetencyScore.fromJson(Map<String, dynamic> json) => CompetencyScore(
        competencyId: json['competency_id'] as String,
        competencyName: json['competency_name'] as String,
        selfScore: json['self_score'] != null
            ? EvaluationScore.values.firstWhere((e) => e.name == json['self_score'])
            : null,
        managerScore: json['manager_score'] != null
            ? EvaluationScore.values.firstWhere((e) => e.name == json['manager_score'])
            : null,
        comment: json['comment'] as String?,
      );
}