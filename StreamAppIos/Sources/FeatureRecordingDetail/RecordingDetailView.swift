import SwiftUI
import LiveVaultCommon
import LiveVaultDesignSystem

public struct RecordingDetailView: View {
    @State private var viewModel: RecordingDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showRenameSheet = false
    @State private var showDeleteAlert = false
    
    public let onPlay: (String) -> Void
    public let onStartDownload: ((String, String, String) -> Void)?
    public let onNavigateToPaywall: (() -> Void)?
    
    public init(
        recordingId: String,
        onPlay: @escaping (String) -> Void,
        onStartDownload: ((String, String, String) -> Void)? = nil,
        onNavigateToPaywall: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: RecordingDetailViewModel(recordingId: recordingId))
        self.onPlay = onPlay
        self.onStartDownload = onStartDownload
        self.onNavigateToPaywall = onNavigateToPaywall
    }
    
    public var body: some View {
        ZStack {
            LiveVaultColors.darkBg.ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.detail == nil {
                ProgressView()
                    .tint(LiveVaultColors.primaryRed)
            } else if let detail = viewModel.detail {
                ScrollView {
                    VStack(spacing: 20) {
                        // Video Player Preview Header
                        videoPreviewHeader(detail)
                        
                        // Metadata Cards
                        metadataSection(detail)
                        
                        // Action Buttons: Download, Edit, Delete
                        actionButtonsSection(detail)
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("Recording Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showRenameSheet = true }) {
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 20))
                        .foregroundColor(LiveVaultColors.indigoSecondary)
                }
            }
        }
        .task {
            await viewModel.loadDetail()
        }
        .alert("Delete Recording?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    let ok = await viewModel.deleteRecording()
                    if ok {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("This will permanently remove the stream recording from LiveVault cloud storage and free up your quota.")
        }
        .sheet(isPresented: $showRenameSheet) {
            renameSheet
        }
    }
    
    private func videoPreviewHeader(_ detail: RecordingDetailDTO) -> some View {
        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 16)
                .fill(LiveVaultColors.darkSurfaceVariant)
                .frame(height: 200)
                .overlay(
                    Image(systemName: "film")
                        .font(.system(size: 44))
                        .foregroundColor(LiveVaultColors.textMuted)
                )
            
            // Play Button
            Button(action: { onPlay(detail.id) }) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(LiveVaultColors.primaryRed)
                    .background(Circle().fill(Color.black.opacity(0.6)))
            }
        }
    }
    
    private func metadataSection(_ detail: RecordingDetailDTO) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(detail.title)
                .font(LiveVaultTypography.titleLarge)
                .foregroundColor(LiveVaultColors.textPrimary)
            
            HStack(spacing: 12) {
                if let avatarUrl = detail.channel?.avatarUrl {
                    ChannelAvatar(displayName: detail.channel?.displayName ?? "Stream", avatarUrl: avatarUrl, platform: detail.platform, size: 36)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(detail.channel?.displayName ?? "Streamer")
                        .font(LiveVaultTypography.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(LiveVaultColors.textPrimary)
                    Text(detail.platform.displayName)
                        .font(LiveVaultTypography.caption)
                        .foregroundColor(LiveVaultColors.colorFor(platform: detail.platform))
                }
            }
            
            Divider().background(LiveVaultColors.darkSurfaceBorder)
            
            // Stats Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statCard(icon: "clock.fill", label: "Duration", value: LiveVaultFormatters.formatDuration(detail.durationSeconds))
                statCard(icon: "internaldrive.fill", label: "File Size", value: LiveVaultFormatters.formatBytesFromString(detail.sizeBytes))
                statCard(icon: "calendar", label: "Recorded", value: LiveVaultFormatters.formatShortDate(LiveVaultFormatters.parseISO8601(detail.recordedAt) ?? Date()))
                statCard(icon: "flag.fill", label: "Status", value: detail.status.displayName)
            }
            
            if let notes = detail.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notes")
                        .font(LiveVaultTypography.labelMedium)
                        .foregroundColor(LiveVaultColors.textSecondary)
                    Text(notes)
                        .font(LiveVaultTypography.bodyMedium)
                        .foregroundColor(LiveVaultColors.textPrimary)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(LiveVaultColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(LiveVaultColors.darkSurfaceBorder, lineWidth: 1))
    }
    
    private func statCard(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(LiveVaultColors.indigoSecondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(LiveVaultTypography.caption)
                    .foregroundColor(LiveVaultColors.textSecondary)
                Text(value)
                    .font(LiveVaultTypography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(LiveVaultColors.textPrimary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LiveVaultColors.darkSurfaceVariant)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func actionButtonsSection(_ detail: RecordingDetailDTO) -> some View {
        VStack(spacing: 12) {
            // Play Button
            Button(action: { onPlay(detail.id) }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Play Livestream")
                        .font(LiveVaultTypography.titleMedium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(LiveVaultColors.primaryRed)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Download Button (PRO / PREMIUM only)
            if viewModel.canDownload {
                Button(action: {
                    Task {
                        if let url = try? await viewModel.getDownloadUrl() {
                            onStartDownload?(detail.id, detail.title, url)
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("Download Video")
                            .font(LiveVaultTypography.bodyLarge)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(LiveVaultColors.indigoPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                Button(action: { onNavigateToPaywall?() }) {
                    HStack {
                        Image(systemName: "crown.fill")
                        Text("Upgrade to Download")
                            .font(LiveVaultTypography.bodyLarge)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(LiveVaultColors.darkSurfaceVariant)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(LiveVaultColors.indigoSecondary, lineWidth: 1))
                }
            }
            
            // Delete Button
            Button(action: { showDeleteAlert = true }) {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Delete Recording")
                        .font(LiveVaultTypography.bodyMedium)
                }
                .foregroundColor(LiveVaultColors.primaryRed)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
            }
        }
    }
    
    private var renameSheet: some View {
        NavigationStack {
            ZStack {
                LiveVaultColors.darkBg.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Title")
                            .font(LiveVaultTypography.labelMedium)
                            .foregroundColor(LiveVaultColors.textSecondary)
                        TextField("", text: $viewModel.editTitle)
                            .padding()
                            .background(LiveVaultColors.darkSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(LiveVaultColors.darkSurfaceBorder, lineWidth: 1))
                            .foregroundColor(LiveVaultColors.textPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes")
                            .font(LiveVaultTypography.labelMedium)
                            .foregroundColor(LiveVaultColors.textSecondary)
                        TextField("", text: $viewModel.editNotes, axis: .vertical)
                            .lineLimit(3...6)
                            .padding()
                            .background(LiveVaultColors.darkSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(LiveVaultColors.darkSurfaceBorder, lineWidth: 1))
                            .foregroundColor(LiveVaultColors.textPrimary)
                    }
                    
                    Spacer()
                    
                    Button("Save Changes") {
                        Task {
                            let ok = await viewModel.updateMetadata()
                            if ok {
                                showRenameSheet = false
                            }
                        }
                    }
                    .font(LiveVaultTypography.titleMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(LiveVaultColors.indigoPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(24)
            }
            .navigationTitle("Edit Recording")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showRenameSheet = false }
                        .foregroundColor(LiveVaultColors.textSecondary)
                }
            }
        }
    }
}
