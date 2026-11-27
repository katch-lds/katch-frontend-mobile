import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'files.dart';

/// Pedidos diretos à API do katch-backend feitos pelos testes de sistema
/// (plano de testes do frontend mobile, secção 6): criam os dados de cada
/// cenário e fazem as ações do Recrutador e do Administrador.
///
/// O endereço e a palavra-passe do Administrador chegam por `--dart-define`
/// (`API_BASE_URL` e `E2E_ADMIN_PASSWORD`) e nunca ficam no repositório.
abstract final class KatchApi {
  /// Endereço da API visto do emulador (o anfitrião é `10.0.2.2`).
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5180',
  );

  static const _adminPassword = String.fromEnvironment('E2E_ADMIN_PASSWORD');

  static const adminEmail = 'admin@katch.pt';

  static final _random = Random();

  /// Sufixo único para correios e nomes criados pelos testes.
  static String unique(String prefix) {
    final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return '$prefix-$stamp${_random.nextInt(1000)}';
  }

  /// Palavra-passe válida (P05), diferente em cada conta criada.
  static String newPassword() => 'Teste${_random.nextInt(900000) + 100000}a';

  /// Telefone com 9 algarismos (P04).
  static String newPhone() => '91${_random.nextInt(9000000) + 1000000}';

  /// NIF válido (algarismo de controlo, módulo 11), começado por 5.
  static String validNif() {
    final base = '5${_random.nextInt(10000000).toString().padLeft(7, '0')}';
    var sum = 0;
    for (var i = 0; i < base.length; i++) {
      sum += int.parse(base[i]) * (9 - i);
    }
    final check = 11 - sum % 11;
    return '$base${check >= 10 ? 0 : check}';
  }

  static String get adminPassword {
    if (_adminPassword.isEmpty) {
      throw StateError(
        'Falta --dart-define=E2E_ADMIN_PASSWORD (ver integration_test/README.md).',
      );
    }
    return _adminPassword;
  }

  /// Início de sessão; `client` é `mobile` para o Candidato e `web` para o
  /// Recrutador e o Administrador.
  static Future<ApiSession> login(
    String email,
    String password, {
    String client = 'web',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: _jsonHeaders(client: client),
      body: jsonEncode({'email': email, 'password': password}),
    );
    final body =
        _check(response, 'início de sessão de $email') as Map<String, Object?>;
    return ApiSession(
      token: body['token'] as String,
      userId: body['userId'] as String,
      client: client,
    );
  }

  static Future<ApiSession> admin() => login(adminEmail, adminPassword);

  /// Candidato registado pela API (por omissão, em Bragança).
  static Future<TestCandidate> createCandidate({
    String prefix = 'sm',
    String locationId = Locations.braganca,
  }) async {
    final email = '${unique(prefix)}@teste.katch.pt';
    final password = newPassword();
    final fullName = 'Candidato ${unique('Teste')}';
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/candidates'),
      headers: _jsonHeaders(client: 'mobile'),
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'phoneNumber': newPhone(),
        'locationId': locationId,
        'password': password,
        'acceptTerms': true,
      }),
    );
    final body = _check(response, 'registar Candidato') as Map<String, Object?>;
    return TestCandidate(
      email: email,
      password: password,
      fullName: fullName,
      session: ApiSession(
        token: body['token'] as String,
        userId: body['userId'] as String,
        client: 'mobile',
      ),
    );
  }

  /// Recrutador com a Empresa registada e aprovada pelo Administrador; a
  /// Empresa tem descrição, sítio na Internet e logótipo (página do RF017).
  static Future<TestRecruiter> createRecruiter({String prefix = 'sm'}) async {
    final email = '${unique(prefix)}@teste.katch.pt';
    final password = newPassword();
    final created = await http.post(
      Uri.parse('$baseUrl/api/auth/recruiters'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'email': email,
        'password': password,
        'acceptTerms': true,
      }),
    );
    final account =
        _check(created, 'criar conta de Recrutador') as Map<String, Object?>;
    final session = ApiSession(
      token: account['token'] as String,
      userId: account['userId'] as String,
      client: 'web',
    );
    final companyName = 'Empresa ${unique('SM')}, Lda.';
    await session.post('/api/recruiter/company', {
      'companyName': companyName,
      'taxId': validNif(),
      'industry': 'TECHNOLOGY',
      'address': 'Rua dos Testes, n.º 1',
      'locationId': Locations.braganca,
      'contactEmail': email,
      'contactPhone': '910000000',
      'responsibleName': 'Responsável de Teste',
    }, 'registar Empresa');
    final status =
        await session.get('/api/recruiter/company/status', 'estado da Empresa')
            as Map<String, Object?>;
    final companyId = status['companyId'] as String;
    final admin = await KatchApi.admin();
    await admin.post(
      '/api/admin/companies/$companyId/approve',
      null,
      'aprovar Empresa',
    );
    const description = 'Empresa fictícia criada pelos testes de sistema.';
    await session.put('/api/recruiter/company/page', {
      'description': description,
      'website': 'https://empresa.example.com',
    }, 'página da Empresa');
    await session.upload(
      '/api/recruiter/company/logo',
      'logo.png',
      TestFiles.png,
      'logótipo',
    );
    return TestRecruiter(
      email: email,
      password: password,
      companyName: companyName,
      companyId: companyId,
      description: description,
      session: session,
    );
  }

  static Future<List<Map<String, Object?>>> referenceList(
    ApiSession session,
    String name,
  ) async {
    final items =
        await session.get('/api/reference-lists/$name', 'lista $name')
            as List<Object?>;
    return [for (final item in items) item as Map<String, Object?>];
  }
}

