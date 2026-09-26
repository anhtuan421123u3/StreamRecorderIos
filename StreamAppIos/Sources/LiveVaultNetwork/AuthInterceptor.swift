import Foundation
import LiveVaultCommon

public actor AuthInterceptor {
    private let tokenStorage: TokenStorageProtocol
    private let baseURL: URL
    private var isRefreshing = false
    private var refreshTask: Task<String, Error>?
    
    public init(tokenStorage: TokenStorageProtocol = KeychainTokenStorage.shared, baseURL: URL = LiveVaultConstants.currentBaseURL) {
        self.tokenStorage = tokenStorage
        self.baseURL = baseURL
    }
    
    public func getValidAccessToken() async throws -> String? {
        return tokenStorage.getAccessToken()
    }
    
    public func refreshToken() async throws -> String {
        // If already refreshing, await existing task
        if let existingTask = refreshTask {
            return try await existingTask.value
        }
        
        guard let refreshToken = tokenStorage.getRefreshToken() else {
            tokenStorage.clearAll()
            throw AppError.unauthorized
        }
        
        let task = Task<String, Error> {
            defer {
                self.refreshTask = nil
            }
            
            let url = baseURL.appendingPathComponent("/api/v1/auth/refresh")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            let body = RefreshTokenRequest(refreshToken: refreshToken)
            request.httpBody = try JSONEncoder().encode(body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.networkError("Invalid HTTP response during token refresh")
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                let decoded = try JSONDecoder().decode(ApiResponse<TokenPair>.self, from: data)
                if let tokens = decoded.data {
                    try tokenStorage.saveTokens(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken)
                    return tokens.accessToken
                }
            }
            
            // If refresh fails with 401/400, clear session
            tokenStorage.clearAll()
            throw AppError.unauthorized
        }
        
        self.refreshTask = task
        return try await task.value
    }
}
