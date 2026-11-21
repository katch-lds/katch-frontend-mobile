import '../core/api_client.dart';
import '../models/match_dto.dart';
import 'match_service.dart';
import 'response_reader.dart';

/// `MatchService` sobre a API v02 (`/api/matches`, 6.7.1).
class HttpMatchService implements MatchService {
  HttpMatchService(this._api);

  static const matchesPath = '/api/matches';

  final ApiClient _api;

  @override
  Future<List<MatchDto>> list() async {
    final result = await _api.get(matchesPath);
    return readModel(
      () => [for (final item in readList(result)) MatchDto.fromJson(item)],
    );
  }
}
