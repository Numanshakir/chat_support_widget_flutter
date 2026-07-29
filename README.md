# chat_support_widget

A Flutter package that provides a ready-to-use live customer support chat widget with a polished agent UI, real-time messaging, and full customization hooks.

---

## ✨ Features

- 🎯 **Drop-in Widget** — Add live support chat with `SupportChatWidget`
- 💬 **Beautiful Chat UI** — Modern chat interface with header, bubbles, and smooth scrolling
- 🎨 **Fully Customizable** — Colors, builders, titles, and positioning
- 👤 **Live Agent Chat** — Real-time messaging with support agents
- 🔌 **Socket.IO Support** — Real-time communication with polling fallback
- ⌨️ **Typing Indicator** — Shows when the agent is typing
- 📱 **Responsive** — Works on all screen sizes

---


## Installation

Add this package to your Flutter project's `pubspec.yaml`:

```yaml
dependencies:
  chat_support_widget: ^0.0.1
```

Run package resolution:

```bash
flutter pub get
```

---

## Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:chat_support_widget/chat_support_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 380,
            height: 600,
            child: SupportChatWidget(
              config: SupportChatConfig(
                visitorConfig: VisitorConfig(
                  baseUrl: 'https://your-chatscript-host',
                  tenantId: 'your-tenant-id',
                  url: 'https://example.com',
                  title: 'Home',
                  isMobile: true,
                  domain: 'example.com',
                ),
                userData: const SupportUserData(
                  name: 'Example',
                  email: 'example@example.com',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## Advanced Customization: Overriding UI Components

### 1. Custom AppBar / Header Builder

```dart
SupportChatWidget(
  config: config,
  headerBuilder: (context, config, isOnline) {
    return Container(
      color: Colors.red,
      padding: const EdgeInsets.all(16.0),
      child: Text(
        'Custom App Bar - ${config.headerTitle}',
        style: const TextStyle(color: Colors.white, fontSize: 18.0),
      ),
    );
  },
)
```

### 2. Custom Welcome Sub-header Builder

```dart
SupportChatWidget(
  config: config,
  subHeaderBuilder: (context, config) {
    return Container(
      color: Colors.amber,
      padding: const EdgeInsets.all(8.0),
      child: Text('Custom Help Text: ${config.subHeaderSubtitle}'),
    );
  },
)
```

### 3. Custom Chat Bubbles Builder

```dart
SupportChatWidget(
  config: config,
  bubbleBuilder: (context, message, formattedTime) {
    if (message.sender == MessageSender.user) {
      return Align(
        alignment: Alignment.centerRight,
        child: Card(
          color: Colors.green[100],
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(message.content),
          ),
        ),
      );
    } else {
      return Align(
        alignment: Alignment.centerLeft,
        child: Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(message.content),
          ),
        ),
      );
    }
  },
)
```

### 4. Custom Bottom Input Field & Toolbar Builder

```dart
SupportChatWidget(
  config: config,
  inputBuilder: (context, controller, isTyping, onSend) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Enter text...'),
            ),
          ),
          ElevatedButton(
            onPressed: onSend,
            child: const Text('Send'),
          ),
        ],
      ),
    );
  },
)
```
