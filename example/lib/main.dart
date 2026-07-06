import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:support_chat/support_chat.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SizedBox(
          width: 380,
          height: 600,
          child: SupportChatWidget(
            config: SupportChatConfig(
              apiKey: const String.fromEnvironment('API_KEY'),
              userData: const SupportUserData(
                name: 'Test User',
                email: 'test@example.com',
                metadata: {},
              ),
            ),
            onUpdateInfoPressed: () {},
            onExitPressed: () {},
            onAttachmentPressed: _pickImageAttachment,
            onMenuPressed: () {},
          ),
        ),
      ),
    );
  }
}
