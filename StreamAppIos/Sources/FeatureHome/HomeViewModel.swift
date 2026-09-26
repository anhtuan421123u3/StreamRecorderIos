import SwiftUI
import LiveVaultCommon
import LiveVaultNetwork
import LiveVaultDatabase

@Observable
public final class HomeViewModel {
    public var channels: [ChannelDTO] = []
    public var recentRecordings: [RecordingDTO] = []
    public var storageUsage: StorageUsageDTO? = nil
    public var activeRecordingSessions: [RecordingDTO] = []
    public var isLoading = false
    public var isRefreshing = false
    public var errorMessage: String? = nil
    
    private let apiClient: APIClientProtocol
    
    public init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }
    
    @MainActor
    public func loadDashboardData() async {
        isLoading = true
        errorMessage = nil
        
        async let channelsTask: ChannelListResponse = apiClient.request(path: "/api/v1/channels", method: "GET", queryItems: nil, body: nil, requiresAuth: true)
        async let recordingsTask: RecordingListResponse = apiClient.request(path: "/api/v1/recordings", method: "GET", queryItems: [URLQueryItem(name: "limit", value: "10")], body: nil, requiresAuth: true)
        async let storageTask: StorageUsageDTO = apiClient.request(path: "/api/v1/recordings/storage-usage", method: "GET", queryItems: nil, body: nil, requiresAuth: true)
        
        do {
            let (channelRes, recRes, storageRes) = try await (channelsTask, recordingsTask, storageTask)
            self.channels = channelRes.channels
            self.recentRecordings = recRes.recordings
            self.storageUsage = storageRes
            self.activeRecordingSessions = recRes.recordings.filter { $0.status == .recording }
            self.isLoading = false
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    public func refreshDashboard() async {
        isRefreshing = true
        await loadDashboardData()
        isRefreshing = false
    }
    
    @MainActor
    public func checkLiveStatus(for channelId: String) async {
        do {
            let res: LiveStatusResponse = try await apiClient.request(
                path: "/api/v1/channels/\(channelId)/check-live",
                method: "POST",
                queryItems: nil,
                body: nil,
                requiresAuth: true
            )
            if let index = channels.firstIndex(where: { $0.id == channelId }) {
                var updated = channels[index]
                updated = ChannelDTO(
                    id: updated.id,
                    userId: updated.userId,
                    platform: updated.platform,
                    platformId: updated.platformId,
                    channelUrl: updated.channelUrl,
                    displayName: updated.displayName,
                    avatarUrl: updated.avatarUrl,
                    isActive: updated.isActive,
                    isLive: res.isLive,
                    lastCheckedAt: res.lastCheckedAt,
                    createdAt: updated.createdAt,
                    updatedAt: updated.updatedAt
                )
                channels[index] = updated
            }
        } catch {
            // Silently ignore live check errors in UI polling
        }
    }
}
