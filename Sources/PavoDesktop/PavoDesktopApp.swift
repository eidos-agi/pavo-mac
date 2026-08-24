import SwiftUI

@main
struct PavoDesktopApp: App {
    @StateObject private var desk = Desk()

    var body: some Scene {
        WindowGroup("Pavo Desktop") {
            RootView()
                .environmentObject(desk)
                .preferredColorScheme(.dark)
                .frame(minWidth: 1080, minHeight: 680)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1280, height: 800)

        Settings {
            SettingsView()
                .environmentObject(desk)
                .frame(width: 420, height: 320)
        }
    }
}
