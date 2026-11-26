import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../core/external_launcher.dart';
import '../models/match_dto.dart';
import '../services/match_service.dart';
import 'failure_messages.dart';
import 'load_status.dart';

/// Estado dos ecrãs M14 (lista de matches) e M15 (contacto da Empresa), do
/// UC13.
///
/// A lista é pedida ao abrir o separador «Matches», que é onde o Candidato vê
/// um novo match (DA v04, F008). Os contactos já vêm no `MatchDto`, pelo que
/// M15 não faz novo pedido (RF025).
class MatchesController extends ChangeNotifier {
  MatchesController({
    required MatchService service,
    required ExternalLauncher launcher,
  }) : _service = service,
       _launcher = launcher;

  /// Indicação de que a aplicação de correio eletrónico não abriu.
  static const emailFailedMessage =
      'Não foi possível abrir a aplicação de correio eletrónico.';

  /// Indicação de que o marcador de chamadas não abriu.
  static const phoneFailedMessage =
      'Não foi possível abrir a aplicação de chamadas.';

  final MatchService _service;
  final ExternalLauncher _launcher;

  List<MatchDto> _matches = const [];
  LoadStatus _status = LoadStatus.idle;
  String? _message;
  bool _disposed = false;

  /// Aumenta em cada pedido, para ignorar respostas antigas.
  int _generation = 0;

  /// Matches, do mais recente para o mais antigo (RF024).
  List<MatchDto> get matches => _matches;

  LoadStatus get status => _status;

  /// Motivo da última falha, ou `null`.
  String? get message => _message;

  /// Pede a lista de matches (6.7.1).
  Future<void> load() async {
    final generation = ++_generation;
    if (_matches.isEmpty) {
      _status = LoadStatus.loading;
    }
    _message = null;
    _notify();
    try {
      final matches = await _service.list();
      if (generation != _generation) {
        return;
      }
      _matches = matches;
      _status = LoadStatus.loaded;
    } on ApiException catch (failure) {
      if (generation != _generation) {
        return;
      }
      _message = failureMessage(failure);
      if (_matches.isEmpty) {
        _status = LoadStatus.failed;
      }
    }
    _notify();
  }

  /// Match com o identificador indicado, ou `null`.
  MatchDto? find(String matchId) {
    for (final match in _matches) {
      if (match.matchId == matchId) {
        return match;
      }
    }
    return null;
  }

  /// Abre a aplicação de correio eletrónico com o contacto da Empresa (RF025).
  Future<void> openEmail(MatchDto match) async {
    final opened = await _launcher.openEmail(match.contactEmail);
    _message = opened ? null : emailFailedMessage;
    _notify();
  }

  /// Abre o marcador de chamadas com o contacto da Empresa (RF025).
  Future<void> openPhone(MatchDto match) async {
    final opened = await _launcher.openPhone(match.contactPhone);
    _message = opened ? null : phoneFailedMessage;
    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
