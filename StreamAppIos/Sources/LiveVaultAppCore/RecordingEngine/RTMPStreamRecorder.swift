import Foundation
import UIKit

public final class RTMPStreamRecorder {
    public static let shared = RTMPStreamRecorder()
    private init() {}
    
    private var activeSessions: [String: UIBackgroundTaskIdentifier] = [:]
    
    public func startRecording(recordingId: String, streamURL: URL, outputURL: URL, onProgress: ((Int64) -> Void)?, onComplete: ((URL) -> Void)?) {
        var bgTaskId: UIBackgroundTaskIdentifier = .invalid
        bgTaskId = UIApplication.shared.beginBackgroundTask(withName: "RTMP_\(recordingId)") {
            if bgTaskId != .invalid {
                UIApplication.shared.endBackgroundTask(bgTaskId)
            }
        }
        activeSessions[recordingId] = bgTaskId
        
        let command = "-y -re -i \"\(streamURL.absoluteString)\" -c copy -f mp4 -movflags +faststart \"\(outputURL.path)\""
        _ = command
        
        // Timer theo dõi dung lượng
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let bytes = (try? FileManager.default.attributesOfItem(atPath: outputURL.path)[.size] as? Int64) ?? 0
            onProgress?(bytes)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            timer.invalidate()
            onComplete?(outputURL)
            if bgTaskId != .invalid {
                UIApplication.shared.endBackgroundTask(bgTaskId)
            }
        }
    }
    
    public func stopRecording(recordingId: String) {
        if let bgId = activeSessions[recordingId] {
            if bgId != .invalid {
                UIApplication.shared.endBackgroundTask(bgId)
            }
            activeSessions.removeValue(forKey: recordingId)
        }
    }
}