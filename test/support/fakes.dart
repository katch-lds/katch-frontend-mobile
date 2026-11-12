import 'dart:async';
import 'dart:collection';

import 'package:katch_mobile/app/app_config.dart';
import 'package:katch_mobile/app/app_dependencies.dart';
import 'package:katch_mobile/core/api_client.dart';
import 'package:katch_mobile/core/api_exception.dart';
import 'package:katch_mobile/core/clock.dart';
import 'package:katch_mobile/core/connection_monitor.dart';
import 'package:katch_mobile/models/api_error_dto.dart';
import 'package:katch_mobile/models/change_password_request.dart';
import 'package:katch_mobile/models/login_request.dart';
import 'package:katch_mobile/models/login_response.dart';
import 'package:katch_mobile/models/reference_item_dto.dart';
import 'package:katch_mobile/models/register_candidate_request.dart';
import 'package:katch_mobile/models/user_type.dart';
import 'package:katch_mobile/services/auth_service.dart';
import 'package:katch_mobile/services/reference_list_service.dart';
import 'package:katch_mobile/session/session.dart';
import 'package:katch_mobile/session/session_manager.dart';
import 'package:katch_mobile/session/session_storage.dart';
import 'package:katch_mobile/state/reference_data_store.dart';

/// Instante fixo dos testes.
final testNow = DateTime.utc(2026, 11, 12, 10);

/// Resposta de início de sessão de um Candidato, válida durante 8 horas.
LoginResponse candidateLogin({
  String token = 'token-candidato',
  UserType userType = UserType.candidate,
  DateTime? expiresAt,
}) {
  return LoginResponse(
    token: token,
    expiresAt: expiresAt ?? testNow.add(const Duration(hours: 8)),
    userType: userType,
    userId: '3f2a9c1e-7b4d-4e8a-9c21-5d6e7f8a9b01',
  );
}

/// Rejeição da API com o `ApiErrorDto` indicado.
ApiRejection rejection(
  String code,
  String message, [
  Map<String, String> fields = const {},
]) {
  return ApiRejection(
    ApiErrorDto(
      code: code,
      message: message,
      fields: [
        for (final entry in fields.entries)
          FieldErrorDto(field: entry.key, reason: entry.value),
      ],
    ),
  );
}

/// Motivos da API v02 (secção 4.3) usados nos testes.
const credentialsMessage =
    'O endereço de correio eletrónico ou a palavra-passe estão incorretos.';
const blockedMessage = 'A conta está bloqueada.';
const validationMessage =
    'Os dados enviados não cumprem a validação automática.';

class FakeClock implements Clock {
  FakeClock([DateTime? now]) : current = now ?? testNow;

  DateTime current;

  @override
  DateTime now() => current;
}

/// Armazenamento da sessão em memória (plano de testes do mobile, 4.3).
class MemorySessionStorage implements SessionStorage {
  MemorySessionStorage([this.saved]);

  Session? saved;
  bool failRead = false;
  int clears = 0;

  @override
  Future<Session?> read() async {
    if (failRead) {
      throw StateError('armazenamento indisponível');
    }
    return saved;
  }

  @override
  Future<void> write(Session session) async {
    saved = session;
  }

  @override
  Future<void> clear() async {
    clears++;
    saved = null;
  }
}

/// `AuthService` simulado: cada operação devolve ou lança o que o teste
/// indicar e regista os pedidos recebidos.
class FakeAuthService implements AuthService {
  final registerRequests = <RegisterCandidateRequest>[];
  final loginRequests = <LoginRequest>[];
  final passwordRequests = <ChangePasswordRequest>[];
  int logouts = 0;

  FutureOr<LoginResponse> Function() onRegister = candidateLogin;
  FutureOr<LoginResponse> Function() onLogin = candidateLogin;
  FutureOr<void> Function() onLogout = () {};
  FutureOr<void> Function() onChangePassword = () {};

  @override
  Future<LoginResponse> register(RegisterCandidateRequest request) async {
    registerRequests.add(request);
    return onRegister();
  }

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    loginRequests.add(request);
    return onLogin();
  }

  @override
  Future<void> logout() async {
    logouts++;
    await onLogout();
  }

  @override
  Future<void> changePassword(ChangePasswordRequest request) async {
    passwordRequests.add(request);
    await onChangePassword();
  }
}

const braga = ReferenceItemDto(
  id: '1a2b3c4d-5e6f-4a7b-8c9d-0e1f2a3b4c07',
  name: 'Braga (Braga)',
);
const felgueiras = ReferenceItemDto(
  id: '1a2b3c4d-5e6f-4a7b-8c9d-0e1f2a3b4c09',
  name: 'Felgueiras (Porto)',
);

class FakeReferenceListService implements ReferenceListService {
  final Queue<FutureOr<List<ReferenceItemDto>> Function()> locationAnswers =
      Queue();
  int locationCalls = 0;

  @override
  Future<List<ReferenceItemDto>> listLocations() async {
    locationCalls++;
    if (locationAnswers.isEmpty) {
      return const [braga, felgueiras];
    }
    return locationAnswers.removeFirst()();
  }

  @override
  Future<List<ReferenceItemDto>> listSkills() async => const [];
}

/// `ApiClient` simulado, que regista os pedidos e devolve a resposta indicada.
class FakeApiClient implements ApiClient {
  final calls = <String>[];
  final bodies = <Object?>[];
  Object? response;
  ApiException? failure;

  Future<Object?> _answer(String method, String path, [Object? body]) async {
    calls.add('$method $path');
    bodies.add(body);
    final error = failure;
    if (error != null) {
      throw error;
    }
    return response;
  }

  @override
  Future<Object?> get(String path) => _answer('GET', path);

  @override
  Future<Object?> post(String path, [Object? body]) {
    return _answer('POST', path, body);
  }

  @override
  Future<Object?> put(String path, [Object? body]) {
    return _answer('PUT', path, body);
  }

  @override
  Future<void> delete(String path) => _answer('DELETE', path);
}

/// Dependências da aplicação com serviços simulados.
class TestApp {
  TestApp({SessionStorage? storage})
    : storage = storage ?? MemorySessionStorage(),
      auth = FakeAuthService(),
      referenceLists = FakeReferenceListService(),
      clock = FakeClock(),
      monitor = ConnectionMonitor() {
    session = SessionManager(storage: this.storage, clock: clock);
    dependencies = AppDependencies(
      config: const AppConfig(
        apiBaseUrl: 'https://api.test',
        requestTimeout: Duration(seconds: 9),
      ),
      monitor: monitor,
      session: session,
      auth: auth,
      referenceData: ReferenceDataStore(referenceLists),
    );
  }

  final SessionStorage storage;
  final FakeAuthService auth;
  final FakeReferenceListService referenceLists;
  final FakeClock clock;
  final ConnectionMonitor monitor;
  late final SessionManager session;
  late final AppDependencies dependencies;
}
