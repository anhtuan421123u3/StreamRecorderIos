import Foundation

public enum StreamType: String, Codable, CaseIterable, Sendable {
    case hls = "HLS (.m3u8)"
    case rtmp = "RTMP"
    case dash = "DASH (.mpd)"
    case direct = "Direct (.mp4/.ts)"
}

public struct StreamMediaInfo: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let url: URL
    public let streamType: StreamType
    public let title: String
    public let resolution: String?
    public let mimeType: String?
    public let detectedAt: Date
    public let pageURL: URL?
    
    public init(
        id: UUID = UUID(),
        url: URL,
        streamType: StreamType,
        title: String,
        resolution: String? = nil,
        mimeType: String? = nil,
        detectedAt: Date = Date(),
        pageURL: URL? = nil
    ) {
        self.id = id
        self.url = url
        self.streamType = streamType
        self.title = title
        self.resolution = resolution
        self.mimeType = mimeType
        self.detectedAt = detectedAt
        self.pageURL = pageURL
    }
}