class GateChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final bool isFromGuard;
  final String text;
  final DateTime timestamp;
  final bool isEmergency;
  final String? statusTag;

  const GateChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.isFromGuard,
    required this.text,
    required this.timestamp,
    this.isEmergency = false,
    this.statusTag,
  });
}

class ResidentChatThread {
  final String residentId;
  final String residentName;
  final String unitAddress;
  final String avatarInitials;
  final List<GateChatMessage> messages;
  final int unreadCount;
  final bool hasActiveEmergency;

  ResidentChatThread({
    required this.residentId,
    required this.residentName,
    required this.unitAddress,
    required this.avatarInitials,
    required this.messages,
    this.unreadCount = 0,
    this.hasActiveEmergency = false,
  });

  GateChatMessage? get lastMessage => messages.isNotEmpty ? messages.last : null;

  ResidentChatThread copyWith({
    String? residentId,
    String? residentName,
    String? unitAddress,
    String? avatarInitials,
    List<GateChatMessage>? messages,
    int? unreadCount,
    bool? hasActiveEmergency,
  }) {
    return ResidentChatThread(
      residentId: residentId ?? this.residentId,
      residentName: residentName ?? this.residentName,
      unitAddress: unitAddress ?? this.unitAddress,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      messages: messages ?? this.messages,
      unreadCount: unreadCount ?? this.unreadCount,
      hasActiveEmergency: hasActiveEmergency ?? this.hasActiveEmergency,
    );
  }
}
