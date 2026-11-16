import 'json.dart';
import 'profile_enums.dart';

/// Preferências de procura (`SearchPreferencesDto`, API v02, 6.2.3).
///
/// `null` ou lista vazia significa sem filtro nesse critério.
final class SearchPreferencesDto {
  const SearchPreferencesDto({
    this.maxDistanceKm,
    this.minSalaryExpectation,
    this.workModes = const [],
    this.contractTypes = const [],
  });

  factory SearchPreferencesDto.fromJson(Json json) {
    final salary = json['minSalaryExpectation'];
    return SearchPreferencesDto(
      maxDistanceKm: json['maxDistanceKm'] as int?,
      minSalaryExpectation: salary is num ? salary.toDouble() : null,
      workModes: [
        for (final value in json['workModes'] as List<Object?>? ?? const [])
          WorkMode.fromWire(value as String),
      ],
      contractTypes: [
        for (final value in json['contractTypes'] as List<Object?>? ?? const [])
          ContractType.fromWire(value as String),
      ],
    );
  }

  final int? maxDistanceKm;
  final double? minSalaryExpectation;
  final List<WorkMode> workModes;
  final List<ContractType> contractTypes;

  Json toJson() => {
    'maxDistanceKm': maxDistanceKm,
    'minSalaryExpectation': minSalaryExpectation,
    'workModes': [for (final mode in workModes) mode.toWire()],
    'contractTypes': [for (final type in contractTypes) type.toWire()],
  };
}
