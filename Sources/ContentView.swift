import SwiftUI

struct ContentView: View {
    @StateObject private var bridge = GameControllerBridge()
    var body: some View {
        WebView(bridge: bridge)
            .ignoresSafeArea()
            .onAppear { bridge.start() }
    }
}