import '../models/reference_item_dto.dart';

/// Operações do `ReferenceListsController` usadas pelo Candidato (API 6.13).
abstract interface class ReferenceListService {
  /// Lista de localidades, sem credencial (6.13.1): usada no registo (RF003).
  Future<List<ReferenceItemDto>> listLocations();

  /// Lista de competências (6.13.2).
  Future<List<ReferenceItemDto>> listSkills();
}
