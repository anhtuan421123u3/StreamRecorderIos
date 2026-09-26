import Foundation
import AVFoundation
import AVKit
import SwiftUI
import LiveVaultCommon
import LiveVaultNetwork

@Observable
public final class PlayerViewModel: NSObject, @unchecked Sendable {
    public var recordingId: String
    public var recordingDetail: RecordingDetailDTO? = nil
    public var isPlaying = false
    public var currentTime: Double = 0.0
    public var duration: Double = 0.0
    public var isBuffering = false
    public var isControlsVisible = true
    public var isPictureInPictureActive = false
    public var isPictureInPictureSupported = AVPictureInPictureController.isPictureInPictureSupported()
    public var errorMessage: String? = nil
    
    // Auto-refresh signed URL state
    public var signedUrlExpiresAt: Date? = nil
    public var lastRefreshedAt: Date? = nil
    
    public var player: AVPlayer? = nil
    private var pipController: AVPictureInPictureController? = nil
    private var timeObserverToken: Any? = nil
    private var autoRefreshTask: Task<Void, Never>? = nil
    private var hideControlsTask: Task<Void, Never>? = nil
    
    private let apiClient: APIClientProtocol
    
    public init(recordingId: String, apiClient: APIClientProtocol = APIClient.shared) {
        self.recordingId = recordingId
        self.apiClient = apiClient
        super.init()
        setupAudioSession()
    }
    
    deinit {
        cleanup()
    }
    
    public func cleanup() {
        autoRefreshTask?.cancel()
        hideControlsTask?.cancel()
        if let token = timeObserverToken, let player = player {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
        player?.pause()
        player = nil
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }
    
    // MARK: - Load Recording & Setup Player
    @MainActor
    public func loadAndPlay() async {
        isBuffering = true
        errorMessage = nil
        
        do {
            let detail: RecordingDetailDTO = try await apiClient.request(
                path: "/api/v1/recordings/\(recordingId)",
                method: "GET",
                queryItems: nil,
                body: nil,
                requiresAuth: true
            )
            self.recordingDetail = detail
            
            // Prefer HLS manifest URL, fallback to playbackUrl
            guard let urlString = detail.hlsPlaybackUrl ?? detail.playbackUrl, let url = URL(string: urlString) else {
                self.errorMessage = "No playable stream URL available."
                self.isBuffering = false
                return
            }
            
            self.lastRefreshedAt = Date()
            self.signedUrlExpiresAt = Date().addingTimeInterval(LiveVaultConstants.signedUrlDurationSeconds)
            
            setupPlayer(with: url, seekToTime: currentTime)
            scheduleProactiveSignedUrlRefresh()
            resetControlsHideTimer()
        } catch {
            self.isBuffering = false
            self.errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    private func setupPlayer(with url: URL, seekToTime: Double) {
        let playerItem = AVPlayerItem(url: url)
        
        if let existingPlayer = self.player {
            existingPlayer.replaceCurrentItem(with: playerItem)
        } else {
            let newPlayer = AVPlayer(playerItem: playerItem)
            self.player = newPlayer
            attachTimeObserver(to: newPlayer)
        }
        
        if seekToTime > 0 {
            let cmTime = CMTime(seconds: seekToTime, preferredTimescale: 600)
            player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        }
        
        player?.play()
        self.isPlaying = true
        self.isBuffering = false
    }
    
    private func attachTimeObserver(to player: AVPlayer) {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            if let duration = player.currentItem?.duration.seconds, !duration.isNaN {
                self.duration = duration
            }
        }
    }
    
    // MARK: - Auto-Refresh Signed Playback URL (Proactive at 12-13 mins & Reactive on 403)
    public func scheduleProactiveSignedUrlRefresh() {
        autoRefreshTask?.cancel()
        
        // Refresh 2-3 mins before 15 min expiration
        let refreshDelay = LiveVaultConstants.signedUrlDurationSeconds - LiveVaultConstants.signedUrlRefreshThresholdSeconds
        
        autoRefreshTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: UInt64(refreshDelay * 1_000_000_000))
                guard let self = self, !Task.isCancelled else { return }
                await self.refreshSignedPlaybackUrlSilently()
            } catch {
                // Task cancelled
            }
        }
    }
    
    @MainActor
    public func refreshSignedPlaybackUrlSilently() async {
        let savedCurrentTime = self.currentTime
        let wasPlaying = self.isPlaying
        
        do {
            let detail: RecordingDetailDTO = try await apiClient.request(
                path: "/api/v1/recordings/\(recordingId)",
                method: "GET",
                queryItems: nil,
                body: nil,
                requiresAuth: true
            )
            self.recordingDetail = detail
            
            guard let urlString = detail.hlsPlaybackUrl ?? detail.playbackUrl, let newUrl = URL(string: urlString) else {
                return
            }
            
            self.lastRefreshedAt = Date()
            self.signedUrlExpiresAt = Date().addingTimeInterval(LiveVaultConstants.signedUrlDurationSeconds)
            
            // Swap AVPlayerItem seamlessly at current timestamp
            let newItem = AVPlayerItem(url: newUrl)
            self.player?.replaceCurrentItem(with: newItem)
            
            if savedCurrentTime > 0 {
                let cmTime = CMTime(seconds: savedCurrentTime, preferredTimescale: 600)
                self.player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
            }
            
            if wasPlaying {
                self.player?.play()
            }
            
            // Schedule next proactive refresh cycle
            scheduleProactiveSignedUrlRefresh()
        } catch {
            print("Silent signed URL refresh failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Player Controls
    @MainActor
    public func togglePlayPause() {
        if isPlaying {
            player?.pause()
            isPlaying = false
        } else {
            player?.play()
            isPlaying = true
        }
        resetControlsHideTimer()
    }
    
    @MainActor
    public func seekRelative(by seconds: Double) {
        let target = max(0, min(duration, currentTime + seconds))
        seek(to: target)
    }
    
    @MainActor
    public func seek(to seconds: Double) {
        let cmTime = CMTime(seconds: seconds, preferredTimescale: 600)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = seconds
        resetControlsHideTimer()
    }
    
    @MainActor
    public func toggleControlsVisibility() {
        isControlsVisible.toggle()
        if isControlsVisible {
            resetControlsHideTimer()
        }
    }
    
    public func resetControlsHideTimer() {
        hideControlsTask?.cancel()
        hideControlsTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            if self.isPlaying {
                self.isControlsVisible = false
            }
        }
    }
}
