import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../models/user_data.dart';

/// Interface for chatbot backends.
abstract class ChatbotService {
  /// Sends a message and returns the assistant's reply.
  /// Passes the message [content], current [history], and [userData] for context.
  Future<String> sendMessage({
    required String content,
    required List<ChatMessage> history,
    required SupportUserData? userData,
    String? deviceId,
  });
}

/// A concrete implementation of [ChatbotService] that integrates directly with Google's Gemini API.
class GeminiChatbotService implements ChatbotService {
  final String apiKey;
  final String modelName;
  final String customSystemInstruction;

  GeminiChatbotService({
    required this.apiKey,
    this.modelName = '',
    this.customSystemInstruction =
        'You are a helpful and polite Live Support AI Assistant. Answer the user\'s queries precisely. If the user attaches an image, analyze it carefully and reply based on it.',
  });

  @override
  Future<String> sendMessage({
    required String content,
    required List<ChatMessage> history,
    required SupportUserData? userData,
    String? deviceId,
  }) async {
    final url = Uri.parse(
      '',
    );

    // Build the system instructions using user context data or fallback to anonymous tracking info
    var systemInstructionText = customSystemInstruction;

    if (userData != null) {
      systemInstructionText +=
          '\n\nActive Support Session User Context:\n'
          '- Name: ${userData.name ?? "Not Provided"}\n'
          '- Email: ${userData.email ?? "Not Provided"}';
      if (userData.metadata != null && userData.metadata!.isNotEmpty) {
        systemInstructionText += '\n- Additional Metadata:';
        userData.metadata!.forEach((key, value) {
          systemInstructionText += '\n    * $key: $value';
        });
      }
    } else {
      systemInstructionText +=
          '\n\nActive Support Session User Context:\n'
          '- Name: Anonymous User\n'
          '- Device ID: ${deviceId ?? "Unknown Device"}';
    }

    // Build the chat history in Gemini format (roles: "user", "model")
    final contentsList = <Map<String, dynamic>>[];
    for (final message in history) {
      if (message.sender == MessageSender.system)
        continue; // skip system announcements
      final role = message.sender == MessageSender.user ? 'user' : 'model';

      final parts = <Map<String, dynamic>>[];

      // If there is an image/file attachment, embed it as inlineData
      if (message.attachment != null) {
        parts.add({
          'inlineData': {
            'mimeType': message.attachment!.mimeType,
            'data': base64Encode(message.attachment!.bytes),
          },
        });
      }

      // Add the text part
      parts.add({'text': message.content});

      contentsList.add({'role': role, 'parts': parts});
    }

    // If for some reason history is empty (fallback), create at least one part
    if (contentsList.isEmpty) {
      contentsList.add({
        'role': 'user',
        'parts': [
          {'text': content},
        ],
      });
    }

    final requestBody = {
      'contents': contentsList,
      'systemInstruction': {
        'parts': [
          {'text': systemInstructionText},
        ],
      },
      'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 800},
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String text =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        if (text.isEmpty) {
          throw Exception('Received empty reply from chatbot model.');
        }
        return text.trim();
      } else {
        final Map<String, dynamic> errorResponse = jsonDecode(response.body);
        final String errorMessage =
            errorResponse['error']?['message'] ??
            'Status code: ${response.statusCode}';
        throw Exception('Chatbot service failed: $errorMessage');
      }
    } catch (e) {
      throw Exception('Failed to communicate with chatbot: $e');
    }
  }
}
