import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../core/clock.dart';
import '../models/api_error_dto.dart';
import '../models/job_card_dto.dart';
import '../models/quota_dto.dart';
import '../models/search_preferences_dto.dart';
import '../polling/app_lifecycle_monitor.dart';
import '../services/job_exploration_service.dart';
import 'failure_messages.dart';
import 'profile_store.dart';

/// Estado da área de exploração (DFM-12).
enum ExplorationStatus {
  /// Pedido da quota ou do cartão em curso.
  loading,

  /// M09: cartão com interesses disponíveis.
  card,

  /// M10: cartão com a quota esgotada; só a recusa e o detalhe ficam ativos.
  quotaExhausted,

  /// M11: nenhuma vaga cumpre as preferências de procura.
  empty,

  /// O cartão ou a quota não foram obtidos; permite repetir.
  failed,
}

/// Estado dos ecrãs M09, M10 e M11 (UC05).
///
/// Pede a quota e o cartão seguinte, recusa a vaga ou manifesta interesse e
/// volta a pedir os cartões quando as preferências de procura do
/// `ProfileStore` mudam (RF023) e quando a aplicação regressa ao primeiro plano
/// (DFM-15). Com a quota esgotada, conta o tempo até ao fim do bloqueio com o
/// `Clock` e, nesse instante, volta a pedir a quota, que o servidor já repôs
/// (RF021).
class ExplorationController extends ChangeNotifier {
  ExplorationController({
    required JobExplorationService service,
    required ProfileStore profile,
    required AppLifecycleMonitor lifecycle,
    required Clock clock,
    this.countdownInterval = const Duration(minutes: 1),
  }) : _service = service,
       _profile = profile,
       _lifecycle = lifecycle,
       _clock = clock,
       _preferences = profile.preferences,
       _inForeground = lifecycle.inForeground {
    _profile.addListener(_onPreferencesChanged);
    _lifecycle.addListener(_onForeground);
  }

  /// Código da rejeição de um interesse com a quota esgotada (API v02, 4.3).
  static const quotaExhaustedCode = 'ERR-31';

  /// Total da quota (P11), enquanto o servidor ainda não o indicou.
  static const defaultQuotaTotal = 10;

  /// Intervalo de atualização do tempo em falta até ao fim do bloqueio.
  final Duration countdownInterval;

  final JobExplorationService _service;
  final ProfileStore _profile;
  final AppLifecycleMonitor _lifecycle;
  final Clock _clock;

  SearchPreferencesDto? _preferences;
  bool _inForeground;
  JobCardDto? _card;
  QuotaDto? _quota;
  String? _message;
  bool _loading = false;
  bool _failed = false;
  bool _refreshingQuota = false;
  bool _disposed = false;
  Timer? _countdown;

  /// Aumenta em cada pedido de cartões, para ignorar respostas antigas.
  int _generation = 0;

  ExplorationStatus get status {
    if (_loading) {
      return ExplorationStatus.loading;
    }
    if (_failed) {
      return ExplorationStatus.failed;
    }
    if (_card == null) {
      return ExplorationStatus.empty;
    }
    return interestBlocked
        ? ExplorationStatus.quotaExhausted
        : ExplorationStatus.card;
  }

  JobCardDto? get currentCard => _card;

  QuotaDto? get quota => _quota;

  /// Motivo da última rejeição ou falha, ou `null`.
  String? get message => _message;

  /// Sem interesses disponíveis: o interesse fica bloqueado (RF020).
  bool get interestBlocked => _quota?.isExhausted ?? false;

