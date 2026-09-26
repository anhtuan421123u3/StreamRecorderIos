import Foundation
import AVFoundation

public protocol HLSDownloadDelegate: AnyObject {
    func hlsDownloadDidProgress(recordingId: String, progress: Double, bytesReceived: Int64)
    func hlsDownloadDidComplete(recordingId: String, outputMP4URL: URL)
    func hlsDownloadDidFail(recordingId: String, error: String)
}

public final class HLSDownloadSessionManager: NSObject, AVAssetDownloadDelegate {
    public static let shared = HLSDownloadSessionManager()
    
    private var downloadSession: AVAssetDownloadURLSession!
    private var taskMap: [AVAssetDownloadTask: String] = [:] // Task -> RecordingId
    private var taskMetadata: [String: (title: String, url: URL)] = [:]
    
    public weak var delegate: HLSDownloadDelegate?
    public var backgroundCompletionHandler: (() -> Void)?
    
    private override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "app.livevault.ios.hls.download")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        self.downloadSession = AVAssetDownloadURLSession(
            configuration: config,
            assetDownloadDelegate: self,
            delegateQueue: OperationQueue.main
        )
    }
    
    public func startHLSDownload(recordingId: String, title: String, hlsURL: URL) {
        let asset = AVURLAsset(url: hlsURL)
        guard let task = downloadSession.makeAssetDownloadTask(
            asset: asset,
            assetTitle: title,
            assetArtworkData: nil,
            options: [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: 0]
        ) else {
            delegate?.hlsDownloadDidFail(recordingId: recordingId, error: "Cannot create AVAssetDownloadTask")
            return
        }
        
        taskMap[task] = recordingId
        taskMetadata[recordingId] = (title: title, url: hlsURL)
        task.resume()
    }
    
    public func cancelHLSDownload(recordingId: String) {
        if let task = taskMap.first(where: { $0.value == recordingId })?.key {
            task.cancel()
            taskMap.removeValue(forKey: task)
            taskMetadata.removeValue(forKey: recordingId)
        }
    }
    
    // MARK: - AVAssetDownloadDelegate
    public func urlSession(
        _ session: URLSession,
        assetDownloadTask: AVAssetDownloadTask,
        didLoad timeRange: CMTimeRange,
        totalTimeRangesLoaded loadedTimeRanges: [NSValue],
        timeRangeExpectedToLoad: CMTimeRange
    ) {
        guard let recId = taskMap[assetDownloadTask] else { return }
        
        var totalLoaded: Double = 0
        for val in loadedTimeRanges {
            totalLoaded += CMTimeGetSeconds(val.cmTimeRangeValue.duration)
        }
        let expected = CMTimeGetSeconds(timeRangeExpectedToLoad.duration)
        let progress = expected > 0 ? min(1.0, max(0.0, totalLoaded / expected)) : 0.0
        
        delegate?.hlsDownloadDidProgress(recordingId: recId, progress: progress, bytesReceived: assetDownloadTask.countOfBytesReceived)
    }
    
    public func urlSession(
        _ session: URLSession,
        assetDownloadTask: AVAssetDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let recId = taskMap[assetDownloadTask],
              let meta = taskMetadata[recId] else { return }
        
        Task {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destDir = docs.appendingPathComponent("Recordings", isDirectory: true)
            try? FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
            
            let safeTitle = meta.title.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: " ", with: "_")
            let destMP4 = destDir.appendingPathComponent("\(safeTitle)_\(recId.prefix(6)).mp4")
            
            do {
                try await HLSToMP4Exporter.shared.exportOfflineAssetToMP4(sourceAssetURL: location, destinationMP4URL: destMP4)
                try? FileManager.default.removeItem(at: location)
                self.taskMap.removeValue(forKey: assetDownloadTask)
                self.taskMetadata.removeValue(forKey: recId)
                self.delegate?.hlsDownloadDidComplete(recordingId: recId, outputMP4URL: destMP4)
            } catch {
                self.delegate?.hlsDownloadDidFail(recordingId: recId, error: error.localizedDescription)
            }
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let dlTask = task as? AVAssetDownloadTask,
              let recId = taskMap[dlTask] else { return }
        
        if let err = error as NSError? {
            if err.domain == NSURLErrorDomain && err.code == NSURLErrorCancelled { return }
            if err.domain == AVFoundationErrorDomain && (err.code == AVError.failedToParse.rawValue || err.code == -11835) {
                delegate?.hlsDownloadDidFail(recordingId: recId, error: "Nội dung có bảo vệ bản quyền (DRM FairPlay). Không hỗ trợ tải.")
                return
            }
            delegate?.hlsDownloadDidFail(recordingId: recId, error: err.localizedDescription)
        }
    }
    
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            self.backgroundCompletionHandler?()
            self.backgroundCompletionHandler = nil
        }
    }
}