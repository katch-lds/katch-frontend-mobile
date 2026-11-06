/// Retira as barras finais de um endereço, sem expressões regulares.
///
/// Igual ao `trimTrailingSlashes` do frontend web (I120): um ciclo em vez de
/// `RegExp(r'/+$')`, que tem retrocesso super-linear (regra S8786 do
/// SonarQube).
String trimTrailingSlashes(String url) {
  var end = url.length;
  while (end > 0 && url.codeUnitAt(end - 1) == 0x2F) {
    end--;
  }
  return url.substring(0, end);
}
