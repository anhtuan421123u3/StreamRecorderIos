import Foundation

public enum LiveVaultConstants {
    public static let productionBaseURL = URL(string: "https://api.livevault.app")!
    public static let localBaseURL = URL(string: "http://localhost:3000")!
    
    #if DEBUG
    public static var currentBaseURL: URL = productionBaseURL
    #else
    public static let currentBaseURL: URL = productionBaseURL
    #endif
    
    public static let apiVersionPath = "/api/v1"
    
    // Signed playback URL refresh settings
    public static let signedUrlDurationSeconds: TimeInterval = 15 * 60 // 15 mins
    public static let signedUrlRefreshThresholdSeconds: TimeInterval = 2 * 60 // Refresh when 2-3 mins left (at min 12-13)
    
    // Quota warning threshold
    public static let storageQuotaWarningPercent: Int = 80
    
    // Keychain service identifier
    public static let keychainService = "app.livevault.ios.auth"
    public static let backgroundDownloadSessionId = "app.livevault.ios.backgroundDownload"
    
    // App schemes
    public static let customScheme = "livevault"
    public static let universalLinkHost = "livevault.app"
}
