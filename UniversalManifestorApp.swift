import SwiftUI

@main
struct UniversalManifestorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .windowStyle(.titleBar)
        #endif
    }
}
