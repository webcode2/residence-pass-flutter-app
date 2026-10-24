class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final List<String> roles;
  final String? houseNumber;
  final String? streetName;
  final String? landlordId;
  final String? rfidTag;
  final String? appId;
  final bool isRevoked;
  final bool mustChangePassword;
  final String? relationshipType;
  final String? phone;

  UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.roles = const ['resident'],
    this.houseNumber,
    this.streetName,
    this.landlordId,
    this.rfidTag,
    this.appId,
    this.isRevoked = false,
    this.mustChangePassword = false,
    this.relationshipType,
    this.phone,
  });

  bool get isResident => roles.any((r) => r.toLowerCase() == 'resident');
  bool get isLandlord => roles.any((r) => r.toLowerCase() == 'landlord');
  bool get isCaretaker => roles.any((r) => r.toLowerCase() == 'caretaker');
  bool get isGuard => roles
      .any((r) => ['guard', 'security', 'gatehouse'].contains(r.toLowerCase()));
  bool get isSaasOwner => roles.any((r) => r.toLowerCase() == 'saas_owner');

  bool get hasMultipleRoles =>
      roles.length > 1 ||
      (isGuard && (isResident || isLandlord || isCaretaker));
  bool get canSwitchToGatehouse => isGuard;
  bool get canSwitchToResident =>
      isResident || isLandlord || isCaretaker || roles.isEmpty;

  String get roleTitle {
    if (hasMultipleRoles) {
      final titles = <String>[];
      if (isResident) titles.add('Resident');
      if (isGuard) titles.add('Security');
      if (isLandlord) titles.add('Host');
      if (isCaretaker) titles.add('Caretaker');
      return titles.join(' • ');
    }
    if (isGuard) return 'Gatehouse Security';
    if (isLandlord) return 'Host';
    if (isCaretaker) return 'Estate Caretaker';
    return 'Resident';
  }

  String get displayName =>
      fullName?.trim().isNotEmpty == true ? fullName! : email.split('@').first;

  String get unitAddress {
    final parts = [houseNumber, streetName]
        .where((s) => s != null && s.trim().isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts.join(', ') : 'Unit not assigned';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedRoles = [];
    if (json['roles'] is List) {
      parsedRoles = (json['roles'] as List).map((e) => e.toString()).toList();
    }

    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? json['fullName']?.toString(),
      roles: parsedRoles.isNotEmpty ? parsedRoles : ['resident'],
      houseNumber:
          json['house_number']?.toString() ?? json['houseNumber']?.toString(),
      streetName:
          json['street_name']?.toString() ?? json['streetName']?.toString(),
      landlordId:
          json['landlord_id']?.toString() ?? json['landlordId']?.toString(),
      rfidTag: json['rfid_tag']?.toString() ?? json['rfidTag']?.toString(),
      appId: json['app_id']?.toString() ?? json['appId']?.toString(),
      mustChangePassword: json["must_change_password"] == true,
      relationshipType: json["relationship_type"]?.toString(),
      phone: json["phone"]?.toString(),
      isRevoked: json['is_revoked'] == true || json['isRevoked'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'roles': roles,
      'house_number': houseNumber,
      'street_name': streetName,
      'landlord_id': landlordId,
      'rfid_tag': rfidTag,
      'app_id': appId,
      'is_revoked': isRevoked,
      'must_change_password': mustChangePassword,
      'phone': phone,
      'relationship_type': relationshipType,
    };
  }
}
