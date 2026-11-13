import 'dart:async';
import 'dart:collection';

import 'package:katch_mobile/app/app_config.dart';
import 'package:katch_mobile/app/app_dependencies.dart';
import 'package:katch_mobile/core/api_client.dart';
import 'package:katch_mobile/core/api_exception.dart';
import 'package:katch_mobile/core/clock.dart';
import 'package:katch_mobile/core/connection_monitor.dart';
import 'package:katch_mobile/core/device_file_picker.dart';
import 'package:katch_mobile/models/api_error_dto.dart';
import 'package:katch_mobile/models/candidate_profile_dto.dart';
import 'package:katch_mobile/models/change_password_request.dart';
import 'package:katch_mobile/models/custom_skill_dto.dart';
import 'package:katch_mobile/models/file_selection.dart';
import 'package:katch_mobile/models/login_request.dart';
import 'package:katch_mobile/models/login_response.dart';
import 'package:katch_mobile/models/profile_enums.dart';
import 'package:katch_mobile/models/profile_requests.dart';
import 'package:katch_mobile/models/reference_item_dto.dart';
import 'package:katch_mobile/models/register_candidate_request.dart';
import 'package:katch_mobile/models/search_preferences_dto.dart';
import 'package:katch_mobile/models/user_type.dart';
import 'package:katch_mobile/services/auth_service.dart';
import 'package:katch_mobile/services/candidate_profile_service.dart';
import 'package:katch_mobile/services/reference_list_service.dart';
import 'package:katch_mobile/session/session.dart';
import 'package:katch_mobile/session/session_manager.dart';
import 'package:katch_mobile/session/session_storage.dart';
import 'package:katch_mobile/state/profile_store.dart';
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

  final Queue<FutureOr<List<ReferenceItemDto>> Function()> skillAnswers =
      Queue();
  int skillCalls = 0;

  @override
  Future<List<ReferenceItemDto>> listSkills() async {
    skillCalls++;
    if (skillAnswers.isEmpty) {
      return const [dotnet, flutterSkill, sql];
    }
    return skillAnswers.removeFirst()();
  }
}

const dotnet = ReferenceItemDto(
  id: '7c1d2e3f-4a5b-4c6d-8e9f-0a1b2c3d4e01',
  name: '.NET',
);
const flutterSkill = ReferenceItemDto(
  id: '7c1d2e3f-4a5b-4c6d-8e9f-0a1b2c3d4e02',
  name: 'Flutter',
);
const sql = ReferenceItemDto(
  id: '7c1d2e3f-4a5b-4c6d-8e9f-0a1b2c3d4e03',
  name: 'SQL',
);

/// Perfil fictício de um Candidato (dados de teste).
CandidateProfileDto sampleProfile({
  String? desiredRole = 'Programador júnior',
  String locationId = '1a2b3c4d-5e6f-4a7b-8c9d-0e1f2a3b4c07',
  String locationName = 'Braga (Braga)',
  Availability? availability = Availability.oneMonth,
  String? experienceSummary = 'Estágio de 6 meses em desenvolvimento web.',
  String? photoUrl,
  bool hasCv = false,
  List<String> links = const [],
  List<ReferenceItemDto> skills = const [flutterSkill],
  List<CustomSkillDto> customSkills = const [],
  SearchPreferencesDto preferences = const SearchPreferencesDto(),
}) {
  return CandidateProfileDto(
    candidateId: '3f2a9c1e-7b4d-4e8a-9c21-5d6e7f8a9b01',
    fullName: 'Rita Fictícia Moreira',
    email: 'rita.moreira@exemplo.pt',
    phoneNumber: '912345678',
    locationId: locationId,
    locationName: locationName,
    desiredRole: desiredRole,
    availability: availability,
    experienceSummary: experienceSummary,
    photoUrl: photoUrl,
    hasCv: hasCv,
    links: links,
    skills: skills,
    customSkills: customSkills,
    preferences: preferences,
  );
}

/// Ficheiros fictícios para a validação local (P01, P02).
final jpegBytes = [0xFF, 0xD8, 0xFF, 0xE0, 0, 0x10, 0x4A, 0x46, 0x49, 0x46];
final pngBytes = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0];
final pdfBytes = '%PDF-1.4\n%fictício\n'.codeUnits;

FileSelection jpegFile([String name = 'fotografia.jpg']) =>
    FileSelection.fromBytes(name, jpegBytes);

FileSelection pdfFile([String name = 'cv.pdf']) =>
    FileSelection.fromBytes(name, pdfBytes);

/// Imagem JPEG com 5 MB + 1 byte, sem ocupar a memória toda (só o início).
FileSelection oversizedJpeg() => FileSelection(
  name: 'grande.jpg',
  sizeBytes: 5 * 1024 * 1024 + 1,
  header: jpegBytes.take(FileSelection.headerLength).toList(),
);

/// Ficheiro com extensão `.pdf` mas com o conteúdo de uma imagem PNG.
FileSelection fakePdf() => FileSelection.fromBytes('falso.pdf', pngBytes);

/// `CandidateProfileService` simulado, que regista os pedidos recebidos.
class FakeCandidateProfileService implements CandidateProfileService {
  FakeCandidateProfileService([CandidateProfileDto? profile])
    : profile = profile ?? sampleProfile();

