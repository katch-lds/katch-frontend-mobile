/// Textos apresentados nos cartões de vaga e na quota de interesses.
library;

/// Valor em euros, sem casas decimais quando é inteiro («1600 €», «1600,50 €»).
String formatEuros(double value) {
  final text = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2).replaceAll('.', ',');
  return '$text €';
}

/// Intervalo salarial bruto mensal da vaga (RF013).
String salaryRange(double min, double max) {
  return min == max
      ? formatEuros(min)
      : '${formatEuros(min)} – ${formatEuros(max)}';
}

/// Localidade da vaga e distância em linha reta (RF015).
String locationAndDistance(String locationName, int distanceKm) {
  return '$locationName · $distanceKm km';
}

/// Tempo em falta, arredondado ao minuto seguinte para nunca indicar menos do
/// que falta («23 h 47 min», «5 min»).
String remainingLabel(Duration remaining) {
  final minutes = (remaining.inSeconds + 59) ~/ 60;
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return hours == 0 ? '$rest min' : '$hours h $rest min';
}

/// Instante na hora local do dispositivo («16:05 de 10/10/2026»).
String instantLabel(DateTime instant) {
  final local = instant.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)} de '
      '${two(local.day)}/${two(local.month)}/${local.year}';
}
