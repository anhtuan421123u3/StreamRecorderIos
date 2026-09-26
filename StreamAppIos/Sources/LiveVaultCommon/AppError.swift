import Foundation

public enum AppError: LocalizedError, Sendable {
    case invalidURL
    case networkError(String)
    case decodingError(String)
    case serverError(statusCode: Int, message: String)
    case unauthorized
    case forbidden(String)
    case notFound(String)
    case rateLimited
    case quotaExceeded
    case playerError(String)
    case downloadError(String)
    case keychainError(String)
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL requested."
        case .networkError(let msg):
            return "Network connection issue: \(msg)"
        case .decodingError(let msg):
            return "Failed to parse data: \(msg)"
        case .serverError(let code, let msg):
            return "Server error (\(code)): \(msg)"
        case .unauthorized:
            return "Session expired. Please log in again."
        case .forbidden(let msg):
            return "Access denied: \(msg)"
        case .notFound(let msg):
            return "Resource not found: \(msg)"
        case .rateLimited:
            return "Too many requests. Please slow down and try again."
        case .quotaExceeded:
            return "Storage quota exceeded. Please upgrade or delete old recordings."
        case .playerError(let msg):
            return "Playback error: \(msg)"
        case .downloadError(let msg):
            return "Download error: \(msg)"
        case .keychainError(let msg):
            return "Security error: \(msg)"
        case .unknown(let msg):
            return msg
        }
    }
}
