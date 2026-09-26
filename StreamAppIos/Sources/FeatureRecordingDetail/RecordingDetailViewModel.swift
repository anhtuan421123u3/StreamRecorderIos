import SwiftUI
import LiveVaultCommon
import LiveVaultNetwork
import LiveVaultDatabase

@Observable
public final class RecordingDetailViewModel {
    public var recordingId: String
    public var detail: RecordingDetailDTO? = nil
    public var isLoading = false
    public var errorMessage: String? = nil
    public var isDeleted = false
    public var isDownloading = false
    
    // Edit state
    public var editTitle = ""
    public var editNotes = ""
    
    private let apiClient: APIClientProtocol
    private let tokenStorage: TokenStorageProtocol
    
    public init(
        recordingId: String,
        apiClient: APIClientProtocol = APIClient.shared,
        tokenStorage: TokenStorageProtocol = KeychainTokenStorage.shared
    ) {
        self.recordingId = recordingId
        self.apiClient = apiClient
        self.tokenStorage = tokenStorage
    }
    
    public var canDownload: Bool {
        let user = tokenStorage.getUserProfile()
        return user?.subscriptionTier != .free
    }
    
    @MainActor
    public func loadDetail() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let res: RecordingDetailDTO = try await apiClient.request(
                path: "/api/v1/recordings/\(recordingId)",
                method: "GET",
                queryItems: nil,
                body: nil,
                requiresAuth: true
            )
            self.detail = res
            self.editTitle = res.title
            self.editNotes = res.notes ?? ""
            self.isLoading = false
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    public func updateMetadata() async -> Bool {
        isLoading = true
        let body = UpdateRecordingRequest(title: editTitle, notes: editNotes.isEmpty ? nil : editNotes)
        
        do {
            let updated: RecordingDTO = try await apiClient.request(
                path: "/api/v1/recordings/\(recordingId)",
                method: "PATCH",
                queryItems: nil,
                body: body,
                requiresAuth: true
            )
            if let current = detail {
                self.detail = RecordingDetailDTO(
                    id: current.id,
                    channelId: current.channelId,
                    userId: current.userId,
                    sessionId: current.sessionId,
                    segmentIndex: current.segmentIndex,
                    title: updated.title,
                    notes: updated.notes,
                    durationSeconds: current.durationSeconds,
                    sizeBytes: current.sizeBytes,
                    recordedAt: current.recordedAt,
                    status: current.status,
                    platform: current.platform,
                    channel: current.channel,
                    playbackUrl: current.playbackUrl,
                    hlsPlaybackUrl: current.hlsPlaybackUrl,
                    thumbnailUrl: current.thumbnailUrl,
                    session: current.session
                )
            }
            self.isLoading = false
            return true
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            return false
        }
    }
    
    @MainActor
    public func deleteRecording() async -> Bool {
        isLoading = true
        do {
            let _: EmptyResponse = try await apiClient.request(
                path: "/api/v1/recordings/\(recordingId)",
                method: "DELETE",
                queryItems: nil,
                body: nil,
                requiresAuth: true
            )
            self.isLoading = false
            self.isDeleted = true
            return true
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            return false
        }
    }
    
    @MainActor
    public func getDownloadUrl() async throws -> String {
        let res: DownloadUrlDTO = try await apiClient.request(
            path: "/api/v1/recordings/\(recordingId)/download",
            method: "GET",
            queryItems: nil,
            body: nil,
            requiresAuth: true
        )
        return res.downloadUrl
    }
}
