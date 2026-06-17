import 'tab_evaluation_model.dart';
import 'tab_goal_model.dart';

enum EvaluationStatus {
  notStarted,
  onGoing,
  finished,
  cancelled;

  // autoEvaluation e liderEvaluation usam camelCase lowercase
  static EvaluationStatus fromString(String value) {
    switch (value) {
      case 'onGoing':   return EvaluationStatus.onGoing;
      case 'finished':  return EvaluationStatus.finished;
      case 'cancelled': return EvaluationStatus.cancelled;
      default:          return EvaluationStatus.notStarted;
    }
  }

  String get sydleValue {
    switch (this) {
      case EvaluationStatus.onGoing:    return 'onGoing';
      case EvaluationStatus.finished:   return 'finished';
      case EvaluationStatus.cancelled:  return 'cancelled';
      case EvaluationStatus.notStarted: return 'notStarted';
    }
  }

  bool get isReadOnly =>
      this == EvaluationStatus.finished || this == EvaluationStatus.cancelled;

  String get label {
    switch (this) {
      case EvaluationStatus.notStarted: return 'Não iniciada';
      case EvaluationStatus.onGoing:    return 'Em andamento';
      case EvaluationStatus.finished:   return 'Finalizada';
      case EvaluationStatus.cancelled:  return 'Cancelada';
    }
  }
}

class AutoEvaluation {
  final String id;
  final String cycleId;
  final String cyclePeriod;
  final int cycleYear;
  final EvaluationStatus status;
  final String employeeId;
  final String appraiserId;

  // Grupos dinâmicos (2 a 4) — substituem behavioralEvaluation/technicalEvaluation.
  // tytleGroupN: identificador do tipo de grupo vindo do SYDLE ('behavioral', 'technical', etc.)
  // groupN: critérios avaliados nesse grupo.
  final String tytleGroup1;
  final List<TabEvaluation> group1;
  final String tytleGroup2;
  final List<TabEvaluation> group2;
  final String? tytleGroup3;
  final List<TabEvaluation>? group3;
  final String? tytleGroup4;
  final List<TabEvaluation>? group4;

  final List<TabGoal> goals; // chave JSON: 'Goals'
  final String? attentionPoints;
  final String? strengths;
  final String? feedback;
  final String? actionPlan;
  final List<String> nextGoals;
  final DateTime? evaluationDate;
  final DateTime? feedbackDate;
  final DateTime? finishedDate;
  final DateTime creationDate;
  final DateTime? lastUpdate;

  const AutoEvaluation({
    required this.id,
    required this.cycleId,
    this.cyclePeriod = '',
    this.cycleYear = 0,
    required this.status,
    required this.employeeId,
    required this.appraiserId,
    this.tytleGroup1 = 'behavioral',
    this.group1 = const [],
    this.tytleGroup2 = 'technical',
    this.group2 = const [],
    this.tytleGroup3,
    this.group3,
    this.tytleGroup4,
    this.group4,
    this.goals = const [],
    this.attentionPoints,
    this.strengths,
    this.feedback,
    this.actionPlan,
    this.nextGoals = const [],
    this.evaluationDate,
    this.feedbackDate,
    this.finishedDate,
    required this.creationDate,
    this.lastUpdate,
  });

