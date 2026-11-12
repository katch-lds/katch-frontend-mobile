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
}
