import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/field_errors.dart';
import 'failure_messages.dart';
import 'load_status.dart';
import 'safe_change_notifier.dart';

/// Base dos formulários que validam localmente e enviam um só pedido: os
/// motivos por campo, o estado do envio e a mensagem da falha.
abstract class FormController extends SafeChangeNotifier {
  FieldErrors _errors = FieldErrors();
  LoadStatus _status = LoadStatus.idle;
  String? _errorMessage;

  FieldErrors get errors => _errors;

  @protected
  set errors(FieldErrors value) => _errors = value;

  /// Estado do envio.
  LoadStatus get status => _status;

  /// Motivo geral da rejeição (por exemplo, falha de ligação, RNF014).
  String? get errorMessage => _errorMessage;

  @protected
  set errorMessage(String? value) => _errorMessage = value;

  /// Valida todos os campos e indica o motivo de cada um em causa.
  bool validate();

  /// Altera um campo e retira o motivo que lhe estava associado.
  @protected
  void edit(String field, void Function() change) {
    change();
    _errors.remove(field);
    notifyListeners();
  }

  /// Mostra os motivos da validação; devolve `true` se não há nenhum.
  @protected
  bool applyValidation(FieldErrors errors) {
    _errors = errors;
    notifyListeners();
    return errors.isEmpty;
  }

  /// Valida e, só depois, envia o pedido; devolve `true` em caso de êxito. Na
  /// rejeição, os motivos por campo e a mensagem são os do servidor.
  @protected
  Future<bool> send(Future<void> Function() request) async {
    if (_status == LoadStatus.loading || !validate()) {
      return false;
    }
    _status = LoadStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      await request();
      _status = LoadStatus.loaded;
      notifyListeners();
      return true;
    } on ApiRejection catch (rejection) {
      _status = LoadStatus.failed;
      _errors = FieldErrors.fromApi(rejection.error);
      _errorMessage = rejection.error.message;
    } on ApiException catch (failure) {
      _status = LoadStatus.failed;
      _errorMessage = failureMessage(failure);
    }
    notifyListeners();
    return false;
  }
}
