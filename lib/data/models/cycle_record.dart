class CycleRecord {
  const CycleRecord({
    required this.id,
    required this.coupleSpaceId,
    required this.ownerProfileId,
    required this.periodStartDate,
    this.periodEndDate,
    this.note,
    this.sharedWithPartner = false,
    this.ownerCycleSharingEnabled = true,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String coupleSpaceId;
  final String ownerProfileId;
  final DateTime periodStartDate;
  final DateTime? periodEndDate;
  final String? note;
  final bool sharedWithPartner;
  final bool ownerCycleSharingEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  factory CycleRecord.fromJson(Map<String, dynamic> json) {
    return CycleRecord(
      id: json['id'] as String,
      coupleSpaceId: json['couple_space_id'] as String,
      ownerProfileId: json['owner_profile_id'] as String,
      periodStartDate: _parseDate(json['period_start_date']),
      periodEndDate: json['period_end_date'] != null
          ? _parseDate(json['period_end_date'])
          : null,
      note: json['note'] as String?,
      sharedWithPartner: json['shared_with_partner'] as bool? ?? false,
      ownerCycleSharingEnabled:
          json['owner_cycle_sharing_enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'couple_space_id': coupleSpaceId,
      'owner_profile_id': ownerProfileId,
      'period_start_date': _formatDate(periodStartDate),
      'period_end_date': periodEndDate == null
          ? null
          : _formatDate(periodEndDate!),
      'note': note,
      'shared_with_partner': sharedWithPartner,
      'owner_cycle_sharing_enabled': ownerCycleSharingEnabled,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day);
    }
    return DateTime.parse(value as String);
  }

  static String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
