import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/clock.dart';
import '../core/connection_monitor.dart';
import '../core/device_file_picker.dart';
import '../core/http_api_client.dart';
import '../core/platform_file_picker.dart';
import '../services/auth_service.dart';
import '../services/candidate_profile_service.dart';
import '../services/http_auth_service.dart';
import '../services/http_candidate_profile_service.dart';
import '../services/http_reference_list_service.dart';
import '../session/secure_session_storage.dart';
import '../session/session_manager.dart';
import '../session/session_storage.dart';
import '../state/profile_store.dart';
import '../state/reference_data_store.dart';
import 'app_config.dart';

/// Composição das dependências da aplicação (modelo de classes, 10.1).
///
/// Os ecrãs obtêm-nas através do `AppScope`. Nos testes, o construtor recebe
/// serviços simulados, um armazenamento da sessão em memória e um seletor de
/// ficheiros simulado.
class AppDependencies {
  AppDependencies({
    required this.config,
    required this.monitor,
    required this.session,
    required this.auth,
    required this.referenceData,
    required this.profileService,
    required this.profile,
    required this.filePicker,
  });

  /// Dependências reais: cliente HTTP da API v02 e armazenamento seguro.
  factory AppDependencies.create(
    AppConfig config, {
    SessionStorage? storage,
    Clock clock = const SystemClock(),
    http.Client? client,
    DeviceFilePicker filePicker = const PlatformFilePicker(),
  }) {
    final monitor = ConnectionMonitor();
    final session = SessionManager(
      storage: storage ?? SecureSessionStorage(),
      clock: clock,
    );
    final api = HttpApiClient(
      baseUrl: config.apiBaseUrl,
      requestTimeout: config.requestTimeout,
      credentials: session,
      monitor: monitor,
      client: client,
      log: kDebugMode ? _debugLog : null,
    );
    final profileService = HttpCandidateProfileService(api);
    return AppDependencies(
      config: config,
      monitor: monitor,
      session: session,
      auth: HttpAuthService(api),
      referenceData: ReferenceDataStore(HttpReferenceListService(api)),
      profileService: profileService,
      profile: ProfileStore(service: profileService, session: session),
      filePicker: filePicker,
    );
  }

  /// Registo dos pedidos à API na consola, só na variante de depuração.
  static void _debugLog(String message) => debugPrint('[API] $message');

  final AppConfig config;
  final ConnectionMonitor monitor;
  final SessionManager session;
  final AuthService auth;
  final ReferenceDataStore referenceData;
  final CandidateProfileService profileService;

  /// Perfil do Candidato, esvaziado no fim de sessão (RF105).
  final ProfileStore profile;

  /// Seletor de ficheiros do dispositivo; nos testes, um seletor simulado.
  final DeviceFilePicker filePicker;
}
