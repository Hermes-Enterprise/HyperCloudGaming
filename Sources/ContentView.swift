import SwiftUI

struct ContentView: View {
    @StateObject private var bridge = GameControllerBridge()
    var body: some View {
        ZStack(alignment: .top) {
            WebView(bridge: bridge)
                .ignoresSafeArea()
                .onAppear { bridge.start() }

            Text(bridge.diagnosticStatus)
                .font(.caption.monospaced())
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.75))
                .cornerRadius(6)
                .padding(.top, 6)
                .allowsHitTesting(false)
        }
    }
}