import XCTest
@testable import LiveVaultCommon
@testable import LiveVaultNetwork

final class NetworkTests: XCTestCase {
    var mockSession: URLSession!
    var mockTokenStorage: MockTokenStorage!
    var apiClient: APIClient!
    
    override func setUp() {
        super.setUp()
        mockSession = MockURLProtocol.makeMockSession()
        mockTokenStorage = MockTokenStorage()
        apiClient = APIClient(
            baseURL: URL(string: "https://api.livevault.app")!,
            session: mockSession,
            tokenStorage: mockTokenStorage
        )
    }
    
    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        mockSession = nil
        mockTokenStorage = nil
        apiClient = nil
        super.tearDown()
    }
    
    func testSuccessfulGetRequest() async throws {
        let jsonResponse = """
        {
            "success": true,
            "data": {
                "id": "ch_123",
                "displayName": "Gamer Live",
                "platform": "TWITCH",
                "channelUrl": "https://twitch.tv/gamerlive",
                "isActive": true,
                "isLive": true
            }
        }
        """.data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, jsonResponse)
        }
        
        let channel: ChannelDTO = try await apiClient.request(path: "/api/v1/channels/ch_123", method: "GET", queryItems: nil, body: nil, requiresAuth: false)
        
        XCTAssertEqual(channel.id, "ch_123")
        XCTAssertEqual(channel.displayName, "Gamer Live")
        XCTAssertEqual(channel.platform, .twitch)
        XCTAssertTrue(channel.isLive)
    }
    
    func testAutoRefreshTokenOn401() async throws {
        mockTokenStorage.mockAccessToken = "expired_access_token"
        mockTokenStorage.mockRefreshToken = "valid_refresh_token"
        
        var requestCount = 0
        
        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            
            if request.url?.path == "/api/v1/auth/refresh" {
                let refreshPayload = """
                {
                    "success": true,
                    "data": {
                        "accessToken": "new_refreshed_access_token",
                        "refreshToken": "new_rotated_refresh_token",
                        "expiresIn": 900
                    }
                }
                """.data(using: .utf8)!
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, refreshPayload)
            }
            
            // First call returns 401, second call returns 200
            if requestCount == 1 {
                let unauthPayload = """
                {
                    "success": false,
                    "statusCode": 401,
                    "message": "Token expired"
                }
                """.data(using: .utf8)!
                let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
                return (response, unauthPayload)
            } else {
                let successPayload = """
                {
                    "success": true,
                    "data": {
                        "channels": []
                    }
                }
                """.data(using: .utf8)!
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, successPayload)
            }
        }
        
        let res: ChannelListResponse = try await apiClient.request(path: "/api/v1/channels", method: "GET", queryItems: nil, body: nil, requiresAuth: true)
        
        XCTAssertEqual(res.channels.count, 0)
        XCTAssertEqual(mockTokenStorage.getAccessToken(), "new_refreshed_access_token")
    }
}

final class MockTokenStorage: TokenStorageProtocol, @unchecked Sendable {
    var mockAccessToken: String? = "mock_access_token"
    var mockRefreshToken: String? = "mock_refresh_token"
    var mockUser: UserProfile? = nil
    
    func saveTokens(accessToken: String, refreshToken: String) throws {
        self.mockAccessToken = accessToken
        self.mockRefreshToken = refreshToken
    }
    
    func getAccessToken() -> String? { mockAccessToken }
    func getRefreshToken() -> String? { mockRefreshToken }
    func saveUserProfile(_ user: UserProfile) throws { self.mockUser = user }
    func getUserProfile() -> UserProfile? { mockUser }
    func clearAll() {
        mockAccessToken = nil
        mockRefreshToken = nil
        mockUser = nil
    }
}
