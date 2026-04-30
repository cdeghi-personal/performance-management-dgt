enum MeetingStatus { scheduled, inProgress, completed, cancelled }

class ExecutiveMeeting {
  final String id;
  final String title;
  final MeetingStatus status;
  final DateTime scheduledAt;
  final String facilitatorId;
  final String facilitatorName;
  final List<String> participantIds;
  final List<String> participantNames;
  final List<MeetingAgendaItem> agendaItems;
  final String? notes;
  final DateTime? completedAt;

  const ExecutiveMeeting({
    required this.id,
    required this.title,
    required this.status,
    required this.scheduledAt,
    required this.facilitatorId,
    required this.facilitatorName,
    this.participantIds = const [],
    this.participantNames = const [],
    this.agendaItems = const [],
    this.notes,
    this.completedAt,
  });

  factory ExecutiveMeeting.fromJson(Map<String, dynamic> json) => ExecutiveMeeting(
        id: json['id'] as String,
        title: json['title'] as String,
        status: MeetingStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => MeetingStatus.scheduled,
        ),
        scheduledAt: DateTime.parse(json['scheduled_at'] as String),
        facilitatorId: json['facilitator_id'] as String,
        facilitatorName: json['facilitator_name'] as String? ?? '',
        participantIds: List<String>.from(json['participant_ids'] as List? ?? []),
        participantNames: List<String>.from(json['participant_names'] as List? ?? []),
        agendaItems: (json['agenda_items'] as List<dynamic>?)
                ?.map((e) => MeetingAgendaItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        notes: json['notes'] as String?,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
      );
}

class MeetingAgendaItem {
  final String id;
  final String employeeId;
  final String employeeName;
  final String topic;
  final String? discussion;
  final String? actionItems;
  final bool reviewed;

  const MeetingAgendaItem({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.topic,
    this.discussion,
    this.actionItems,
    this.reviewed = false,
  });

  factory MeetingAgendaItem.fromJson(Map<String, dynamic> json) => MeetingAgendaItem(
        id: json['id'] as String,
        employeeId: json['employee_id'] as String,
        employeeName: json['employee_name'] as String? ?? '',
        topic: json['topic'] as String,
        discussion: json['discussion'] as String?,
        actionItems: json['action_items'] as String?,
        reviewed: json['reviewed'] as bool? ?? false,
      );
}