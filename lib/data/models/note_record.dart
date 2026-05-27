class NoteRecord {
  const NoteRecord({
    required this.id,
    required this.coupleSpaceId,
    required this.authorProfileId,
    required this.body,
    required this.authoredAt,
    required this.authorLocalDate,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String coupleSpaceId;
  final String authorProfileId;
  final String body;
  final DateTime authoredAt;
  final String authorLocalDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  factory NoteRecord.fromJson(Map<String, dynamic> json) {
    return NoteRecord(
      id: json['id'] as String,
      coupleSpaceId: json['couple_space_id'] as String,
      authorProfileId: json['author_profile_id'] as String,
      body: json['body'] as String,
      authoredAt: DateTime.parse(json['authored_at'] as String),
      authorLocalDate: json['author_local_date'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }
}
