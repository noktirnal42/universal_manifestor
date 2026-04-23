// UniversalManifestorApp.swift
import SwiftUI

@main
struct UniversalManifestorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.colorScheme, .dark)
        }
        #if os(macOS)
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        #endif
    }
}
