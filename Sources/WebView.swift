import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    @ObservedObject var model: WebViewModel
    func makeUIView(context: Context) -> WKWebView { model.webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}