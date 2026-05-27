class CalendarEventRecord {
  const CalendarEventRecord({
    required this.id,
    required this.coupleSpaceId,
    required this.createdBy,
    required this.eventType,
    required this.title,
    this.description,
    required this.startsAt,
    this.endsAt,
    this.allDay = false,
    this.recurrence = 'none',
    this.sourcePlanId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String coupleSpaceId;
  final String createdBy;
  final String eventType;
  final String title;
  final String? description;
  final DateTime startsAt;
  final DateTime? endsAt;
  final bool allDay;
  final String recurrence;
  final String? sourcePlanId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  factory CalendarEventRecord.fromJson(Map<String, dynamic> json) {
    return CalendarEventRecord(
      id: json['id'] as String,
      coupleSpaceId: json['couple_space_id'] as String,
      createdBy: json['created_by'] as String,
      eventType: json['event_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: json['ends_at'] != null
          ? DateTime.parse(json['ends_at'] as String)
          : null,
      allDay: json['all_day'] as bool? ?? false,
      recurrence: json['recurrence'] as String? ?? 'none',
      sourcePlanId: json['source_plan_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }
}
