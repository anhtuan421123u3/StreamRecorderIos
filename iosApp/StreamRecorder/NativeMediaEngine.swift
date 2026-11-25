import Foundation
import UIKit
import AVFoundation
import AVKit
import CoreMedia
import WebKit
import Photos
import ComposeApp

final class NativeMediaEngine: NSObject, IosNativeDelegate {
    static let shared = NativeMediaEngine()

    private var playerObservers: [ObjectIdentifier: (player: AVPlayer, token: Any, url: String)] = [:]
    private var lastAppliedSeek: [ObjectIdentifier: Double] = [:]

    override private init() {
        super.init()
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Audio session best-effort
        }
    }

    private func resolveMediaURL(_ urlOrPath: String) -> URL? {
        if urlOrPath.hasPrefix("http://") || urlOrPath.hasPrefix("https://") {
            return URL(string: urlOrPath)
        }
        return URL(fileURLWithPath: urlOrPath)
    }

    private func recordingsDirectory() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func clipsDirectory() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Clips", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // MARK: - Native AVPlayerViewController

    func createPlayerViewController(
        urlOrPath: String,
        autoPlay: Bool,
        listener: any IosPlaybackListener
    ) -> UIViewController {
        let playerVC = AVPlayerViewController()
        playerVC.showsPlaybackControls = true
        playerVC.allowsPictureInPicturePlayback = true
        playerVC.view.backgroundColor = .black

        guard let mediaURL = resolveMediaURL(urlOrPath) else {
            return playerVC
        }

        let player = AVPlayer(url: mediaURL)
        playerVC.player = player

        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        let token = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak player] time in
            guard let player = player else { return }
            let cur = CMTimeGetSeconds(time)
            let rawDur = player.currentItem.map { CMTimeGetSeconds($0.duration) } ?? 0.0
            let safeCur = cur.isFinite && cur >= 0 ? cur : 0.0
            let safeDur = rawDur.isFinite && rawDur > 0 ? rawDur : 0.0
            listener.onTimeUpdate(currentSec: safeCur, durationSec: safeDur)
        }

        let key = ObjectIdentifier(playerVC)
        playerObservers[key] = (player: player, token: token, url: urlOrPath)

        if autoPlay {
            player.play()
        }
        return playerVC
    }

    func updatePlayerState(
        controller: UIViewController,
        urlOrPath: String,
        isPlaying: Bool,
        seekSeconds: Double
    ) {
        guard let playerVC = controller as? AVPlayerViewController,
              let player = playerVC.player else { return }
        let key = ObjectIdentifier(playerVC)

        if let entry = playerObservers[key], entry.url != urlOrPath, let newURL = resolveMediaURL(urlOrPath) {
            player.replaceCurrentItem(with: AVPlayerItem(url: newURL))
            playerObservers[key] = (player: player, token: entry.token, url: urlOrPath)
        }

        if seekSeconds >= 0 {
            let prevSeek = lastAppliedSeek[key] ?? -999.0
            if abs(prevSeek - seekSeconds) > 0.25 {
                lastAppliedSeek[key] = seekSeconds
                let target = CMTime(seconds: seekSeconds, preferredTimescale: 600)
                player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero) { _ in }
            }
        }

        if isPlaying {
            if player.timeControlStatus != .playing {
                player.play()
            }
        } else {
            if player.timeControlStatus != .paused {
                player.pause()
            }
        }
    }

    func releasePlayer(controller: UIViewController) {
        let key = ObjectIdentifier(controller)
        if let entry = playerObservers.removeValue(forKey: key) {
            entry.player.removeTimeObserver(entry.token)
            entry.player.pause()
        }
        lastAppliedSeek.removeValue(forKey: key)
        if let playerVC = controller as? AVPlayerViewController {
            playerVC.player = nil
        }
    }

    // MARK: - WKWebView Live Stream Sniffer (.m3u8 & .mp4)

    func createWebSnifferViewController(
        initialUrl: String,
        listener: any IosSnifferListener
    ) -> UIViewController {
        let vc = WebSnifferHostController(initialUrl: initialUrl, listener: listener)
        return vc
    }

    func loadUrlInSniffer(controller: UIViewController, url: String) {
        (controller as? WebSnifferHostController)?.loadAddress(url)
    }

    // MARK: - Stream / Video Download to Local Documents/Recordings

    func downloadStream(
        recordingId: String,
        streamUrl: String,
        suggestedFileName: String,
        listener: any IosTaskListener
    ) {
        guard let remoteURL = URL(string: streamUrl) else {
            listener.onFinished(success: false, pathOrMessage: "Invalid stream URL")
            return
        }

        let cleanBase = suggestedFileName
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
        let destURL = recordingsDirectory().appendingPathComponent("\(cleanBase).mp4")

        // If HLS (.m3u8), export stream segment via AVAssetExportSession; if direct MP4, download directly via URLSession
        if streamUrl.lowercased().contains(".m3u8") {
            let asset = AVURLAsset(url: remoteURL)
            guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
                listener.onFinished(success: false, pathOrMessage: "HLS stream protected or unsupported")
                return
            }
            try? FileManager.default.removeItem(at: destURL)
            exporter.outputURL = destURL
            exporter.outputFileType = .mp4
            exporter.shouldOptimizeForNetworkUse = true
            // Cap live HLS snapshot export to 30 seconds if live/indefinite so export completes reliably
            exporter.timeRange = CMTimeRange(
                start: .zero,
                duration: CMTime(seconds: 30.0, preferredTimescale: 600)
            )
            listener.onProgress(progress: 0.35)
            exporter.exportAsynchronously {
                DispatchQueue.main.async {
                    if exporter.status == .completed {
                        listener.onProgress(progress: 1.0)
                        listener.onFinished(success: true, pathOrMessage: destURL.path)
                    } else {
                        let msg = exporter.error?.localizedDescription ?? "HLS export finished"
                        listener.onFinished(success: false, pathOrMessage: msg)
                    }
                }
            }
        } else {
            listener.onProgress(progress: 0.2)
            let task = URLSession.shared.downloadTask(with: remoteURL) { tempURL, _, error in
                DispatchQueue.main.async {
                    if let error = error {
                        listener.onFinished(success: false, pathOrMessage: error.localizedDescription)
                        return
                    }
                    guard let tempURL = tempURL else {
                        listener.onFinished(success: false, pathOrMessage: "Empty download response")
                        return
                    }
                    try? FileManager.default.removeItem(at: destURL)
                    do {
                        try FileManager.default.moveItem(at: tempURL, to: destURL)
                        listener.onProgress(progress: 1.0)
                        listener.onFinished(success: true, pathOrMessage: destURL.path)
                    } catch {
                        listener.onFinished(success: false, pathOrMessage: error.localizedDescription)
                    }
                }
            }
            task.resume()
        }
    }

    // MARK: - Clip Trimmer via AVAssetExportSession

    func trimClipToMp4(
        sourceUrlOrPath: String,
        startSec: Double,
        endSec: Double,
        outputClipName: String,
        listener: any IosTaskListener
    ) {
        guard let sourceURL = resolveMediaURL(sourceUrlOrPath) else {
            listener.onFinished(success: false, pathOrMessage: "Invalid source video URL")
            return
        }

        let asset = AVURLAsset(url: sourceURL)
        let preset = AVAssetExportPresetHighestQuality
        guard let exporter = AVAssetExportSession(asset: asset, presetName: preset) else {
            listener.onFinished(success: false, pathOrMessage: "Unable to initialize AVAssetExportSession")
            return
        }

        let destURL = clipsDirectory().appendingPathComponent("\(outputClipName).mp4")
        try? FileManager.default.removeItem(at: destURL)

        let safeStart = max(0.0, startSec)
        let safeDuration = max(1.0, endSec - safeStart)
        let startCM = CMTime(seconds: safeStart, preferredTimescale: 600)
        let durationCM = CMTime(seconds: safeDuration, preferredTimescale: 600)

        exporter.outputURL = destURL
        exporter.outputFileType = .mp4
        exporter.timeRange = CMTimeRange(start: startCM, duration: durationCM)
        exporter.shouldOptimizeForNetworkUse = true

        listener.onProgress(progress: 0.4)
        exporter.exportAsynchronously {
            DispatchQueue.main.async {
                if exporter.status == .completed {
                    listener.onProgress(progress: 1.0)
                    listener.onFinished(success: true, pathOrMessage: destURL.path)
                } else {
                    let errMsg = exporter.error?.localizedDescription ?? "Clip saved as timestamp bookmark"
                    listener.onFinished(success: false, pathOrMessage: errMsg)
                }
            }
        }
    }

    // MARK: - Save Clip / Video to iPhone Photos Library

    func saveVideoToPhotoLibrary(
        filePathOrUrl: String,
        listener: any IosTaskListener
    ) {
        if filePathOrUrl.hasPrefix("http://") || filePathOrUrl.hasPrefix("https://") {
            // Download remote clip first, then save to Photos
            guard let remote = URL(string: filePathOrUrl) else {
                listener.onFinished(success: false, pathOrMessage: "Invalid video URL")
                return
            }
            let tempDest = clipsDirectory().appendingPathComponent("photos_export_\(Int(Date().timeIntervalSince1970)).mp4")
            URLSession.shared.downloadTask(with: remote) { tmp, _, err in
                if let err = err {
                    DispatchQueue.main.async {
                        listener.onFinished(success: false, pathOrMessage: err.localizedDescription)
                    }
                    return
                }
                guard let tmp = tmp else { return }
                try? FileManager.default.removeItem(at: tempDest)
                try? FileManager.default.moveItem(at: tmp, to: tempDest)
                self.performPhotoLibrarySave(localFileURL: tempDest, listener: listener)
            }.resume()
        } else {
            let localURL = URL(fileURLWithPath: filePathOrUrl)
            performPhotoLibrarySave(localFileURL: localURL, listener: listener)
        }
    }

    private func performPhotoLibrarySave(localFileURL: URL, listener: any IosTaskListener) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    listener.onFinished(success: false, pathOrMessage: "Photos permission denied in iOS Settings")
                }
                return
            }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: localFileURL)
            }) { ok, error in
                DispatchQueue.main.async {
                    if ok {
                        listener.onFinished(success: true, pathOrMessage: "Saved to iPhone Photos")
                    } else {
                        listener.onFinished(success: false, pathOrMessage: error?.localizedDescription ?? "Could not save video")
                    }
                }
            }
        }
    }

    // MARK: - Share Sheet & Storage Management

    func shareItem(filePathOrUrl: String, title: String) {
        DispatchQueue.main.async {
            let itemToShare: Any
            if filePathOrUrl.hasPrefix("http://") || filePathOrUrl.hasPrefix("https://"),
               let url = URL(string: filePathOrUrl) {
                itemToShare = url
            } else {
                itemToShare = URL(fileURLWithPath: filePathOrUrl)
            }

            let activityVC = UIActivityViewController(activityItems: [title, itemToShare], applicationActivities: nil)
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = scene.windows.first?.rootViewController {
                if let pop = activityVC.popoverPresentationController {
                    pop.sourceView = rootVC.view
                    pop.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 1, height: 1)
                }
                rootVC.present(activityVC, animated: true)
            }
        }
    }

    func getStorageSummary() -> String {
        let fm = FileManager.default
        let dirs = [recordingsDirectory(), clipsDirectory()]
        var totalBytes: Int64 = 0
        var fileCount = 0

        for dir in dirs {
            if let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.fileSizeKey]) {
                for f in files {
                    let size = (try? f.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                    totalBytes += Int64(size)
                    fileCount += 1
                }
            }
        }

        let formatted = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
        return "Offline MP4 Files: \(fileCount) files (\(formatted)) in Documents/Recordings & Clips"
    }

    func clearDownloadsDirectory() -> Bool {
        let fm = FileManager.default
        for dir in [recordingsDirectory(), clipsDirectory()] {
            if let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                for f in files {
                    try? fm.removeItem(at: f)
                }
            }
        }
        return true
    }
}

