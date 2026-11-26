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

  late final _locations = _ReferenceList(
    _service.listLocations,
    notifyListeners,
  );

  late final _skills = _ReferenceList(_service.listSkills, notifyListeners);

  List<ReferenceItemDto> get locations => _locations.items;

  LoadStatus get status => _locations.status;

  ApiException? get error => _locations.error;

  List<ReferenceItemDto> get skills => _skills.items;

  LoadStatus get skillsStatus => _skills.status;

  ApiException? get skillsError => _skills.error;

  /// Pede a lista de localidades (ver `_ReferenceList.load`).
  Future<void> loadLocations() => _locations.load();

  /// Pede a lista de competências (RF008; ver `_ReferenceList.load`).
  Future<void> loadSkills() => _skills.load();
}

/// Uma lista pré-definida, com o estado e a falha do último pedido.
class _ReferenceList {
  _ReferenceList(this._fetch, this._onChange);

  final Future<List<ReferenceItemDto>> Function() _fetch;
  final VoidCallback _onChange;

  List<ReferenceItemDto> items = const [];
  LoadStatus status = LoadStatus.idle;
  ApiException? error;
  Future<void> _request = Future.value();

  /// Pede a lista, uma vez; quem pede durante o pedido em curso espera por
  /// ele; depois de uma falha, volta a pedir.
  Future<void> load() {
    switch (status) {
      case LoadStatus.loaded:
        return Future.value();
      case LoadStatus.loading:
        return _request;
      case LoadStatus.idle || LoadStatus.failed:
        status = LoadStatus.loading;
        error = null;
        _request = _fetchItems();
        _onChange();
        return _request;
    }
  }

  Future<void> _fetchItems() async {
    try {
      items = List.unmodifiable(await _fetch());
      status = LoadStatus.loaded;
    } on ApiException catch (failure) {
      error = failure;
      status = LoadStatus.failed;
    }
    _onChange();
  }
}
