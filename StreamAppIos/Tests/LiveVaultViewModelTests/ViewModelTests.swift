import XCTest
@testable import LiveVaultCommon
@testable import LiveVaultNetwork
@testable import LiveVaultDatabase
@testable import FeatureAuth
@testable import FeatureHome
@testable import FeatureLibrary
@testable import FeaturePlayer
@testable import FeatureSettings

final class ViewModelTests: XCTestCase {
    var mockApiClient: MockApiClient!
    var mockTokenStorage: MockTokenStorage!
    
    override func setUp() {
        super.setUp()
        mockApiClient = MockApiClient()
        mockTokenStorage = MockTokenStorage()
    }
    
    override func tearDown() {
        mockApiClient = nil
        mockTokenStorage = nil
        super.tearDown()
    }
    
    // MARK: - AuthViewModel Tests
    @MainActor
    func testAuthViewModelLoginSuccess() async throws {
        let fakeUser = UserProfile(
            id: "u_1",
            email: "streamer@livevault.app",
            displayName: "Pro Streamer",
            avatarUrl: nil,
            subscriptionTier: .pro,
            subscriptionExpiry: nil,
            storageQuotaBytes: "53687091200",
            storageUsedBytes: "1073741824",
            createdAt: "2026-01-01T00:00:00Z"
        )
        let fakeResult = AuthResult(
            accessToken: "test_access_jwt",
            refreshToken: "test_refresh_jwt",
            expiresIn: 900,
            user: fakeUser
        )
        mockApiClient.mockResponse = fakeResult
        
        let viewModel = AuthViewModel(apiClient: mockApiClient, tokenStorage: mockTokenStorage)
        viewModel.email = "streamer@livevault.app"
        viewModel.password = "password123"
        
        await viewModel.login()
        
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertEqual(viewModel.currentUser?.displayName, "Pro Streamer")
        XCTAssertEqual(mockTokenStorage.getAccessToken(), "test_access_jwt")
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - HomeViewModel Tests
    @MainActor
    func testHomeViewModelLoadsDashboard() async throws {
        let fakeChannels = ChannelListResponse(channels: [
            ChannelDTO(id: "ch_1", platform: .youtube, channelUrl: "https://youtube.com/@live", displayName: "Tech Live", isLive: true)
        ])
        let fakeRecordings = RecordingListResponse(recordings: [
            RecordingDTO(id: "rec_1", channelId: "ch_1", title: "Keynote Stream", durationSeconds: 3600, sizeBytes: "1073741824", recordedAt: "2026-09-22T08:00:00Z", status: .ready, platform: .youtube)
        ])
        let fakeStorage = StorageUsageDTO(usedBytes: "1073741824", quotaBytes: "53687091200", usedPercent: 2, tier: .pro)
        
        mockApiClient.mockResponseHandlers["/api/v1/channels"] = { fakeChannels }
        mockApiClient.mockResponseHandlers["/api/v1/recordings"] = { fakeRecordings }
        mockApiClient.mockResponseHandlers["/api/v1/recordings/storage-usage"] = { fakeStorage }
        
        let viewModel = HomeViewModel(apiClient: mockApiClient)
        await viewModel.loadDashboardData()
        
        XCTAssertEqual(viewModel.channels.count, 1)
        XCTAssertTrue(viewModel.channels.first?.isLive == true)
        XCTAssertEqual(viewModel.recentRecordings.count, 1)
        XCTAssertEqual(viewModel.storageUsage?.usedPercent, 2)
    }
    
    // MARK: - PlayerViewModel Signed URL Auto-Refresh Tests
    @MainActor
    func testPlayerSignedUrlAutoRefresh() async throws {
        let fakeDetail1 = RecordingDetailDTO(
            id: "rec_hls_1",
            channelId: "ch_1",
            title: "Live Stream Segment",
            durationSeconds: 7200,
            sizeBytes: "2147483648",
            recordedAt: "2026-09-22T08:00:00Z",
            status: .ready,
            platform: .twitch,
            hlsPlaybackUrl: "https://cdn.livevault.app/hls/rec_1/master.m3u8?token=exp_15m"
        )
        
        let fakeDetail2 = RecordingDetailDTO(
            id: "rec_hls_1",
            channelId: "ch_1",
            title: "Live Stream Segment",
            durationSeconds: 7200,
            sizeBytes: "2147483648",
            recordedAt: "2026-09-22T08:00:00Z",
            status: .ready,
            platform: .twitch,
            hlsPlaybackUrl: "https://cdn.livevault.app/hls/rec_1/master.m3u8?token=exp_refreshed_15m"
        )
        
        var callCount = 0
        mockApiClient.mockResponseHandlers["/api/v1/recordings/rec_hls_1"] = {
            callCount += 1
            return callCount == 1 ? fakeDetail1 : fakeDetail2
        }
        
        let playerVM = PlayerViewModel(recordingId: "rec_hls_1", apiClient: mockApiClient)
        
        // Initial load
        await playerVM.loadAndPlay()
        XCTAssertNotNil(playerVM.recordingDetail)
        XCTAssertEqual(playerVM.recordingDetail?.hlsPlaybackUrl, "https://cdn.livevault.app/hls/rec_1/master.m3u8?token=exp_15m")
        XCTAssertNotNil(playerVM.signedUrlExpiresAt)
        
        // Simulate playback progress to 45.0 seconds
        playerVM.currentTime = 45.0
        playerVM.isPlaying = true
        
        // Trigger silent refresh (as happens at minute 12-13)
        await playerVM.refreshSignedPlaybackUrlSilently()
        
        XCTAssertEqual(playerVM.recordingDetail?.hlsPlaybackUrl, "https://cdn.livevault.app/hls/rec_1/master.m3u8?token=exp_refreshed_15m")
        XCTAssertEqual(playerVM.currentTime, 45.0, "Playback currentTime must be seamlessly preserved during signed URL swap")
        XCTAssertTrue(playerVM.isPlaying, "Player must continue playing after signed URL refresh")
    }
    
    // MARK: - Storage Quota Threshold Warning Tests
    func testStorageQuotaWarningThreshold() {
        let safeUsage = StorageUsageDTO(usedBytes: "30000000000", quotaBytes: "50000000000", usedPercent: 60, tier: .pro)
        let warningUsage = StorageUsageDTO(usedBytes: "42000000000", quotaBytes: "50000000000", usedPercent: 84, tier: .pro)
        let criticalUsage = StorageUsageDTO(usedBytes: "49000000000", quotaBytes: "50000000000", usedPercent: 98, tier: .pro)
        
        XCTAssertFalse(safeUsage.usedPercent >= LiveVaultConstants.storageQuotaWarningPercent)
        XCTAssertTrue(warningUsage.usedPercent >= LiveVaultConstants.storageQuotaWarningPercent)
        XCTAssertTrue(criticalUsage.usedPercent >= 95)
    }
}

// MARK: - Mock API Client
final class MockApiClient: APIClientProtocol, @unchecked Sendable {
    var mockResponse: Any? = nil
    var mockResponseHandlers: [String: () -> Any] = [:]
    
    func request<T: Codable & Sendable>(
        path: String,
        method: String,
        queryItems: [URLQueryItem]?,
        body: (any Encodable & Sendable)?,
        requiresAuth: Bool
    ) async throws -> T {
        if let handler = mockResponseHandlers[path] {
            if let res = handler() as? T {
                return res
            }
        }
        
        if let mock = mockResponse as? T {
            return mock
        }
        
        throw AppError.notFound("No mock configured for path: \(path)")
    }
}
