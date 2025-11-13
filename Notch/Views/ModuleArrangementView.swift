//
//  ModuleArrangementView.swift
//  Notch
//
//  Created for OpenNotch
//

import SwiftUI
import Combine

/// View for arranging modules with drag-and-drop
struct ModuleArrangementView: View {
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var moduleManager = ModuleManager.shared

    @State private var leftModuleIds: [String] = []
    @State private var rightModuleIds: [String] = []
    @State private var draggedModule: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Module Arrangement")
                .font(.headline)
                .foregroundColor(.white)

            Text("Drag modules to reorder or move between sides")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))

            HStack(alignment: .top, spacing: 20) {
                // Left side
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(settings.getAccentColor())
                        Text("Left Side")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(spacing: 8) {
                        ForEach(leftModuleIds, id: \.self) { moduleId in
                            if let module = moduleManager.getModule(by: moduleId) {
                                ModuleDraggableCard(
                                    module: module,
                                    side: .left,
                                    onMove: moveModule,
                                    draggedModule: $draggedModule
                                )
                            }
                        }

                        // Drop zone for empty left side
                        if leftModuleIds.isEmpty {
                            EmptyDropZone(side: .left)
                                .dropDestination(for: String.self) { items, _ in
                                    handleDrop(items: items, to: .left, at: 0)
                                    return true
                                }
                        }
                    }
                    .frame(minHeight: 100)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 200)
                    .background(Color.white.opacity(0.2))

                // Right side
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Right Side")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(settings.getAccentColor())
                    }

                    VStack(spacing: 8) {
                        ForEach(rightModuleIds, id: \.self) { moduleId in
                            if let module = moduleManager.getModule(by: moduleId) {
                                ModuleDraggableCard(
                                    module: module,
                                    side: .right,
                                    onMove: moveModule,
                                    draggedModule: $draggedModule
                                )
                            }
                        }

                        // Drop zone for empty right side
                        if rightModuleIds.isEmpty {
                            EmptyDropZone(side: .right)
                                .dropDestination(for: String.self) { items, _ in
                                    handleDrop(items: items, to: .right, at: 0)
                                    return true
                                }
                        }
                    }
                    .frame(minHeight: 100)
                }
                .frame(maxWidth: .infinity)
            }

            // Preview
            NotchPreviewView()
                .frame(height: 60)
                .padding(.top, 8)
        }
        .padding()
        .onAppear {
            loadCurrentArrangement()
        }
    }

    /// Load the current arrangement from settings
    private func loadCurrentArrangement() {
        let allModules = moduleManager.availableModules.filter { $0.isEnabled }

        // Initialize from saved settings or defaults
        var tempLeft: [String] = []
        var tempRight: [String] = []

        for module in allModules {
            let side = moduleManager.getEffectiveSide(for: module)
            if side == .left {
                tempLeft.append(module.id)
            } else {
                tempRight.append(module.id)
            }
        }

        // Sort by saved order or priority
        leftModuleIds = sortByOrder(tempLeft, orderArray: settings.moduleOrderLeft)
        rightModuleIds = sortByOrder(tempRight, orderArray: settings.moduleOrderRight)
    }

    /// Sort module IDs by saved order or priority
    private func sortByOrder(_ ids: [String], orderArray: [String]) -> [String] {
        if orderArray.isEmpty {
            // Sort by priority
            return ids.sorted { id1, id2 in
                let module1 = moduleManager.getModule(by: id1)
                let module2 = moduleManager.getModule(by: id2)
                return (module1?.priority ?? 0) > (module2?.priority ?? 0)
            }
        }

        return ids.sorted { id1, id2 in
            let index1 = orderArray.firstIndex(of: id1) ?? Int.max
            let index2 = orderArray.firstIndex(of: id2) ?? Int.max
            return index1 < index2
        }
    }

    /// Move a module to a new side and position
    private func moveModule(moduleId: String, to side: ModuleSide, at index: Int) {
        // Remove from both sides
        leftModuleIds.removeAll { $0 == moduleId }
        rightModuleIds.removeAll { $0 == moduleId }

        // Add to the target side at the specified index
        if side == .left {
            leftModuleIds.insert(moduleId, at: min(index, leftModuleIds.count))
        } else {
            rightModuleIds.insert(moduleId, at: min(index, rightModuleIds.count))
        }

        // Save the arrangement
        saveArrangement()
    }

    /// Handle drop event
    private func handleDrop(items: [String], to side: ModuleSide, at index: Int) {
        guard let moduleId = items.first else { return }
        moveModule(moduleId: moduleId, to: side, at: index)
    }

    /// Save the current arrangement to settings
    private func saveArrangement() {
        // Update side assignments
        var assignments: [String: ModuleSide] = [:]
        for id in leftModuleIds {
            assignments[id] = .left
        }
        for id in rightModuleIds {
            assignments[id] = .right
        }
        settings.moduleSideAssignments = assignments

        // Update order
        settings.moduleOrderLeft = leftModuleIds
        settings.moduleOrderRight = rightModuleIds

        // Notify module manager to refresh
        moduleManager.objectWillChange.send()
    }
}

// MARK: - Draggable Module Card
struct ModuleDraggableCard: View {
    let module: any NotchModule
    let side: ModuleSide
    let onMove: (String, ModuleSide, Int) -> Void
    @Binding var draggedModule: String?

    @State private var isHovering = false
    @StateObject private var settings = SettingsManager.shared

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: module.miniIcon)
                .font(.system(size: 16))
                .foregroundColor(settings.getAccentColor())
                .frame(width: 24, height: 24)

            // Module name
            Text(module.name)
                .font(.system(size: 13))
                .foregroundColor(.white)

            Spacer()

            // Drag handle
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovering ? Color.white.opacity(0.08) : Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(draggedModule == module.id ? settings.getAccentColor() : Color.clear, lineWidth: 1)
        )
        .onHover { hovering in
            isHovering = hovering
        }
        .draggable(module.id) {
            // Drag preview
            HStack(spacing: 8) {
                Image(systemName: module.miniIcon)
                    .font(.system(size: 14))
                Text(module.name)
                    .font(.system(size: 12))
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(settings.getAccentColor().opacity(0.8))
            )
            .foregroundColor(.white)
        }
        .dropDestination(for: String.self) { items, _ in
            handleDrop(items: items)
            return true
        }
        .onAppear {
            // Update dragged state
            if draggedModule == module.id {
                draggedModule = nil
            }
        }
    }

    private func handleDrop(items: [String]) {
        guard let droppedId = items.first else { return }
        if let currentIndex = getCurrentIndex() {
            onMove(droppedId, side, currentIndex)
        }
    }

    private func getCurrentIndex() -> Int? {
        if side == .left {
            return SettingsManager.shared.moduleOrderLeft.firstIndex(of: module.id)
        } else {
            return SettingsManager.shared.moduleOrderRight.firstIndex(of: module.id)
        }
    }
}

// MARK: - Empty Drop Zone
struct EmptyDropZone: View {
    let side: ModuleSide
    @StateObject private var settings = SettingsManager.shared

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.down.circle.dotted")
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.3))

            Text("Drop modules here")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                        .foregroundColor(.white.opacity(0.2))
                )
        )
    }
}

#Preview {
    ModuleArrangementView()
        .frame(width: 600, height: 400)
        .background(Color.black)
}
