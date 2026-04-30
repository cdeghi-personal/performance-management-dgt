enum FeedbackType { positive, developmental, recognition }

enum FeedbackVisibility { publicVisible, managerOnly, private }

class FeedbackEntry {
  final String id;
  final FeedbackType type;
  final String fromId;
  final String fromName;
  final String? fromAvatarUrl;
  final String toId;
  final String toName;
  final String message;
  final FeedbackVisibility visibility;
  final DateTime createdAt;
  final String? relatedGoalId;
  final String? relatedGoalTitle;

  const FeedbackEntry({
    required this.id,
    required this.type,
    required this.fromId,
    required this.fromName,
    this.fromAvatarUrl,
    required this.toId,
    required this.toName,
    required this.message,
    required this.visibility,
    required this.createdAt,
    this.relatedGoalId,
    this.relatedGoalTitle,
  });

  factory FeedbackEntry.fromJson(Map<String, dynamic> json) => FeedbackEntry(
        id: json['id'] as String,
        type: FeedbackType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => FeedbackType.developmental,
        ),
        fromId: json['from_id'] as String,
        fromName: json['from_name'] as String? ?? '',
        fromAvatarUrl: json['from_avatar_url'] as String?,
        toId: json['to_id'] as String,
        toName: json['to_name'] as String? ?? '',
        message: json['message'] as String,
        visibility: FeedbackVisibility.values.firstWhere(
          (e) => e.name == json['visibility'],
          orElse: () => FeedbackVisibility.managerOnly,
        ),
        createdAt: DateTime.parse(json['created_at'] as String),
        relatedGoalId: json['related_goal_id'] as String?,
        relatedGoalTitle: json['related_goal_title'] as String?,
      );
}