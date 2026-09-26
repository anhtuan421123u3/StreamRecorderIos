import Foundation
import SwiftData
import LiveVaultCommon
import LiveVaultDatabase

public final class DownloadManager: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    public static let shared = DownloadManager()
    
    private var session: URLSession!
    private var activeTasks: [String: URLSessionDownloadTask] = [:] // recordingId -> Task
    private var resumeDataMap: [String: Data] = [:] // recordingId -> Data
    private var taskToRecordingId: [Int: String] = [:] // taskIdentifier -> recordingId
    
    public var onProgressUpdate: ((String, Double) -> Void)?
    public var onDownloadComplete: ((String, URL) -> Void)?
    
    private override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: LiveVaultConstants.backgroundDownloadSessionId)
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    public func startDownload(recordingId: String, title: String, channelName: String, urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        let task = session.downloadTask(with: url)
        activeTasks[recordingId] = task
        taskToRecordingId[task.taskIdentifier] = recordingId
        
        // Save initial entity in SwiftData
        Task { @MainActor in
            let entity = DownloadEntity(
                recordingId: recordingId,
                title: title,
                channelName: channelName,
                progress: 0.0,
                statusRaw: "downloading"
            )
            DatabaseService.shared.saveChannel(ChannelEntity(id: "", platformRaw: "", channelUrl: "", displayName: "")) // Ensure context
            let context = DatabaseService.shared.context
            context.insert(entity)
            try? context.save()
        }
        
        task.resume()
    }
    
    public func pauseDownload(recordingId: String) {
        guard let task = activeTasks[recordingId] else { return }
        task.cancel { [weak self] resumeData in
            if let data = resumeData {
                self?.resumeDataMap[recordingId] = data
            }
        }
        activeTasks.removeValue(forKey: recordingId)
    }
    
    public func resumeDownload(recordingId: String) {
        guard let resumeData = resumeDataMap[recordingId] else { return }
        let task = session.downloadTask(withResumeData: resumeData)
        activeTasks[recordingId] = task
        taskToRecordingId[task.taskIdentifier] = recordingId
        resumeDataMap.removeValue(forKey: recordingId)
        task.resume()
    }
    
    // MARK: - URLSessionDownloadDelegate
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let recordingId = taskToRecordingId[downloadTask.taskIdentifier] else { return }
        
        let fileManager = FileManager.default
        guard let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let destinationDir = docs.appendingPathComponent("Recordings", isDirectory: true)
        
        try? fileManager.createDirectory(at: destinationDir, withIntermediateDirectories: true)
        let destinationUrl = destinationDir.appendingPathComponent("\(recordingId).mp4")
        
        try? fileManager.removeItem(at: destinationUrl)
        do {
            try fileManager.moveItem(at: location, to: destinationUrl)
            Task { @MainActor in
                DatabaseService.shared.updateDownloadProgress(
                    recordingId: recordingId,
                    progress: 1.0,
                    downloadedBytes: downloadTask.countOfBytesReceived,
                    totalBytes: downloadTask.countOfBytesExpectedToReceive
                )
                
                // Mark recording downloaded in SwiftData
                let descriptor = FetchDescriptor<RecordingEntity>(predicate: #Predicate { $0.id == recordingId })
                if let recs = try? DatabaseService.shared.context.fetch(descriptor), let rec = recs.first {
                    rec.isDownloaded = true
                    rec.localFilePath = destinationUrl.path
                    try? DatabaseService.shared.context.save()
                }
            }
            onDownloadComplete?(recordingId, destinationUrl)
        } catch {
            print("Failed to save downloaded file: \(error)")
        }
        
        activeTasks.removeValue(forKey: recordingId)
        taskToRecordingId.removeValue(forKey: downloadTask.taskIdentifier)
    }
    
    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let recordingId = taskToRecordingId[downloadTask.taskIdentifier], totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        
        Task { @MainActor in
            DatabaseService.shared.updateDownloadProgress(
                recordingId: recordingId,
                progress: progress,
                downloadedBytes: totalBytesWritten,
                totalBytes: totalBytesExpectedToWrite
            )
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.onProgressUpdate?(recordingId, progress)
        }
    }
}
