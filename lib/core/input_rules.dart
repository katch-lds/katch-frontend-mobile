import '../models/file_selection.dart';

/// Regras de validação local (modelo de classes do mobile v02, secção 4.2).
///
/// Só servem para dar ao Candidato o motivo antes de enviar o pedido: o
/// servidor aplica as mesmas regras e é a autoridade (RNF008). Os motivos são
/// os textos da API v02 (secção 4.3), para o Candidato ver a mesma indicação
/// quer a rejeição seja local quer venha do servidor (RF004).
abstract final class InputRules {
  /// Campo obrigatório vazio.
  static const requiredReason = 'O campo é obrigatório.';

  /// Correio eletrónico fora do formato local@domínio (P04).
  static const emailReason =
      'O endereço de correio eletrónico tem de ter o formato local@domínio.';

  /// Contacto telefónico sem 9 algarismos (P04).
  static const phoneReason = 'O contacto telefónico tem de ter 9 algarismos.';

  /// Palavra-passe fora do P05.
  static const passwordReason =
      'A palavra-passe tem de ter pelo menos 8 caracteres, uma letra e um '
      'algarismo.';

  /// Condições de utilização por aceitar (RF003).
  static const acceptTermsReason =
      'É obrigatório aceitar as condições de utilização.';

  /// Competência «Outro» fora do P07 (RF009).
  static const customSkillReason =
      'A competência tem de ter entre 2 e 40 caracteres e conter apenas '
      'letras, algarismos, espaços e os símbolos + # . -';

  /// Distância máxima fora do P06 (RF007).
  static const distanceReason =
      'A distância máxima tem de ser um número inteiro entre 1 e 500.';

  /// Pretensão salarial que não é um valor em euros (RF007).
  static const salaryReason = 'O valor tem de ser um número positivo em euros.';

  /// Mais de 3 hiperligações (P10, RF012).
  static const tooManyLinksReason = 'São permitidas no máximo 3 hiperligações.';

  /// Hiperligação sem `http://` nem `https://` (P10, RF012).
  static const linkReason =
      'O endereço tem de começar por http:// ou https://.';

  /// Fotografia noutro formato (P01, RF010).
  static const photoFormatReason =
      'O ficheiro tem de estar no formato JPEG ou PNG.';

  /// Curriculum vitae noutro formato (P02, RF011).
  static const cvFormatReason = 'O ficheiro tem de estar no formato PDF.';

  /// Ficheiro acima de 5 MB (P01, P02).
  static const fileTooLargeReason = 'O ficheiro excede 5 MB.';

  /// Texto acima do limite de caracteres (P08).
  static String textTooLongReason(int maxLength) =>
      'O texto não pode exceder $maxLength caracteres.';

  /// Limite da função pretendida (API v02, 6.2.2).
  static const desiredRoleMaxLength = 150;

  /// Limite do resumo da experiência (P08).
  static const summaryMaxLength = 1000;

  /// Limite da distância máxima, em quilómetros (P06).
  static const maxDistanceKm = 500;

  /// Número máximo de hiperligações (P10).
  static const maxLinks = 3;

  /// Dimensão máxima da fotografia e do curriculum vitae: 5 MB (P01, P02).
  static const maxFileBytes = 5 * 1024 * 1024;

  static final _customSkill = RegExp(r'^[\p{L}0-9 +#.\-]+$', unicode: true);
  static final _letter = RegExp(r'\p{L}', unicode: true);
  static final _digit = RegExp(r'\p{Nd}', unicode: true);
  static final _whitespace = RegExp(r'\s');
  static final _nineDigits = RegExp(r'^[0-9]{9}$');

  /// Formato local@domínio: um único `@`, com texto de cada lado e sem
  /// espaços (P04; igual à regra do backend).
  static bool isValidEmail(String value) {
    final email = value.trim();
    final at = email.indexOf('@');
    return at > 0 &&
        at == email.lastIndexOf('@') &&
        at < email.length - 1 &&
        !_whitespace.hasMatch(email);
  }

  /// Exatamente 9 algarismos (P04).
  static bool isValidPhone(String value) => _nineDigits.hasMatch(value.trim());

  /// Pelo menos 8 caracteres, uma letra e um algarismo (P05).
  static bool isValidPassword(String value) {
    return value.length >= 8 &&
        _letter.hasMatch(value) &&
        _digit.hasMatch(value);
  }

  /// Texto vazio ou só com espaços (API v02, secção 2.3).
  static bool isBlank(String value) => value.trim().isEmpty;

  /// 2 a 40 caracteres, sem os espaços das extremidades: letras, algarismos
  /// de 0 a 9, espaços e os símbolos + # . - (P07; igual à regra do backend).
  static bool isValidCustomSkill(String value) {
    final label = value.trim();
    return label.length >= 2 &&
        label.length <= 40 &&
        _customSkill.hasMatch(label);
  }

  /// Número inteiro de 1 a 500 (P06).
  static bool isValidDistanceKm(int value) =>
      value >= 1 && value <= maxDistanceKm;

  /// Endereço iniciado por `http://` ou `https://` (P10).
  static bool isValidLink(String value) {
    final url = value.trim().toLowerCase();
    return url.startsWith('http://') || url.startsWith('https://');
  }

  /// No máximo 1000 caracteres, sem os espaços das extremidades (P08).
  static bool isValidSummary(String value) =>
      value.trim().length <= summaryMaxLength;

  /// Motivo da recusa da fotografia, ou `null`: JPEG ou PNG até 5 MB (P01).
  static String? photoError(FileSelection file) {
    return _fileError(file, const {
      '.jpg': _FileFormat.jpeg,
      '.jpeg': _FileFormat.jpeg,
      '.png': _FileFormat.png,
    }, photoFormatReason);
  }

  /// Motivo da recusa do curriculum vitae, ou `null`: PDF até 5 MB (P02).
  static String? cvError(FileSelection file) {
    return _fileError(file, const {'.pdf': _FileFormat.pdf}, cvFormatReason);
  }

  /// Mesma ordem do backend: ficheiro vazio, extensão, assinatura do conteúdo
  /// (RNF016) e dimensão.
  static String? _fileError(
    FileSelection file,
    Map<String, _FileFormat> accepted,
    String formatReason,
  ) {
    if (file.sizeBytes == 0) {
      return requiredReason;
    }
    final format = accepted[file.extension];
    if (format == null) {
      return formatReason;
    }
    if (file.header.isNotEmpty && !format.matches(file.header)) {
      return formatReason;
    }
    return file.sizeBytes > maxFileBytes ? fileTooLargeReason : null;
  }
}

/// Formatos aceites e a assinatura do início do conteúdo (P01, P02).
enum _FileFormat {
  jpeg([0xFF, 0xD8, 0xFF]),
  png([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
  pdf([0x25, 0x50, 0x44, 0x46, 0x2D]);

  const _FileFormat(this.signature);

  final List<int> signature;

  bool matches(List<int> header) {
    if (header.length < signature.length) {
      return false;
    }
    for (var i = 0; i < signature.length; i++) {
      if (header[i] != signature[i]) {
        return false;
      }
    }
    return true;
  }
}
