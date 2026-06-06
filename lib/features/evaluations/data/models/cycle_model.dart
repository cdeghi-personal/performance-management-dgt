enum CycleStatus {
  notStarted,
  onGoing,
  finished,
  cancelled;

  static CycleStatus fromString(String value) {
    switch (value) {
      case 'OnGoing':   return CycleStatus.onGoing;
      case 'Finished':  return CycleStatus.finished;
      case 'Cancelled': return CycleStatus.cancelled;
      default:          return CycleStatus.notStarted;
    }
  }

  String get sydleValue {
    switch (this) {
      case CycleStatus.onGoing:    return 'OnGoing';
      case CycleStatus.finished:   return 'Finished';
      case CycleStatus.cancelled:  return 'Cancelled';
      case CycleStatus.notStarted: return 'notStarted';
    }
  }
}

enum PhaseIdentifier {
  started,
  selfEvaluation,
  leaderEvaluation,
  evaluationMeeting,
  results;

  static PhaseIdentifier fromString(String v) {
    switch (v) {
      case 'Started':           return PhaseIdentifier.started;
      case 'SelfEvaluation':    return PhaseIdentifier.selfEvaluation;
      case 'LeaderEvaluation':  return PhaseIdentifier.leaderEvaluation;
      case 'EvaluationMetting': return PhaseIdentifier.evaluationMeeting;
      case 'Results':           return PhaseIdentifier.results;
      default:                  return PhaseIdentifier.started;
    }
  }

  // Preserves 'EvaluationMetting' typo — exact value used in SYDLE backend.
  String get sydleValue {
    switch (this) {
      case PhaseIdentifier.started:           return 'Started';
      case PhaseIdentifier.selfEvaluation:    return 'SelfEvaluation';
      case PhaseIdentifier.leaderEvaluation:  return 'LeaderEvaluation';
      case PhaseIdentifier.evaluationMeeting: return 'EvaluationMetting';
      case PhaseIdentifier.results:           return 'Results';
    }
  }

  String get label {
    switch (this) {
      case PhaseIdentifier.started:           return 'Iniciada';
      case PhaseIdentifier.selfEvaluation:    return 'Auto-Avaliação';
      case PhaseIdentifier.leaderEvaluation:  return 'Avaliação Liderança';
      case PhaseIdentifier.evaluationMeeting: return 'Reunião Avaliações';
      case PhaseIdentifier.results:           return 'Finalização';
    }
  }
}

enum PhaseStatus {
  notStarted,
  onGoing,
  finished;

  static PhaseStatus fromString(String v) {
    switch (v) {
      case 'OnGoing':   return PhaseStatus.onGoing;
      case 'Finished':  return PhaseStatus.finished;
      default:          return PhaseStatus.notStarted;
    }
  }

  String get sydleValue {
    switch (this) {
      case PhaseStatus.onGoing:    return 'OnGoing';
      case PhaseStatus.finished:   return 'Finished';
      case PhaseStatus.notStarted: return 'notStarted';
    }
  }

  String get label {
    switch (this) {
      case PhaseStatus.notStarted: return 'Em breve';
      case PhaseStatus.onGoing:    return 'Em andamento';
      case PhaseStatus.finished:   return 'Concluída';
    }
  }
}

class TabPhase {
  final String id;
  final PhaseIdentifier phase;
  final PhaseStatus status;
  final DateTime? planDate;
  final DateTime? realDate;

  const TabPhase({
    required this.id,
    required this.phase,
    required this.status,
    this.planDate,
    this.realDate,
  });

  factory TabPhase.fromJson(Map<String, dynamic> json) {
    return TabPhase(
      id:       json['_id'] as String? ?? '',
      phase:    PhaseIdentifier.fromString(json['phase'] as String? ?? ''),
      status:   PhaseStatus.fromString(json['status'] as String? ?? ''),
      planDate: _parseDate(json['planDate']),
      realDate: _parseDate(json['realDate']),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) '_id': id,
    'phase': phase.sydleValue,
    'status': status.sydleValue,
    if (planDate != null) 'planDate': planDate!.millisecondsSinceEpoch,
    if (realDate != null) 'realDate': realDate!.millisecondsSinceEpoch,
  };

  TabPhase copyWith({
    PhaseStatus? status,
    DateTime? planDate,
    bool clearPlanDate = false,
  }) => TabPhase(
    id: id,
    phase: phase,
    status: status ?? this.status,
    planDate: clearPlanDate ? null : (planDate ?? this.planDate),
    realDate: realDate,
  );

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class Cycle {
  final String id;
  final String period;
  final int year;
  final CycleStatus status;
  final List<String> criteriaIds;
  final DateTime? cycleDate;
  final List<TabPhase> tabPhases;
  final DateTime creationDate;

  const Cycle({
    required this.id,
    required this.period,
    required this.year,
    required this.status,
    required this.criteriaIds,
    this.cycleDate,
    required this.tabPhases,
    required this.creationDate,
  });

  TabPhase? phaseFor(PhaseIdentifier p) =>
      tabPhases.where((t) => t.phase == p).firstOrNull;

  TabPhase? get startedPhase       => phaseFor(PhaseIdentifier.started);
  TabPhase? get selfEvalPhase      => phaseFor(PhaseIdentifier.selfEvaluation);
  TabPhase? get leaderEvalPhase    => phaseFor(PhaseIdentifier.leaderEvaluation);
  TabPhase? get meetingPhase       => phaseFor(PhaseIdentifier.evaluationMeeting);
  TabPhase? get resultsPhase       => phaseFor(PhaseIdentifier.results);

  factory Cycle.fromJson(Map<String, dynamic> json) {
    final rawCriteria = json['criteria'] as List<dynamic>? ?? [];
    final criteriaIds = rawCriteria.map((c) {
      if (c is Map<String, dynamic>) return c['_id'] as String;
      return c as String;
    }).toList();

    final rawPhases = json['tabPhases'] as List<dynamic>? ?? [];
    final tabPhases = rawPhases
        .whereType<Map<String, dynamic>>()
        .map(TabPhase.fromJson)
        .toList();

    return Cycle(
      id:           json['_id'] as String,
      period:       json['period'] as String? ?? '',
      year:         json['year'] as int? ?? 0,
      status:       CycleStatus.fromString(json['status'] as String? ?? ''),
      criteriaIds:  criteriaIds,
      cycleDate:    _parseDate(json['cycleDate']),
      tabPhases:    tabPhases,
      creationDate: _parseDate(json['_creationDate']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'period': period,
    'year': year,
    'status': status.sydleValue,
    'criteria': criteriaIds.map((cid) => {'_id': cid}).toList(),
    if (cycleDate != null) 'cycleDate': cycleDate!.millisecondsSinceEpoch,
    'tabPhases': tabPhases.map((p) => p.toJson()).toList(),
  };

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
