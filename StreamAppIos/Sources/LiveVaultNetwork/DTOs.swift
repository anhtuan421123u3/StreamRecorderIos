import Foundation
import LiveVaultCommon

// MARK: - Generic API Response & Error
public struct ApiResponse<T: Codable & Sendable>: Codable, Sendable {
    public let success: Bool
    public let data: T?
    public let timestamp: String?
    
    public init(success: Bool, data: T?, timestamp: String? = nil) {
        self.success = success
        self.data = data
        self.timestamp = timestamp
    }
}

public struct ErrorResponse: Codable, Sendable {
    public let success: Bool
    public let statusCode: Int?
    public let error: String?
    public let message: ErrorMessage?
    public let timestamp: String?
    public let path: String?
    
    public enum ErrorMessage: Codable, Sendable {
        case single(String)
        case multiple([String])
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let string = try? container.decode(String.self) {
                self = .single(string)
            } else if let array = try? container.decode([String].self) {
                self = .multiple(array)
            } else {
                self = .single("Unknown error")
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .single(let str):
                try container.encode(str)
            case .multiple(let arr):
                try container.encode(arr)
            }
        }
        
        public var text: String {
            switch self {
            case .single(let str): return str
            case .multiple(let arr): return arr.joined(separator: ", ")
            }
        }
    }
}

public struct PaginationMeta: Codable, Sendable {
    public let total: Int
    public let page: Int
    public let totalPages: Int?
    
    public init(total: Int, page: Int, totalPages: Int? = nil) {
        self.total = total
        self.page = page
        self.totalPages = totalPages
    }
}

// MARK: - Auth DTOs
public struct TokenPair: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int
    
    public init(accessToken: String, refreshToken: String, expiresIn: Int) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
    }
}

public struct UserProfile: Codable, Sendable, Identifiable {
    public let id: String
    public let email: String?
    public let displayName: String
    public let avatarUrl: String?
    public let subscriptionTier: SubscriptionTier
    public let subscriptionExpiry: String?
    public let storageQuotaBytes: String
    public let storageUsedBytes: String
    public let createdAt: String
    
    public init(
        id: String,
        email: String?,
        displayName: String,
        avatarUrl: String?,
        subscriptionTier: SubscriptionTier,
        subscriptionExpiry: String?,
        storageQuotaBytes: String,
        storageUsedBytes: String,
        createdAt: String
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.subscriptionTier = subscriptionTier
        self.subscriptionExpiry = subscriptionExpiry
        self.storageQuotaBytes = storageQuotaBytes
        self.storageUsedBytes = storageUsedBytes
        self.createdAt = createdAt
    }
}

public struct AuthResult: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int
    public let user: UserProfile
    
    public init(accessToken: String, refreshToken: String, expiresIn: Int, user: UserProfile) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.user = user
    }
}

public struct LoginRequest: Codable, Sendable {
    public let email: String
    public let password: String
    
    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

public struct RegisterRequest: Codable, Sendable {
    public let email: String
    public let password: String
    public let displayName: String
    public let avatarUrl: String?
    
    public init(email: String, password: String, displayName: String, avatarUrl: String? = nil) {
        self.email = email
        self.password = password
        self.displayName = displayName
        self.avatarUrl = avatarUrl
    }
}

public struct RefreshTokenRequest: Codable, Sendable {
    public let refreshToken: String
    
    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}

public struct AppleAuthRequest: Codable, Sendable {
    public let identityToken: String
    public let displayName: String?
    
    public init(identityToken: String, displayName: String?) {
        self.identityToken = identityToken
        self.displayName = displayName
    }
}

public struct GoogleAuthRequest: Codable, Sendable {
    public let idToken: String
    
    public init(idToken: String) {
        self.idToken = idToken
    }
}

// MARK: - Channel DTOs
public struct ChannelDTO: Codable, Sendable, Identifiable {
    public let id: String
    public let userId: String?
    public let platform: Platform
    public let platformId: String?
    public let channelUrl: String
    public let displayName: String
    public let avatarUrl: String?
    public let isActive: Bool
    public let isLive: Bool
    public let lastCheckedAt: String?
    public let createdAt: String?
    public let updatedAt: String?
    
