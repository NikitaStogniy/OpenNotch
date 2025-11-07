//
//  NotchApp.swift
//  Notch
//
//  Created by Nikita Stogniy on 7/11/25.
//

import SwiftUI
import SwiftData
import AppKit

@main
struct NotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            StoredFile.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        // Pass model container to AppDelegate
        appDelegate.modelContainer = sharedModelContainer
    }

    var body: some Scene {
        MenuBarExtra("Notch", systemImage: "music.note") {
            MenuBarView()
                .modelContainer(sharedModelContainer)
        }
        .menuBarExtraStyle(.menu)
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var floatingWindowManager: FloatingWindowManager?
    var modelContainer: ModelContainer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 App launched!")

        // Hide dock icon (MenuBarExtra should do this automatically, but ensure it)
        NSApp.setActivationPolicy(.accessory)

        // Initialize floating window manager
        floatingWindowManager = FloatingWindowManager.shared

        // Model container will be set from NotchApp
        if let container = modelContainer {
            print("✅ Creating floating panel...")
            floatingWindowManager?.createFloatingPanel(modelContainer: container)
            floatingWindowManager?.show()
            print("✅ Floating panel created and shown!")
        } else {
            print("❌ Model container not available")
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Don't quit when closing the floating window
        return false
    }
}

// MARK: - App Access Extension
extension NotchApp {
    var sharedModelContainerPublic: ModelContainer {
        return sharedModelContainer
    }
}
