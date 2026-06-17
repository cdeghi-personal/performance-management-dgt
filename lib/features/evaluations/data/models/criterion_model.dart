enum CriterionType {
  behavioral,
  technical,
  delivery,
  governance,
  compliance;

  static CriterionType fromString(String value) {
    switch (value) {
      case 'technical':   return CriterionType.technical;
      case 'delivery':    return CriterionType.delivery;
      case 'governance':  return CriterionType.governance;
      case 'compliance':  return CriterionType.compliance;
      default:            return CriterionType.behavioral;
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