  /// Tempo em falta até ao fim do bloqueio, nunca negativo; `null` fora do
  /// bloqueio (RF020).
  Duration? get remainingBlock {
    final until = _quota?.blockedUntil;
    if (!interestBlocked || until == null) {
      return null;
    }
    final remaining = until.difference(_clock.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Pede a quota e o cartão seguinte (UC05).
  Future<void> load() async {
    await _fetch(_start(), withQuota: true);
  }

  /// Recusa a vaga do cartão e passa ao seguinte, sem alterar a quota (RF018).
  Future<void> decline() async {
    final card = _card;
    if (card == null || _loading) {
      return;
    }
    await _answer(card, () => _service.decline(card.jobId));
  }

  /// Manifesta interesse na vaga do cartão e passa ao seguinte (RF019). Com a
  /// quota esgotada não faz nenhum pedido (RF020).
  Future<void> expressInterest() async {
    final card = _card;
    if (card == null || _loading || interestBlocked) {
      return;
    }
    await _answer(card, () async {
      final quota = await _service.expressInterest(card.jobId);
      _quota = quota;
    });
  }

  /// Volta a pedir a quota (RF022); no fim do bloqueio, o servidor já a repôs
  /// antes de responder (API v02, 6.3.6; RF021).
  Future<void> refreshQuota() async {
    if (_refreshingQuota) {
      return;
    }
    _refreshingQuota = true;
    try {
      final quota = await _service.getQuota();
      if (_disposed) {
        return;
      }
      _quota = quota;
    } on ApiException {
      // A quota mantém-se; o temporizador volta a pedi-la mais tarde.
    } finally {
      _refreshingQuota = false;
    }
    _syncCountdown();
    _notify();
  }

  /// Envia a resposta à vaga do cartão; o cartão deixa de ser apresentado
  /// enquanto o pedido está em curso, para não ser respondido duas vezes.
  Future<void> _answer(JobCardDto card, Future<void> Function() send) async {
    final generation = _start();
    try {
      await send();
    } on ApiRejection catch (rejection) {
      if (generation != _generation) {
        return;
      }
      _message = rejection.message;
      if (_keepCard(card, rejection.error)) {
        return;
      }
      await _fetch(generation, withQuota: true);
      return;
    } on ApiException catch (failure) {
      if (generation != _generation) {
        return;
      }
      // Nada foi registado: o cartão volta a ser apresentado.
      _card = card;
      _message = failureMessage(failure);
      _finish();
      return;
    }
    if (generation != _generation) {
      return;
    }
    await _fetch(generation, withQuota: false);
  }

  /// A quota esgotou-se entretanto (ERR-31): o fim do bloqueio vem na
  /// rejeição, e o cartão continua a ser apresentado, sem novo pedido.
  bool _keepCard(JobCardDto card, ApiErrorDto error) {
    if (error.code != quotaExhaustedCode) {
      return false;
    }
    _quota = QuotaDto(
      available: 0,
      total: _quota?.total ?? defaultQuotaTotal,
      blockedUntil: error.blockedUntil,
    );
    _card = card;
    _finish();
    return true;
  }

  /// Começa um pedido: o cartão atual deixa de ser apresentado.
  int _start() {
    _loading = true;
    _failed = false;
    _card = null;
    _message = null;
    _notify();
    return ++_generation;
  }

  Future<void> _fetch(int generation, {required bool withQuota}) async {
    try {
      final results = await Future.wait<Object?>([
        if (withQuota) _service.getQuota(),
        _service.getNextCard(),
      ]);
      if (generation != _generation) {
        return;
      }
      if (withQuota) {
        _quota = results.first as QuotaDto?;
      }
      _card = results.last as JobCardDto?;
    } on ApiException catch (failure) {
      if (generation != _generation) {
        return;
      }
      _card = null;
      _failed = true;
      _message = failureMessage(failure);
    }
    _finish();
  }

  void _finish() {
    _loading = false;
    _syncCountdown();
    _notify();
  }

  /// Agenda a próxima atualização do tempo em falta, ou o pedido da quota no
  /// fim do bloqueio. Se o servidor ainda indicar o bloqueio, o pedido seguinte
  /// só é feito depois de `countdownInterval`.
  void _syncCountdown() {
    _countdown?.cancel();
    _countdown = null;
    final remaining = remainingBlock;
    if (remaining == null || _disposed) {
      return;
    }
    final delay = remaining > Duration.zero && remaining < countdownInterval
        ? remaining
        : countdownInterval;
    _countdown = Timer(delay, _onCountdown);
  }

  void _onCountdown() {
    _countdown = null;
    if (remainingBlock == Duration.zero) {
      unawaited(refreshQuota());
      return;
    }
    _syncCountdown();
    _notify();
  }

  /// As preferências gravadas em M08 alteram os cartões seguintes (RF023).
  void _onPreferencesChanged() {
    final previous = _preferences;
    final current = _profile.preferences;
    _preferences = current;
    if (previous != null &&
        current != null &&
        !_samePreferences(previous, current)) {
      unawaited(load());
    }
  }

  /// O bloqueio pode ter terminado com a aplicação em segundo plano (DFM-15).
  void _onForeground() {
    final foreground = _lifecycle.inForeground;
    if (foreground && !_inForeground) {
      unawaited(load());
    }
    _inForeground = foreground;
  }

  static bool _samePreferences(SearchPreferencesDto a, SearchPreferencesDto b) {
    return a.maxDistanceKm == b.maxDistanceKm &&
        a.minSalaryExpectation == b.minSalaryExpectation &&
        listEquals(a.workModes, b.workModes) &&
        listEquals(a.contractTypes, b.contractTypes);
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _countdown?.cancel();
    _profile.removeListener(_onPreferencesChanged);
    _lifecycle.removeListener(_onForeground);
    super.dispose();
  }
}
