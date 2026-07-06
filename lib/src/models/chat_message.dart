import 'attachment_file.dart';

enum MessageSender {
  user,
  assistant,
  system,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  seen,
  failed,
}

/// Represents a single message in the chat conversation.
class ChatMessage {
  final String id;
  final String content;
  final MessageSender sender;
  final DateTime timestamp;
  final MessageStatus status;
  final AttachmentFile? attachment;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.attachment,
  });

  /// Helper constructor for system messages.
  factory ChatMessage.system(String content) {
    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      content: content,
      sender: MessageSender.system,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );
  }

  /// Helper constructor for user messages.
  factory ChatMessage.user(String content, {AttachmentFile? attachment}) {
    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      content: content,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      attachment: attachment,
    );
  }

  /// Helper constructor for assistant messages.
  factory ChatMessage.assistant(String content) {
    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      content: content,
      sender: MessageSender.assistant,
      timestamp: DateTime.now(),
      status: MessageStatus.seen,
    );
  }

  /// Creates a copy of this message with customized values.
  ChatMessage copyWith({
    String? id,
    String? content,
    MessageSender? sender,
    DateTime? timestamp,
    MessageStatus? status,
    AttachmentFile? attachment,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      attachment: attachment ?? this.attachment,
    );
  }
}
