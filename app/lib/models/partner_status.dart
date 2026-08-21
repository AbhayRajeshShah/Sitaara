/// Whether the caller's family currently has two members. Mirrors the
/// backend's response for `GET /partner/status`.
class PartnerStatus {
  const PartnerStatus({required this.isConnected});

  final bool isConnected;

  factory PartnerStatus.fromJson(Map<String, dynamic> json) {
    return PartnerStatus(isConnected: json['isConnected'] as bool);
  }
}
