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
            MediaControllerModule(),
            TodoListModule(),
            FileManagerModule(),
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

    /// Get the effective side for a module (user preference or default)
    func getEffectiveSide(for module: any NotchModule) -> ModuleSide {
        let assignments = SettingsManager.shared.moduleSideAssignments
        return assignments[module.id] ?? module.side
    }

    /// Get modules for the left side in user-defined order
    var leftModules: [any NotchModule] {
        let leftSideModules = collapsedModules.filter { getEffectiveSide(for: $0) == .left }
        return sortModulesByUserOrder(leftSideModules, orderArray: SettingsManager.shared.moduleOrderLeft)
    }

    /// Get modules for the right side in user-defined order
    var rightModules: [any NotchModule] {
        let rightSideModules = collapsedModules.filter { getEffectiveSide(for: $0) == .right }
        return sortModulesByUserOrder(rightSideModules, orderArray: SettingsManager.shared.moduleOrderRight)
    }

    /// Sort modules by user-defined order, fallback to priority
    private func sortModulesByUserOrder(_ modules: [any NotchModule], orderArray: [String]) -> [any NotchModule] {
        if orderArray.isEmpty {
            // No user order defined, use priority
            return modules.sorted { $0.priority > $1.priority }
        }

        // Sort by user order
        return modules.sorted { module1, module2 in
            let index1 = orderArray.firstIndex(of: module1.id) ?? Int.max
            let index2 = orderArray.firstIndex(of: module2.id) ?? Int.max

            if index1 == Int.max && index2 == Int.max {
                // Neither in order array, sort by priority
                return module1.priority > module2.priority
            }

            return index1 < index2
        }
    }
}