  factory AutoEvaluation.fromJson(Map<String, dynamic> json) {
    return AutoEvaluation(
      id:           json['_id'] as String,
      cycleId:      _refId(json['cycle']),
      cyclePeriod:  _refStr(json['cycle'], 'period'),
      cycleYear:    _refInt(json['cycle'], 'year'),
      status:       EvaluationStatus.fromString(json['status'] as String? ?? ''),
      employeeId:   _refId(json['employee']),
      appraiserId:  _refId(json['appraiser']),
      // group1/group2: fallback para behavioralEvaluation/technicalEvaluation (dados legados)
      tytleGroup1:  json['tytleGroup1'] as String? ?? 'behavioral',
      group1:       _parseTabList(json['group1'] ?? json['behavioralEvaluation']),
      tytleGroup2:  json['tytleGroup2'] as String? ?? 'technical',
      group2:       _parseTabList(json['group2'] ?? json['technicalEvaluation']),
      tytleGroup3:  json['tytleGroup3'] as String?,
      group3:       json['group3'] != null ? _parseTabList(json['group3']) : null,
      tytleGroup4:  json['tytleGroup4'] as String?,
      group4:       json['group4'] != null ? _parseTabList(json['group4']) : null,
      goals:           _parseGoalList(json['Goals']),
      attentionPoints: json['attentionPoints'] as String?,
      strengths:       json['strengths'] as String?,
      feedback:        json['feedback'] as String?,
      actionPlan:      json['actionPlan'] as String?,
      nextGoals:       List<String>.from(json['nextGoals'] as List<dynamic>? ?? []),
      evaluationDate:  _parseDate(json['evaluationDate']),
      feedbackDate:    _parseDate(json['feedbackDate']),
      finishedDate:    _parseDate(json['finishedDate']),
      creationDate:    _parseDate(json['_creationDate']) ?? DateTime.now(),
      lastUpdate:      _parseDate(json['_lastUpdate']),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id':        id,
    'cycle':      {'_id': cycleId},
    'employee':   {'_id': employeeId},
    'appraiser':  {'_id': appraiserId},
    'status':     status.sydleValue,
    'tytleGroup1': tytleGroup1,
    'group1':      group1.map((e) => e.toJson()).toList(),
    'tytleGroup2': tytleGroup2,
    'group2':      group2.map((e) => e.toJson()).toList(),
    if (tytleGroup3 != null) 'tytleGroup3': tytleGroup3,
    if (group3 != null) 'group3': group3!.map((e) => e.toJson()).toList(),
    if (tytleGroup4 != null) 'tytleGroup4': tytleGroup4,
    if (group4 != null) 'group4': group4!.map((e) => e.toJson()).toList(),
    'Goals': goals.map((g) => g.toJson()).toList(),
    if (attentionPoints != null) 'attentionPoints': attentionPoints,
    if (strengths != null) 'strengths': strengths,
    if (feedback != null) 'feedback': feedback,
    if (actionPlan != null) 'actionPlan': actionPlan,
    'nextGoals': nextGoals,
  };

  bool get isReadOnly => status.isReadOnly;

  /// Lista de grupos ativos na avaliação (2 a 4 grupos).
  List<EvaluationGroup> get groups {
    final result = <EvaluationGroup>[
      EvaluationGroup(title: tytleGroup1, criteria: group1),
      EvaluationGroup(title: tytleGroup2, criteria: group2),
    ];
    if (tytleGroup3 != null && tytleGroup3!.isNotEmpty) {
      result.add(EvaluationGroup(title: tytleGroup3!, criteria: group3 ?? []));
    }
    if (tytleGroup4 != null && tytleGroup4!.isNotEmpty) {
      result.add(EvaluationGroup(title: tytleGroup4!, criteria: group4 ?? []));
    }
    return result;
  }

  /// Média geral sobre todos os critérios avaliados.
  double get overallAverage {
    final allScores = groups
        .expand((g) => g.criteria)
        .where((t) => t.evaluation != null)
        .map((t) => t.evaluation!.toDouble())
        .toList();
    if (allScores.isEmpty) return 0;
    return allScores.reduce((a, b) => a + b) / allScores.length;
  }

  static String _refId(dynamic ref) {
    if (ref is Map<String, dynamic>) return ref['_id'] as String? ?? '';
    return ref as String? ?? '';
  }

  static String _refStr(dynamic ref, String key) {
    if (ref is Map<String, dynamic>) return ref[key] as String? ?? '';
    return '';
  }

  static int _refInt(dynamic ref, String key) {
    if (ref is Map<String, dynamic>) return ref[key] as int? ?? 0;
    return 0;
  }

  static List<TabEvaluation> _parseTabList(dynamic raw) {
    final list = raw as List<dynamic>? ?? [];
    return list
        .map((e) => TabEvaluation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static List<TabGoal> _parseGoalList(dynamic raw) {
    final list = raw as List<dynamic>? ?? [];
    return list
        .map((e) => TabGoal.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
