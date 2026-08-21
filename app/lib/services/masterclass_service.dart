import '../models/masterclass.dart';
import '../models/masterclass_detail.dart';
import 'api_client.dart';

/// Fetches masterclass listings and detail, with per-family-member watch
/// progress on the listing.
class MasterclassService {
  MasterclassService(this._api);

  final ApiClient _api;

  Future<List<MasterclassSummary>> list() async {
    final data = await _api.get('/masterclasses') as List;
    return data.map((e) => MasterclassSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MasterclassDetail> getDetail(String id) async {
    final data = await _api.get('/masterclasses/$id') as Map<String, dynamic>;
    return MasterclassDetail.fromJson(data);
  }

  /// Toggles the caller's like state for a video: likes it if not already
  /// liked, unlikes it otherwise. Returns the resulting `liked` state.
  Future<bool> toggleLike(String videoId) async {
    final data = await _api.post('/videos/$videoId/like') as Map<String, dynamic>;
    return data['liked'] as bool;
  }

  /// Reports the caller's current playback position for a video. The
  /// backend keeps whichever is furthest, so this is safe to call
  /// repeatedly with any position. Returns the stored (furthest-watched)
  /// position, which may be greater than [watchedSeconds].
  Future<int> updateProgress(String videoId, int watchedSeconds) async {
    final data =
        await _api.post('/videos/$videoId/progress', body: {'watchedSeconds': watchedSeconds}) as Map<String, dynamic>;
    return data['watchedSeconds'] as int;
  }
}
