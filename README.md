# Support Chat

A premium, customizable Flutter chatbot package designed exactly to match your customer support interface. It provides a default high-fidelity UI integrated directly with Google's Gemini API, but allows developers to override and customize **every single visual component** (AppBar, Subheader, Chat Bubbles, and Chat Input Field).

---

## Features
- **Visual Fidelity:** Replicates the premium support agent interface (blue header, online status indicator, concierge/bell banner, styled bubbles, custom avatars).
- **Demographic Context Integration:** Automatically appends provided `SupportUserData` (name, email, tier, app metadata) into system instructions for customized AI messaging.
- **Visitor SDK:** JSON visitor endpoints (`/chatscript/visitor/session`, `/polling`, `/activity`) with Socket.IO realtime and polling fallback.
- **Robust Integration:** Direct lightweight HTTP interface with Google's Gemini by default, or chatscript visitor backend via `visitorConfig`.
- **100% UI Customization:** Complete layout customizability using custom builders (`headerBuilder`, `subHeaderBuilder`, `bubbleBuilder`, and `inputBuilder`).

---

## Visitor SDK Backend

Wire the chatscript visitor JSON API (session, activity, polling, Socket.IO) without changing the chat UI:

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

Architecture:

- `VisitorConfig` — client options
- `VisitorRemoteDataSource` — HTTP `/chatscript/visitor/*`
- `VisitorSocketDataSource` — Socket.IO (`message_to_client`, `typing`)
- `VisitorRepository` — domain contract
- `VisitorChatService` — orchestrates session → poll/socket → activity

Gemini remains available via `apiKey`; custom backends via `customService`.


---

## Getting Started

Add this package to your Flutter project's `pubspec.yaml`:

```yaml
dependencies:
  support_chat:
    path: ../support_chat # or use pub.dev dependency path when published
```

Run package resolution:
```bash
flutter pub get
```

---

## Basic Usage

If you want to use the **default premium UI** (matching the designed mockup), simply use the widget out of the box:

```dart
import 'package:flutter/material.dart';
import 'package:support_chat/support_chat.dart';

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
                apiKey: 'YOUR_GEMINI_API_KEY', // Supply your Gemini API key here
                userData: const SupportUserData(
                  name: 'Imran Computer',
                  email: 'imran@example.com',
                  metadata: {
                    'account_tier': 'Gold VIP',
                  },
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

Anyone using this package can fully customize the look and feel of the widget using custom builders:

### 1. Custom AppBar / Header Builder
```dart
SupportChatWidget(
  config: config,
  headerBuilder: (context, config, isOnline) {
    return Container(
      color: Colors.red, // Custom color
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
