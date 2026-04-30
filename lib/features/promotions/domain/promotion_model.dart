enum PromotionStatus { pending, underReview, approved, rejected, onHold }

class PromotionRequest {
  final String id;
  final String employeeId;
  final String employeeName;
  final String currentRole;
  final String targetRole;
  final String requestedById;
  final String requestedByName;
  final PromotionStatus status;
  final DateTime requestedAt;
  final String justification;
  final String? managerEndorsement;
  final String? hrComments;
  final String? executiveDecision;
  final DateTime? decisionAt;
  final bool isQuotaRelated;

  const PromotionRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.currentRole,
    required this.targetRole,
    required this.requestedById,
    required this.requestedByName,
    required this.status,
    required this.requestedAt,
    required this.justification,
    this.managerEndorsement,
    this.hrComments,
    this.executiveDecision,
    this.decisionAt,
    this.isQuotaRelated = false,
  });

  factory PromotionRequest.fromJson(Map<String, dynamic> json) => PromotionRequest(
        id: json['id'] as String,
        employeeId: json['employee_id'] as String,
        employeeName: json['employee_name'] as String? ?? '',
        currentRole: json['current_role'] as String,
        targetRole: json['target_role'] as String,
        requestedById: json['requested_by_id'] as String,
        requestedByName: json['requested_by_name'] as String? ?? '',
        status: PromotionStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => PromotionStatus.pending,
        ),
        requestedAt: DateTime.parse(json['requested_at'] as String),
        justification: json['justification'] as String? ?? '',
        managerEndorsement: json['manager_endorsement'] as String?,
        hrComments: json['hr_comments'] as String?,
        executiveDecision: json['executive_decision'] as String?,
        decisionAt: json['decision_at'] != null
            ? DateTime.parse(json['decision_at'] as String)
            : null,
        isQuotaRelated: json['is_quota_related'] as bool? ?? false,
      );
}