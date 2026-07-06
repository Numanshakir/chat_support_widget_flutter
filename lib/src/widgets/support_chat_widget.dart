import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../models/user_data.dart';
import '../models/attachment_file.dart';
import '../services/chatbot_service.dart';

/// Configuration options for the support chat UI and backend.
class SupportChatConfig {
  /// Gemini API Key to power the chatbot.
  final String? apiKey;

  /// User demographic details to personalize chatbot context.
  final SupportUserData? userData;

  /// Unique Device ID used for anonymous users if [userData] is null.
  final String? deviceId;

  /// Custom implementation of [ChatbotService]. If not provided,
  /// [GeminiChatbotService] is used by default (requires [apiKey]).
  final ChatbotService? customService;

  /// Bot name shown on assistant messages. Defaults to "AI Assistant".
  final String botName;

  /// Title shown in the main header. Defaults to "support".
  final String headerTitle;

  /// Title shown in the sub-header. Defaults to "live support".
  final String subHeaderTitle;

  /// Subtitle shown in the sub-header. Defaults to "Ask us anything".
  final String subHeaderSubtitle;

  /// Custom system instructions to modify AI behavior.
  final String? systemInstructions;

  const SupportChatConfig({
    this.apiKey,
    this.userData,
    this.deviceId,
    this.customService,
    this.botName = 'AI Assistant',
    this.headerTitle = 'support',
    this.subHeaderTitle = 'live support',
    this.subHeaderSubtitle = 'Ask us anything',
    this.systemInstructions,
  }) : assert(
         apiKey != null || customService != null,
         'Either apiKey or customService must be provided.',
       );
}

// Custom builder type definitions for ultimate flexibility
typedef HeaderBuilder =
    Widget Function(
      BuildContext context,
      SupportChatConfig config,
      bool isOnline,
    );

typedef SubHeaderBuilder =
    Widget Function(BuildContext context, SupportChatConfig config);

typedef MessageBubbleBuilder =
    Widget Function(
      BuildContext context,
      ChatMessage message,
      String formattedTime,
    );

typedef InputAreaBuilder =
    Widget Function(
      BuildContext context,
      TextEditingController controller,
      bool isTyping,
      AttachmentFile? pendingAttachment,
      VoidCallback onSelectAttachment,
      VoidCallback onRemoveAttachment,
      VoidCallback onSend,
    );

/// The highly customizable Support Chatbot Widget.
class SupportChatWidget extends StatefulWidget {
  final SupportChatConfig config;

  /// Callback when the "Please update your info" action link is pressed.
  final VoidCallback? onUpdateInfoPressed;

  /// Callback when the exit/reset button is pressed.
  final VoidCallback? onExitPressed;

  /// Callback when the attachment (paperclip) button is pressed.
  /// Should return an [AttachmentFile] representing the selected image.
  final Future<AttachmentFile?> Function()? onAttachmentPressed;

  /// Callback when the menu (three dots) button is pressed.
  final VoidCallback? onMenuPressed;

  /// Custom builder for the App Bar / Main Header.
  final HeaderBuilder? headerBuilder;

  /// Custom builder for the Subheader Welcome Banner.
  final SubHeaderBuilder? subHeaderBuilder;

  /// Custom builder for individual chat bubbles (user, assistant, system messages).
  final MessageBubbleBuilder? bubbleBuilder;

  /// Custom builder for the input area and send/tool buttons.
  final InputAreaBuilder? inputBuilder;

  /// Theme styling customization.
  final Color primaryColor;
  final Color backgroundColor;

  const SupportChatWidget({
    Key? key,
    required this.config,
    this.onUpdateInfoPressed,
    this.onExitPressed,
    this.onAttachmentPressed,
    this.onMenuPressed,
    this.headerBuilder,
    this.subHeaderBuilder,
    this.bubbleBuilder,
    this.inputBuilder,
    this.primaryColor = const Color(0xFF2B5AD9), // exact bold blue from mockup
    this.backgroundColor = const Color(0xFFF5F7FB),
  }) : super(key: key);

  @override
  State<SupportChatWidget> createState() => _SupportChatWidgetState();
}

