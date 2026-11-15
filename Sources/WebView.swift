import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let bridge: GameControllerBridge

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        config.userContentController.add(bridge, name: "pointerLock")
        config.userContentController.add(bridge, name: "keyboard")

        // 1) GM_* API shims — must come first
        if let url = Bundle.main.url(forResource: "gm-shim", withExtension: "js"),
           let src = try? String(contentsOf: url) {
            config.userContentController.addUserScript(
                WKUserScript(source: src, injectionTime: .atDocumentStart, forMainFrameOnly: true)
            )
        }

        // 2) Better xCloud userscript
        if let url = Bundle.main.url(forResource: "better-xcloud.user", withExtension: "js"),
           let src = try? String(contentsOf: url) {
            config.userContentController.addUserScript(
                WKUserScript(source: src, injectionTime: .atDocumentStart, forMainFrameOnly: true)
            )
        }

        // 3) Our pointer-lock + diagnostics shim — last so our overrides win
        if let url = Bundle.main.url(forResource: "pointer-shim", withExtension: "js"),
           let src = try? String(contentsOf: url) {
            config.userContentController.addUserScript(
                WKUserScript(source: src, injectionTime: .atDocumentStart, forMainFrameOnly: true)
            )
        }

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = context.coordinator

        if let url = URL(string: "https://www.xbox.com/play") {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        // Handle target="_blank" — load in same WebView instead of dropping the link
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