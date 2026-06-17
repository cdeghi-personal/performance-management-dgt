class EmployeePerfil {
  final String id;
  final String employeeId;
  final String careerLevel;
  final String function;
  final DateTime? hiringDate;
  // SYDLE field names: double 'a' in 'classificacation' is an intentional backend typo.
  final String classificacationLastCycle;
  final bool topPerformer;
  final String classificacationPreviousCycle;
  final bool topPerformerUltimoCiclo;
  // Novos campos — "Colaborador" ou "Prestador"
  final String? type;
  final String? eMailCelular;

  const EmployeePerfil({
    required this.id,
    required this.employeeId,
    required this.careerLevel,
    required this.function,
    this.hiringDate,
    required this.classificacationLastCycle,
    required this.topPerformer,
    required this.classificacationPreviousCycle,
    required this.topPerformerUltimoCiclo,
    this.type,
    this.eMailCelular,
  });

  factory EmployeePerfil.fromJson(Map<String, dynamic> json) {
    final emp = json['employee'];
    final employeeId =
        (emp is Map<String, dynamic>) ? emp['_id'] as String? ?? '' : '';
    return EmployeePerfil(
      id:                             json['_id'] as String? ?? '',
      employeeId:                     employeeId,
      careerLevel:                    json['careerLevel'] as String? ?? '',
      function:                       json['function'] as String? ?? '',
      hiringDate:                     _parseDate(json['hiringDate']),
      classificacationLastCycle:      json['classificacationLastCycle'] as String? ?? '',
      topPerformer:                   json['topPerformer'] as bool? ?? false,
      classificacationPreviousCycle:  json['classificacationPreviousCycle'] as String? ?? '',
      topPerformerUltimoCiclo:        json['topPerformerUltimoCiclo'] as bool? ?? false,
      type:                           json['type'] as String?,
      eMailCelular:                   json['eMailCelular'] as String?,
    );
  }

  /// Rótulo de pessoa baseado no tipo do perfil.
  String get personTypeLabel {
    if (type == 'Prestador') return 'Prestador';
    return 'Colaborador';
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
