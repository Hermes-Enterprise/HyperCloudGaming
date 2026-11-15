import SwiftUI

struct ContentView: View {
    @StateObject private var model = WebViewModel()
    @State private var showURLSheet = false
    @State private var showHome = false
    @State private var showSettings = false

    var body: some View {
        WebView(model: model)
            .ignoresSafeArea()
            .overlay(alignment: .top) {
                Text(model.diagnosticMessage)
                    .font(.caption2.monospaced())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                    .padding(.top, 8)
                    .allowsHitTesting(false)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                BrowserBar(
                    model: model,
                    showURLSheet: $showURLSheet,
                    showHome: $showHome,
                    showSettings: $showSettings
                )
            }
            .sheet(isPresented: $showURLSheet) {
                URLSheet(model: model)
                    .presentationDetents([.height(240)])
            }
            .sheet(isPresented: $showHome) {
                HomeView(model: model)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
    }
}

private struct BrowserBar: View {
    @ObservedObject var model: WebViewModel
    @Binding var showURLSheet: Bool
    @Binding var showHome: Bool
    @Binding var showSettings: Bool

    var body: some View {
        HStack(spacing: 0) {
            BarButton(icon: "chevron.backward", enabled: model.canGoBack) { model.goBack() }
            BarButton(icon: "chevron.forward", enabled: model.canGoForward) { model.goForward() }
            BarButton(icon: "arrow.clockwise") { model.reload() }
            BarButton(icon: "house") { showHome = true }
            BarButton(icon: "ellipsis") { showURLSheet = true }
            BarButton(icon: "gearshape") { showSettings = true }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(.white.opacity(0.15)),
            alignment: .top
        )
    }
}

private struct BarButton: View {
    let icon: String
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 34)
                .contentShape(Rectangle())
        }
        .disabled(!enabled)
        .opacity(enabled ? 1.0 : 0.35)
    }
}

private struct URLSheet: View {
    @ObservedObject var model: WebViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var urlField = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("URL", text: $urlField)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .keyboardType(.URL)
                        Button("Go") {
                            model.load(urlString: urlField)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                Section {
                    Button("Reload") {
                        model.reload()
                        dismiss()
                    }
                    Button("Reset app data & reload", role: .destructive) {
                        model.hardReset()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Browser")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { urlField = model.currentURL }
        }
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Text("Settings coming soon")
                .navigationTitle("Settings")
        }
    }
}