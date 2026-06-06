import 'auto_evaluation_model.dart';
import 'tab_evaluation_model.dart';
import 'tab_goal_model.dart';

enum EvaluationClassification {
  aboveLevel,
  atLevel,
  belowLevel;

  static EvaluationClassification? fromString(String? value) {
    switch (value) {
      case 'aboveLevel': return EvaluationClassification.aboveLevel;
      case 'atLevel':    return EvaluationClassification.atLevel;
      case 'belowLevel': return EvaluationClassification.belowLevel;
      default:           return null;
    }
  }

  String get sydleValue {
    switch (this) {
      case EvaluationClassification.aboveLevel: return 'aboveLevel';
      case EvaluationClassification.atLevel:    return 'atLevel';
      case EvaluationClassification.belowLevel: return 'belowLevel';
    }
  }

  String get label {
    switch (this) {
      case EvaluationClassification.aboveLevel: return 'Acima do nível';
      case EvaluationClassification.atLevel:    return 'No nível';
      case EvaluationClassification.belowLevel: return 'Abaixo do nível';
    }
  }
}

class LiderEvaluation {
  final String id;
  final String cycleId;
  final String cyclePeriod;
  final int cycleYear;
  final EvaluationStatus status;
  final String employeeId;
  final String employeeName;
  final String appraiserId;
  final String appraiserName;
  final List<TabEvaluation> behavioralEvaluation;
  final List<TabEvaluation> technicalEvaluation;
  final List<TabGoal> goals;
  final String? attentionPoints;
  final String? strengths;
  final String? feedback;
  final String? actionPlan;
  final List<String> nextGoals;
  final EvaluationClassification? classification;
  final bool topPerformer;
  final String? commentsPerfMeeting;
  final DateTime? evaluationDate;
  final DateTime? feedbackDate;
  final DateTime? finishedDate;
  final DateTime creationDate;
  final DateTime? lastUpdate;

  const LiderEvaluation({
    required this.id,
    required this.cycleId,
    this.cyclePeriod = '',
    this.cycleYear = 0,
    required this.status,
    required this.employeeId,
    this.employeeName = '',
    required this.appraiserId,
    this.appraiserName = '',
    this.behavioralEvaluation = const [],
    this.technicalEvaluation = const [],
    this.goals = const [],
    this.attentionPoints,
    this.strengths,
    this.feedback,
    this.actionPlan,
    this.nextGoals = const [],
    this.classification,
    this.topPerformer = false,
    this.commentsPerfMeeting,
    this.evaluationDate,
    this.feedbackDate,
    this.finishedDate,
    required this.creationDate,
    this.lastUpdate,
  });

  factory LiderEvaluation.fromJson(Map<String, dynamic> json) {
    return LiderEvaluation(
      id:          json['_id'] as String,
      cycleId:     _refId(json['cycle']),
      cyclePeriod: _refStr(json['cycle'], 'period'),
      cycleYear:   _refInt(json['cycle'], 'year'),
      status:      EvaluationStatus.fromString(json['status'] as String? ?? ''),
      employeeId:   _refId(json['employee']),
      employeeName: _refName(json['employee']),
      appraiserId:   _refId(json['appraiser']),
      appraiserName: _refName(json['appraiser']),
      behavioralEvaluation: _parseTabList(json['behavioralEvaluation']),
      technicalEvaluation:  _parseTabList(json['technicalEvaluation']),
      goals: _parseGoalList(json['Goals']),
      attentionPoints: json['attentionPoints'] as String?,
      strengths:       json['strengths'] as String?,
      feedback:        json['feedback'] as String?,
      actionPlan:      json['actionPlan'] as String?,
      nextGoals: List<String>.from(json['nextGoals'] as List<dynamic>? ?? []),
      classification: EvaluationClassification.fromString(json['classification'] as String?),
      topPerformer:   json['topPerformer'] as bool? ?? false,
      commentsPerfMeeting: json['commentsPerfMeeting'] as String?,
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
    if (classification != null) 'classification': classification!.sydleValue,
    'topPerformer': topPerformer,
    if (commentsPerfMeeting != null && commentsPerfMeeting!.isNotEmpty) 'commentsPerfMeeting': commentsPerfMeeting,
  };

  Map<String, dynamic> toPatchJson({
    EvaluationClassification? newClassification,
    bool? newTopPerformer,
  }) => {
    '_id': id,
    if (newClassification != null) 'classification': newClassification.sydleValue,
    if (newTopPerformer != null) 'topPerformer': newTopPerformer,
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

  /// Tenta extrair o nome de um campo de referência SYDLE.
  /// Cobre variações de nomenclatura: name, nomeCompleto, nome, displayName.
  static String _refName(dynamic ref) {
    if (ref is! Map<String, dynamic>) return '';
    for (final key in ['name', 'nomeCompleto', 'nome', 'displayName', 'fullName']) {
      final v = ref[key];
      if (v is String && v.isNotEmpty) return v;
    }
    return '';
  }

  static int _refInt(dynamic ref, String key) {
    if (ref is Map<String, dynamic>) return ref[key] as int? ?? 0;
    return 0;
  }

  static List<TabEvaluation> _parseTabList(dynamic raw) {
    final list = raw as List<dynamic>? ?? [];
    return list.map((e) => TabEvaluation.fromJson(e as Map<String, dynamic>)).toList();
  }

  static List<TabGoal> _parseGoalList(dynamic raw) {
    final list = raw as List<dynamic>? ?? [];
    return list.map((e) => TabGoal.fromJson(e as Map<String, dynamic>)).toList();
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
