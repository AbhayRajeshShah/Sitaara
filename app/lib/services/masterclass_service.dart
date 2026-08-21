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
}
