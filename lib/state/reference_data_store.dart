import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/reference_item_dto.dart';
import '../services/reference_list_service.dart';
import 'load_status.dart';

/// Listas pré-definidas partilhadas entre ecrãs (modelo de classes, 8.1).
///
/// Não é de âmbito de sessão: a lista de localidades é precisa no registo,
/// antes do início de sessão (API v02, 6.13.1). A lista de competências exige
/// sessão (6.13.2) e tem um estado próprio (`skillsStatus`).
class ReferenceDataStore extends ChangeNotifier {
  ReferenceDataStore(this._service);

  final ReferenceListService _service;

  List<ReferenceItemDto> _locations = const [];
  LoadStatus _status = LoadStatus.idle;
  ApiException? _error;

  List<ReferenceItemDto> get locations => _locations;

  LoadStatus get status => _status;

  ApiException? get error => _error;

  List<ReferenceItemDto> _skills = const [];
  LoadStatus _skillsStatus = LoadStatus.idle;
  ApiException? _skillsError;

  List<ReferenceItemDto> get skills => _skills;

  LoadStatus get skillsStatus => _skillsStatus;

  ApiException? get skillsError => _skillsError;

  /// Pede a lista de localidades, uma vez; depois de uma falha, volta a pedir.
  Future<void> loadLocations() async {
    if (_status == LoadStatus.loading || _status == LoadStatus.loaded) {
      return;
    }
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _locations = List.unmodifiable(await _service.listLocations());
      _status = LoadStatus.loaded;
    } on ApiException catch (failure) {
      _error = failure;
      _status = LoadStatus.failed;
    }
    notifyListeners();
  }

  /// Pede a lista de competências, uma vez; depois de uma falha, volta a
  /// pedir (RF008).
  Future<void> loadSkills() async {
    if (_skillsStatus == LoadStatus.loading ||
        _skillsStatus == LoadStatus.loaded) {
      return;
    }
    _skillsStatus = LoadStatus.loading;
    _skillsError = null;
    notifyListeners();
    try {
      _skills = List.unmodifiable(await _service.listSkills());
      _skillsStatus = LoadStatus.loaded;
    } on ApiException catch (failure) {
      _skillsError = failure;
      _skillsStatus = LoadStatus.failed;
    }
    notifyListeners();
  }
}