/// Sessão iniciada na API, com a credencial nos pedidos.
class ApiSession {
  ApiSession({required this.token, required this.userId, required this.client});

  final String token;
  final String userId;
  final String client;

  Map<String, String> get _headers => {
    ..._jsonHeaders(client: client),
    'Authorization': 'Bearer $token',
  };

  Uri _uri(String path) => Uri.parse('${KatchApi.baseUrl}$path');

  Future<Object?> get(String path, String what) async =>
      _check(await http.get(_uri(path), headers: _headers), what);

  Future<Object?> post(String path, Object? body, String what) async => _check(
    await http.post(
      _uri(path),
      headers: _headers,
      body: body == null ? null : jsonEncode(body),
    ),
    what,
  );

  Future<Object?> put(String path, Object? body, String what) async => _check(
    await http.put(_uri(path), headers: _headers, body: jsonEncode(body)),
    what,
  );

  /// Pedido sem verificar o resultado: estado HTTP e código ERR-nn do corpo.
  Future<ApiOutcome> rawPost(String path, Object? body) async {
    final response = await http.post(
      _uri(path),
      headers: _headers,
      body: body == null ? null : jsonEncode(body),
    );
    return ApiOutcome.of(response);
  }

  Future<ApiOutcome> rawPut(String path, Object? body) async {
    final response = await http.put(
      _uri(path),
      headers: _headers,
      body: jsonEncode(body),
    );
    return ApiOutcome.of(response);
  }

  /// Envio de um ficheiro sem verificar o resultado (casos de erro).
  Future<ApiOutcome> rawUpload(
    String path,
    String name,
    List<int> bytes,
  ) async {
    return ApiOutcome.of(await _sendFile(path, name, bytes));
  }

  Future<http.Response> _sendFile(
    String path,
    String name,
    List<int> bytes,
  ) async {
    final request = http.MultipartRequest('PUT', _uri(path))
      ..headers.addAll({
        'X-Client-App': client,
        'Authorization': 'Bearer $token',
      })
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: name));
    return http.Response.fromStream(await request.send());
  }

  /// Envio de um ficheiro (`multipart/form-data`, campo `file`); a API
  /// reconhece o formato pela assinatura do conteúdo.
  Future<void> upload(
    String path,
    String name,
    List<int> bytes,
    String what,
  ) async {
    _check(await _sendFile(path, name, bytes), what);
  }
}

/// Resultado de um pedido que se espera recusado.
class ApiOutcome {
  const ApiOutcome(this.status, this.code);

  factory ApiOutcome.of(http.Response response) {
    String? code;
    if (response.statusCode >= 400 && response.body.isNotEmpty) {
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, Object?>) {
          code = body['code'] as String?;
        }
      } on FormatException {
        // Corpo sem JSON (por exemplo, recusado pelo servidor HTTP).
      }
    }
    return ApiOutcome(response.statusCode, code);
  }

  final int status;
  final String? code;

  @override
  String toString() => '$status ${code ?? ''}'.trim();
}

class TestCandidate {
  TestCandidate({
    required this.email,
    required this.password,
    required this.fullName,
    required this.session,
  });

  final String email;
  final String password;
  final String fullName;
  final ApiSession session;
}

class TestRecruiter {
  TestRecruiter({
    required this.email,
    required this.password,
    required this.companyName,
    required this.companyId,
    required this.description,
    required this.session,
  });

  final String email;
  final String password;
  final String companyName;
  final String companyId;
  final String description;
  final ApiSession session;

