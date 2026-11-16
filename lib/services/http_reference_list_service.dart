import '../core/api_client.dart';
import '../models/reference_item_dto.dart';
import 'reference_list_service.dart';
import 'response_reader.dart';

/// `ReferenceListService` sobre a API v02 (`/api/reference-lists`, 6.13).
class HttpReferenceListService implements ReferenceListService {
  HttpReferenceListService(this._api);

  static const locationsPath = '/api/reference-lists/locations';
  static const skillsPath = '/api/reference-lists/skills';

  final ApiClient _api;

  @override
  Future<List<ReferenceItemDto>> listLocations() => _list(locationsPath);

  @override
  Future<List<ReferenceItemDto>> listSkills() => _list(skillsPath);

  Future<List<ReferenceItemDto>> _list(String path) async {
    final result = await _api.get(path);
    return readModel(
      () => [
        for (final item in readList(result)) ReferenceItemDto.fromJson(item),
      ],
    );
  }
}
