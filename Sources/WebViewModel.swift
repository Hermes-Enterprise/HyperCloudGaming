import SwiftUI
import WebKit

final class WebViewModel: NSObject, ObservableObject {
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = false
    @Published var currentURL = ""
    @Published var diagnosticMessage = "Waiting for injection..."

    let webView: WKWebView

    override init() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.websiteDataStore = .default() // persistent cookies

        // Inject scripts in order — no WKAppBoundDomains, so this will actually run.
        for (name, ext) in [("gm-shim", "js"), ("better-xcloud.user", "js"), ("pointer-shim", "js")] {
            if let url = Bundle.main.url(forResource: name, withExtension: ext),
               let source = try? String(contentsOf: url) {
                let script = WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false)
                config.userContentController.addUserScript(script)
            }
        }

        let handler = ScriptMessageProxy()
        config.userContentController.add(handler, name: "pointerLock")
        config.userContentController.add(handler, name: "keyboard")

        webView = WKWebView(frame: .zero, configuration: config)
        super.init()

        handler.owner = self
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = self

        // Load only once; do NOT clear cache here.
        webView.load(URLRequest(url: URL(string: "https://www.xbox.com/play")!))
    }

    func goBack() { webView.goBack() }
    func goForward() { webView.goForward() }
    func reload() { webView.reload() }
    func load(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        webView.load(URLRequest(url: url))
    }
}

extension WebViewModel: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isLoading = true
        currentURL = webView.url?.absoluteString ?? ""
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        currentURL = webView.url?.absoluteString ?? ""
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        isLoading = false
    }

    // Handle target="_blank"
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

// Small proxy so the view model can conform to WKScriptMessageHandler without retain cycles.
private final class ScriptMessageProxy: NSObject, WKScriptMessageHandler {
    weak var owner: WebViewModel?
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else { return }
        if let diag = body["diagnostic"] as? String {
            DispatchQueue.main.async { owner?.diagnosticMessage = diag }
        }
        // pointer-lock / keyboard messages can be forwarded to your bridge later.
    }
}