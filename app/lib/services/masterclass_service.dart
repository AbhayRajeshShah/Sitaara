import '../models/masterclass.dart';
import 'api_client.dart';

/// Fetches masterclass listings with per-family-member watch progress.
class MasterclassService {
  MasterclassService(this._api);

  final ApiClient _api;

  Future<List<MasterclassSummary>> list() async {
    final data = await _api.get('/masterclasses') as List;
    return data.map((e) => MasterclassSummary.fromJson(e as Map<String, dynamic>)).toList();
  }
}
