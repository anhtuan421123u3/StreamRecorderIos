import SwiftUI
import LiveVaultCommon
import LiveVaultNetwork
import LiveVaultDesignSystem

public struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    public let onSelectRecording: (String) -> Void
    public let onSelectChannel: (String) -> Void
    public let onAddChannel: () -> Void
    public let onNavigateToPaywall: () -> Void
    
    public init(
        onSelectRecording: @escaping (String) -> Void,
        onSelectChannel: @escaping (String) -> Void,
        onAddChannel: @escaping () -> Void,
        onNavigateToPaywall: @escaping () -> Void
    ) {
        self.onSelectRecording = onSelectRecording
        self.onSelectChannel = onSelectChannel
        self.onAddChannel = onAddChannel
        self.onNavigateToPaywall = onNavigateToPaywall
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                LiveVaultColors.darkBg.ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.channels.isEmpty {
                    loadingSkeleton
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Top Storage Usage Bar
                            if let storage = viewModel.storageUsage,
                               let used = Int64(storage.usedBytes),
                               let quota = Int64(storage.quotaBytes) {
                                StorageUsageBar(usedBytes: used, quotaBytes: quota, usedPercent: storage.usedPercent)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 8)
                            }
                            
                            // Active Recording Banner (if any stream is actively recording)
                            if !viewModel.activeRecordingSessions.isEmpty {
                                activeRecordingBanner
                            }
                            
                            // Channels Section
                            channelsSection
                            
                            // Recent Recordings Section
                            recentRecordingsSection
                        }
                        .padding(.bottom, 32)
                    }
                    .refreshable {
                        await viewModel.refreshDashboard()
                    }
                }
            }
            .navigationTitle("LiveVault")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onAddChannel) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(LiveVaultColors.primaryRed)
                    }
                }
            }
            .task {
                await viewModel.loadDashboardData()
            }
        }
    }
    
    // MARK: - Active Recording Banner
    private var activeRecordingBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(LiveVaultColors.livePulseRed)
                        .frame(width: 8, height: 8)
                    Text("RECORDING IN PROGRESS")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(LiveVaultColors.livePulseRed)
                }
                Spacer()
                Text("\(viewModel.activeRecordingSessions.count) Active")
                    .font(LiveVaultTypography.caption)
                    .foregroundColor(LiveVaultColors.textSecondary)
            }
            
            ForEach(viewModel.activeRecordingSessions) { session in
                Button(action: { onSelectRecording(session.id) }) {
                    HStack(spacing: 12) {
                        Image(systemName: "recordingtape")
                            .font(.system(size: 22))
                            .foregroundColor(LiveVaultColors.primaryRed)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.title)
                                .font(LiveVaultTypography.bodyLarge)
                                .fontWeight(.semibold)
                                .foregroundColor(LiveVaultColors.textPrimary)
                                .lineLimit(1)
                            Text(session.channel?.displayName ?? "Stream Channel")
                                .font(LiveVaultTypography.caption)
                                .foregroundColor(LiveVaultColors.textSecondary)
                        }
                        
                        Spacer()
                        
                        LiveBadge()
                    }
                    .padding(12)
                    .background(LiveVaultColors.darkSurfaceVariant)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .background(LiveVaultColors.primaryRed.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(LiveVaultColors.primaryRed.opacity(0.3), lineWidth: 1))
        .padding(.horizontal, 16)
    }
    
    // MARK: - Channels Section
    private var channelsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Monitored Channels")
                    .font(LiveVaultTypography.titleMedium)
                    .foregroundColor(LiveVaultColors.textPrimary)
                Spacer()
                Button("Add Channel", action: onAddChannel)
                    .font(LiveVaultTypography.labelMedium)
                    .foregroundColor(LiveVaultColors.indigoPrimary)
            }
            .padding(.horizontal, 16)
            
            if viewModel.channels.isEmpty {
                EmptyStateView(
                    iconName: "tv.badge.wifi",
                    title: "No Channels Monitored",
                    subtitle: "Add your YouTube, Twitch, or Kick channel to start archiving livestreams automatically.",
                    actionTitle: "Add Channel",
                    action: onAddChannel
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(viewModel.channels) { channel in
                            Button(action: { onSelectChannel(channel.id) }) {
                                VStack(spacing: 8) {
                                    ZStack(alignment: .topTrailing) {
                                        ChannelAvatar(
                                            displayName: channel.displayName,
                                            avatarUrl: channel.avatarUrl,
                                            platform: channel.platform,
                                            size: 58
                                        )
                                        
                                        if channel.isLive {
                                            LiveBadge()
                                                .scaleEffect(0.8)
                                                .offset(x: 10, y: -6)
                                        }
                                    }
                                    
                                    Text(channel.displayName)
                                        .font(LiveVaultTypography.caption)
                                        .foregroundColor(LiveVaultColors.textPrimary)
                                        .lineLimit(1)
                                        .frame(width: 72)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 6)
                                .background(LiveVaultColors.darkSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(LiveVaultColors.darkSurfaceBorder, lineWidth: 1))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
    
    // MARK: - Recent Recordings Section
    private var recentRecordingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Recent Recordings")
                    .font(LiveVaultTypography.titleMedium)
                    .foregroundColor(LiveVaultColors.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            if viewModel.recentRecordings.isEmpty {
                EmptyStateView(
                    iconName: "film.stack",
                    title: "No Recordings Yet",
                    subtitle: "LiveVault will automatically capture and index livestreams when your monitored channels go live."
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.recentRecordings) { recording in
                        Button(action: { onSelectRecording(recording.id) }) {
                            recordingRow(recording)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private func recordingRow(_ recording: RecordingDTO) -> some View {
        HStack(spacing: 14) {
            // Thumbnail / Icon
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LiveVaultColors.darkSurfaceVariant)
                    .frame(width: 100, height: 60)
                    .overlay(
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(LiveVaultColors.textMuted)
                    )
                
                Text(LiveVaultFormatters.formatDuration(recording.durationSeconds))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.75))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(4)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recording.title)
                    .font(LiveVaultTypography.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(LiveVaultColors.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(recording.channel?.displayName ?? "Channel")
                        .font(LiveVaultTypography.caption)
                        .foregroundColor(LiveVaultColors.textSecondary)
                    
                    Text("•")
                        .font(LiveVaultTypography.caption)
                        .foregroundColor(LiveVaultColors.textMuted)
                    
                    Text(LiveVaultFormatters.formatBytesFromString(recording.sizeBytes))
                        .font(LiveVaultTypography.caption)
                        .foregroundColor(LiveVaultColors.textSecondary)
                }
                
                if recording.status == .recording {
                    LiveBadge()
                        .scaleEffect(0.85)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(LiveVaultColors.textMuted)
        }
        .padding(12)
        .background(LiveVaultColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(LiveVaultColors.darkSurfaceBorder, lineWidth: 1))
    }
    
    private var loadingSkeleton: some View {
        VStack(spacing: 20) {
            SkeletonBox(height: 90, cornerRadius: 14)
                .padding(.horizontal, 16)
                .padding(.top, 16)
            
            HStack {
                SkeletonBox(width: 140, height: 20)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            HStack(spacing: 12) {
                ForEach(0..<4) { _ in
                    SkeletonBox(width: 70, height: 80, cornerRadius: 12)
                }
            }
            .padding(.horizontal, 16)
            
            Spacer()
        }
    }
}
