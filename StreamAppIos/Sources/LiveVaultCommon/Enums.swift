import Foundation

public enum Platform: String, Codable, CaseIterable, Sendable {
    case youtube = "YOUTUBE"
    case twitch = "TWITCH"
    case kick = "KICK"
    case tiktok = "TIKTOK"
    case customRtmp = "CUSTOM_RTMP"
    
    public var displayName: String {
        switch self {
        case .youtube: return "YouTube"
        case .twitch: return "Twitch"
        case .kick: return "Kick"
        case .tiktok: return "TikTok"
        case .customRtmp: return "Custom RTMP"
        }
    }
    
    public var sfSymbol: String {
        switch self {
        case .youtube: return "play.rectangle.fill"
        case .twitch: return "tv.fill"
        case .kick: return "bolt.fill"
        case .tiktok: return "music.note"
        case .customRtmp: return "antenna.radiowaves.left.and.right"
        }
    }
}

public enum SubscriptionTier: String, Codable, CaseIterable, Sendable, Comparable {
    case free = "FREE"
    case pro = "PRO"
    case premium = "PREMIUM"
    
    public var rank: Int {
        switch self {
        case .free: return 0
        case .pro: return 1
        case .premium: return 2
        }
    }
    
    public static func < (lhs: SubscriptionTier, rhs: SubscriptionTier) -> Bool {
        return lhs.rank < rhs.rank
    }
    
    public var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        case .premium: return "Premium"
        }
    }
    
    public var maxChannels: Int {
        switch self {
        case .free: return 1
        case .pro: return 5
        case .premium: return 20
        }
    }
    
    public var storageQuotaGb: Int {
        switch self {
        case .free: return 5
        case .pro: return 50
        case .premium: return 200
        }
    }
    
    public var retentionDays: Int {
        switch self {
        case .free: return 3
        case .pro: return 30
        case .premium: return 90
        }
    }
    
    public var downloadEnabled: Bool {
        switch self {
        case .free: return false
        case .pro, .premium: return true
        }
    }
}

public enum RecordingStatus: String, Codable, CaseIterable, Sendable {
    case queued = "QUEUED"
    case recording = "RECORDING"
    case processing = "PROCESSING"
    case ready = "READY"
    case failed = "FAILED"
    case deleted = "DELETED"
    
    public var isPlayable: Bool {
        self == .ready
    }
    
    public var isActivelyRecording: Bool {
        self == .recording
    }
    
    public var displayName: String {
        switch self {
        case .queued: return "Queued"
        case .recording: return "Recording"
        case .processing: return "Processing"
        case .ready: return "Ready"
        case .failed: return "Failed"
        case .deleted: return "Deleted"
        }
    }
}

public enum NotificationType: String, Codable, CaseIterable, Sendable {
    case recordingComplete = "RECORDING_COMPLETE"
    case recordingFailed = "RECORDING_FAILED"
    case storageQuotaWarning = "STORAGE_QUOTA_WARNING"
    case storageQuotaExceeded = "STORAGE_QUOTA_EXCEEDED"
    case subscriptionExpiring = "SUBSCRIPTION_EXPIRING"
    case subscriptionExpired = "SUBSCRIPTION_EXPIRED"
    
    public var sfSymbol: String {
        switch self {
        case .recordingComplete: return "checkmark.circle.fill"
        case .recordingFailed: return "exclamationmark.triangle.fill"
        case .storageQuotaWarning: return "internaldrive"
        case .storageQuotaExceeded: return "xmark.octagon.fill"
        case .subscriptionExpiring, .subscriptionExpired: return "crown.fill"
        }
    }
}