  /// Cria e publica uma vaga da Empresa. Por omissão é urgente: as vagas
  /// urgentes aparecem primeiro e, entre elas, as mais próximas, por isso uma
  /// vaga na localidade do Candidato é o primeiro cartão, à distância 0.
  Future<TestJob> createJob({
    String? title,
    String locationId = Locations.braganca,
    double minSalary = 1500,
    double maxSalary = 2000,
    String contractType = 'PERMANENT',
    String workMode = 'ON_SITE',
    bool isUrgent = true,
    bool withSkillsAndBenefits = false,
  }) async {
    final jobTitle = title ?? KatchApi.unique('Vaga SM');
    final skills = await KatchApi.referenceList(session, 'skills');
    final benefits = withSkillsAndBenefits
        ? await KatchApi.referenceList(session, 'benefits')
        : const <Map<String, Object?>>[];
    final skillCount = withSkillsAndBenefits ? 2 : 1;
    final chosenSkills = skills.take(skillCount).toList();
    final chosenBenefits = benefits.take(2).toList();
    const description = 'Vaga fictícia criada pelos testes de sistema.';
    final created =
        await session.post('/api/recruiter/jobs', {
              'title': jobTitle,
              'description': description,
              'minSalary': minSalary,
              'maxSalary': maxSalary,
              'locationId': locationId,
              'contractType': contractType,
              'workMode': workMode,
              'skillIds': [for (final skill in chosenSkills) skill['id']],
              'benefitIds': [
                for (final benefit in chosenBenefits) benefit['id'],
              ],
              'isUrgent': isUrgent,
              'expiresAt': null,
            }, 'criar vaga')
            as Map<String, Object?>;
    final jobId = created['jobId'] as String;
    await session.post(
      '/api/recruiter/jobs/$jobId/publish',
      null,
      'publicar vaga',
    );
    return TestJob(
      jobId: jobId,
      title: jobTitle,
      description: description,
      skills: [for (final skill in chosenSkills) skill['name'] as String],
      benefits: [
        for (final benefit in chosenBenefits) benefit['name'] as String,
      ],
    );
  }

  /// Aceita o interesse do Candidato na vaga (abre o perfil antes, como na
  /// aplicação web) e devolve o `matchId`.
  Future<String> accept(TestJob job, TestCandidate candidate) async {
    final waiting =
        await session.get(
              '/api/recruiter/jobs/${job.jobId}/waiting-candidates',
              'candidatos em espera',
            )
            as List<Object?>;
    final entry = waiting.cast<Map<String, Object?>>().firstWhere(
      (item) => item['candidateId'] == candidate.session.userId,
      orElse: () => waiting.first as Map<String, Object?>,
    );
    final matchId = entry['matchId'] as String;
    await session.get(
      '/api/recruiter/interests/$matchId/profile',
      'abrir perfil',
    );
    await session.post(
      '/api/recruiter/interests/$matchId/accept',
      null,
      'aceitar interesse',
    );
    return matchId;
  }

  /// Mensagem do Recrutador na conversa do match.
  Future<void> send(String matchId, String content) async {
    await session.post('/api/conversations/$matchId/messages', {
      'content': content,
    }, 'mensagem do Recrutador');
  }
}

class TestJob {
  const TestJob({
    required this.jobId,
    required this.title,
    required this.description,
    required this.skills,
    required this.benefits,
  });

  final String jobId;
  final String title;
  final String description;
  final List<String> skills;
  final List<String> benefits;
}

/// Match criado pela API: o Candidato manifesta interesse e o Recrutador
/// aceita-o.
Future<String> createMatch(
  TestRecruiter recruiter,
  TestJob job,
  TestCandidate candidate,
) async {
  await candidate.session.post(
    '/api/candidate/jobs/${job.jobId}/interest',
    null,
    'manifestar interesse',
  );
  return recruiter.accept(job, candidate);
}

Map<String, String> _jsonHeaders({String client = 'web'}) => {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'X-Client-App': client,
};

Object? _check(http.Response response, String what) {
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw StateError('$what: ${response.statusCode} ${response.body}');
  }
  return response.body.isEmpty ? null : jsonDecode(response.body);
}

/// Localidades da lista de referência (02-seed-reference-data.sql) sem vagas
/// nos dados de demonstração: cada cenário de exploração usa a sua, para que a
/// vaga que cria seja o primeiro cartão do seu Candidato.
abstract final class Locations {
  static const braganca = '95403bb6-dfd8-5ec9-b7be-cca706c28d46';

  /// Nome apresentado pela API (localidade e distrito).
  static const bragancaName = 'Bragança (Bragança)';

  /// Cerca de 80 km de Bragança: fora de uma distância máxima de 50 km.
  static const vilaReal = 'd85fd474-2dd2-5c5d-8838-0e1bfaa15906';
  static const guarda = 'a9d21b96-20f2-5713-ba87-f21f8fd84f57';
  static const viseu = 'f577b67c-9afe-59ea-929d-465a5b6f3f45';
  static const casteloBranco = '1b39cde1-862a-52cd-8939-91194b8213a0';
  static const evora = '02bd4f95-69ee-5c1e-9c9b-0ba36ea5f541';
  static const beja = '50464d05-d697-5c9f-98f1-3e536a1e942a';
  static const faro = '4a5fbc5e-3804-51db-b97f-ed6e3812dcfe';
  static const portalegre = 'b3498910-1834-5c7b-943f-dd4a48bd2f01';
  static const leiria = '0cb922db-0b48-5b61-95fe-1aebe0a447a8';
  static const aveiro = '672b1ca0-3721-5b2f-bd2f-93c5aa7e0456';
}
