# LiveVault iOS (Pure Swift & SwiftUI)

Production-grade iOS native application for **LiveVault** — Automated 24/7 Livestream Recording & Cloud Archival for Content Creators.

Built with **Swift 5.10+ / Swift 6**, **SwiftUI**, **Modular Swift Packages (SPM)**, **SwiftData (Offline-First)**, and **AVFoundation (HLS with Auto-Refresh & PiP)**.

---

## 🏛️ Architecture & Module Structure

The project follows a **Modular Clean Architecture** matching the Android architecture (`:core:*` and `:feature:*`):

```
StreamAppIos/
├── Package.swift                             # Modular Swift Package definition
├── Sources/
│   ├── LiveVaultCommon/                     # Constants, Enums, AppError, Byte/Duration Formatters
│   ├── LiveVaultNetwork/                    # URLSession APIClient, Codable DTOs, AuthInterceptor, KeychainTokenStorage
│   ├── LiveVaultDatabase/                   # SwiftData Models (Channel, Recording, Notification, Download)
│   ├── LiveVaultDesignSystem/               # Colors (#E50914, #0B0E14), Typography, LiveBadge, StorageUsageBar, Shimmer
│   ├── FeatureAuth/                         # Splash/Onboarding, Login, Register, Sign in with Apple / Google
│   ├── FeatureHome/                         # Home Dashboard, Channel Carousel with LiveBadge, Active Sessions
│   ├── FeatureChannel/                      # Add Channel (Platform selector, Mandatory Consent Screen & Audit Trail)
│   ├── FeatureLibrary/                      # Library (All / Downloaded tabs), Infinite Scroll, Real-time progress
│   ├── FeaturePlayer/                       # AVPlayer HLS, PiP, Custom Controls, Auto-Refresh Signed URL at min 12-13
│   ├── FeatureRecordingDetail/              # Metadata, Rename (PATCH), Delete (DELETE), Download (PRO/PREMIUM)
│   ├── FeatureNotifications/                # Push notification list, Read/Unread filters, Deep link to Player
│   ├── FeatureSettings/                     # User Profile, StorageUsageBar (>80% warning), Push toggle, Legal
│   ├── FeaturePaywall/                      # StoreKit 2 & RevenueCat, Tier Comparison Table (Free vs Pro vs Premium)
│   └── LiveVaultAppCore/                    # RootView, AppRouter, DownloadManager, PushNotificationManager, DeepLinkManager
└── Tests/
    ├── LiveVaultNetworkTests/               # MockURLProtocol tests, 401 token refresh retry tests
    └── LiveVaultViewModelTests/             # AuthViewModel, HomeViewModel, Signed URL Auto-Refresh Player tests, Storage tests
```

---

## 🚀 Key Technical Capabilities

1. **AVPlayer HLS & Signed URL Auto-Refresh**:
   - Presigned playback URLs expire after 15 minutes (`TTL = 900s`).
   - `PlayerViewModel` proactively invokes `GET /api/v1/recordings/:id` at **minute 12–13**, silently swaps the `AVPlayerItem`, and seeks to the exact `currentTime` to avoid any playback interruption or 403 Forbidden errors.
   - Picture-in-Picture (`AVPictureInPictureController`) and Background Audio playback.

2. **Offline-First SwiftData Architecture**:
   - `LibraryViewModel` loads cached recordings from local `SwiftData` immediately for instant startup.
   - Synchronizes with backend `GET /api/v1/recordings` in background.

3. **Background Video Downloads (`URLSessionConfiguration.background`)**:
   - Equivalent to Android WorkManager.
   - Supports HTTP Range resume, pause/cancel, progress callbacks, and saves directly to `Documents/Recordings/`.

4. **Legal Consent & Compliance Audit Trail**:
   - Mandatory `ChannelConsentView` requiring explicit user certification of channel ownership/authorization before calling `POST /api/v1/channels` with `consentConfirmed: true`.

5. **Deep Linking & Push Notifications**:
   - Custom scheme `livevault://recording/{id}` and Universal Links `https://livevault.app/recording/{id}`.
   - Push notifications (`RECORDING_COMPLETE`, `RECORDING_FAILED`, `STORAGE_QUOTA_WARNING`) deep link directly into the Player or Storage settings.

6. **Automatic 401 Token Refresh (`AuthInterceptor`)**:
   - Intercepts `401 Unauthorized` responses, calls `POST /api/v1/auth/refresh`, updates the secure Keychain token storage, and retries the original request seamlessly.

---

## 🧪 Testing

Run unit tests via command line or Xcode:
```bash
swift test
```
Or open `Package.swift` directly in Xcode on macOS (`Product -> Test` / `Cmd+U`).
