import Foundation
import LiveVaultCommon

public protocol APIClientProtocol: Sendable {
    func request<T: Codable & Sendable>(
        path: String,
        method: String,
        queryItems: [URLQueryItem]?,
        body: (any Encodable & Sendable)?,
        requiresAuth: Bool
    ) async throws -> T
}

public final class APIClient: APIClientProtocol, @unchecked Sendable {
    public static let shared = APIClient()
    
    private let baseURL: URL
    private let session: URLSession
    private let tokenStorage: TokenStorageProtocol
    private let authInterceptor: AuthInterceptor
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    public init(
        baseURL: URL = LiveVaultConstants.currentBaseURL,
        session: URLSession = .shared,
        tokenStorage: TokenStorageProtocol = KeychainTokenStorage.shared
    ) {
        self.baseURL = baseURL
        self.session = session
        self.tokenStorage = tokenStorage
        self.authInterceptor = AuthInterceptor(tokenStorage: tokenStorage, baseURL: baseURL)
        
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }
    
    public func request<T: Codable & Sendable>(
        path: String,
        method: String = "GET",
        queryItems: [URLQueryItem]? = nil,
        body: (any Encodable & Sendable)? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        return try await performRequest(
            path: path,
            method: method,
            queryItems: queryItems,
            body: body,
            requiresAuth: requiresAuth,
            isRetry: false
        )
    }
    
    private func performRequest<T: Codable & Sendable>(
        path: String,
        method: String,
        queryItems: [URLQueryItem]?,
        body: (any Encodable & Sendable)?,
        requiresAuth: Bool,
        isRetry: Bool
    ) async throws -> T {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true)
        if let queryItems = queryItems, !queryItems.isEmpty {
            urlComponents?.queryItems = queryItems
        }
        
        guard let url = urlComponents?.url else {
            throw AppError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if requiresAuth {
            if let token = tokenStorage.getAccessToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }
        
        if let body = body {
            request.httpBody = try encoder.encode(body)
        }
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AppError.networkError(error.localizedDescription)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.networkError("Invalid server response")
        }
        
        // Handle 401 and Token Refresh
        if httpResponse.statusCode == 401 && requiresAuth && !isRetry {
            do {
                _ = try await authInterceptor.refreshToken()
                // Retry request with new token
                return try await performRequest(
                    path: path,
                    method: method,
                    queryItems: queryItems,
                    body: body,
                    requiresAuth: requiresAuth,
                    isRetry: true
                )
            } catch {
                throw AppError.unauthorized
            }
        }
        
        // Handle Success
        if (200...299).contains(httpResponse.statusCode) {
            do {
                let apiResponse = try decoder.decode(ApiResponse<T>.self, from: data)
                if let responseData = apiResponse.data {
                    return responseData
                } else if T.self == EmptyResponse.self {
                    return EmptyResponse() as! T
                } else {
                    // Try decoding T directly
                    return try decoder.decode(T.self, from: data)
                }
            } catch {
                // Fallback direct decode
                do {
                    return try decoder.decode(T.self, from: data)
                } catch let decodeErr {
                    throw AppError.decodingError(decodeErr.localizedDescription)
                }
            }
        }
        
        // Handle Errors
        let errorMsg: String
        if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data), let msg = errorResponse.message {
            errorMsg = msg.text
        } else if let rawString = String(data: data, encoding: .utf8), !rawString.isEmpty {
            errorMsg = rawString
        } else {
            errorMsg = "HTTP Status \(httpResponse.statusCode)"
        }
        
        switch httpResponse.statusCode {
        case 400:
            throw AppError.serverError(statusCode: 400, message: errorMsg)
        case 401:
            throw AppError.unauthorized
        case 403:
            throw AppError.forbidden(errorMsg)
        case 404:
            throw AppError.notFound(errorMsg)
        case 429:
            throw AppError.rateLimited
        default:
            throw AppError.serverError(statusCode: httpResponse.statusCode, message: errorMsg)
        }
    }
}

public struct EmptyResponse: Codable, Sendable {
    public init() {}
}
