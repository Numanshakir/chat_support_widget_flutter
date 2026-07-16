import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:support_chat/support_chat.dart';

import 'talk_troves_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Support Chat Example',
      home: const SupportChatDemoPage(),
    );
  }
}

class SupportChatDemoPage extends StatefulWidget {
  const SupportChatDemoPage({super.key});

  @override
  State<SupportChatDemoPage> createState() => _SupportChatDemoPageState();
}

class _SupportChatDemoPageState extends State<SupportChatDemoPage> {
  final ImagePicker _imagePicker = ImagePicker();
  int _chatInstance = 0;

  /// Always create a NEW session with the configured tenant (no reconnect).
  SupportChatConfig get _config {
    return SupportChatConfig(
      visitorConfig: VisitorConfig(
        baseUrl: TalkTrovesConfig.baseUrl,
        tenantId: TalkTrovesConfig.tenantId,
        sessionId: null,
        reconnect: false,
        url: TalkTrovesConfig.pageUrl,
        title: TalkTrovesConfig.pageTitle,
        tz: TalkTrovesConfig.timezoneOffsetHours,
        navigatorLanguage: TalkTrovesConfig.navigatorLanguage,
        isMobile: true,
        domain: TalkTrovesConfig.domain,
        enableSocket: TalkTrovesConfig.enableSocket,
        pollingInterval: TalkTrovesConfig.pollingInterval,
      ),
      userData: const SupportUserData(
        name: 'Flutter Dummy User',
        email: 'flutter-dummy@example.com',
        metadata: {'source': 'flutter_sdk_demo', 'role': 'visitor'},
      ),
      deviceId: 'dummy-sender-device-001',
      botName: 'TalkTroves Bot',
      headerTitle: 'support',
      subHeaderTitle: 'live support',
      subHeaderSubtitle: 'Ask us anything',
    );
  }

  Future<AttachmentFile?> _pickImageAttachment() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) return null;

    final bytes = await pickedFile.readAsBytes();
    return AttachmentFile(
      name: pickedFile.name,
      bytes: bytes,
      mimeType: _imageMimeType(pickedFile.name),
    );
  }

  String _imageMimeType(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    return switch (extension) {
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      _ => 'image/jpeg',
    };
  }

  void _prepareNextChatSession() {
    setState(() {
      _chatInstance++;
    });
    if (kDebugMode) {
      debugPrint(
        '[TalkTroves] Chat closed — next open will create a new session | '
        'tenant=${TalkTrovesConfig.tenantId}',
      );
    }
  }

  void _openChatPopup() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(380.0, constraints.maxWidth);
              final height = math.min(600.0, constraints.maxHeight);

              return SizedBox(
                width: width,
                height: height,
                child: SupportChatWidget(
                  key: ValueKey(_chatInstance),
                  config: _config,
                  onSessionReady: (tenantId, sessionId) {
                    if (kDebugMode) {
                      debugPrint(
                        '[TalkTroves] Session created → chat with '
                        'tid=$tenantId sid=$sessionId',
                      );
                    }
                  },
                  onExitPressed: () {
                    Navigator.of(dialogContext).pop();
                    _prepareNextChatSession();
                  },
                  onAttachmentPressed: _pickImageAttachment,
                  onMenuPressed: () {},
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Support Chat Demo'),
        backgroundColor: const Color(0xFF2B5AD9),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Tap the chat button to open live support.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openChatPopup,
        backgroundColor: const Color(0xFF2B5AD9),
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Support'),
      ),
    );
  }
}
