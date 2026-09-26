import Foundation
import WebKit
import Combine

public final class BrowserViewModel: ObservableObject {
    @Published public var urlString: String = "https://www.google.com"
    @Published public var isLoading: Bool = false
    @Published public var canGoBack: Bool = false
    @Published public var canGoForward: Bool = false
    @Published public var detectedStreams: [StreamMediaInfo] = []
    @Published public var showStreamSelectionSheet: Bool = false
    @Published public var latestDetectedStream: StreamMediaInfo? = nil
    @Published public var showToast: Bool = false
    
    public var onStartDownloadStream: ((StreamMediaInfo) -> Void)?
    
    weak var webView: WKWebView?
    
    public init() {}
    
    public func loadURL() {
        var formatted = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !formatted.hasPrefix("http://") && !formatted.hasPrefix("https://") {
            if formatted.contains(".") && !formatted.contains(" ") {
                formatted = "https://" + formatted
            } else {
                let query = formatted.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                formatted = "https://www.google.com/search?q=\(query)"
            }
        }
        self.urlString = formatted
        if let url = URL(string: formatted) {
            webView?.load(URLRequest(url: url))
        }
    }
    
    public func goBack() { webView?.goBack() }
    public func goForward() { webView?.goForward() }
    public func reload() { webView?.reload() }
    
    public func onStreamDetected(_ stream: StreamMediaInfo) {
        guard !detectedStreams.contains(where: { $0.url == stream.url }) else { return }
        detectedStreams.insert(stream, at: 0)
        latestDetectedStream = stream
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            self.showToast = false
        }
    }
    
    public func triggerDownload(stream: StreamMediaInfo) {
        onStartDownloadStream?(stream)
    }
}