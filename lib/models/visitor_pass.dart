enum VisitorStatus {
  pending,
  checkedIn,
  checkedOut,
}

class VisitorPass {
  final String id;
  final String visitorName;
  final String code;
  VisitorStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  DateTime? checkedInAt;
  DateTime? checkedOutAt;
  String? bookoutCode;
  DateTime? bookoutExpiresAt;
  final bool isFrequent;

  VisitorPass({
    required this.id,
    required this.visitorName,
    required this.code,
    this.status = VisitorStatus.pending,
    required this.createdAt,
    required this.expiresAt,
    this.checkedInAt,
    this.checkedOutAt,
    this.bookoutCode,
    this.bookoutExpiresAt,
    this.isFrequent = false,
  });

  static DateTime parseTime(String value) => DateTime.parse(
          RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(value) ? value : '${value}Z')
      .toLocal();

  factory VisitorPass.fromJson(Map<String, dynamic> json) => VisitorPass(
        id: json['id'] as String,
        visitorName: json['visitor_name'] as String,
        code: json['code'] as String,
        status: json['status'] == 'checked_in'
            ? VisitorStatus.checkedIn
            : json['status'] == 'checked_out'
                ? VisitorStatus.checkedOut
                : VisitorStatus.pending,
        createdAt: parseTime(json['created_at'] as String),
        expiresAt: parseTime(json['expires_at'] as String),
        checkedInAt: json['checked_in_at'] == null
            ? null
            : parseTime(json['checked_in_at']),
        checkedOutAt: json['checked_out_at'] == null
            ? null
            : parseTime(json['checked_out_at']),
        bookoutCode: json['bookout_code'],
        bookoutExpiresAt: json['bookout_expires_at'] == null
            ? null
            : parseTime(json['bookout_expires_at']),
      );

  String get activityCode =>
      status == VisitorStatus.checkedOut && bookoutCode != null
          ? bookoutCode!
          : code;
  String get activitySummary =>
      '$visitorName · ${status == VisitorStatus.checkedOut && bookoutCode != null ? 'Exit' : 'Entry'} code: $activityCode';

  String get statusLabel {
    switch (status) {
      case VisitorStatus.pending:
        return 'Pending Entry';
      case VisitorStatus.checkedIn:
        return 'Checked In';
      case VisitorStatus.checkedOut:
        return 'Checked Out';
    }
  }

  VisitorPass copyWith({
    String? id,
    String? visitorName,
    String? code,
    VisitorStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? checkedInAt,
    DateTime? checkedOutAt,
    String? bookoutCode,
    DateTime? bookoutExpiresAt,
    bool? isFrequent,
  }) {
    return VisitorPass(
      id: id ?? this.id,
      visitorName: visitorName ?? this.visitorName,
      code: code ?? this.code,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      checkedOutAt: checkedOutAt ?? this.checkedOutAt,
      bookoutCode: bookoutCode ?? this.bookoutCode,
      bookoutExpiresAt: bookoutExpiresAt ?? this.bookoutExpiresAt,
      isFrequent: isFrequent ?? this.isFrequent,
    );
  }
}

class FrequentGuest {
  final String id;
  final String name;
  final String relationship; // e.g. "Family", "Delivery", "Friend", "Service"
  final DateTime lastVisited;

  const FrequentGuest({
    required this.id,
    required this.name,
    required this.relationship,
    required this.lastVisited,
  });
}
