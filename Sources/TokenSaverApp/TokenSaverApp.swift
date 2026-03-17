import AppKit
import SwiftUI

@main
struct TokenSaverApp: App {
    @State private var model = AppModel()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra("TokenSaver", systemImage: "chart.bar.xaxis") {
            ContentView(model: self.model)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(model: self.model)
                .frame(width: 360, height: 220)
        }
    }
}
