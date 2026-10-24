enum GateActionType {
  entryGranted,
  exitGranted,
  accessDenied,
  emergencyAlert,
}

class GateLogEntry {
  final String id;
  final DateTime timestamp;
  final String visitorName;
  final String code;
  final String hostResident;
  final String hostUnit;
  final GateActionType actionType;
  final String gateLocation;
  final String officerName;
  final String verificationMethod;
  final String? denialReason;

  const GateLogEntry({
    required this.id,
    required this.timestamp,
    required this.visitorName,
    required this.code,
    required this.hostResident,
    required this.hostUnit,
    required this.actionType,
    this.gateLocation = 'Main Gate (Boom Barrier)',
    this.officerName = 'Security officer',
    this.verificationMethod = '5-Digit OTP Code',
    this.denialReason,
  });

  String get actionLabel {
    switch (actionType) {
      case GateActionType.entryGranted:
        return 'ENTRY CLEARED';
      case GateActionType.exitGranted:
        return 'EXIT CLEARED';
      case GateActionType.accessDenied:
        return 'ACCESS DENIED';
      case GateActionType.emergencyAlert:
        return 'SOS EMERGENCY';
    }
  }

  bool get isEntry => actionType == GateActionType.entryGranted;
  bool get isExit => actionType == GateActionType.exitGranted;
  bool get isDenied => actionType == GateActionType.accessDenied;
  bool get isEmergency => actionType == GateActionType.emergencyAlert;
}
