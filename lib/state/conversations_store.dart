import 'dart:async';

import '../core/api_exception.dart';
import '../models/conversation_summary_dto.dart';
import '../polling/app_lifecycle_monitor.dart';
import '../polling/polling_loop.dart';
import '../services/conversation_service.dart';
import '../session/session_manager.dart';
import 'failure_messages.dart';
import 'load_status.dart';
import 'session_scoped_store.dart';

/// Lista de conversas do Candidato e total de mensagens por ler (modelo de
/// classes, 8.1 e 8.5; secção 7).
///
/// Enquanto a lista de conversas (M16) está apresentada (`watchList(true)`) e
/// a aplicação está em primeiro plano, a lista é pedida de 3 em 3 segundos
/// (RF027, RF029). Fora de M16, é pedida uma vez quando o Candidato escolhe os
/// separadores «Matches» ou «Conversas» e quando a aplicação volta ao primeiro
/// plano, para o contador do separador (regra 7 da secção 7). A conversa aberta
/// (`ChatController`) entrega-lhe a lista que pede na sua consulta periódica.
class ConversationsStore extends SessionScopedStore {
  ConversationsStore({
    required ConversationService service,
    required SessionManager session,
    required AppLifecycleMonitor lifecycle,
    Duration interval = PollingLoop.defaultInterval,
  }) : _service = service,
       _lifecycle = lifecycle,
       _inForeground = lifecycle.inForeground,
       super(session) {
    _polling = PollingLoop(_poll, interval: interval);
    _lifecycle.addListener(_onLifecycleChanged);
  }

  final ConversationService _service;
  final AppLifecycleMonitor _lifecycle;
  late final PollingLoop _polling;

  List<ConversationSummaryDto> _conversations = const [];
  LoadStatus _status = LoadStatus.idle;
  String? _message;
  bool _watching = false;
  bool _inForeground;

  /// Aumenta em cada `reset()`, para ignorar respostas pedidas antes do fim
  /// de sessão.
  int _generation = 0;

  /// Conversas, pela ordem da API: as mais recentes primeiro (6.8.1).
  List<ConversationSummaryDto> get conversations => _conversations;

  LoadStatus get status => _status;

  /// Motivo da última falha, ou `null`.
  String? get message => _message;

  /// Total de mensagens por ler, para o separador «Conversas» (RF027).
  int get unreadMessages {
    var total = 0;
    for (final conversation in _conversations) {
      total += conversation.unreadCount;
    }
    return total;
  }

  /// A lista está a ser consultada periodicamente.
  bool get isPolling => _polling.isRunning;

  /// Resumo da conversa do match, ou `null` se ainda não estiver na lista.
  ConversationSummaryDto? find(String matchId) {
    for (final conversation in _conversations) {
      if (conversation.matchId == matchId) {
        return conversation;
      }
    }
    return null;
  }

  /// Pede a lista uma vez.
  Future<void> load() async {
    final generation = _generation;
    if (_conversations.isEmpty) {
      _status = LoadStatus.loading;
      _message = null;
      notifyListeners();
    }
    try {
      final conversations = await _service.list();
      if (generation != _generation) {
        return;
      }
      _conversations = conversations;
      _status = LoadStatus.loaded;
      _message = null;
    } on ApiException catch (failure) {
      if (generation != _generation) {
        return;
      }
      _message = failureMessage(failure);
      if (_conversations.isEmpty) {
        _status = LoadStatus.failed;
      }
    }
    notifyListeners();
  }

  /// Ativa a consulta periódica com M16 apresentado e desativa-a quando deixa
  /// de o estar (secção 7, regra 1).
  void watchList(bool active) {
    _watching = active;
    _syncPolling();
  }

  /// Lista obtida pela consulta periódica de uma conversa aberta (secção 7,
  /// regra 5).
  void replace(List<ConversationSummaryDto> conversations) {
    _conversations = conversations;
    _status = LoadStatus.loaded;
    _message = null;
    notifyListeners();
  }

  Future<void> _poll() => load();

  void _syncPolling() {
    if (_watching && _inForeground) {
      _polling.start();
    } else {
      _polling.stop();
    }
  }

  /// Em segundo plano não há consultas; ao voltar ao primeiro plano, a lista
  /// é pedida logo, para o contador do separador (regra 7).
  void _onLifecycleChanged() {
    final foreground = _lifecycle.inForeground;
    final returned = foreground && !_inForeground;
    _inForeground = foreground;
    _syncPolling();
    if (returned && !_watching && _status != LoadStatus.idle) {
      unawaited(load());
    }
  }

  @override
  void reset() {
    _generation++;
    _watching = false;
    _polling.stop();
    _conversations = const [];
    _status = LoadStatus.idle;
    _message = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _polling.stop();
    _lifecycle.removeListener(_onLifecycleChanged);
    super.dispose();
  }
}
