import Foundation
import SwiftUI
import Photos

public struct IPAddressHelper {
    public static func getWiFiAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)
        return address
    }
}

public final class LocalWebDAVServer: ObservableObject {
    public static let shared = LocalWebDAVServer()
    @Published public private(set) var isRunning: Bool = false
    @Published public private(set) var serverURLString: String? = nil
    @Published public private(set) var localIP: String? = nil
    public let port: UInt = 8080
    
    private init() {
        refreshIP()
    }
    
    public func refreshIP() {
        self.localIP = IPAddressHelper.getWiFiAddress()
        if let ip = localIP {
            self.serverURLString = "http://\(ip):\(port)/"
        } else {
            self.serverURLString = nil
        }
    }
    
    public func startServer() {
        refreshIP()
        self.isRunning = true
    }
    
    public func stopServer() {
        self.isRunning = false
    }
}

public final class FileExportManager {
    public static let shared = FileExportManager()
    private init() {}
    
    public func saveVideoToPhotoLibrary(fileURL: URL) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw NSError(domain: "FileExportManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Quyền truy cập Thư viện Ảnh bị từ chối."])
        }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
        }
    }
}

public struct ActivityViewControllerRepresentable: UIViewControllerRepresentable {
    public let activityItems: [Any]
    public init(activityItems: [Any]) {
        self.activityItems = activityItems
    }
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}