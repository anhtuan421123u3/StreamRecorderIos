import Foundation
import SwiftData
import LiveVaultCommon

@MainActor
public final class DatabaseService {
    public static let shared = DatabaseService()
    
    public let modelContainer: ModelContainer
    public var context: ModelContext {
        modelContainer.mainContext
    }
    
    public init(inMemory: Bool = false) {
        let schema = Schema([
            ChannelEntity.self,
            RecordingEntity.self,
            NotificationEntity.self,
            DownloadEntity.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            self.modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    // MARK: - Channel CRUD
    public func fetchChannels() -> [ChannelEntity] {
        let descriptor = FetchDescriptor<ChannelEntity>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }
    
    public func saveChannel(_ channel: ChannelEntity) {
        context.insert(channel)
        try? context.save()
    }
    
    public func deleteChannel(id: String) {
        let descriptor = FetchDescriptor<ChannelEntity>(predicate: #Predicate { $0.id == id })
        if let channels = try? context.fetch(descriptor) {
            for ch in channels {
                context.delete(ch)
            }
            try? context.save()
        }
    }
    
    // MARK: - Recording CRUD
    public func fetchRecordings() -> [RecordingEntity] {
        let descriptor = FetchDescriptor<RecordingEntity>(sortBy: [SortDescriptor(\.recordedAt, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }
    
    public func fetchDownloadedRecordings() -> [RecordingEntity] {
        let descriptor = FetchDescriptor<RecordingEntity>(
            predicate: #Predicate { $0.isDownloaded == true },
            sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    public func saveRecording(_ recording: RecordingEntity) {
        context.insert(recording)
        try? context.save()
    }
    
    public func deleteRecording(id: String) {
        let descriptor = FetchDescriptor<RecordingEntity>(predicate: #Predicate { $0.id == id })
        if let recordings = try? context.fetch(descriptor) {
            for rec in recordings {
                context.delete(rec)
            }
            try? context.save()
        }
    }
    
    // MARK: - Download Tracking
    public func fetchDownloads() -> [DownloadEntity] {
        let descriptor = FetchDescriptor<DownloadEntity>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }
    
    public func updateDownloadProgress(recordingId: String, progress: Double, downloadedBytes: Int64, totalBytes: Int64) {
        let descriptor = FetchDescriptor<DownloadEntity>(predicate: #Predicate { $0.recordingId == recordingId })
        if let downloads = try? context.fetch(descriptor), let download = downloads.first {
            download.progress = progress
            download.downloadedBytes = downloadedBytes
            download.totalBytes = totalBytes
            download.updatedAt = Date()
            try? context.save()
        }
    }
}
