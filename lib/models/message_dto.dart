import 'json.dart';

/// Mensagem de uma conversa (`MessageDto`, API v02, 6.8.2 e 8.4).
///
/// `senderId` é o `userId` do remetente; `readAt` é a leitura pelo
/// destinatário (RF028), `null` enquanto a mensagem não foi lida.
final class MessageDto {
  const MessageDto({
    required this.messageId,
    required this.senderId,
    required this.content,
    required this.sentAt,
    this.readAt,
  });

  factory MessageDto.fromJson(Json json) {
    final read = json['readAt'] as String?;
    return MessageDto(
      messageId: json['messageId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      readAt: read == null ? null : DateTime.parse(read),
    );
  }

  final String messageId;
  final String senderId;
  final String content;
  final DateTime sentAt;
  final DateTime? readAt;
}

/// Corpo do envio de uma mensagem (`SendMessageRequest`, API v02, 6.8.3).
final class SendMessageRequest {
  const SendMessageRequest(this.content);

  /// Texto da mensagem, com 1 a 1000 caracteres (P03).
  final String content;

  Json toJson() => {'content': content};
}
