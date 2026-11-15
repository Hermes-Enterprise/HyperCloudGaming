import SwiftUI

struct ContentView: View {
    @StateObject private var model = WebViewModel()
    @State private var toolbarExpanded = false
    @State private var showHome = false
    @State private var showSettings = false
    @State private var urlField = ""

    var body: some View {
        ZStack(alignment: .top) {
            WebView(model: model).ignoresSafeArea()

            // Drag handle + collapsible toolbar
            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 40, height: 4)
                    .padding(.vertical, 6)
                    .onTapGesture { withAnimation { toolbarExpanded.toggle() } }
                    .gesture(
                        DragGesture(minimumDistance: 10)
                            .onEnded { value in
                                if value.translation.height > 20 { withAnimation { toolbarExpanded = true } }
                                if value.translation.height < -20 { withAnimation { toolbarExpanded = false } }
                            }
                    )

                if toolbarExpanded {
                    VStack(spacing: 8) {
                        // URL row
                        HStack {
                            TextField("URL", text: $urlField, onCommit: {
                                model.load(urlString: urlField)
                            })
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)

                            Button { model.reload() } label: { Image(systemName: "arrow.clockwise") }
                        }

                        // Navigation row
                        HStack(spacing: 20) {
                            Button { model.goBack() } label: { Image(systemName: "chevron.backward") }
                                .disabled(!model.canGoBack)
                            Button { model.goForward() } label: { Image(systemName: "chevron.forward") }
                                .disabled(!model.canGoForward)
                            Button { showHome = true } label: { Image(systemName: "house") }
                            Spacer()
                            Button { showSettings = true } label: { Image(systemName: "gearshape") }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .background(.ultraThinMaterial)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Diagnostic pill (always visible under the handle)
                Text(model.diagnosticMessage)
                    .font(.caption2.monospaced())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                    .padding(.top, 4)
                    .allowsHitTesting(false)
            }
        }
        .onAppear { urlField = model.currentURL }
        .onChange(of: model.currentURL) { urlField = $0 }
        .sheet(isPresented: $showHome) { HomeView(model: model) }
        .sheet(isPresented: $showSettings) { SettingsView() }
    }
}

struct HomeView: View {
    @ObservedObject var model: WebViewModel
    @Environment(\.dismiss) private var dismiss

    private let bookmarks: [(String, String)] = [
        ("Xbox Cloud Gaming", "https://www.xbox.com/play"),
        ("GeForce NOW", "https://play.geforcenow.com"),
        ("Luna", "https://luna.amazon.com")
    ]

    var body: some View {
        NavigationStack {
            List(bookmarks, id: \.1) { name, url in
                Button(name) {
                    model.load(urlString: url)
                    dismiss()
                }
            }
            .navigationTitle("Home")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Text("Settings coming soon").navigationTitle("Settings")
        }
    }
}