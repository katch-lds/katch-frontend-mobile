import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../core/input_rules.dart';
import '../models/conversation_summary_dto.dart';
import '../models/message_dto.dart';
import '../polling/app_lifecycle_monitor.dart';
import '../polling/polling_loop.dart';
import '../services/conversation_service.dart';
import '../session/session_manager.dart';
import 'conversations_store.dart';
import 'failure_messages.dart';
import 'load_status.dart';

/// Estado dos ecrãs M17 (conversa) e M18 (conversa só de consulta), do UC14.
///
/// Abre a conversa com o histórico completo, que o servidor marca como lido
/// (RF028, RF108), envia (RF026) e encerra (RF030). Enquanto o ecrã está
/// aberto e a aplicação em primeiro plano, `poll()` corre de 3 em 3 segundos:
/// pede as mensagens novas e a lista de conversas, de onde vem o estado da
/// conversa (RF029, RF075). As mensagens são juntadas por `messageId`, sem
/// duplicados.
///
/// Indicação de leitura (RF028): enquanto houver mensagens do Candidato por
/// ler, a consulta usa como `after` o `sentAt` da mensagem anterior à mais
/// antiga dessas, para o servidor devolver também as mensagens do Candidato
/// com o `readAt` atualizado; sem mensagens próprias por ler, usa o `sentAt` da
/// última mensagem recebida.
class ChatController extends ChangeNotifier {
  ChatController({
    required ConversationService service,
    required ConversationsStore store,
    required SessionManager session,
    required AppLifecycleMonitor lifecycle,
    Duration interval = PollingLoop.defaultInterval,
  }) : _service = service,
       _store = store,
       _session = session,
       _lifecycle = lifecycle {
    _messagesPolling = PollingLoop(_pollTask, interval: interval);
    _lifecycle.addListener(_onLifecycleChanged);
  }

  /// Comprimento máximo de uma mensagem (P03).
  static const maxLength = InputRules.maxMessageLength;

  /// Conversa em modo apenas de consulta (ERR-36) ou sem match (ERR-37):
  /// o estado da conversa é lido de novo.
  static const readOnlyCodes = {'ERR-36', 'ERR-37'};

  final ConversationService _service;
  final ConversationsStore _store;
  final SessionManager _session;
  final AppLifecycleMonitor _lifecycle;
  late final PollingLoop _messagesPolling;

  String? _matchId;
  List<MessageDto> _messages = const [];
  String _draft = '';
  LoadStatus _status = LoadStatus.idle;
  String? _errorMessage;
  bool _sending = false;
  bool _closing = false;
  bool _disposed = false;

  String? get matchId => _matchId;

  /// Resumo da conversa (Empresa, vaga, estado, motivo e quem encerrou).
  ConversationSummaryDto? get summary {
    final matchId = _matchId;
    return matchId == null ? null : _store.find(matchId);
  }

  /// Histórico, da mensagem mais antiga para a mais recente (RF028).
  List<MessageDto> get messages => _messages;

  String get draft => _draft;

  int get draftLength => _draft.length;

  LoadStatus get status => _status;

  /// Motivo da última rejeição ou falha, ou `null`.
  String? get errorMessage => _errorMessage;

  bool get isSending => _sending;

  bool get isClosing => _closing;

  /// Conversa em modo apenas de consulta: M18 (RF030, RF075).
  bool get isReadOnly => summary?.isReadOnly ?? false;

  /// A conversa foi encerrada pelo próprio Candidato.
  bool get closedByMe {
    final closedBy = summary?.closedBy;
    return closedBy != null && closedBy == _session.userId;
  }

  /// Envio possível: conversa aberta e texto de 1 a 1000 caracteres, não só
  /// espaços (P03, RF026).
  bool get canSend =>
      _status == LoadStatus.loaded &&
      !isReadOnly &&
      !_sending &&
      InputRules.isValidMessage(_draft);

  /// A consulta periódica está ativa.
  bool get isPolling => _messagesPolling.isRunning;

  /// A mensagem foi enviada pelo Candidato da sessão.
  bool isOwn(MessageDto message) => message.senderId == _session.userId;

  /// Abre a conversa do match: histórico completo e resumo (6.8.1, 6.8.2).
  Future<void> open(String matchId) async {
    _matchId = matchId;
    _status = LoadStatus.loading;
    _errorMessage = null;
    _notify();
    try {
      if (_store.find(matchId) == null) {
        _store.replace(await _service.list());
      }
      final messages = await _service.open(matchId);
      if (_disposed) {
        return;
      }
      _messages = const [];
      _merge(messages);
      _status = LoadStatus.loaded;
    } on ApiException catch (failure) {
      if (_disposed) {
        return;
      }
      _status = LoadStatus.failed;
      _errorMessage = failureMessage(failure);
    }
    _notify();
    _syncPolling();
  }

