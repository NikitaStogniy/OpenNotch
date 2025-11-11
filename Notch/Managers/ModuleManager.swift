//
//  ModuleManager.swift
//  Notch
//
//  Created by Nikita Stogniy on 11/11/25.
//

import SwiftUI
import Combine

class ModuleManager: ObservableObject {
    static let shared = ModuleManager()

    @Published var availableModules: [any NotchModule] = []
    @Published var enabledModules: [any NotchModule] = []

    private init() {
        registerDefaultModules()
        updateEnabledModules()
    }

    /// Register default modules that ship with the app
    private func registerDefaultModules() {
        // Register built-in modules
        availableModules = [
            CalendarModule(),
            // Future modules can be added here
        ]
    }

    /// Update the list of enabled modules based on their isEnabled property
    func updateEnabledModules() {
        enabledModules = availableModules
            .filter { $0.isEnabled }
            .sorted { $0.priority > $1.priority }
    }

    /// Get module by ID
    func getModule(by id: String) -> (any NotchModule)? {
        return availableModules.first { $0.id == id }
    }

    /// Toggle module enabled state
    func toggleModule(id: String) {
        if let index = availableModules.firstIndex(where: { $0.id == id }) {
            availableModules[index].isEnabled.toggle()
            updateEnabledModules()
            objectWillChange.send()
        }
    }

    /// Get modules that should show in collapsed state
    var collapsedModules: [any NotchModule] {
        enabledModules.filter { $0.showInCollapsed }
    }
}
