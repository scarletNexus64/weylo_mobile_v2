# Weylo Flutter Project - Architecture & Components Analysis

## Project Overview
**App Name:** Weylo  
**State Management:** GetX  
**API Client:** Dio  
**Local Storage:** GetStorage  
**Real-time:** WebSocket (Laravel Reverb with Pusher protocol)  
**Platform:** Cross-platform (Android, iOS, Web)  

---

## 1. AUTHENTICATION SYSTEM

### 1.1 Authentication Files

#### Location: `/lib/app/data/services/auth_service.dart`
**Purpose:** Singleton service handling all authentication operations

**Key Methods:**
```dart
- register() - Register new user with phone, password, optional email/name
- login() - Login with username/email/phone + password
- logout() - Clear session and local storage
- me() - Fetch current user profile from API
- refreshToken() - Refresh authentication token
- isAuthenticated() - Check if user has valid token
- getCurrentUser() - Get user from local storage
- getToken() - Get auth token
- verifyToken() - Verify token validity via /auth/me endpoint
- changePassword() - Change user password
- updateProfile() - Update user profile data
```

**Key Features:**
- Singleton pattern (thread-safe)
- Integration with StorageService for persistence
- Integration with ApiService for API calls
- Conditional save to storage (registration doesn't auto-save)
- Comprehensive logging with emojis

#### Storage Service Location: `/lib/app/data/services/storage_service.dart`
**Keys Used:**
```
- auth_token - JWT token
- token_type - Bearer (default)
- user_data - Serialized UserModel JSON
- is_logged_in - Boolean flag
- onboarding_completed - Boolean flag
```

### 1.2 Authentication Modules

#### Login Module
**Path:** `/lib/app/modules/login/`
- **Controller:** `login_controller.dart`
- **View:** `login_view.dart`
- **Binding:** `login_binding.dart`

**Features:**
- Phone number input with country code selector
- PIN-based login
- Animation sequences for UI elements
- Full validation before submission
- Integration with AuthService

#### Register Module
**Path:** `/lib/app/modules/register/`
- **Controller:** `register_controller.dart`
- **View:** `register_view.dart`
- **Binding:** `register_binding.dart`

**Features:**
- Multi-step registration (step 0, 1, 2, 3)
- Username, phone, PIN (with confirmation)
- Legal page loading and acceptance
- Terms of service integration
- Country code support

#### Password Recovery Modules
- **ForgotPassword:** `/lib/app/modules/forgotpassword/`
- **ResetPassword:** `/lib/app/modules/resetpassword/`

### 1.3 API Endpoints (Auth)
**Base URL:** `http://10.74.254.28:8001/api/v1`

```
POST   /auth/register         - Register new user
POST   /auth/login            - Login user
POST   /auth/logout           - Logout user
GET    /auth/me               - Get current user profile
POST   /auth/refresh          - Refresh token
```

---

## 2. CHAT & MESSAGING IMPLEMENTATION

### 2.1 Chat Service
**File:** `/lib/app/data/services/chat_service.dart`

**Key Methods:**
```dart
- getConversations(page, perPage) - List all conversations with pagination
- getMessages(conversationId, page, perPage) - Get messages in conversation
- getConversation(conversationId) - Get conversation details
- getChatStats() - Get chat statistics
- markAsRead(conversationId) - Mark conversation as read
- startConversation(username) - Start or get existing conversation
- sendMessage(conversationId, content, type, media, metadata) - Send message
- updateMessage(conversationId, messageId, content) - Edit message
- deleteMessage(conversationId, messageId) - Delete message
- sendTypingIndicator(conversationId) - Send typing indicator
- deleteConversation(conversationId) - Delete entire conversation
- getTotalUnreadCount() - Get total unread across all chats
- sendGift(conversationId, giftId, message, isAnonymous) - Send gift
```

**Message Features:**
- **Types:** text, image, audio, video, gift, system
- **Rich Media:** Supports audio (with voice types), images, videos
- **Voice Types:** normal, robot, alien, mystery, chipmunk
- **Metadata:** Custom metadata support for extended message data
- **Gifts:** Send gifts with optional anonymous flag

**Pagination Response Models:**
```dart
ConversationListResponse {
  conversations: List<ConversationModel>,
  meta: ConversationPaginationMeta
}

ChatMessageListResponse {
  messages: List<ChatMessageModel>,
  meta: ChatMessagePaginationMeta
}

ChatStats {
  totalConversations: int,
  unreadConversations: int,
  totalMessages: int
}
```

### 2.2 Message Service
**File:** `/lib/app/data/services/message_service.dart`

**Purpose:** Handle anonymous messages (send to username without conversation)

**Key Methods:**
```dart
- getReceivedMessages(page, perPage) - Get received anonymous messages
- getSentMessages(page, perPage) - Get sent anonymous messages
- getUserShareLink() - Get user's share link for anonymous messages
- sendMessage(username, content, media, voiceType, gift, revealIdentity)
- sendReply(replyToMessageId, content, media, voiceType, gift, revealIdentity)
- deleteMessage(messageId) - Delete anonymous message
- markAsRead(messageId) - Mark as read
- markAllAsRead() - Mark all as read
- getMessageStats() - Get message statistics
- startConversationFromMessage(messageId) - Convert to conversation
```

**Message Stats Response:**
```dart
MessageStats {
  receivedCount: int,
  sentCount: int,
  unreadCount: int,
  revealedCount: int
}
```

### 2.3 Conversation State Service (Global)
**File:** `/lib/app/data/services/conversation_state_service.dart`

**Purpose:** Global service managing real-time conversation state across entire app

**Key Features:**
- Initialized in `main.dart` if user is authenticated
- Maintains global list of conversations (observable)
- Tracks total unread count (badge)
- Tracks current open conversation (prevents badge increment)
- Automatic WebSocket subscription to conversation channels
- Cache invalidation on conversation updates

**Observable Properties:**
```dart
- conversations: RxList<ConversationModel> - All conversations
- totalUnreadCount: RxInt - Sum of all unread messages
- unreadConversationsCount: RxInt - Number of unread conversations
- currentOpenConversationId: Rx<int?> - Currently viewed conversation
- isInitialized: RxBool - Initialization status
- isLoading: RxBool - Loading status
```

**Methods:**
```dart
- loadConversations(refresh) - Load conversations from API
- _subscribeToConversationChannels() - Subscribe to WebSocket channels
- _calculateBadgeCounts() - Update badge counts
```

### 2.4 Chat Modules

#### Chat Module (List View)
**Path:** `/lib/app/modules/chat/`
- **Controller:** `chat_controller.dart`
- **View:** `chat_view.dart`
- **Binding:** `chat_binding.dart`

**Features:**
- Display list of conversations
- Real-time updates via WebSocket
- Unread count badges
- Search/filter conversations
- Last message preview

#### Chat Detail Module (Conversation View)
**Path:** `/lib/app/modules/chat_detail/`
- **Controller:** `chat_detail_controller.dart`
- **View:** `chat_detail_view.dart`
- **Binding:** `chat_detail_binding.dart`

**Features:**
- Message list with pagination
- Real-time message reception
- Voice message recording/playback
- Image/video messaging
- Gift sending
- Message editing/deletion
- Reply to message functionality
- Typing indicator
- Audio player with progress tracking
- Message cache with `MessageCacheService`

### 2.5 Chat Message Model
**File:** `/lib/app/data/models/chat_message_model.dart`

```dart
ChatMessageModel {
  id: int,
  conversationId: int,
  senderId: int,
  sender: UserModel?,
  content: String?,
  type: ChatMessageType,
  mediaUrl: String?,
  metadata: Map<String, dynamic>?,
  giftData: ChatGiftData?,
  replyToMessage: ChatMessageModel?,
  createdAt: DateTime,
  updatedAt: DateTime,
  isEdited: bool
}

enum ChatMessageType { text, image, audio, video, gift, system }
```

### 2.6 Conversation Model
**File:** `/lib/app/data/models/conversation_model.dart`

```dart
ConversationModel {
  id: int,
  participantOneId: int?,
  participantTwoId: int?,
  otherParticipant: UserModel?,
  lastMessage: ChatMessageModel?,
  unreadCount: int,
  hasPremium: bool,
  isAnonymous: bool,
  identityRevealed: bool,
  canInitiateReveal: bool,
  anonymousMessageId: int?,
  createdAt: DateTime,
  updatedAt: DateTime?,
  lastMessageAt: DateTime?
}
```

### 2.7 Message Cache Service
**File:** `/lib/app/data/services/message_cache_service.dart`

**Purpose:** Local caching of messages and conversations

**Methods:**
```dart
- saveConversationsCache(conversations, page)
- getConversationsCache(page)
- saveMessageCache(conversationId, messages, page)
- getMessageCache(conversationId, page)
- invalidateConversationCache(conversationId)
- invalidateAllConversationsCache()
```

### 2.8 API Endpoints (Chat & Messages)
```
GET    /chat/conversations               - Get user's conversations
POST   /chat/conversations               - Start new conversation
GET    /chat/conversations/{id}          - Get conversation details
GET    /chat/conversations/{id}/messages - Get messages in conversation
POST   /chat/conversations/{id}/messages - Send message
PATCH  /chat/conversations/{id}/messages/{id} - Edit message
DELETE /chat/conversations/{id}/messages/{id} - Delete message
POST   /chat/conversations/{id}/read     - Mark as read
POST   /chat/conversations/{id}/typing   - Send typing indicator
POST   /chat/conversations/{id}/gift     - Send gift
DELETE /chat/conversations/{id}          - Delete conversation
GET    /chat/stats                       - Get chat statistics
GET    /chat/unread-count                - Get total unread count

GET    /messages                         - Get received anonymous messages
GET    /messages/sent                    - Get sent anonymous messages
POST   /messages/send/{username}         - Send anonymous message
POST   /messages/send/reply              - Reply to anonymous message
GET    /users/share-link                 - Get user's share link
GET    /messages/{id}                    - Get message details
DELETE /messages/{id}                    - Delete message
POST   /messages/read-all                - Mark all as read
GET    /messages/stats                   - Get message statistics
POST   /messages/{id}/start-conversation - Start conversation from message
```

---

## 3. REAL-TIME SYSTEM (WebSocket)

### 3.1 Realtime Service
**File:** `/lib/app/data/services/realtime_service.dart`

**Purpose:** WebSocket connection management with Laravel Reverb (Pusher protocol)

**Configuration:**
```dart
static const String wsHost = '10.74.254.28';
static const int wsPort = 8080;
static const String appKey = '1425cdd3ef7425fa6746d2895a233e52';
static const String appId = 'Weylo-app';
```

**WebSocket URL Format:**
```
ws://10.74.254.28:8080/app/1425cdd3ef7425fa6746d2895a233e52?protocol=7&client=js&version=8.4.0-rc2&flash=false
```

**Key Methods:**
```dart
- connect() - Establish WebSocket connection
- disconnect() - Close WebSocket connection
- subscribeToPrivateChannel(channelName, onEvent) - Subscribe to private channel
- unsubscribeFromChannel(channelName) - Unsubscribe from channel
- _authenticateChannel(channelName, socketId, token) - Get auth signature
- _handleMessage(message) - Process incoming messages
- _handleError(error) - Handle connection errors
- _handleDone() - Handle connection closure
- _resubscribeToAllChannels() - Auto-resubscribe after reconnection
```

**Observable State:**
```dart
- isConnected: RxBool - Connection status
- connectionState: RxString - 'connecting', 'connected', 'disconnecting', 'disconnected', 'error'
```

**Pusher Protocol Events:**
```
pusher:connection_established - Initial connection success
pusher_internal:subscription_succeeded - Channel subscription success
pusher:error - Pusher error
[Custom events] - App-specific events (e.g., 'message.sent')
```

**Channel Naming Conventions:**
- Private channels: `private-user.{userId}` - Per-user channel for all messages
- Private channels: `private-conversation.{conversationId}` - Per-conversation channel

**Authentication Flow:**
1. Connect to WebSocket → Receive socket_id
2. Call `/broadcasting/auth` endpoint with socket_id + token
3. Receive auth signature
4. Send subscribe message with auth signature
5. Server confirms subscription

---

## 4. API SERVICE ARCHITECTURE

### 4.1 API Service
**File:** `/lib/app/data/core/api_service.dart`

**Purpose:** Dio-based HTTP client with interceptors for all API requests

**Initialization:**
```dart
- init() - Set up Dio with base options and interceptors
```

**Methods:**
```dart
- get(path, queryParameters, options)
- post(path, data, queryParameters, options)
- put(path, data, queryParameters, options)
- delete(path, data, queryParameters, options)
- patch(path, data, queryParameters, options)
- uploadFile(path, formData, onSendProgress, options)
```

**Interceptors:**
- **onRequest:** Add auth header, set Content-Type, log requests
- **onResponse:** Log responses, detect HTML errors
- **onError:** Log errors, handle different error types

**Timeouts:**
```dart
connectTimeout: 30 seconds
receiveTimeout: 60 seconds
sendTimeout: 120 seconds (for large file uploads)
```

**Error Handling:**
- Converts DioException to custom ApiException
- Handles validation errors (extracts first error message)
- Network errors
- Timeout errors
- Unknown exceptions

### 4.2 API Configuration
**File:** `/lib/app/data/core/api_config.dart`

**Base URL:**
```
http://10.74.254.28:8001/api/v1
```

**Broadcasting/WebSocket Auth:**
```
POST /broadcasting/auth
```

**All Endpoints:** (see section 2.8 above)

---

## 5. MAIN APP STRUCTURE

### 5.1 Main Entry Point
**File:** `/lib/main.dart`

**Initialization Sequence:**
```dart
1. WidgetsFlutterBinding.ensureInitialized()
2. StorageService.init() - Initialize local storage
3. ApiService().init() - Set up HTTP client
4. DeeplinkService().init() - Initialize deep linking
5. Check if user is logged in:
   - If yes: Initialize ConversationStateService globally
   - If no: Skip (will be initialized on login)
6. Configure system UI (status bar)
7. Launch GetMaterialApp
```

**Initial Route:** SPLASHSCREEN

### 5.2 App Configuration
**File:** `/lib/app/widgets/app_theme_system.dart`

**Features:**
- Light and dark themes
- Theme follows system settings
- Material Design 3

### 5.3 Routing System
**File:** `/lib/app/routes/app_pages.dart`

**Routes:**
```
/ (INITIAL) → SPLASHSCREEN
/home → HOME (authenticated main screen)
/login → LOGIN
/register → REGISTER
/welcomer → WELCOMER (pre-auth)
/onboarding → ONBOARDING
/chat → CHAT (conversations list)
/chat-detail → CHAT_DETAIL (conversation view)
/anonymepage → ANONYMEPAGE (anonymous messages)
/feeds → FEEDS (confessions/stories)
/profile → PROFILE
/edit-profile → EDITPROFILE
/settings → SEETING
/notification → NOTIFICATION
/forgot-password → FORGOTPASSWORD
/reset-password → RESETPASSWORD
/groups → GROUPE
/send-message → SENDMESSAGE
/wallet → MY_WALLET
/deposit → WALLET_DEPOSIT
/withdraw → WALLET_WITHDRAW
/sponsoring → SPONSORING
```

### 5.4 Deep Linking
**File:** `/lib/app/data/services/deeplink_service.dart`

**Purpose:** Handle app links and navigation

**Methods:**
```dart
- init() - Initialize deep link listener
```

### 5.5 Module Structure Pattern

Each module follows GetX pattern:
```
module/
├── bindings/
│   └── {module}_binding.dart (dependency injection)
├── controllers/
│   └── {module}_controller.dart (business logic)
└── views/
    └── {module}_view.dart (UI)
```

**Example: Chat Module**
```
chat/
├── bindings/chat_binding.dart
├── controllers/chat_controller.dart
└── views/chat_view.dart
```

---

## 6. FCM & NOTIFICATION SETUP

### 6.1 Current Status: NOT IMPLEMENTED

**Findings:**
- ❌ No Firebase integration
- ❌ No FCM (Firebase Cloud Messaging) setup
- ❌ No cloud_messaging package in pubspec.yaml
- ❌ NotificationController exists but is NOT implemented (TODO comment)
- ✅ Notification module exists but only as UI placeholder

### 6.2 Notification Module
**File:** `/lib/app/modules/notification/`

**Current Implementation:**
- Basic controller with count observable
- No actual notification handling
- No push notification listeners
- No notification persistence

### 6.3 Recommendation for Implementation
Would need to add:
1. `firebase_messaging` package
2. FCM token management
3. Foreground/background notification handlers
4. Local notifications (flutter_local_notifications)
5. Notification routing/navigation
6. Badge count management

---

## 7. DATA MODELS

### 7.1 User Model
**File:** `/lib/app/data/models/user_model.dart`

```dart
UserModel {
  id: int,
  firstName: String,
  lastName: String?,
  fullName: String,
  username: String,
  email: String,
  phone: String,
  avatar: String?,
  avatarUrl: String?,
  coverPhoto: String?,
  coverPhotoUrl: String?,
  bio: String?,
  profileUrl: String?,
  isVerified: bool,
  isOnline: bool,
  role: String?,
  walletBalance: double,
  formattedBalance: String?,
  settings: Map<String, dynamic>?,
  isPremium: bool,
  hasActivePremium: bool,
  premiumStartedAt: DateTime?,
  premiumExpiresAt: DateTime?,
  premiumAutoRenew: bool,
  premiumDaysRemaining: int?,
  isBanned: bool,
  bannedReason: String?,
  emailVerifiedAt: DateTime?,
  phoneVerifiedAt: DateTime?,
  lastSeenAt: DateTime?,
  createdAt: DateTime,
  updatedAt: DateTime
}
```

### 7.2 Auth Response Model
**File:** `/lib/app/data/models/auth_response_model.dart`

```dart
AuthResponseModel {
  token: String,
  tokenType: String,
  user: UserModel
}
```

---

## 8. DEPENDENCIES (pubspec.yaml)

### Key Packages:
```yaml
# State Management & Navigation
get: ^4.7.3

# HTTP Client
dio: ^5.7.0

# Local Storage
get_storage: ^2.1.1

# WebSocket
web_socket_channel: ^3.0.1
pusher_channels_flutter: ^2.4.0
socket_io_client: ^2.0.3+1

# Media Handling
image_picker: ^1.1.2
video_player: ^2.9.2
image_editor_plus: ^1.0.8
video_thumbnail: ^0.5.3
flutter_sound: ^9.16.3
audioplayers: ^6.1.0

# UI Components
flutter_svg: ^2.0.16
lottie: ^3.1.3
google_fonts: ^8.0.1
intl_phone_field: ^3.2.0
pinput: ^5.0.0

# Permissions
permission_handler: ^12.0.1

# Other
app_links: ^7.0.0 (deep linking)
share_plus: ^12.0.1
package_info_plus: ^8.1.2
```

**Notable Absences:**
- ❌ firebase_messaging (FCM)
- ❌ flutter_local_notifications
- ❌ firebase_core
- ❌ firebase_crashlytics

---

## 9. KEY SERVICE PATTERNS

### 9.1 Singleton Pattern
All services use singleton pattern:
```dart
class ServiceName {
  static final ServiceName _instance = ServiceName._internal();
  factory ServiceName() => _instance;
  ServiceName._internal();
  
  // Implementation
}
```

### 9.2 Initialization Order
1. StorageService - Local data persistence
2. ApiService - HTTP client setup
3. DeeplinkService - Deep link handling
4. AuthService - Check if logged in
5. ConversationStateService - Global chat state (if logged in)

### 9.3 Observable Patterns (GetX)
```dart
final isLoading = false.obs;        // RxBool
final messages = <Model>[].obs;     // RxList<Model>
final selectedItem = Rx<Model?>(null); // Rx<Model?>
```

---

## 10. SUMMARY TABLE

| Component | Location | Status | Purpose |
|-----------|----------|--------|---------|
| AuthService | `/services/auth_service.dart` | Implemented | User authentication |
| ChatService | `/services/chat_service.dart` | Implemented | Chat operations |
| MessageService | `/services/message_service.dart` | Implemented | Anonymous messages |
| RealtimeService | `/services/realtime_service.dart` | Implemented | WebSocket management |
| ConversationStateService | `/services/conversation_state_service.dart` | Implemented | Global chat state |
| ApiService | `/core/api_service.dart` | Implemented | HTTP client |
| StorageService | `/services/storage_service.dart` | Implemented | Local storage |
| FCM Setup | N/A | NOT IMPLEMENTED | Push notifications |
| Notification Module | `/modules/notification/` | Placeholder Only | Notification UI |

---

## 11. LANGUAGE
Application is in **French** (all logs, comments, UI strings)