// MARK: - Dedicated WKWebView Stream Sniffer Controller

final class WebSnifferHostController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {
    private let listener: any IosSnifferListener
    private var webView: WKWebView!
    private let initialUrl: String
    private var lastLoadedUrl: String = ""

    init(initialUrl: String, listener: any IosSnifferListener) {
        self.initialUrl = initialUrl
        self.listener = listener
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.03, green: 0.02, blue: 0.07, alpha: 1.0)

        let contentController = WKUserContentController()
        contentController.add(self, name: "srSniffer")

        let snifferJS = """
        (function() {
            if (window.__srHooked) return;
            window.__srHooked = true;
            var seen = {};
            function notify(rawUrl) {
                if (!rawUrl || typeof rawUrl !== 'string') return;
                try { rawUrl = new URL(rawUrl, window.location.href).href; } catch(e) { return; }
                if (seen[rawUrl]) return;
                var lower = rawUrl.toLowerCase();
                var kind = null;
                if (lower.indexOf('.m3u8') !== -1) kind = 'HLS (.m3u8)';
                else if (lower.indexOf('.mp4') !== -1) kind = 'MP4 Stream';
                if (kind && window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.srSniffer) {
                    seen[rawUrl] = true;
                    window.webkit.messageHandlers.srSniffer.postMessage({
                        url: rawUrl,
                        typeLabel: kind,
                        pageTitle: document.title || 'Live Broadcast'
                    });
                }
            }
            var origFetch = window.fetch;
            if (origFetch) {
                window.fetch = function() {
                    var arg = arguments[0];
                    notify(typeof arg === 'string' ? arg : (arg ? arg.url : ''));
                    return origFetch.apply(this, arguments);
                };
            }
            var origOpen = XMLHttpRequest.prototype.open;
            XMLHttpRequest.prototype.open = function(m, u) {
                notify(u);
                return origOpen.apply(this, arguments);
            };
            document.addEventListener('play', function(e) {
                if (e.target && e.target.currentSrc) notify(e.target.currentSrc);
            }, true);
        })();
        """

        let script = WKUserScript(source: snifferJS, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        contentController.addUserScript(script)

        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.userContentController = contentController

        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        view.addSubview(webView)

        loadAddress(initialUrl)
    }

    func loadAddress(_ urlString: String) {
        guard isViewLoaded, urlString != lastLoadedUrl, let url = URL(string: urlString) else { return }
        lastLoadedUrl = urlString
        webView.load(URLRequest(url: url))
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "srSniffer",
              let dict = message.body as? [String: Any],
              let url = dict["url"] as? String else { return }
        let typeLabel = (dict["typeLabel"] as? String) ?? "HLS (.m3u8)"
        let title = (dict["pageTitle"] as? String) ?? "Live Stream"
        DispatchQueue.main.async {
            self.listener.onStreamDetected(url: url, typeLabel: typeLabel, pageTitle: title)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url?.absoluteString {
            lastLoadedUrl = current
            listener.onUrlChanged(currentUrl: current)
        }
    }
}
