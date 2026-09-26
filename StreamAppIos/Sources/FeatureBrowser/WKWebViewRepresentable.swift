import SwiftUI
import WebKit

public struct WKWebViewRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: BrowserViewModel
    
    public init(viewModel: BrowserViewModel) {
        self.viewModel = viewModel
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    public func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "streamSniffer")
        
        let scriptSource = """
        (function() {
            var originalOpen = XMLHttpRequest.prototype.open;
            XMLHttpRequest.prototype.open = function(m, url) {
                if (url && (url.indexOf('.m3u8') !== -1 || url.indexOf('.mpd') !== -1 || url.indexOf('rtmp://') !== -1)) {
                    window.webkit.messageHandlers.streamSniffer.postMessage({
                        url: url,
                        streamType: url.indexOf('.m3u8') !== -1 ? 'HLS (.m3u8)' : (url.indexOf('rtmp://') !== -1 ? 'RTMP' : 'DASH (.mpd)'),
                        title: document.title
                    });
                }
                return originalOpen.apply(this, arguments);
            };
            
            var originalFetch = window.fetch;
            if (originalFetch) {
                window.fetch = function() {
                    var r = arguments[0];
                    var u = (typeof r === 'string') ? r : (r ? r.url : '');
                    if (u && (u.indexOf('.m3u8') !== -1 || u.indexOf('.mpd') !== -1)) {
                        window.webkit.messageHandlers.streamSniffer.postMessage({
                            url: u,
                            streamType: u.indexOf('.m3u8') !== -1 ? 'HLS (.m3u8)' : 'DASH (.mpd)',
                            title: document.title
                        });
                    }
                    return originalFetch.apply(this, arguments);
                };
            }
        })();
        """
        let userScript = WKUserScript(source: scriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        contentController.addUserScript(userScript)
        
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        viewModel.webView = webView
        
        if let url = URL(string: viewModel.urlString) {
            webView.load(URLRequest(url: url))
        }
        
        return webView
    }
    
    public func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    public class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var viewModel: BrowserViewModel
        
        init(viewModel: BrowserViewModel) {
            self.viewModel = viewModel
        }
        
        public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "streamSniffer",
                  let body = message.body as? [String: Any],
                  let urlString = body["url"] as? String,
                  let streamURL = URL(string: urlString) else { return }
            
            let title = (body["title"] as? String) ?? "Live Stream"
            let typeStr = (body["streamType"] as? String) ?? ""
            
            let type: StreamType
            if typeStr.contains("HLS") { type = .hls }
            else if typeStr.contains("RTMP") { type = .rtmp }
            else if typeStr.contains("DASH") { type = .dash }
            else { type = .direct }
            
            let stream = StreamMediaInfo(
                url: streamURL,
                streamType: type,
                title: title,
                pageURL: viewModel.webView?.url
            )
            
            DispatchQueue.main.async {
                self.viewModel.onStreamDetected(stream)
            }
        }
        
        public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            if let responseURL = navigationResponse.response.url {
                let mime = navigationResponse.response.mimeType ?? ""
                let lower = responseURL.absoluteString.lowercased()
                if lower.contains(".m3u8") || mime.contains("mpegurl") {
                    let stream = StreamMediaInfo(
                        url: responseURL,
                        streamType: .hls,
                        title: webView.title ?? "HLS Live Stream",
                        mimeType: mime
                    )
                    DispatchQueue.main.async {
                        self.viewModel.onStreamDetected(stream)
                    }
                }
            }
            decisionHandler(.allow)
        }
        
        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.viewModel.isLoading = true
                self.viewModel.canGoBack = webView.canGoBack
                self.viewModel.canGoForward = webView.canGoForward
            }
        }
        
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.viewModel.isLoading = false
                self.viewModel.canGoBack = webView.canGoBack
                self.viewModel.canGoForward = webView.canGoForward
                if let u = webView.url?.absoluteString {
                    self.viewModel.urlString = u
                }
            }
        }
    }
}