    public init(
        id: String,
        userId: String? = nil,
        platform: Platform,
        platformId: String? = nil,
        channelUrl: String,
        displayName: String,
        avatarUrl: String? = nil,
        isActive: Bool = true,
        isLive: Bool = false,
        lastCheckedAt: String? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.platform = platform
        self.platformId = platformId
        self.channelUrl = channelUrl
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.isActive = isActive
        self.isLive = isLive
        self.lastCheckedAt = lastCheckedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct ChannelListResponse: Codable, Sendable {
    public let channels: [ChannelDTO]
    public let total: Int?
    public let page: Int?
    public let totalPages: Int?
    
    public init(channels: [ChannelDTO], total: Int? = nil, page: Int? = nil, totalPages: Int? = nil) {
        self.channels = channels
        self.total = total
        self.page = page
        self.totalPages = totalPages
    }
}

public struct AddChannelRequest: Codable, Sendable {
    public let platform: Platform
    public let platformId: String?
    public let channelUrl: String
    public let displayName: String
    public let avatarUrl: String?
    public let rtmpStreamUrl: String?
    public let consentConfirmed: Bool
    
    public init(
        platform: Platform,
        platformId: String? = nil,
        channelUrl: String,
        displayName: String,
        avatarUrl: String? = nil,
        rtmpStreamUrl: String? = nil,
        consentConfirmed: Bool = true
    ) {
        self.platform = platform
        self.platformId = platformId
        self.channelUrl = channelUrl
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.rtmpStreamUrl = rtmpStreamUrl
        self.consentConfirmed = consentConfirmed
    }
}

public struct LiveStatusResponse: Codable, Sendable {
    public let channelId: String
    public let isLive: Bool
    public let lastCheckedAt: String?
    
    public init(channelId: String, isLive: Bool, lastCheckedAt: String? = nil) {
        self.channelId = channelId
        self.isLive = isLive
        self.lastCheckedAt = lastCheckedAt
    }
}

// MARK: - Recording DTOs
public struct ChannelSummary: Codable, Sendable {
    public let displayName: String
    public let platform: Platform
    public let avatarUrl: String?
    
    public init(displayName: String, platform: Platform, avatarUrl: String? = nil) {
        self.displayName = displayName
        self.platform = platform
        self.avatarUrl = avatarUrl
    }
}

public struct RecordingDTO: Codable, Sendable, Identifiable {
    public let id: String
    public let channelId: String
    public let userId: String?
    public let sessionId: String?
    public let segmentIndex: Int?
    public let title: String
    public let notes: String?
    public let durationSeconds: Int
    public let sizeBytes: String
    public let recordedAt: String
    public let status: RecordingStatus
    public let platform: Platform
    public let channel: ChannelSummary?
    
    public init(
        id: String,
        channelId: String,
        userId: String? = nil,
        sessionId: String? = nil,
        segmentIndex: Int? = 0,
        title: String,
        notes: String? = nil,
        durationSeconds: Int,
        sizeBytes: String,
        recordedAt: String,
        status: RecordingStatus,
        platform: Platform,
        channel: ChannelSummary? = nil
    ) {
        self.id = id
        self.channelId = channelId
        self.userId = userId
        self.sessionId = sessionId
        self.segmentIndex = segmentIndex
        self.title = title
        self.notes = notes
        self.durationSeconds = durationSeconds
        self.sizeBytes = sizeBytes
        self.recordedAt = recordedAt
        self.status = status
        self.platform = platform
        self.channel = channel
    }
}

public struct SessionSummary: Codable, Sendable {
    public let id: String
    public let title: String?
    public let startedAt: String
    
    public init(id: String, title: String?, startedAt: String) {
        self.id = id
        self.title = title
        self.startedAt = startedAt
    }
}

public struct RecordingDetailDTO: Codable, Sendable, Identifiable {
    public let id: String
    public let channelId: String
    public let userId: String?
    public let sessionId: String?
    public let segmentIndex: Int?
    public let title: String
    public let notes: String?
    public let durationSeconds: Int
    public let sizeBytes: String
    public let recordedAt: String
    public let status: RecordingStatus
    public let platform: Platform
    public let channel: ChannelSummary?
    public let playbackUrl: String?
    public let hlsPlaybackUrl: String?
    public let thumbnailUrl: String?
    public let session: SessionSummary?
    
    public init(
        id: String,
        channelId: String,
        userId: String? = nil,
        sessionId: String? = nil,
        segmentIndex: Int? = 0,
        title: String,
        notes: String? = nil,
        durationSeconds: Int,
        sizeBytes: String,
        recordedAt: String,
        status: RecordingStatus,
        platform: Platform,
        channel: ChannelSummary? = nil,
        playbackUrl: String? = nil,
        hlsPlaybackUrl: String? = nil,
        thumbnailUrl: String? = nil,
        session: SessionSummary? = nil
    ) {
        self.id = id
        self.channelId = channelId
        self.userId = userId
        self.sessionId = sessionId
        self.segmentIndex = segmentIndex
        self.title = title
        self.notes = notes
        self.durationSeconds = durationSeconds
        self.sizeBytes = sizeBytes
        self.recordedAt = recordedAt
        self.status = status
        self.platform = platform
        self.channel = channel
        self.playbackUrl = playbackUrl
        self.hlsPlaybackUrl = hlsPlaybackUrl
        self.thumbnailUrl = thumbnailUrl
        self.session = session
    }
}

public struct RecordingListResponse: Codable, Sendable {
    public let recordings: [RecordingDTO]
    public let total: Int?
    public let page: Int?
    public let totalPages: Int?
    
    public init(recordings: [RecordingDTO], total: Int? = nil, page: Int? = nil, totalPages: Int? = nil) {
        self.recordings = recordings
        self.total = total
        self.page = page
        self.totalPages = totalPages
    }
}

public struct StorageUsageDTO: Codable, Sendable {
    public let usedBytes: String
    public let quotaBytes: String
    public let usedPercent: Int
    public let tier: SubscriptionTier
    
    public init(usedBytes: String, quotaBytes: String, usedPercent: Int, tier: SubscriptionTier) {
        self.usedBytes = usedBytes
        self.quotaBytes = quotaBytes
        self.usedPercent = usedPercent
        self.tier = tier
    }
}

public struct UpdateRecordingRequest: Codable, Sendable {
    public let title: String?
    public let notes: String?
    
    public init(title: String? = nil, notes: String? = nil) {
        self.title = title
        self.notes = notes
    }
}

public struct DownloadUrlDTO: Codable, Sendable {
    public let downloadUrl: String
    public let expiresIn: Int
    
    public init(downloadUrl: String, expiresIn: Int) {
        self.downloadUrl = downloadUrl
        self.expiresIn = expiresIn
    }
}

// MARK: - Subscription DTOs
public struct SubscriptionLimits: Codable, Sendable {
    public let maxChannels: Int?
    public let maxHoursPerMonth: Int?
    public let storageQuotaGb: Int?
    public let retentionDays: Int?
    public let downloadEnabled: Bool?
    
    public init(
        maxChannels: Int? = nil,
        maxHoursPerMonth: Int? = nil,
        storageQuotaGb: Int? = nil,
        retentionDays: Int? = nil,
        downloadEnabled: Bool? = nil
    ) {
        self.maxChannels = maxChannels
        self.maxHoursPerMonth = maxHoursPerMonth
        self.storageQuotaGb = storageQuotaGb
        self.retentionDays = retentionDays
        self.downloadEnabled = downloadEnabled
    }
}

public struct SubscriptionStatusDTO: Codable, Sendable {
    public let tier: SubscriptionTier
    public let expiresAt: String?
    public let isActive: Bool
    public let source: String?
    public let limits: SubscriptionLimits?
    
    public init(
        tier: SubscriptionTier,
        expiresAt: String? = nil,
        isActive: Bool = true,
        source: String? = nil,
        limits: SubscriptionLimits? = nil
    ) {
        self.tier = tier
        self.expiresAt = expiresAt
        self.isActive = isActive
        self.source = source
        self.limits = limits
    }
}

public struct LinkRevenueCatRequest: Codable, Sendable {
    public let revenuecatId: String
    
    public init(revenuecatId: String) {
        self.revenuecatId = revenuecatId
    }
}

// MARK: - Notification DTOs
public struct NotificationDTO: Codable, Sendable, Identifiable {
    public let id: String
    public let userId: String
    public let recordingId: String?
    public let type: NotificationType
    public let title: String
    public let body: String
    public var read: Bool
    public let createdAt: String
    
    public init(
        id: String,
        userId: String,
        recordingId: String? = nil,
        type: NotificationType,
        title: String,
        body: String,
        read: Bool = false,
        createdAt: String
    ) {
        self.id = id
        self.userId = userId
        self.recordingId = recordingId
        self.type = type
        self.title = title
        self.body = body
        self.read = read
        self.createdAt = createdAt
    }
}

public struct NotificationListDTO: Codable, Sendable {
    public let notifications: [NotificationDTO]
    public let total: Int
    public let unreadCount: Int
    public let page: Int
    public let totalPages: Int
    
    public init(notifications: [NotificationDTO], total: Int, unreadCount: Int, page: Int, totalPages: Int) {
        self.notifications = notifications
        self.total = total
        self.unreadCount = unreadCount
        self.page = page
        self.totalPages = totalPages
    }
}

public struct MarkAllReadResponse: Codable, Sendable {
    public let count: Int
    
    public init(count: Int) {
        self.count = count
    }
}

// MARK: - Device DTOs
public struct RegisterDeviceTokenRequest: Codable, Sendable {
    public let platform: String
    public let token: String
    
    public init(platform: String = "ios", token: String) {
        self.platform = platform
        self.token = token
    }
}
