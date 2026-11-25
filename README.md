# StreamRecorder for iOS (Kotlin Multiplatform + Native Xcode)

Recreated 1:1 after **StreamRecorder** (`id6754601768`) using **Kotlin Multiplatform (`2.4.21`)**, **Compose Multiplatform (`1.12.2`)**, and **Native iOS `AVFoundation` / `AVKit` / `WKWebView` / `Photos`** wrapped in an Xcode project (`iosApp/`) with automated `.ipa` builds on GitHub Actions & GitLab CI.

## Features
- **Search & Monitor Streamers (`Twitch, Kick, TikTok, YouTube, SOOP, BiliBili, Chzzk`)**: Monitor creators or paste any direct `.m3u8` / `.mp4` live stream link to capture immediately.
- **Built-in Live Stream Sniffer (`WKWebView`)**: Browse live broadcast pages and auto-detect `.m3u8` / `.mp4` streams for 1-tap recording.
- **HD Recordings Archive (`List ☰ / Grid ⊞`)**: Watch live or archived streams via native `AVPlayerViewController` (with Picture-in-Picture) and download offline MP4 files to `Documents/Recordings/`.
- **Clip Studio (`Clip ✂️` -> `Save ▷`)**: Trim any recording with start/end handles and export real `.mp4` clips via `AVAssetExportSession`.
- **Your Clips**: Manage clips in List/Grid view, rename titles inline, Share, or save directly to the **iPhone Photos Library**.

## Building the `.ipa`
Push to `main` (or click **Run workflow** under **Actions -> Build iOS IPA (Kotlin Multiplatform)**) and download **`StreamRecorder-iOS-IPA`** from the **Artifacts** section.
