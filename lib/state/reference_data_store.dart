import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/reference_item_dto.dart';
import '../services/reference_list_service.dart';
import 'load_status.dart';

/// Listas pré-definidas partilhadas entre ecrãs (modelo de classes, 8.1).
///
/// Não é de âmbito de sessão: a lista de localidades é precisa no registo,
/// antes do início de sessão (API v02, 6.13.1).
class ReferenceDataStore extends ChangeNotifier {
  ReferenceDataStore(this._service);

  final ReferenceListService _service;

  List<ReferenceItemDto> _locations = const [];
  LoadStatus _status = LoadStatus.idle;
  ApiException? _error;

  List<ReferenceItemDto> get locations => _locations;

  LoadStatus get status => _status;

  ApiException? get error => _error;

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
}
