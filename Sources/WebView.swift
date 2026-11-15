import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let bridge: GameControllerBridge

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        config.userContentController.add(bridge, name: "pointerLock")
        config.userContentController.add(bridge, name: "keyboard")

        // Inject pointer-lock + input shim at document start
        if let shimURL = Bundle.main.url(forResource: "pointer-shim", withExtension: "js"),
           let shim = try? String(contentsOf: shimURL) {
            let script = WKUserScript(source: shim, injectionTime: .atDocumentStart, forMainFrameOnly: true)
            config.userContentController.addUserScript(script)
        }

        // Inject bundled Better xCloud userscript
        if let bxURL = Bundle.main.url(forResource: "better-xcloud.user", withExtension: "js"),
           let bx = try? String(contentsOf: bxURL) {
            let script = WKUserScript(source: bx, injectionTime: .atDocumentStart, forMainFrameOnly: true)
            config.userContentController.addUserScript(script)
        }

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        if let url = URL(string: "https://www.xbox.com/play") {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}