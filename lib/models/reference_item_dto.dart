import 'json.dart';

/// Elemento de uma lista pré-definida (`ReferenceItemDto`, API v02 6.13).
final class ReferenceItemDto {
  const ReferenceItemDto({required this.id, required this.name});

  factory ReferenceItemDto.fromJson(Json json) {
    return ReferenceItemDto(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  final String id;
  final String name;
}
