import Foundation
import AVFoundation

public final class HLSToMP4Exporter {
    public static let shared = HLSToMP4Exporter()
    private init() {}
    
    public func exportOfflineAssetToMP4(sourceAssetURL: URL, destinationMP4URL: URL) async throws {
        let asset = AVURLAsset(url: sourceAssetURL)
        let compatiblePresets = await AVAssetExportSession.exportPresets(compatibleWith: asset)
        
        let chosenPreset: String
        if compatiblePresets.contains(AVAssetExportPresetPassthrough) {
            chosenPreset = AVAssetExportPresetPassthrough
        } else if compatiblePresets.contains(AVAssetExportPresetHighestQuality) {
            chosenPreset = AVAssetExportPresetHighestQuality
        } else {
            chosenPreset = AVAssetExportPreset1920x1080
        }
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: chosenPreset) else {
            throw NSError(domain: "HLSToMP4Exporter", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to init AVAssetExportSession"])
        }
        
        exportSession.outputURL = destinationMP4URL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        if FileManager.default.fileExists(atPath: destinationMP4URL.path) {
            try? FileManager.default.removeItem(at: destinationMP4URL)
        }
        
        await exportSession.export()
        
        guard exportSession.status == .completed else {
            let msg = exportSession.error?.localizedDescription ?? "Export failed with status \(exportSession.status.rawValue)"
            throw NSError(domain: "HLSToMP4Exporter", code: -2, userInfo: [NSLocalizedDescriptionKey: msg])
        }
    }
}