  /// Texto da mensagem a enviar.
  void updateDraft(String value) {
    _draft = value;
    _notify();
  }

  /// Envia a mensagem escrita (RF026). A mensagem gravada entra logo no
  /// histórico.
  Future<void> send() async {
    final matchId = _matchId;
    if (matchId == null || !canSend) {
      return;
    }
    _sending = true;
    _errorMessage = null;
    _notify();
    try {
      final message = await _service.send(matchId, SendMessageRequest(_draft));
      if (_disposed) {
        return;
      }
      _merge([message]);
      _draft = '';
    } on ApiRejection catch (rejection) {
      if (_disposed) {
        return;
      }
      _errorMessage = rejection.message;
      if (readOnlyCodes.contains(rejection.error.code)) {
        await _refreshSummary();
      }
    } on ApiException catch (failure) {
      if (_disposed) {
        return;
      }
      _errorMessage = failureMessage(failure);
    } finally {
      _sending = false;
    }
    _notify();
  }

  /// Encerra a conversa (RF030) e lê de novo a lista, para obter o estado, o
  /// motivo e a parte que encerrou.
  Future<void> close() async {
    final matchId = _matchId;
    if (matchId == null || isReadOnly || _closing) {
      return;
    }
    _closing = true;
    _errorMessage = null;
    _notify();
    try {
      await _service.close(matchId);
      if (_disposed) {
        return;
      }
      _draft = '';
      await _refreshSummary();
    } on ApiRejection catch (rejection) {
      if (_disposed) {
        return;
      }
      _errorMessage = rejection.message;
      if (readOnlyCodes.contains(rejection.error.code)) {
        await _refreshSummary();
      }
    } on ApiException catch (failure) {
      if (_disposed) {
        return;
      }
      _errorMessage = failureMessage(failure);
    } finally {
      _closing = false;
    }
    _notify();
  }

  /// Consulta periódica: mensagens novas e estado da conversa.
  @visibleForTesting
  Future<void> poll() => _pollTask();

  Future<void> _pollTask() async {
    final matchId = _matchId;
    if (matchId == null || _disposed || _status != LoadStatus.loaded) {
      return;
    }
    final received = await _service.open(matchId, after: _pollAfter());
    if (_disposed || matchId != _matchId) {
      return;
    }
    _merge(received);
    final conversations = await _service.list();
    if (_disposed) {
      return;
    }
    _store.replace(conversations);
    _notify();
  }

  /// `after` da consulta seguinte; `null` pede o histórico completo.
  DateTime? _pollAfter() {
    if (_messages.isEmpty) {
      return null;
    }
    for (var index = 0; index < _messages.length; index++) {
      final message = _messages[index];
      if (isOwn(message) && message.readAt == null) {
        return index == 0 ? null : _messages[index - 1].sentAt;
      }
    }
    return _messages.last.sentAt;
  }

  /// Junta as mensagens por `messageId`: uma mensagem já conhecida é
  /// substituída (por exemplo, com o `readAt` preenchido) e as novas são
  /// acrescentadas, por ordem de envio.
  void _merge(List<MessageDto> received) {
    if (received.isEmpty) {
      return;
    }
    final byId = <String, MessageDto>{
      for (final message in _messages) message.messageId: message,
    };
    for (final message in received) {
      byId[message.messageId] = message;
    }
    final merged = byId.values.toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    _messages = merged;
  }

  Future<void> _refreshSummary() async {
    try {
      final conversations = await _service.list();
      if (!_disposed) {
        _store.replace(conversations);
      }
    } on ApiException {
      // O estado é lido de novo na consulta periódica seguinte.
    }
  }

  void _syncPolling() {
    if (!_disposed && _status == LoadStatus.loaded && _lifecycle.inForeground) {
      _messagesPolling.start();
    } else {
      _messagesPolling.stop();
    }
  }

  /// Em segundo plano a consulta suspende-se; ao voltar ao primeiro plano,
  /// consulta logo e retoma o ciclo.
  void _onLifecycleChanged() => _syncPolling();

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _messagesPolling.stop();
    _lifecycle.removeListener(_onLifecycleChanged);
    super.dispose();
  }
}
