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
  final List<TabEvaluation> behavioralEvaluation;
  final List<TabEvaluation> technicalEvaluation;
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
    this.behavioralEvaluation = const [],
    this.technicalEvaluation = const [],
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
      employeeId:  _refId(json['employee']),
      appraiserId: _refId(json['appraiser']),
      behavioralEvaluation: _parseTabList(json['behavioralEvaluation']),
      technicalEvaluation:  _parseTabList(json['technicalEvaluation']),
      goals: _parseGoalList(json['Goals']),
      attentionPoints: json['attentionPoints'] as String?,
      strengths:      json['strengths'] as String?,
      feedback:       json['feedback'] as String?,
      actionPlan:     json['actionPlan'] as String?,
      nextGoals: List<String>.from(json['nextGoals'] as List<dynamic>? ?? []),
      evaluationDate: _parseDate(json['evaluationDate']),
      feedbackDate:   _parseDate(json['feedbackDate']),
      finishedDate:   _parseDate(json['finishedDate']),
      creationDate:   _parseDate(json['_creationDate']) ?? DateTime.now(),
      lastUpdate:     _parseDate(json['_lastUpdate']),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'cycle':     {'_id': cycleId},
    'employee':  {'_id': employeeId},
    'appraiser': {'_id': appraiserId},
    'status': status.sydleValue,
    'behavioralEvaluation': behavioralEvaluation.map((e) => e.toJson()).toList(),
    'technicalEvaluation':  technicalEvaluation.map((e) => e.toJson()).toList(),
    'Goals': goals.map((g) => g.toJson()).toList(),
    if (attentionPoints != null) 'attentionPoints': attentionPoints,
    if (strengths != null) 'strengths': strengths,
    if (feedback != null) 'feedback': feedback,
    if (actionPlan != null) 'actionPlan': actionPlan,
    'nextGoals': nextGoals,
  };

  bool get isReadOnly => status.isReadOnly;

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
