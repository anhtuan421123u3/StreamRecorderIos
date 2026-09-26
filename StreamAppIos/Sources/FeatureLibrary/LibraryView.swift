import SwiftUI
import LiveVaultCommon
import LiveVaultNetwork
import LiveVaultDesignSystem

public struct LibraryView: View {
    @State private var viewModel = LibraryViewModel()
    public let onSelectRecording: (String) -> Void
    
    public init(onSelectRecording: @escaping (String) -> Void) {
        self.onSelectRecording = onSelectRecording
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                LiveVaultColors.darkBg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Segmented Tabs
                    Picker("Library Tab", selection: $viewModel.selectedTab) {
                        ForEach(LibraryTab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    // Platform Filter Chips
                    platformFilterChips
                    
                    // Content List
                    if viewModel.selectedTab == .all {
                        allRecordingsList
                    } else {
                        downloadedRecordingsList
                    }
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.fetchRecordings(page: 1)
            }
        }
    }
    
    private var platformFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "All Platforms", isSelected: viewModel.selectedPlatform == nil) {
                    viewModel.selectedPlatform = nil
                    Task { await viewModel.fetchRecordings(page: 1) }
                }
                
                ForEach(Platform.allCases, id: \.self) { platform in
                    filterChip(title: platform.displayName, isSelected: viewModel.selectedPlatform == platform) {
                        viewModel.selectedPlatform = platform
                        Task { await viewModel.fetchRecordings(page: 1) }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
    
    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(LiveVaultTypography.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : LiveVaultColors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? LiveVaultColors.indigoPrimary : LiveVaultColors.darkSurface)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? LiveVaultColors.indigoSecondary : LiveVaultColors.darkSurfaceBorder, lineWidth: 1))
        }
    }
    
    private var allRecordingsList: some View {
        Group {
            if viewModel.recordings.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    iconName: "video.slash",
                    title: "No Recordings Found",
                    subtitle: "Streams recorded by LiveVault will appear here ready to stream or download."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.recordings) { recording in
                            Button(action: { onSelectRecording(recording.id) }) {
                                recordingCard(recording)
                            }
                            .task {
                                await viewModel.loadMoreIfNeeded(currentRecording: recording)
                            }
                        }
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(LiveVaultColors.indigoPrimary)
                                .padding()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .refreshable {
                    await viewModel.fetchRecordings(page: 1)
                }
            }
        }
    }
    
    private var downloadedRecordingsList: some View {
        Group {
            if viewModel.downloadedRecordings.isEmpty {
                EmptyStateView(
                    iconName: "arrow.down.circle",
                    title: "No Downloaded Streams",
                    subtitle: "PRO and PREMIUM members can download videos for offline playback anytime."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.downloadedRecordings) { recording in
                            Button(action: { onSelectRecording(recording.id) }) {
                                recordingCard(recording)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
    }
    
    private func recordingCard(_ recording: RecordingDTO) -> some View {
        HStack(spacing: 14) {
            // Thumbnail container with download progress overlay
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LiveVaultColors.darkSurfaceVariant)
                    .frame(width: 110, height: 68)
                    .overlay(
                        Image(systemName: "film")
                            .font(.system(size: 24))
                            .foregroundColor(LiveVaultColors.textMuted)
                    )
                
                // Real-time download progress bar if active
                if let progress = viewModel.downloadProgressMap[recording.id] {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.black.opacity(0.6))
                                .frame(height: 6)
                            Rectangle()
                                .fill(LiveVaultColors.emeraldSuccess)
                                .frame(width: geo.size.width * CGFloat(progress), height: 6)
                        }
                    }
                    .frame(height: 6)
                } else {
                    HStack {
                        Spacer()
                        Text(LiveVaultFormatters.formatDuration(recording.durationSeconds))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .padding(4)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recording.title)
                    .font(LiveVaultTypography.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(LiveVaultColors.textPrimary)
                    .lineLimit(2)
                
                HStack(spacing: 6) {
                    Text(recording.channel?.displayName ?? "Stream")
                        .font(LiveVaultTypography.caption)
                        .foregroundColor(LiveVaultColors.textSecondary)
                    
                    Text("•")
                        .font(LiveVaultTypography.caption)
                        .foregroundColor(LiveVaultColors.textMuted)
                    
                    Text(LiveVaultFormatters.formatBytesFromString(recording.sizeBytes))
                        .font(LiveVaultTypography.caption)
                        .foregroundColor(LiveVaultColors.textSecondary)
                }
                
                if let date = LiveVaultFormatters.parseISO8601(recording.recordedAt) {
                    Text(LiveVaultFormatters.formatRelativeTime(date))
                        .font(LiveVaultTypography.caption)
                        .foregroundColor(LiveVaultColors.textMuted)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(LiveVaultColors.textMuted)
        }
        .padding(12)
        .background(LiveVaultColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(LiveVaultColors.darkSurfaceBorder, lineWidth: 1))
    }
}
