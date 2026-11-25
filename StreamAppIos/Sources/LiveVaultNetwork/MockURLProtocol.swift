import Foundation

public final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    public nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?
    
    public override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    public override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("MockURLProtocol.requestHandler is not set.")
        }
        
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    public override func stopLoading() {}
    
    public static func makeMockSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

public final class MockTokenStorage: TokenStorageProtocol, @unchecked Sendable {
    public var mockAccessToken: String? = "mock_access_token"
    public var mockRefreshToken: String? = "mock_refresh_token"
    public var mockUser: UserProfile? = nil

    public init() {}

    public func saveTokens(accessToken: String, refreshToken: String) throws {
        self.mockAccessToken = accessToken
        self.mockRefreshToken = refreshToken
    }

    public func getAccessToken() -> String? { mockAccessToken }
    public func getRefreshToken() -> String? { mockRefreshToken }
    public func saveUserProfile(_ user: UserProfile) throws { self.mockUser = user }
    public func getUserProfile() -> UserProfile? { mockUser }
    public func clearAll() {
        mockAccessToken = nil
        mockRefreshToken = nil
        mockUser = nil
    }
}
