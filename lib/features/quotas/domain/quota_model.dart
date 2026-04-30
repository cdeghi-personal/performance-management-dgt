enum QuotaCategory { race, gender, disability, lgbtq, other }

class QuotaProgram {
  final String id;
  final String cycleYear;
  final List<QuotaTarget> targets;
  final DateTime updatedAt;

  const QuotaProgram({
    required this.id,
    required this.cycleYear,
    required this.targets,
    required this.updatedAt,
  });

  factory QuotaProgram.fromJson(Map<String, dynamic> json) => QuotaProgram(
        id: json['id'] as String,
        cycleYear: json['cycle_year'] as String,
        targets: (json['targets'] as List<dynamic>?)
                ?.map((e) => QuotaTarget.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

class QuotaTarget {
  final String id;
  final QuotaCategory category;
  final String label;
  final int targetCount;
  final int currentCount;
  final String level; // 'entry', 'mid', 'senior', 'leadership'
  final String? notes;

  const QuotaTarget({
    required this.id,
    required this.category,
    required this.label,
    required this.targetCount,
    required this.currentCount,
    required this.level,
    this.notes,
  });

  double get fillRate => targetCount > 0 ? currentCount / targetCount : 0;
  int get gap => targetCount - currentCount;
  bool get isMet => currentCount >= targetCount;

  factory QuotaTarget.fromJson(Map<String, dynamic> json) => QuotaTarget(
        id: json['id'] as String,
        category: QuotaCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => QuotaCategory.other,
        ),
        label: json['label'] as String,
        targetCount: json['target_count'] as int,
        currentCount: json['current_count'] as int,
        level: json['level'] as String? ?? 'all',
        notes: json['notes'] as String?,
      );
}