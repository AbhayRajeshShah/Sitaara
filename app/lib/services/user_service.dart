import '../models/user_profile.dart';
import 'api_client.dart';

/// Fetches the signed-in user's own account info.
class UserService {
  UserService(this._api);

  final ApiClient _api;

  Future<UserProfile> getMe() async {
    final data = await _api.get('/me') as Map<String, dynamic>;
    return UserProfile.fromJson(data);
  }
}
