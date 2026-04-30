enum GoalStatus { draft, active, atRisk, behind, completed, cancelled }

enum GoalType { individual, team, company }

class Goal {
  final String id;
  final String title;
  final String description;
  final GoalType type;
  final GoalStatus status;
  final String cycleYear;
  final String ownerId;
  final String ownerName;
  final double progressPercent;
  final DateTime dueDate;
  final DateTime createdAt;
  final String? parentGoalId;
  final List<KeyResult> keyResults;

  const Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.cycleYear,
    required this.ownerId,
    required this.ownerName,
    required this.progressPercent,
    required this.dueDate,
    required this.createdAt,
    this.parentGoalId,
    this.keyResults = const [],
  });

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        type: GoalType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => GoalType.individual,
        ),
        status: GoalStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => GoalStatus.draft,
        ),
        cycleYear: json['cycle_year'] as String,
        ownerId: json['owner_id'] as String,
        ownerName: json['owner_name'] as String? ?? '',
        progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0,
        dueDate: DateTime.parse(json['due_date'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        parentGoalId: json['parent_goal_id'] as String?,
        keyResults: (json['key_results'] as List<dynamic>?)
                ?.map((e) => KeyResult.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class KeyResult {
  final String id;
  final String title;
  final double currentValue;
  final double targetValue;
  final String unit;
  final DateTime dueDate;

  const KeyResult({
    required this.id,
    required this.title,
    required this.currentValue,
    required this.targetValue,
    required this.unit,
    required this.dueDate,
  });

  double get progress => targetValue > 0 ? (currentValue / targetValue).clamp(0, 1) : 0;

  factory KeyResult.fromJson(Map<String, dynamic> json) => KeyResult(
        id: json['id'] as String,
        title: json['title'] as String,
        currentValue: (json['current_value'] as num?)?.toDouble() ?? 0,
        targetValue: (json['target_value'] as num?)?.toDouble() ?? 100,
        unit: json['unit'] as String? ?? '%',
        dueDate: DateTime.parse(json['due_date'] as String),
      );
}