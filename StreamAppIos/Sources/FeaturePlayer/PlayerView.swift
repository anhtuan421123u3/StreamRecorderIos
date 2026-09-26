import SwiftUI
import AVKit
import LiveVaultCommon
import LiveVaultDesignSystem

public struct PlayerView: View {
    @State private var viewModel: PlayerViewModel
    @Environment(\.dismiss) private var dismiss
    
    public init(recordingId: String) {
        _viewModel = State(initialValue: PlayerViewModel(recordingId: recordingId))
    }
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Video Player Layer
            if let player = viewModel.player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onTapGesture {
                        viewModel.toggleControlsVisibility()
                    }
            } else if viewModel.isBuffering {
                ProgressView("Loading Stream...")
                    .tint(.white)
                    .foregroundColor(.white)
            }
            
            // Custom Player Overlay Controls
            if viewModel.isControlsVisible {
                playerControlsOverlay
                    .transition(.opacity)
            }
            
            // Error Message
            if let error = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(LiveVaultColors.amberWarning)
                    Text("Playback Error")
                        .font(LiveVaultTypography.titleMedium)
                        .foregroundColor(.white)
                    Text(error)
                        .font(LiveVaultTypography.caption)
                        .foregroundColor(LiveVaultColors.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Retry") {
                        Task {
                            await viewModel.loadAndPlay()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(LiveVaultColors.indigoPrimary)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(24)
                .background(Color.black.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .statusBarHidden(true)
        .task {
            await viewModel.loadAndPlay()
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
    
    private var playerControlsOverlay: some View {
        VStack {
            // Top Bar: Back button, Title, PiP, Quality Info
            HStack(spacing: 16) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.recordingDetail?.title ?? "Livestream Playback")
                        .font(LiveVaultTypography.bodyLarge)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(viewModel.recordingDetail?.channel?.displayName ?? "")
                        .font(LiveVaultTypography.caption)
                        .foregroundColor(LiveVaultColors.textSecondary)
                }
                
                Spacer()
                
                // Live or HLS Indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(LiveVaultColors.emeraldSuccess)
                        .frame(width: 6, height: 6)
                    Text("HLS 1080p")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.6))
                .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            Spacer()
            
            // Center Play / Pause & Skip Buttons
            HStack(spacing: 40) {
                Button(action: { viewModel.seekRelative(by: -10) }) {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
                
                Button(action: { viewModel.togglePlayPause() }) {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.white)
                }
                
                Button(action: { viewModel.seekRelative(by: 10) }) {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            // Bottom Bar: Scrubber & Timers
            VStack(spacing: 6) {
                // Scrubber Slider
                if viewModel.duration > 0 {
                    Slider(
                        value: Binding(
                            get: { viewModel.currentTime },
                            set: { newValue in
                                viewModel.seek(to: newValue)
                            }
                        ),
                        in: 0...viewModel.duration
                    )
                    .tint(LiveVaultColors.primaryRed)
                }
                
                HStack {
                    Text(LiveVaultFormatters.formatDuration(Int(viewModel.currentTime)))
                        .font(LiveVaultTypography.caption)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(LiveVaultFormatters.formatDuration(Int(viewModel.duration)))
                        .font(LiveVaultTypography.caption)
                        .foregroundColor(LiveVaultColors.textSecondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.7), Color.clear, Color.black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
