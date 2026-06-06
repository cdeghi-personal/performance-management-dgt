enum CriterionType {
  behavioral,
  technical;

  static CriterionType fromString(String value) {
    switch (value) {
      case 'technical': return CriterionType.technical;
      default:          return CriterionType.behavioral;
    }
  }
}

class Criterion {
  final String id;
  final String name;
  final CriterionType type;
  final bool active;

  const Criterion({
    required this.id,
    required this.name,
    required this.type,
    required this.active,
  });

  factory Criterion.fromJson(Map<String, dynamic> json) {
    return Criterion(
      id:     json['_id'] as String,
      name:   json['criterion'] as String? ?? '',
      type:   CriterionType.fromString(json['type'] as String? ?? ''),
      active: json['active'] as bool? ?? true,
    );
  }
}
