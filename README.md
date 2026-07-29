# chat_support_widget

A Flutter package for live customer support chat using the **chatscript visitor JSON API** (session, activity, polling, Socket.IO). The default UI matches a premium support-agent interface and can be customized with builders for header, subheader, bubbles, and input.

---

## Features

- **Visitor SDK:** JSON endpoints (`/chatscript/visitor/session`, `/polling`, `/activity`) with Socket.IO realtime and polling fallback
- **Live agent chat:** Session create/reconnect, send messages, forms (name/email), typing, logout/expire
- **Visual fidelity:** Blue header, online status, welcome banner, styled bubbles, custom avatars
- **UI customization:** Override layout with `headerBuilder`, `subHeaderBuilder`, `bubbleBuilder`, and `inputBuilder`

---

## Visitor SDK Backend

```dart
SupportChatWidget(
  config: SupportChatConfig(
    visitorConfig: VisitorConfig(
      baseUrl: 'https://your-chatscript-host',
      tenantId: 'tenant-id',
      url: 'https://example.com',
      title: 'Home',
      isMobile: true,
      domain: 'example.com',
      enableSocket: true,
    ),
    userData: const SupportUserData(
      name: 'Imran',
      email: 'imran@example.com',
    ),
  ),
)
```


## Getting Started

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
                  name: 'Imran Computer',
                  email: 'imran@example.com',
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