  /// Perfil «no servidor», alterado pelas operações bem-sucedidas.
  CandidateProfileDto profile;

  final calls = <String>[];
  final updateRequests = <UpdateCandidateProfileRequest>[];
  final preferenceRequests = <SearchPreferencesDto>[];
  final linkRequests = <SetLinksRequest>[];
  final uploads = <FileSelection>[];

  /// Falha a lançar pela operação com este nome (por exemplo, `uploadCv`).
  final failures = <String, Object Function()>{};

  Future<void> _call(String name) async {
    calls.add(name);
    final failure = failures[name];
    if (failure != null) {
      throw failure();
    }
  }

  CandidateProfileDto _with({
    String? photoUrl,
    bool? hasCv,
    List<String>? links,
    List<ReferenceItemDto>? skills,
    List<CustomSkillDto>? customSkills,
    UpdateCandidateProfileRequest? data,
  }) {
    final current = profile;
    profile = CandidateProfileDto(
      candidateId: current.candidateId,
      fullName: current.fullName,
      email: current.email,
      phoneNumber: current.phoneNumber,
      locationId: data?.locationId ?? current.locationId,
      locationName: current.locationName,
      desiredRole: data == null ? current.desiredRole : data.desiredRole,
      availability: data == null ? current.availability : data.availability,
      experienceSummary: data == null
          ? current.experienceSummary
          : data.experienceSummary,
      photoUrl: photoUrl ?? current.photoUrl,
      hasCv: hasCv ?? current.hasCv,
      links: links ?? current.links,
      skills: skills ?? current.skills,
      customSkills: customSkills ?? current.customSkills,
      preferences: current.preferences,
    );
    return profile;
  }

  @override
  Future<CandidateProfileDto> getProfile() async {
    await _call('getProfile');
    return profile;
  }

  @override
  Future<CandidateProfileDto> updateProfile(
    UpdateCandidateProfileRequest request,
  ) async {
    await _call('updateProfile');
    updateRequests.add(request);
    return _with(data: request);
  }

  @override
  Future<SearchPreferencesDto> updatePreferences(
    SearchPreferencesDto request,
  ) async {
    await _call('updatePreferences');
    preferenceRequests.add(request);
    profile = profile.withPreferences(request);
    return request;
  }

  @override
  Future<CandidateProfileDto> addSkill(AddSkillRequest request) async {
    await _call('addSkill:${request.skillId}');
    final skill = [
      dotnet,
      flutterSkill,
      sql,
    ].firstWhere((item) => item.id == request.skillId);
    return _with(skills: [...profile.skills, skill]);
  }

  @override
  Future<void> removeSkill(String skillId) async {
    await _call('removeSkill:$skillId');
    _with(skills: [...profile.skills.where((item) => item.id != skillId)]);
  }

  @override
  Future<CandidateProfileDto> addCustomSkill(
    AddCustomSkillRequest request,
  ) async {
    await _call('addCustomSkill:${request.label}');
    final id = 'custom-${profile.customSkills.length + 1}';
    return _with(
      customSkills: [
        ...profile.customSkills,
        CustomSkillDto(customSkillId: id, label: request.label),
      ],
    );
  }

  @override
  Future<void> removeCustomSkill(String customSkillId) async {
    await _call('removeCustomSkill:$customSkillId');
    _with(
      customSkills: [
        ...profile.customSkills.where(
          (item) => item.customSkillId != customSkillId,
        ),
      ],
    );
  }

  @override
  Future<CandidateProfileDto> setLinks(SetLinksRequest request) async {
    await _call('setLinks');
    linkRequests.add(request);
    return _with(links: request.urls);
  }

  @override
  Future<void> uploadPhoto(FileSelection file) async {
    await _call('uploadPhoto');
    uploads.add(file);
    _with(photoUrl: '/api/files/profile-photo/${file.name}');
  }

  @override
  Future<void> uploadCv(FileSelection file) async {
    await _call('uploadCv');
    uploads.add(file);
    _with(hasCv: true);
  }
}

/// Seletor de ficheiros simulado: devolve o ficheiro indicado pelo teste.
class FakeFilePicker implements DeviceFilePicker {
  FileSelection? image;
  FileSelection? pdf;

  @override
  Future<FileSelection?> pickImage() async => image;

  @override
  Future<FileSelection?> pickPdf() async => pdf;
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

  @override
  Future<void> upload(String path, FileSelection file) {
    return _answer('UPLOAD', path, file);
  }
}

/// Dependências da aplicação com serviços simulados.
class TestApp {
  TestApp({SessionStorage? storage, CandidateProfileDto? profile})
    : storage = storage ?? MemorySessionStorage(),
      auth = FakeAuthService(),
      referenceLists = FakeReferenceListService(),
      profileService = FakeCandidateProfileService(profile),
      filePicker = FakeFilePicker(),
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
      profileService: profileService,
      profile: ProfileStore(service: profileService, session: session),
      filePicker: filePicker,
    );
  }

  final SessionStorage storage;
  final FakeAuthService auth;
  final FakeReferenceListService referenceLists;
  final FakeCandidateProfileService profileService;
  final FakeFilePicker filePicker;
  final FakeClock clock;
  final ConnectionMonitor monitor;
  late final SessionManager session;
  late final AppDependencies dependencies;
}
