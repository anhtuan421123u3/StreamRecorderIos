import Foundation
import SwiftData
import LiveVaultCommon

@Model
public final class ChannelEntity {
    @Attribute(.unique) public var id: String
    public var userId: String?
    public var platformRaw: String
    public var platformId: String?
    public var channelUrl: String
    public var displayName: String
    public var avatarUrl: String?
    public var isActive: Bool
    public var isLive: Bool
    public var lastCheckedAt: Date?
    public var createdAt: Date?
    public var updatedAt: Date?
    
    public init(
        id: String,
        userId: String? = nil,
        platformRaw: String,
        platformId: String? = nil,
        channelUrl: String,
        displayName: String,
        avatarUrl: String? = nil,
        isActive: Bool = true,
        isLive: Bool = false,
        lastCheckedAt: Date? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.platformRaw = platformRaw
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
    
    public var platform: Platform {
        Platform(rawValue: platformRaw) ?? .youtube
    }
}

@Model
public final class RecordingEntity {
    @Attribute(.unique) public var id: String
    public var channelId: String
    public var userId: String?
    public var sessionId: String?
    public var segmentIndex: Int
    public var title: String
    public var notes: String?
    public var durationSeconds: Int
    public var sizeBytesString: String
    public var recordedAt: Date
    public var statusRaw: String
    public var platformRaw: String
    public var channelDisplayName: String
    public var channelAvatarUrl: String?
    public var playbackUrl: String?
    public var hlsPlaybackUrl: String?
    public var thumbnailUrl: String?
    public var isDownloaded: Bool
    public var localFilePath: String?
    
    public init(
        id: String,
        channelId: String,
        userId: String? = nil,
        sessionId: String? = nil,
        segmentIndex: Int = 0,
        title: String,
        notes: String? = nil,
        durationSeconds: Int,
        sizeBytesString: String,
        recordedAt: Date,
        statusRaw: String,
        platformRaw: String,
        channelDisplayName: String,
        channelAvatarUrl: String? = nil,
        playbackUrl: String? = nil,
        hlsPlaybackUrl: String? = nil,
        thumbnailUrl: String? = nil,
        isDownloaded: Bool = false,
        localFilePath: String? = nil
    ) {
        self.id = id
        self.channelId = channelId
        self.userId = userId
        self.sessionId = sessionId
        self.segmentIndex = segmentIndex
        self.title = title
        self.notes = notes
        self.durationSeconds = durationSeconds
        self.sizeBytesString = sizeBytesString
        self.recordedAt = recordedAt
        self.statusRaw = statusRaw
        self.platformRaw = platformRaw
        self.channelDisplayName = channelDisplayName
        self.channelAvatarUrl = channelAvatarUrl
        self.playbackUrl = playbackUrl
        self.hlsPlaybackUrl = hlsPlaybackUrl
        self.thumbnailUrl = thumbnailUrl
        self.isDownloaded = isDownloaded
        self.localFilePath = localFilePath
    }
    
    public var status: RecordingStatus {
        RecordingStatus(rawValue: statusRaw) ?? .ready
    }
    
    public var platform: Platform {
        Platform(rawValue: platformRaw) ?? .youtube
    }
}

@Model
public final class NotificationEntity {
    @Attribute(.unique) public var id: String
    public var userId: String
    public var recordingId: String?
    public var typeRaw: String
    public var title: String
    public var body: String
    public var isRead: Bool
    public var createdAt: Date
    
    public init(
        id: String,
        userId: String,
        recordingId: String? = nil,
        typeRaw: String,
        title: String,
        body: String,
        isRead: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.recordingId = recordingId
        self.typeRaw = typeRaw
        self.title = title
        self.body = body
        self.isRead = isRead
        self.createdAt = createdAt
    }
    
    public var type: NotificationType {
        NotificationType(rawValue: typeRaw) ?? .recordingComplete
    }
}

@Model
public final class DownloadEntity {
    @Attribute(.unique) public var recordingId: String
    public var title: String
    public var channelName: String
    public var progress: Double // 0.0 to 1.0
    public var statusRaw: String // "downloading", "paused", "completed", "failed"
    public var totalBytes: Int64
    public var downloadedBytes: Int64
    public var localRelativePath: String?
    public var errorDescription: String?
    public var updatedAt: Date
    
    public init(
        recordingId: String,
        title: String,
        channelName: String,
        progress: Double = 0.0,
        statusRaw: String = "downloading",
        totalBytes: Int64 = 0,
        downloadedBytes: Int64 = 0,
        localRelativePath: String? = nil,
        errorDescription: String? = nil,
        updatedAt: Date = Date()
    ) {
        self.recordingId = recordingId
        self.title = title
        self.channelName = channelName
        self.progress = progress
        self.statusRaw = statusRaw
        self.totalBytes = totalBytes
        self.downloadedBytes = downloadedBytes
        self.localRelativePath = localRelativePath
        self.errorDescription = errorDescription
        self.updatedAt = updatedAt
    }
}
