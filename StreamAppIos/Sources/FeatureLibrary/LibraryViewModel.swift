import SwiftUI
import LiveVaultCommon
import LiveVaultNetwork
import LiveVaultDatabase

public enum LibraryTab: String, CaseIterable, Identifiable {
    case all = "All Recordings"
    case downloaded = "Downloaded"
    
    public var id: String { rawValue }
}

@Observable
public final class LibraryViewModel {
    public var selectedTab: LibraryTab = .all
    public var selectedPlatform: Platform? = nil
    public var recordings: [RecordingDTO] = []
    public var downloadedRecordings: [RecordingDTO] = []
    public var downloadProgressMap: [String: Double] = [:] // recordingId -> progress (0.0 to 1.0)
    
    public var isLoading = false
    public var isRefreshing = false
    public var errorMessage: String? = nil
    
    public var currentPage = 1
    public var totalPages = 1
    public var hasMore = false
    
    private let apiClient: APIClientProtocol
    private let databaseService: DatabaseService
    
    @MainActor
    public init(
        apiClient: APIClientProtocol = APIClient.shared,
        databaseService: DatabaseService? = nil
    ) {
        self.apiClient = apiClient
        self.databaseService = databaseService ?? DatabaseService.shared
        loadOfflineCache()
    }
    
    @MainActor
    public func loadOfflineCache() {
        let cached = databaseService.fetchRecordings()
        if !cached.isEmpty {
            self.recordings = cached.map { entity in
                RecordingDTO(
                    id: entity.id,
                    channelId: entity.channelId,
                    userId: entity.userId,
                    sessionId: entity.sessionId,
                    segmentIndex: entity.segmentIndex,
                    title: entity.title,
                    notes: entity.notes,
                    durationSeconds: entity.durationSeconds,
                    sizeBytes: entity.sizeBytesString,
                    recordedAt: ISO8601DateFormatter().string(from: entity.recordedAt),
                    status: entity.status,
                    platform: entity.platform,
                    channel: ChannelSummary(displayName: entity.channelDisplayName, platform: entity.platform, avatarUrl: entity.channelAvatarUrl)
                )
            }
        }
        
        let downloaded = databaseService.fetchDownloadedRecordings()
        self.downloadedRecordings = downloaded.map { entity in
            RecordingDTO(
                id: entity.id,
                channelId: entity.channelId,
                title: entity.title,
                durationSeconds: entity.durationSeconds,
                sizeBytes: entity.sizeBytesString,
                recordedAt: ISO8601DateFormatter().string(from: entity.recordedAt),
                status: entity.status,
                platform: entity.platform,
                channel: ChannelSummary(displayName: entity.channelDisplayName, platform: entity.platform, avatarUrl: entity.channelAvatarUrl)
            )
        }
    }
    
    @MainActor
    public func fetchRecordings(page: Int = 1) async {
        if page == 1 {
            isLoading = true
        }
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "20")
        ]
        
        if let platform = selectedPlatform {
            queryItems.append(URLQueryItem(name: "platform", value: platform.rawValue))
        }
        
        do {
            let res: RecordingListResponse = try await apiClient.request(
                path: "/api/v1/recordings",
                method: "GET",
                queryItems: queryItems,
                body: nil,
                requiresAuth: true
            )
            
            if page == 1 {
                self.recordings = res.recordings
            } else {
                self.recordings.append(contentsOf: res.recordings)
            }
            
            self.currentPage = page
            self.totalPages = res.totalPages ?? 1
            self.hasMore = page < (res.totalPages ?? 1)
            self.isLoading = false
            
            // Sync to SwiftData
            for rec in res.recordings {
                let entity = RecordingEntity(
                    id: rec.id,
                    channelId: rec.channelId,
                    userId: rec.userId,
                    sessionId: rec.sessionId,
                    segmentIndex: rec.segmentIndex ?? 0,
                    title: rec.title,
                    notes: rec.notes,
                    durationSeconds: rec.durationSeconds,
                    sizeBytesString: rec.sizeBytes,
                    recordedAt: LiveVaultFormatters.parseISO8601(rec.recordedAt) ?? Date(),
                    statusRaw: rec.status.rawValue,
                    platformRaw: rec.platform.rawValue,
                    channelDisplayName: rec.channel?.displayName ?? "Channel",
                    channelAvatarUrl: rec.channel?.avatarUrl
                )
                databaseService.saveRecording(entity)
            }
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    public func loadMoreIfNeeded(currentRecording: RecordingDTO) async {
        guard hasMore, !isLoading else { return }
        if recordings.last?.id == currentRecording.id {
            await fetchRecordings(page: currentPage + 1)
        }
    }
    
    @MainActor
    public func updateDownloadProgress(recordingId: String, progress: Double) {
        if progress >= 1.0 {
            downloadProgressMap.removeValue(forKey: recordingId)
            loadOfflineCache()
        } else {
            downloadProgressMap[recordingId] = progress
        }
    }
}
