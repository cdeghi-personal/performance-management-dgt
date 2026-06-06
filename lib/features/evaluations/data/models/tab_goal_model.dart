enum GoalAchievement {
  yes,
  no,
  partial;

  static GoalAchievement? fromString(String? value) {
    switch (value) {
      case 'yes':     return GoalAchievement.yes;
      case 'no':      return GoalAchievement.no;
      case 'partial': return GoalAchievement.partial;
      default:        return null;
    }
  }

  String get sydleValue {
    switch (this) {
      case GoalAchievement.yes:     return 'yes';
      case GoalAchievement.no:      return 'no';
      case GoalAchievement.partial: return 'partial';
    }
  }
}

// Embedded — nunca tem endpoint próprio.
// ATENÇÃO: o identifier no SYDLE é 'Goals' (G maiúsculo) — usar ao serializar.
class TabGoal {
  final String? id;
  final String? goal;
  final GoalAchievement? achieve;

  const TabGoal({this.id, this.goal, this.achieve});

  factory TabGoal.fromJson(Map<String, dynamic> json) {
    return TabGoal(
      id:      json['_id'] as String?,
      goal:    json['Goal'] as String?,
      achieve: GoalAchievement.fromString(json['achieve'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) '_id': id,
    if (goal != null) 'Goal': goal,
    if (achieve != null) 'achieve': achieve!.sydleValue,
  };
}
