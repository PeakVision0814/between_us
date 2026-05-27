class PlanRecord {
  const PlanRecord({
    required this.id,
    required this.coupleSpaceId,
    required this.createdBy,
    required this.title,
    this.body,
    required this.status,
    this.scheduledEventId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String coupleSpaceId;
  final String createdBy;
  final String title;
  final String? body;
  final String status;
  final String? scheduledEventId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  factory PlanRecord.fromJson(Map<String, dynamic> json) {
    return PlanRecord(
      id: json['id'] as String,
      coupleSpaceId: json['couple_space_id'] as String,
      createdBy: json['created_by'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
      status: json['status'] as String,
      scheduledEventId: json['scheduled_event_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }
}