class _SupportChatWidgetState extends State<SupportChatWidget> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ChatbotService _chatbotService;
  bool _isTyping = false;
  bool _isOnline = true;
  AttachmentFile? _pendingAttachment;
  late final String _activeDeviceId;

  @override
  void initState() {
    super.initState();

    // Resolve dynamic device ID fallback for anonymous users
    _activeDeviceId =
        widget.config.deviceId ??
        'Session-${DateTime.now().millisecondsSinceEpoch}';

    // Initialize chatbot backend service
    if (widget.config.customService != null) {
      _chatbotService = widget.config.customService!;
    } else {
      _chatbotService = GeminiChatbotService(
        apiKey: widget.config.apiKey!,
        customSystemInstruction:
            widget.config.systemInstructions ??
            'You are a helpful and polite Live Support AI Assistant. Answer the user\'s queries precisely. If the user attaches an image, analyze it carefully and reply based on it.',
      );
    }

    // Load initial greeting and system state
    _messages.add(ChatMessage.system('ended the chat'));
    _messages.add(ChatMessage.assistant('Hi! How can I help you today?'));
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleAttachmentSelection() async {
    if (widget.onAttachmentPressed != null) {
      final file = await widget.onAttachmentPressed!();
      if (file != null) {
        setState(() {
          _pendingAttachment = file;
        });
        await _sendMessage();
      }
    }
  }

  void _handleRemoveAttachment() {
    setState(() {
      _pendingAttachment = null;
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty && _pendingAttachment == null) return;

    // Use placeholder text if only an image is sent
    final messageText = text.isEmpty ? "Sent an image attachment" : text;

    _inputController.clear();

    // 1. Create and add user message (with attachment if present)
    final userMessage = ChatMessage.user(
      messageText,
      attachment: _pendingAttachment,
    );

    setState(() {
      _messages.add(userMessage);
      _pendingAttachment = null;
      _isTyping = true;
    });
    _scrollToBottom();

    // Simulate standard messaging state change to "delivered"
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _messages.indexWhere((msg) => msg.id == userMessage.id);
    if (index != -1) {
      setState(() {
        _messages[index] = _messages[index].copyWith(
          status: MessageStatus.delivered,
        );
      });
    }

    try {
      // 2. Fetch response from Service (passing full message list history including image bytes)
      final reply = await _chatbotService.sendMessage(
        content: messageText,
        history: _messages,
        userData: widget.config.userData,
        deviceId: _activeDeviceId,
      );

      setState(() {
        _messages.add(ChatMessage.assistant(reply));
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            content: 'Error: Could not connect to support. Please try again.',
            sender: MessageSender.system,
            timestamp: DateTime.now(),
          ),
        );
        _isTyping = false;
      });
    }

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8.0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // 1. Main Header / App Bar
            widget.headerBuilder != null
                ? widget.headerBuilder!(context, widget.config, _isOnline)
                : _buildDefaultHeader(),

            // 2. Sub Header Live Support Banner
            widget.subHeaderBuilder != null
                ? widget.subHeaderBuilder!(context, widget.config)
                : _buildDefaultSubHeader(),

            // 3. Chat Message Log
            Expanded(
              child: Container(
                color: widget.backgroundColor,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final timeStr = DateFormat(
                      'h:mm a',
                    ).format(message.timestamp);

                    // User Custom Bubble Builder support
                    if (widget.bubbleBuilder != null) {
                      return widget.bubbleBuilder!(context, message, timeStr);
                    }

                    if (message.sender == MessageSender.system) {
                      return _buildDefaultSystemMessage(message);
                    } else if (message.sender == MessageSender.user) {
                      return _buildDefaultUserBubble(message, timeStr);
                    } else {
                      return _buildDefaultAssistantBubble(message, timeStr);
                    }
                  },
                ),
              ),
            ),

            if (_isTyping && widget.inputBuilder == null)
              Container(
                color: widget.backgroundColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 4.0,
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  '${widget.config.botName} is typing...',
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            // 4. Chat Input Section
            widget.inputBuilder != null
                ? widget.inputBuilder!(
                    context,
                    _inputController,
                    _isTyping,
                    _pendingAttachment,
                    _handleAttachmentSelection,
                    _handleRemoveAttachment,
                    _sendMessage,
                  )
                : _buildDefaultInputSection(),
          ],
        ),
      ),
    );
  }

  // --- Premium Default Component Builders ---

  Widget _buildDefaultHeader() {
    return Container(
      color: widget.primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        children: [
          Container(
            width: 42.0,
            height: 42.0,
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white,
              size: 22.0,
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.config.headerTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
                const SizedBox(height: 2.0),
                Row(
                  children: [
                    Container(
                      width: 8.0,
                      height: 8.0,
                      decoration: BoxDecoration(
                        color: _isOnline
                            ? const Color(0xFF34C759)
                            : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      _isOnline ? 'Online' : 'Offline',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(
              Icons.crop_square,
              color: Colors.white70,
              size: 20.0,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 12.0),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.remove, color: Colors.white70, size: 22.0),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultSubHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.room_service_outlined,
              color: Colors.black87,
              size: 20.0,
            ),
          ),
          const SizedBox(width: 12.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.config.subHeaderTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15.0,
                  color: Colors.black87,
                ),
              ),
              Text(
                widget.config.subHeaderSubtitle,
                style: TextStyle(fontSize: 12.0, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultSystemMessage(ChatMessage message) {
    if (message.content.contains('ended the chat')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Center(
          child: Text(
            message.content,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13.0),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDefaultUserBubble(ChatMessage message, String timeStr) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 260.0),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFF0F3FA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                  bottomLeft: Radius.circular(16.0),
                  bottomRight: Radius.circular(4.0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attachment Rendering
                  if (message.attachment != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Image.memory(
                        message.attachment!.bytes,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                  ],
                  Text(
                    message.content,
                    style: const TextStyle(
                      color: Color(0xFF2C3E6B),
                      fontSize: 15.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4.0),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(fontSize: 11.0, color: Colors.grey.shade500),
                ),
                const SizedBox(width: 4.0),
                Icon(
                  message.status == MessageStatus.sending
                      ? Icons.done
                      : Icons.done_all,
                  size: 14.0,
                  color:
                      message.status == MessageStatus.seen ||
                          message.status == MessageStatus.delivered
                      ? const Color(0xFF34C759)
                      : Colors.grey.shade400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAssistantBubble(ChatMessage message, String timeStr) {
    final hasUpdateInfoLink = message.content.contains(
      'Hi! How can I help you today?',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16.0,
              backgroundColor: Colors.grey.shade300,
              child: const Icon(Icons.person, color: Colors.white, size: 20.0),
            ),
            const SizedBox(width: 8.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.config.botName,
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4.0),
                Container(
                  constraints: const BoxConstraints(maxWidth: 240.0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFFEBEFF5),
                      width: 1.0,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4.0),
                      topRight: Radius.circular(16.0),
                      bottomLeft: Radius.circular(16.0),
                      bottomRight: Radius.circular(16.0),
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15.0,
                    ),
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  timeStr,
                  style: TextStyle(fontSize: 11.0, color: Colors.grey.shade500),
                ),
                if (hasUpdateInfoLink) ...[
                  const SizedBox(height: 12.0),
                  InkWell(
                    onTap: widget.onUpdateInfoPressed,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        'Please update your info',
                        style: TextStyle(
                          color: widget.primaryColor,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          fontSize: 14.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultInputSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Image upload thumbnail preview inside bottom field
          if (_pendingAttachment != null) ...[
            Container(
              padding: const EdgeInsets.only(bottom: 12.0),
              alignment: Alignment.centerLeft,
              child: Stack(
                children: [
                  Container(
                    width: 70.0,
                    height: 70.0,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.memory(
                      _pendingAttachment!.bytes,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 2.0,
                    right: 2.0,
                    child: InkWell(
                      onTap: _handleRemoveAttachment,
                      child: CircleAvatar(
                        radius: 10.0,
                        backgroundColor: Colors.black.withOpacity(0.6),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 12.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300, width: 1.0),
              borderRadius: BorderRadius.circular(16.0),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 4.0,
            ),
            child: TextField(
              controller: _inputController,
              maxLines: 3,
              minLines: 2,
              decoration: const InputDecoration(
                hintText: 'Type a message here',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 15.0),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.exit_to_app, color: Colors.black54),
                onPressed: widget.onExitPressed,
              ),
              // Attachment selection handler
              IconButton(
                icon: const Icon(Icons.attach_file, color: Colors.black54),
                onPressed: _handleAttachmentSelection,
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz, color: Colors.black54),
                onPressed: widget.onMenuPressed,
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                ),
                onPressed: _sendMessage,
                child: const Text(
                  'Send',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
