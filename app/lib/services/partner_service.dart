import '../models/invite_code.dart';
import '../models/partner_status.dart';
import 'api_client.dart';

/// Partner-linking endpoints: checking connection status, generating/
/// fetching the family's invite code, and redeeming another family's code.
class PartnerService {
  PartnerService(this._api);

  final ApiClient _api;

  Future<PartnerStatus> getStatus() async {
    final data = await _api.get('/partner/status') as Map<String, dynamic>;
    return PartnerStatus.fromJson(data);
  }

  /// Mints a fresh invite code for the caller's family, rotating out any
  /// previous unredeemed one.
  Future<InviteCode> generateInviteCode() async {
    final data = await _api.post('/invite-codes') as Map<String, dynamic>;
    return InviteCode.fromJson(data);
  }

  /// The caller's family's current unredeemed invite code, or null if none
  /// exists yet (backend 404s `no_active_invite`).
  Future<InviteCode?> getActiveInviteCode() async {
    try {
      final data = await _api.get('/invite-codes/active') as Map<String, dynamic>;
      return InviteCode.fromJson(data);
    } on ApiException catch (e) {
      if (e.code == 'no_active_invite') return null;
      rethrow;
    }
  }

  /// Redeems [code], switching the caller into that family. Throws
  /// [ApiException] on failure (invalid/used code, business-rule conflicts).
  Future<void> redeem(String code) async {
    await _api.post('/invite-codes/$code/redeem');
  }
}
