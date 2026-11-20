import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/reference_item_dto.dart';
import '../services/reference_list_service.dart';
import 'load_status.dart';

/// Listas pré-definidas partilhadas entre ecrãs.
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
  Future<void> _locationsRequest = Future.value();

  List<ReferenceItemDto> get locations => _locations;

  LoadStatus get status => _status;

  ApiException? get error => _error;

  List<ReferenceItemDto> _skills = const [];
  LoadStatus _skillsStatus = LoadStatus.idle;
  ApiException? _skillsError;
  Future<void> _skillsRequest = Future.value();

  List<ReferenceItemDto> get skills => _skills;

  LoadStatus get skillsStatus => _skillsStatus;

  ApiException? get skillsError => _skillsError;

  /// Pede a lista de localidades, uma vez; quem pede durante o pedido em
  /// curso espera por ele; depois de uma falha, volta a pedir.
  Future<void> loadLocations() {
    switch (_status) {
      case LoadStatus.loaded:
        return Future.value();
      case LoadStatus.loading:
        return _locationsRequest;
      case LoadStatus.idle || LoadStatus.failed:
        _status = LoadStatus.loading;
        _error = null;
        _locationsRequest = _fetchLocations();
        notifyListeners();
        return _locationsRequest;
    }
  }

  Future<void> _fetchLocations() async {
    try {
      _locations = List.unmodifiable(await _service.listLocations());
      _status = LoadStatus.loaded;
    } on ApiException catch (failure) {
      _error = failure;
      _status = LoadStatus.failed;
    }
    notifyListeners();
  }

  /// Pede a lista de competências, uma vez; quem pede durante o pedido em
  /// curso espera por ele; depois de uma falha, volta a pedir (RF008).
  Future<void> loadSkills() {
    switch (_skillsStatus) {
      case LoadStatus.loaded:
        return Future.value();
      case LoadStatus.loading:
        return _skillsRequest;
      case LoadStatus.idle || LoadStatus.failed:
        _skillsStatus = LoadStatus.loading;
        _skillsError = null;
        _skillsRequest = _fetchSkills();
        notifyListeners();
        return _skillsRequest;
    }
  }

  Future<void> _fetchSkills() async {
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
