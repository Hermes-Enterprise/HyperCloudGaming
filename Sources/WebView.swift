import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let bridge: GameControllerBridge

    func makeCoordinator() -> Coordinator { Coordinator(bridge: bridge) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        config.userContentController.add(bridge, name: "pointerLock")
        config.userContentController.add(bridge, name: "keyboard")

        let scripts: [(String, String)] = [
            ("gm-shim", "js"),
            ("better-xcloud.user", "js"),
            ("pointer-shim", "js")
        ]
        for (name, ext) in scripts {
            if let url = Bundle.main.url(forResource: name, withExtension: ext),
               let src = try? String(contentsOf: url) {
                config.userContentController.addUserScript(
                    WKUserScript(source: src,
                                 injectionTime: .atDocumentStart,
                                 forMainFrameOnly: false)   // <-- inject into iframes too
                )
            } else {
                print("!! Missing bundled script: \(name).\(ext)")
            }
        }

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = context.coordinator

        // Clear cache before loading — rules out stale WebKit cache
        let store = WKWebsiteDataStore.default()
        store.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                         modifiedSince: Date(timeIntervalSince1970: 0)) {
            if let url = URL(string: "https://www.xbox.com/play") {
                DispatchQueue.main.async {
                    webView.load(URLRequest(url: url))
                }
            }
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        let bridge: GameControllerBridge
        init(bridge: GameControllerBridge) { self.bridge = bridge }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            bridge.diagnosticStatus = "Loading..."
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            bridge.diagnosticStatus = "Loaded: \(webView.url?.absoluteString ?? "?")"
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            bridge.diagnosticStatus = "Fail: \(error.localizedDescription)"
        }

        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
    }
}